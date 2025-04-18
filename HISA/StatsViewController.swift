import UIKit
import FirebaseDatabase
import Charts
import SwiftUI

class StatsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIScrollViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var filterButton: UIButton!

    var ref: DatabaseReference!
    var partTypes: [String: [String: Any]] = [:]
    var partTypeNames: [String] = []
    var filteredPartTypeNames: [String] = []
    var selectedPartsForComparison: [String] = []
    var selectedIndexPaths: Set<IndexPath> = []
    var scanHistory: [(date: String, count: Int)] = []
    var failureRateHistory: [(date: String, rate: Double)] = []
    let failureRateThreshold: Double = -1.0

    private var buttonStackView: UIStackView!
    private var bottomConstraint: NSLayoutConstraint!

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

    enum Section: Int, CaseIterable {
        case parts = 0
        case charts

        var title: String {
            switch self {
            case .parts: return "Parts Statistics"
            case .charts: return "Scan Charts"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.register(StatsTableViewCell.self, forCellReuseIdentifier: "StatsCell")
        tableView.register(ManagerChartTableViewCell.self, forCellReuseIdentifier: "ChartCell")

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        tableView.addGestureRecognizer(longPressRecognizer)

        setupButtons()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl

        fetchAllData()
    }

    @objc func setupButtons() {
        // Create buttons
        let compareButton = UIButton(type: .system)
        compareButton.setTitle("Compare Selected", for: .normal)
        compareButton.addTarget(self, action: #selector(compareTapped), for: .touchUpInside)

        let exportSelectedButton = UIButton(type: .system)
        exportSelectedButton.setTitle("Export Selected", for: .normal)
        exportSelectedButton.addTarget(self, action: #selector(exportSelectedTapped), for: .touchUpInside)

        let exportAllButton = UIButton(type: .system)
        exportAllButton.setTitle("Export All", for: .normal)
        exportAllButton.addTarget(self, action: #selector(exportAllTapped), for: .touchUpInside)

        // Create stack view
        buttonStackView = UIStackView(arrangedSubviews: [compareButton, exportSelectedButton, exportAllButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 16
        buttonStackView.distribution = .equalSpacing
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStackView)

        // Anchor to bottom of safe area
        bottomConstraint = buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)

        NSLayoutConstraint.activate([
            bottomConstraint,
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }

    @objc func exportSelectedTapped() {
        guard !selectedPartsForComparison.isEmpty else {
            let alert = UIAlertController(title: "No Parts Selected",
                                          message: "Please select at least one part to export.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Aggregate data for selected parts by date
        var dateCounts: [String: (good: Int, bad: Int)] = [:]
        for partType in selectedPartsForComparison {
            if let entries = partTypes[partType]?["entries"] as? [[String: Any]] {
                for entry in entries {
                    guard let dateStr = entry["date"] as? String else { continue }
                    let status = entry["status"] as? String ?? ""
                    var counts = dateCounts[dateStr] ?? (good: 0, bad: 0)
                    if status == "Good Part" || (status == "" && partTypes[partType]?["good"] as? Int ?? 0 > 0) {
                        counts.good += 1
                    } else {
                        counts.bad += 1
                    }
                    dateCounts[dateStr] = counts
                }
            }
        }

        // Convert to CSV format
        let data = dateCounts.map { (date, counts) in
            let total = counts.good + counts.bad
            let failureRate = total > 0 ? (Double(counts.bad) / Double(total)) * 100 : 0.0
            return (date: date, total: total, good: counts.good, bad: counts.bad, rate: failureRate)
        }.sorted { $0.date > $1.date } // Sort by date descending

        let csvContent = generateCSV(from: data)
        shareCSV(content: csvContent, fileName: "SelectedPartsStats.csv")
    }

    @objc func exportAllTapped() {
        // Use scanHistory and failureRateHistory for all parts
        let data = scanHistory.enumerated().map { (index, scan) in
            let rate = failureRateHistory.first(where: { $0.date == scan.date })?.rate ?? 0.0
            let bad = Int(round(Double(scan.count) * (rate / 100.0)))
            let good = scan.count - bad
            return (date: scan.date, total: scan.count, good: good, bad: bad, rate: rate)
        }.sorted { $0.date > $1.date } // Sort by date descending

        let csvContent = generateCSV(from: data)
        shareCSV(content: csvContent, fileName: "AllPartsStats.csv")
    }

    private func generateCSV(from data: [(date: String, total: Int, good: Int, bad: Int, rate: Double)]) -> String {
        var csv = "Date,Total Scans,Good Scans,Bad Scans,Failure Rate (%)\n"
        for item in data {
            let rateFormatted = String(format: "%.2f", item.rate)
            csv += "\(item.date),\(item.total),\(item.good),\(item.bad),\(rateFormatted)\n"
        }
        return csv
    }

    private func shareCSV(content: String, fileName: String) {
        // Write CSV content to a temporary file
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            activityVC.excludedActivityTypes = [.addToReadingList, .assignToContact]
            present(activityVC, animated: true)
        } catch {
            print("Failed to write CSV file: \(error.localizedDescription)")
            let alert = UIAlertController(title: "Export Failed",
                                          message: "Unable to generate CSV file. Please try again.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
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
        print("Applying filter: \(currentFilter)")
        let previousRowCount = filteredPartTypeNames.count
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
        print("Filtered part types count changed from \(previousRowCount) to \(filteredPartTypeNames.count)")
    }

    private func updateCharts() {
        print("Updating charts section")
        tableView.reloadSections(IndexSet(integer: Section.charts.rawValue), with: .none)
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

    private func fetchAllData() {
        print("Fetching all data")
        // Reset data to avoid stale state
        partTypes.removeAll()
        partTypeNames.removeAll()
        filteredPartTypeNames.removeAll()
        scanHistory.removeAll()
        failureRateHistory.removeAll()

        let dispatchGroup = DispatchGroup()

        // Fetch part types
        dispatchGroup.enter()
        fetchPartTypesAndStatuses { [weak self] in
            dispatchGroup.leave()
        }

        // Fetch scan history and failure rates
        dispatchGroup.enter()
        fetchScanHistory { [weak self] in
            dispatchGroup.leave()
        }

        // Update UI after both fetches complete
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            print("All data fetched. Part types: \(self.partTypeNames.count), Scan history: \(self.scanHistory.count), Failure rate history: \(self.failureRateHistory.count)")
            self.applyCurrentFilter()
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
    }

    private func fetchPartTypesAndStatuses(completion: @escaping () -> Void) {
        ref.child("users").child("employees").observeSingleEvent(of: .value, with: { snapshot in
            var localPartTypes: [String: [String: Any]] = [:]

            if snapshot.exists() {
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
                                entries.append(["date": dateStr, "status": status])
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
                                entries.append(["date": dateStr, "status": status])
                                partTypeEntry["entries"] = entries
                            }
                            localPartTypes[partType] = partTypeEntry
                        }
                    }
                }

                self.savePartCountsToFirebase(localPartTypes)
                self.partTypes = localPartTypes
                self.partTypeNames = Array(localPartTypes.keys)
            } else {
                print("No data found for part types")
            }
            completion()
        }) { error in
            print("Error retrieving part types: \(error.localizedDescription)")
            completion()
        }
    }

    private func fetchScanHistory(completion: @escaping () -> Void) {
        ref.child("users").child("employees").observeSingleEvent(of: .value, with: { snapshot in
            var scanCounts: [String: Int] = [:]
            var badCounts: [String: Int] = [:]

            if snapshot.exists() {
                for employeeSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                    ["images", "videos"].forEach { mediaType in
                        let mediaRef = employeeSnapshot.childSnapshot(forPath: mediaType)
                        for mediaSnapshot in mediaRef.children.allObjects as! [DataSnapshot] {
                            if let date = mediaSnapshot.childSnapshot(forPath: "date").value as? String {
                                scanCounts[date] = (scanCounts[date] ?? 0) + 1
                                if let status = mediaSnapshot.childSnapshot(forPath: "status").value as? String, status != "Good Part" {
                                    badCounts[date] = (badCounts[date] ?? 0) + 1
                                }
                            }
                        }
                    }
                }

                // Calculate scan history
                var history = scanCounts.map { (date: $0.key, count: $0.value) }
                    .sorted { $0.date > $1.date }
                if history.count > 30 {
                    history = Array(history[0..<30])
                }
                self.scanHistory = history

                // Calculate failure rate history
                var failureRates = scanCounts.map { (date: $0.key, total: $0.value) }
                    .map { (date: $0.date, rate: Double(badCounts[$0.date] ?? 0) / Double($0.total) * 100) }
                    .sorted { $0.date > $1.date }
                if failureRates.count > 30 {
                    failureRates = Array(failureRates[0..<30])
                }
                self.failureRateHistory = failureRates
            }
            completion()
        }) { error in
            print("Error retrieving scan history: \(error.localizedDescription)")
            completion()
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

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return 44 // Standard header height to prevent overlap
        }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rowCount: Int
        switch Section(rawValue: section) {
        case .parts:
            rowCount = filteredPartTypeNames.count
        case .charts:
            rowCount = 1
        default:
            rowCount = 0
        }
        print("Number of rows in section \(section): \(rowCount)")
        return rowCount
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if Section(rawValue: section) == .parts {
            let footerView = UIView()
            footerView.backgroundColor = .clear
            return footerView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if Section(rawValue: section) == .parts {
            return 16 // Add padding between parts and charts sections
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .parts:
            let cell = tableView.dequeueReusableCell(withIdentifier: "StatsCell", for: indexPath) as! StatsTableViewCell
            let partType = filteredPartTypeNames[indexPath.row]
            
            if let statusCounts = partTypes[partType] {
                var goodCount = 0
                var badCount = 0
                
                if case .dateRange(let start, let end) = currentFilter,
                   let entries = statusCounts["entries"] as? [[String: Any]] {
                    for entry in entries {
                        if let dateStr = entry["date"] as? String,
                           let date = dateFormatter.date(from: dateStr),
                           date >= start && date <= end {
                            let status = statusCounts["status"] as? String ?? ""
                            if status == "Good Part" || (status == "" && statusCounts["good"] as? Int ?? 0 > 0) {
                                goodCount += 1
                            } else {
                                badCount += 1
                            }
                        }
                    }
                } else {
                    goodCount = statusCounts["good"] as? Int ?? 0
                    badCount = statusCounts["bad"] as? Int ?? 0
                }
                
                cell.configure(with: partType, goodCount: goodCount, badCount: badCount)
            }
            
            cell.accessoryType = selectedIndexPaths.contains(indexPath) ? .checkmark : .none
            return cell
            
        case .charts:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChartCell", for: indexPath) as! ManagerChartTableViewCell
            
            var partsData: [String: Double] = [:]
            for (partType, counts) in partTypes {
                if let good = counts["good"] as? Int, let bad = counts["bad"] as? Int {
                    partsData[partType] = Double(good) + Double(bad)
                }
            }
            
            cell.configure(
                partsData: partsData,
                scanHistoryData: scanHistory.map { ($0.date, $0.count) },
                failureRateData: failureRateHistory.map { ($0.date, $0.rate)}
            )
            return cell
            
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if Section(rawValue: indexPath.section) == .charts {
            return 850 // Height for three charts
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if Section(rawValue: indexPath.section) == .parts {
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
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint), Section(rawValue: indexPath.section) == .parts {
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
        fetchAllData()
    }

    @objc func refreshData() {
        fetchAllData()
    }
}

// Update ChartsView to include the new FailureRateChartView and add top padding
struct ManagerChartsView: View {
    let partsData: [String: Double]
    let scanHistoryData: [(String, Int)]
    let failureRateData: [(String, Double)]

    var body: some View {
        VStack(spacing: 16) {
            PartsDistributionChartView(data: partsData)
            ScanHistoryChartView(data: scanHistoryData)
            OverallFailureRateChartView(data: failureRateData)
        }
        .padding(.top, 30) // Add top padding to prevent overlap with section header
    }
}

// FailureRateChartView for displaying failure rate over time
struct OverallFailureRateChartView: View {
    let data: [(date: Date, rate: Double)]
    private let dateFormatter: DateFormatter

    init(data: [(date: String, rate: Double)]) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateFormatter = formatter

        self.data = data.compactMap { (dateString, rate) in
            guard let date = formatter.date(from: dateString) else { return nil }
            return (date: date, rate: rate)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Failure Rate Over Time (%)")
                .font(.headline)
                .foregroundColor(.primary)

            if data.isEmpty {
                Text("No failure rate data available")
                    .frame(height: 200)
            } else {
                Chart {
                    ForEach(data, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Failure Rate (%)", item.rate)
                        )
                        .interpolationMethod(.linear)

                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Failure Rate (%)", item.rate)
                        )
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        if let date = value.as(Date.self) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                Text(date, format: .dateTime.day().month())
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartLegend(position: .bottom, alignment: .center, spacing: 20)
                .frame(height: 200)
                .padding()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

class ManagerChartTableViewCell: UITableViewCell {
    private var managerHostingController: UIHostingController<AnyView>?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        managerHostingController?.view.removeFromSuperview()
        managerHostingController = nil
    }
    
    func configure(partsData: [String: Double], scanHistoryData: [(String, Int)], failureRateData: [(String, Double)]) {
        let chartsView = ManagerChartsView(partsData: partsData, scanHistoryData: scanHistoryData, failureRateData: failureRateData)
        let hostingController = UIHostingController(rootView: AnyView(chartsView))

        guard let hostView = hostingController.view else { return }
        contentView.addSubview(hostView)
        hostView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostView.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            hostView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        hostingController.didMove(toParent: parentViewController)
    }
}

extension UIView {
    var managerParentResponder: UIViewController? {
        var managerParentResponder: UIResponder? = self
        while managerParentResponder != nil {
            managerParentResponder = managerParentResponder?.next
            if let viewController = managerParentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
