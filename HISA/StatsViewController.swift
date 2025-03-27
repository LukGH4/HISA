import UIKit
import FirebaseDatabase

class StatsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var ref: DatabaseReference!
    var partTypes: [String: [String: Any]] = [:]
    var partTypeNames: [String] = []
    
    var selectedPartsForComparison: [String] = [] // Array to store selected parts for comparison
    
    let failureRateThreshold: Double = -1.0
    

    override func viewDidLoad() {
        super.viewDidLoad()

        ref = Database.database().reference()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        tableView.register(StatsTableViewCell.self, forCellReuseIdentifier: "StatsCell")
        
        fetchPartTypesAndStatuses()
        
        let compareButton = UIButton(type: .system)
        compareButton.setTitle("Compare", for: .normal)
        compareButton.addTarget(self, action: #selector(compareTapped), for: .touchUpInside)
        compareButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(compareButton)

        // Add constraints
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
        
        for (partType, statusCounts) in partTypes {
            if let goodCount = statusCounts["good"] as? Int,
               let badCount = statusCounts["bad"] as? Int {
                let total = goodCount + badCount
                let failureRatio = total > 0 ? (Double(badCount) / Double(total)) * 100 : 0.0

                if failureRatio > failureRateThreshold {
                    alertMessage += "\(partType): \(String(format: "%.2f", failureRatio))%\n"
                    hasHighFailureRate = true
                }
            }
        }
        if hasHighFailureRate {
            let alert = UIAlertController(title: "High Failure Rate Alert", message: alertMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
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
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let partType = partTypeNames[indexPath.row]
        
        // Navigate to PartDetailViewController
        performSegue(withIdentifier: "showPartDetail", sender: partType)
    }

    @objc func compareTapped(_ sender: UIBarButtonItem) {
        // Present a selection view for the manager to select multiple parts
        let alertController = UIAlertController(title: "Select Parts for Comparison", message: nil, preferredStyle: .alert)

        for partType in partTypeNames {
            alertController.addAction(UIAlertAction(title: partType, style: .default, handler: { [weak self] _ in
                self?.selectedPartsForComparison.append(partType)
            }))
        }

        alertController.addAction(UIAlertAction(title: "Done", style: .default, handler: { [weak self] _ in
            // Navigate to ComparisonViewController
            if self?.selectedPartsForComparison.count ?? 0 > 1 {
                self?.performSegue(withIdentifier: "showComparison", sender: nil)
            } else {
                let errorAlert = UIAlertController(title: "Error", message: "Please select at least two parts to compare.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(errorAlert, animated: true)
            }
        }))

        present(alertController, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPartDetail", let partType = sender as? String {
            // Pass the partType to PartDetailViewController
            let partDetailVC = segue.destination as! PartDetailViewController
            partDetailVC.partType = partType
        } else if segue.identifier == "showComparison" {
            // Ensure that selectedPartsForComparison is populated with the correct data
            let comparisonVC = segue.destination as! ComparisonViewController
            comparisonVC.selectedParts = selectedPartsForComparison
        }
    }

}
