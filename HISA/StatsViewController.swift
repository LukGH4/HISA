import UIKit
import FirebaseDatabase

class StatsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var filterButton: UIButton!

    var ref: DatabaseReference!
    var partTypes: [String: [String: Any]] = [:]
    var partTypeNames: [String] = []
    var filteredPartTypeNames: [String] = []
    var selectedPartsForComparison: [String] = []
    var selectedIndexPaths: Set<IndexPath> = []
    let failureRateThreshold: Double = -1.0

    enum FilterType {
        case none
        case failureRate(Double)
        case name(String)
        case dateRange(Date, Date)
    }

    var currentFilter: FilterType = .none

    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(StatsTableViewCell.self, forCellReuseIdentifier: "StatsCell")

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        tableView.addGestureRecognizer(longPressRecognizer)

        fetchPartTypesAndStatuses()
        setupCompareButton()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc func setupCompareButton() {
        let compareButton = UIButton(type: .system)
        compareButton.setTitle("Compare Selected", for: .normal)
        compareButton.addTarget(self, action: #selector(compareTapped), for: .touchUpInside)
        compareButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(compareButton)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl

        NSLayoutConstraint.activate([
            compareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            compareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc func dismissKeyboard(_ gesture: UITapGestureRecognizer) {
        let touchLocation = gesture.location(in: view)
        if !tableView.frame.contains(touchLocation) {
            searchBar.resignFirstResponder()
        }
    }

    @IBAction func filterButtonTapped(_ sender: UIButton) {
        showFilterOptions()
    }

    @objc func presentDateRangePicker() {
        let alert = UIAlertController(title: "Select Date Range", message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Start Date (yyyy-MM-dd)"
        }
        alert.addTextField { textField in
            textField.placeholder = "End Date (yyyy-MM-dd)"
        }

        alert.addAction(UIAlertAction(title: "Apply", style: .default, handler: { _ in
            guard
                let startText = alert.textFields?[0].text,
                let endText = alert.textFields?[1].text,
                let startDate = self.dateFormatter.date(from: startText),
                let endDate = self.dateFormatter.date(from: endText)
            else { return }

            self.currentFilter = .dateRange(startDate, endDate)
            self.applyCurrentFilter()
            self.tableView.reloadData()
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    func applyCurrentFilter() {
        switch currentFilter {
        case .none:
            filteredPartTypeNames = partTypeNames
        case .failureRate(let threshold):
            filteredPartTypeNames = partTypeNames.filter {
                if let statusCounts = self.partTypes[$0],
                   let goodCount = statusCounts["good"] as? Int,
                   let badCount = statusCounts["bad"] as? Int {
                    let total = goodCount + badCount
                    return total > 0 && (Double(badCount) / Double(total)) * 100 > threshold
                }
                return false
            }
        case .name(let filterString):
            filteredPartTypeNames = partTypeNames.filter {
                $0.lowercased().contains(filterString.lowercased())
            }
        case .dateRange(let start, let end):
            filteredPartTypeNames = partTypeNames.filter { name in
                guard let entries = partTypes[name]?["entries"] as? [[String: Any]] else { return false }
                return entries.contains(where: {
                    guard let dateStr = $0["date"] as? String,
                          let date = self.dateFormatter.date(from: dateStr) else { return false }
                    return date >= start && date <= end
                })
            }
        }
        filteredPartTypeNames.sort { $0.lowercased() < $1.lowercased() }
    }

    @objc func showFilterOptions() {
        let alert = UIAlertController(title: "Filter Options", message: "Choose a filter", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Failure Rate > 20%", style: .default, handler: { _ in
            self.currentFilter = .failureRate(20)
            self.applyCurrentFilter()
            self.tableView.reloadData()
        }))

        alert.addAction(UIAlertAction(title: "Filter by Name", style: .default, handler: { _ in
            let alertName = UIAlertController(title: "Filter by Name", message: "Enter name to filter by", preferredStyle: .alert)
            alertName.addTextField { textField in
                textField.placeholder = "Enter part name"
            }

            alertName.addAction(UIAlertAction(title: "Filter", style: .default, handler: { _ in
                if let nameFilter = alertName.textFields?.first?.text, !nameFilter.isEmpty {
                    self.currentFilter = .name(nameFilter)
                } else {
                    self.currentFilter = .none
                }
                self.applyCurrentFilter()
                self.tableView.reloadData()
            }))

            alertName.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alertName, animated: true)
        }))

        alert.addAction(UIAlertAction(title: "Filter by Date", style: .default, handler: { _ in
            self.presentDateRangePicker()
        }))

        alert.addAction(UIAlertAction(title: "Show All", style: .default, handler: { _ in
            self.currentFilter = .none
            self.applyCurrentFilter()
            self.tableView.reloadData()
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func fetchPartTypesAndStatuses() {
        ref.child("users").child("employees").observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                var localPartTypes: [String: [String: Any]] = [:]

                for employeeSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                    let imagesRef = employeeSnapshot.childSnapshot(forPath: "images")
                    let videosRef = employeeSnapshot.childSnapshot(forPath: "videos")

                    for imageSnapshot in imagesRef.children.allObjects as! [DataSnapshot] {
                        if let partType = imageSnapshot.childSnapshot(forPath: "part_type").value as? String,
                           let status = imageSnapshot.childSnapshot(forPath: "status").value as? String {
                            var partTypeEntry = localPartTypes[partType] ?? ["good": 0, "bad": 0, "entries": []]
                            if status == "Good Part" {
                                partTypeEntry["good"] = (partTypeEntry["good"] as? Int ?? 0) + 1
                            } else {
                                partTypeEntry["bad"] = (partTypeEntry["bad"] as? Int ?? 0) + 1
                            }
                            if let dateStr = imageSnapshot.childSnapshot(forPath: "date").value as? String {
                                var entries = partTypeEntry["entries"] as? [[String: Any]] ?? []
                                entries.append(["date": dateStr])
                                partTypeEntry["entries"] = entries
                            }
                            localPartTypes[partType] = partTypeEntry
                        }
                    }

                    for videoSnapshot in videosRef.children.allObjects as! [DataSnapshot] {
                        if let partType = videoSnapshot.childSnapshot(forPath: "part_type").value as? String,
                           let status = videoSnapshot.childSnapshot(forPath: "status").value as? String {
                            var partTypeEntry = localPartTypes[partType] ?? ["good": 0, "bad": 0, "entries": []]
                            if status == "Good Part" {
                                partTypeEntry["good"] = (partTypeEntry["good"] as? Int ?? 0) + 1
                            } else {
                                partTypeEntry["bad"] = (partTypeEntry["bad"] as? Int ?? 0) + 1
                            }
                            if let dateStr = videoSnapshot.childSnapshot(forPath: "date").value as? String {
                                var entries = partTypeEntry["entries"] as? [[String: Any]] ?? []
                                entries.append(["date": dateStr])
                                partTypeEntry["entries"] = entries
                            }
                            localPartTypes[partType] = partTypeEntry
                        }
                    }
                }

                self.savePartCountsToFirebase(localPartTypes)
                DispatchQueue.main.async {
                    self.partTypes = localPartTypes
                    self.partTypeNames = Array(self.partTypes.keys)
                    self.applyCurrentFilter()
                    self.tableView.reloadData()
                    self.checkFailureRates()
                    self.tableView.refreshControl?.endRefreshing()
                }
            } else {
                print("No data found")
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
                }
            }
        }) { error in
            print("Error retrieving data: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.tableView.refreshControl?.endRefreshing()
            }
        }
    }

    func savePartCountsToFirebase(_ partCounts: [String: [String: Any]]) {
        let partsRef = Database.database().reference().child("parts")

        for (partType, statusCounts) in partCounts {
            let partTypeRef = partsRef.child(partType)
            partTypeRef.updateChildValues([
                "good": statusCounts["good"] ?? 0,
                "bad": statusCounts["bad"] ?? 0
            ]) { error, _ in
                if let error = error {
                    print("Failed to update counts for \(partType): \(error.localizedDescription)")
                } else {
                    print("Successfully updated counts for \(partType)")
                }
            }
        }
    }

    func checkFailureRates() {
        var alertMessage = "The following parts have surpassed the failure threshold:\n"
        var hasHighFailureRate = false
        var thresholdFetchCount = 0
        let totalPartTypes = partTypes.count
        var partMessages: [String] = []

        for (partType, statusCounts) in partTypes {
            if let goodCount = statusCounts["good"] as? Int,
               let badCount = statusCounts["bad"] as? Int {
                let total = goodCount + badCount
                let failureRatio = total > 0 ? (Double(badCount) / Double(total)) * 100 : 0.0

                fetchThreshold(for: partType) { threshold in
                    let partTypeThreshold = threshold ?? self.failureRateThreshold
                    if failureRatio > partTypeThreshold {
                        partMessages.append("\(partType): \(String(format: "%.2f", failureRatio))%")
                        hasHighFailureRate = true
                    }
                    thresholdFetchCount += 1

                    if thresholdFetchCount == totalPartTypes {
                        if hasHighFailureRate {
                            alertMessage += partMessages.joined(separator: "\n")
                            DispatchQueue.main.async {
                                let alert = UIAlertController(title: "High Failure Rate Alert", message: alertMessage, preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .default))
                                self.present(alert, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }

    func fetchThreshold(for partType: String, completion: @escaping (Double?) -> Void) {
        let partsRef = Database.database().reference().child("parts").child(partType)

        partsRef.observeSingleEvent(of: .value, with: { snapshot in
            if let data = snapshot.value as? [String: Any], let storedThreshold = data["threshold"] as? Double {
                completion(storedThreshold)
            } else {
                completion(nil)
            }
        }) { error in
            print("Error retrieving threshold for part type \(partType): \(error.localizedDescription)")
            completion(nil)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredPartTypeNames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StatsCell", for: indexPath) as! StatsTableViewCell
        let partType = filteredPartTypeNames[indexPath.row]
        
        if let statusCounts = partTypes[partType] {
            var goodCount = 0
            var badCount = 0
            
            // If date range filter is active, count only entries within the range
            if case .dateRange(let start, let end) = currentFilter,
               let entries = statusCounts["entries"] as? [[String: Any]] {
                for entry in entries {
                    if let dateStr = entry["date"] as? String,
                       let date = dateFormatter.date(from: dateStr),
                       date >= start && date <= end {
                        // Get status from the original data if available, or use the aggregated counts
                        let status = statusCounts["status"] as? String ?? ""
                        if status == "Good Part" || (status == "" && statusCounts["good"] as? Int ?? 0 > 0) {
                            goodCount += 1
                        } else {
                            badCount += 1
                        }
                    }
                }
            } else {
                // Use total counts when no date filter is applied
                goodCount = statusCounts["good"] as? Int ?? 0
                badCount = statusCounts["bad"] as? Int ?? 0
            }
            
            cell.configure(with: partType, goodCount: goodCount, badCount: badCount)
        }
        
        cell.accessoryType = selectedIndexPaths.contains(indexPath) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let partType = filteredPartTypeNames[indexPath.row]

        if selectedPartsForComparison.contains(partType) {
            selectedPartsForComparison.removeAll { $0 == partType }
            selectedIndexPaths.remove(indexPath)
        } else {
            selectedPartsForComparison.append(partType)
            selectedIndexPaths.insert(indexPath)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                let partType = filteredPartTypeNames[indexPath.row]
                performSegue(withIdentifier: "showPartDetail", sender: partType)
            }
        }
    }

    @objc func compareTapped() {
        if selectedPartsForComparison.count >= 2 {
            performSegue(withIdentifier: "showComparison", sender: nil)
        } else {
            let alert = UIAlertController(title: "Selection Required",
                                          message: "Please select at least two parts to compare.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPartDetail", let partType = sender as? String {
            let partDetailVC = segue.destination as! PartDetailViewController
            partDetailVC.partType = partType
            if case .dateRange(let start, let end) = currentFilter {
                partDetailVC.dateRange = (start, end)
            }
        } else if segue.identifier == "showComparison" {
            let comparisonVC = segue.destination as! ComparisonViewController
            comparisonVC.selectedParts = selectedPartsForComparison
            if case .dateRange(let start, let end) = currentFilter {
                comparisonVC.dateRange = (start, end)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchPartTypesAndStatuses()
    }

    @objc func refreshData() {
        fetchPartTypesAndStatuses()
    }
}
