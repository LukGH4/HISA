//
//  EmployeeDetailViewController.swift
//  HISA
//
//  Created by Barnabas Li on 1/23/25.
//


import UIKit

class EmployeeDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var dataAccessControl: UISwitch!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var scansLabel: UILabel!
    
    @IBOutlet weak var scanHistoryTableView: UITableView!

    var employee: Employee!

    override func viewDidLoad() {
        super.viewDidLoad()

        nameLabel.text = employee.name
        dateLabel.text = employee.date
        scansLabel.text = "\(employee.scans)"
        // slider button for data access
        dataAccessControl.isOn = employee.dataAccess
        
        scanHistoryTableView.dataSource = self
        scanHistoryTableView.delegate = self
        scanHistoryTableView.reloadData()
        
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return employee.scanHistory.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScanHistoryCell", for: indexPath)
        let scanHistoryItem = employee.scanHistory[indexPath.row]

        cell.textLabel?.text = scanHistoryItem

        cell.textLabel?.textColor = .blue
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedLink = employee.scanHistory[indexPath.row]
        
        if let url = URL(string: selectedLink) {
            UIApplication.shared.open(url)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
    // needs backend implementation
    @objc func dataAccessSwitchChanged(_ sender: UISwitch) {
        employee.dataAccess = sender.isOn
    }

}
