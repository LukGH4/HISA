//
//  ManagerDashViewController.swift
//  HISA
//
//  Created by Barnabas Li on 1/23/25.
//

import UIKit

class ManagerDashViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    // employee data here is temporary and hardcoded for ease of developing and testing before db is set up
    var employees = [
        Employee(name: "Alice Smith", date: "2025-01-23", scans: 12, dataAccess: true, scanHistory: ["Scan 1 Link", "Scan 2 Link", "Scan 3 Link"]),
        Employee(name: "Bob Williams", date: "2025-01-22", scans: 8, dataAccess: false, scanHistory: ["Scan 1 Link", "Scan 2 Link", "Scan 3 Link"]),
        Employee(name: "Charlie Brown", date: "2025-01-21", scans: 15, dataAccess: true, scanHistory: ["Scan 1 Link", "Scan 2 Link", "Scan 3 Link"])
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        setupAddEmployeeButton()
    }
    
    
    private func setupAddEmployeeButton() {
        let addButton = UIButton(type: .system)
        addButton.setTitle("Add Employee", for: .normal)
        addButton.setTitleColor(.white, for: .normal)
        addButton.backgroundColor = .systemBlue
        addButton.layer.cornerRadius = 10
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        
        // Add the button to the view
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    func updateEmployee(_ updatedEmployee: Employee) {
        if let index = employees.firstIndex(where: { $0.name == updatedEmployee.name }) {
            employees[index] = updatedEmployee
            tableView.reloadData()
        }
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
            destinationVC.delegate = self
        }
    }
    
    @objc func addButtonTapped() {
        let alert = UIAlertController(title: "Add Employee", message: "Enter details of the new employee.", preferredStyle: .alert)

        alert.addTextField { $0.placeholder = "Name" }
        alert.addTextField { $0.placeholder = "Date (YYYY-MM-DD)" }
        alert.addTextField { $0.placeholder = "Number of Scans"; $0.keyboardType = .numberPad }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?[0].text, !name.isEmpty,
                  let date = alert.textFields?[1].text, !date.isEmpty,
                  let scansText = alert.textFields?[2].text, let scans = Int(scansText) else { return }

            let newEmployee = Employee(name: name, date: date, scans: scans, dataAccess: false, scanHistory: [])
            self.employees.append(newEmployee)
            self.tableView.reloadData()
        })

        present(alert, animated: true, completion: nil)
    }
}

extension ManagerDashViewController: EmployeeDetailDelegate {
    func deleteEmployee(_ employee: Employee) {
        if let index = employees.firstIndex(where: { $0.name == employee.name }) {
            employees.remove(at: index)
            tableView.reloadData()
        }
    }
}
