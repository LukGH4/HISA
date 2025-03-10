//
//  StatsViewController.swift
//  HISA
//
//  Created by Hoyeon Kang on 11/16/24.
//

import UIKit
import FirebaseDatabase

class StatsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var ref: DatabaseReference!
    var partTypes: [String: [String: Any]] = [:]
    var partTypeNames: [String] = []
    
    let failureRateThreshold: Double = 0.0 //hardcoded for testing, will make editable from managers later

    override func viewDidLoad() {
        super.viewDidLoad()

        ref = Database.database().reference()

        tableView.dataSource = self
        tableView.delegate = self

        fetchPartTypesAndStatuses()

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
        var alertMessage = "The following part types have a high failure rate\n"
        var hasHighFailureRate = false
        
        for (partType, statusCounts) in partTypes {
            if let goodCount = statusCounts["good"] as? Int,
               let badCount = statusCounts["bad"] as? Int {
                let total = goodCount + badCount
                let failureRatio = total > 0 ? (Double(badCount) / Double(total)) * 100 : 0.0

                if failureRatio >= failureRateThreshold {
                    alertMessage += "\(partType): \(failureRatio)%\n"
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "PartTypeCell", for: indexPath)
        let partType = partTypeNames[indexPath.row]
        cell.textLabel?.text = partType
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let partType = partTypeNames[indexPath.row]
        if let statusCounts = partTypes[partType],
           let goodCount = statusCounts["good"] as? Int,
           let badCount = statusCounts["bad"] as? Int {
            let total = goodCount + badCount
            let failureRatio  = badCount/total * 100

            let alert = UIAlertController(title: "Part Information", message: "Part Type: \(partType)\nFailure Ratio: \(failureRatio)%", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

