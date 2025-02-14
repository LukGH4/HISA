//
//  ManagerDashViewController.swift
//  HISA
//
//  Created by Barnabas Li on 1/23/25.
//

import FirebaseDatabase
import UIKit

class ManagerDashViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var employees: [Employee] = []
    let databaseRef = Database.database().reference().child("users/employees")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        tableView.dataSource = self
        tableView.delegate = self
        fetchEmployees()
    }
    
    private func fetchEmployees() {
        databaseRef.observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [String: [String: Any]] else { return }
            self.employees = value.compactMap { Employee(id: $0.key, data: $0.value) }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
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
        performSegue(withIdentifier: "ShowEmployeeDetail", sender: selectedEmployee)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowEmployeeDetail" {
            if let detailVC = segue.destination as? EmployeeDetailViewController,
               let selectedEmployee = sender as? Employee {
                detailVC.employeeID = selectedEmployee.id
            }
        }
    }
}
