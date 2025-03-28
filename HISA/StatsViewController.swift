import UIKit
import FirebaseDatabase

class StatsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var ref: DatabaseReference!
    var partTypes: [String: [String: Any]] = [:]
    var partTypeNames: [String] = []
    
    var selectedPartsForComparison: [String] = [] // Array to store selected parts for comparison
    var selectedIndexPaths: Set<IndexPath> = [] // Array to store selected parts for comparison
    
    let failureRateThreshold: Double = -1.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        tableView.register(StatsTableViewCell.self, forCellReuseIdentifier: "StatsCell")
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        tableView.addGestureRecognizer(longPressRecognizer)
        
        fetchPartTypesAndStatuses()
        
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
        
        print("Stats Screen Loaded")
    }
    
    func fetchPartTypesAndStatuses() {
        let employeesRef = ref.child("users").child("employees")
        employeesRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                var localPartTypes: [String: [String: Any]] = [:]
                for employeeSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                    let imagesRef = employeeSnapshot.childSnapshot(forPath: "images")
                    let videosRef = employeeSnapshot.childSnapshot(forPath: "videos")
                    for imageSnapshot in imagesRef.children.allObjects as! [DataSnapshot] {
                        if let partType = imageSnapshot.childSnapshot(forPath: "part_type").value as? String,
                           let status = imageSnapshot.childSnapshot(forPath: "status").value as? String {
                            var partTypeEntry = localPartTypes[partType] ?? ["good": 0, "bad": 0]
                            
                            if status == "Good Part" {
                                partTypeEntry["good"] = (partTypeEntry["good"] as? Int ?? 0) + 1
                            } else {
                                partTypeEntry["bad"] = (partTypeEntry["bad"] as? Int ?? 0) + 1
                            }
                            localPartTypes[partType] = partTypeEntry
                        }
                    }
                    for videoSnapshot in videosRef.children.allObjects as! [DataSnapshot] {
                        if let partType = videoSnapshot.childSnapshot(forPath: "part_type").value as? String,
                           let status = videoSnapshot.childSnapshot(forPath: "status").value as? String {
                            var partTypeEntry = localPartTypes[partType] ?? ["good": 0, "bad": 0]
                            
                            if status == "Good Part" {
                                partTypeEntry["good"] = (partTypeEntry["good"] as? Int ?? 0) + 1
                            } else {
                                partTypeEntry["bad"] = (partTypeEntry["bad"] as? Int ?? 0) + 1
                            }
                            localPartTypes[partType] = partTypeEntry
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.partTypes = localPartTypes
                    self.partTypeNames = Array(self.partTypes.keys)
                    self.tableView.reloadData()
                    self.checkFailureRates()
                }
            } else {
                print("No data found")
            }
        }) { error in
            print("Error retrieving data: \(error.localizedDescription)")
        }
    }

    
    func checkFailureRates() {
        var alertMessage = "The following parts have surpassed the failure threshold:\n"
        var hasHighFailureRate = false
        var thresholdFetchCount = 0
        let totalPartTypes = partTypes.count
        for (partType, statusCounts) in partTypes {
            if let goodCount = statusCounts["good"] as? Int,
               let badCount = statusCounts["bad"] as? Int {
                let total = goodCount + badCount
                let failureRatio = total > 0 ? (Double(badCount) / Double(total)) * 100 : 0.0
                
                fetchThreshold(for: partType) { threshold in
                    let partTypeThreshold = threshold ?? self.failureRateThreshold
                    if failureRatio > partTypeThreshold {
                        alertMessage += "\(partType): \(String(format: "%.2f", failureRatio))%\n"
                        hasHighFailureRate = true
                    }
                    thresholdFetchCount += 1
                    if thresholdFetchCount == totalPartTypes {
                        if hasHighFailureRate {
                            DispatchQueue.main.async {
                                let alert = UIAlertController(title: "High Failure Rate Alert", message: alertMessage, preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
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
                print("Fetched threshold for \(partType): \(storedThreshold)")
                completion(storedThreshold)
            } else {
                print("No threshold found for \(partType). Using default.")
                completion(nil)
            }
        }) { error in
            print("Error retrieving threshold for part type \(partType): \(error.localizedDescription)")
            completion(nil)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return partTypeNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StatsCell", for: indexPath) as! StatsTableViewCell
        let partType = partTypeNames[indexPath.row]
        if let statusCounts = partTypes[partType],
           let goodCount = statusCounts["good"] as? Int,
           let badCount = statusCounts["bad"] as? Int {
            cell.configure(with: partType, goodCount: goodCount, badCount: badCount)
        }
        
        if selectedIndexPaths.contains(indexPath) {
            cell.accessoryType = .checkmark
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                let partType = partTypeNames[indexPath.row]
                performSegue(withIdentifier: "showPartDetail", sender: partType)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let partType = partTypeNames[indexPath.row]
        
        if selectedPartsForComparison.contains(partType) {
            // Deselect if already selected
            selectedPartsForComparison.removeAll { $0 == partType }
            selectedIndexPaths.remove(indexPath)
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            // Select if not selected
            selectedPartsForComparison.append(partType)
            selectedIndexPaths.insert(indexPath)
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        }
    }
    
    @objc func compareTapped(_ sender: UIBarButtonItem) {
        // Present a selection view for the manager to select multiple parts
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
        } else if segue.identifier == "showComparison" {
            let comparisonVC = segue.destination as! ComparisonViewController
            comparisonVC.selectedParts = selectedPartsForComparison
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.checkFailureRates()
        fetchPartTypesAndStatuses()
    }
    
    @objc func refreshData() {
        fetchPartTypesAndStatuses()
        
        tableView.refreshControl?.endRefreshing()
    }
}
