//
//  ManagerDashViewController.swift
//  HISA
//
//  Created by Barnabas Li on 1/23/25.
//


import UIKit

class ManagerDashViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!

    // when backend is set up we need to replace this with a query
    var employees = [
        Employee(name: "Alice Smith", date: "2025-01-23", scans: 12, dataAccess: true, scanHistory: ["Scan 1 Link", "Scan 2 Link", "Scan 3 Link"]),
        Employee(name: "Bob Williams", date: "2025-01-22", scans: 8, dataAccess: false, scanHistory: ["Scan 1 Link", "Scan 2 Link", "Scan 3 Link"]),
        Employee(name: "Charlie Brown", date: "2025-01-21", scans: 15, dataAccess: true, scanHistory: ["Scan 1 Link", "Scan 2 Link", "Scan 3 Link"])
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return employees.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let employee = employees[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "EmployeeCell", for: indexPath) as! EmployeeTableViewCell
        
        cell.nameLabel.text = employee.name
        cell.scansLabel.text = "\(employee.scans)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedEmployee = employees[indexPath.row]
        performSegue(withIdentifier: "ShowEmployeeDetails", sender: selectedEmployee)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowEmployeeDetails",
           let destinationVC = segue.destination as? EmployeeDetailViewController,
           let selectedEmployee = sender as? Employee {
            destinationVC.employee = selectedEmployee
        }
    }
}

