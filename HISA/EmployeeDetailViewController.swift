// EmployeeDetailViewController.swift
// HISA
// Created by Barnabas Li on 1/23/25.

import UIKit
import FirebaseDatabase

protocol EmployeeDetailDelegate: AnyObject {
    func deleteEmployee(_ employee: Employee)
    func updateEmployee(_ updatedEmployee: Employee)
}

class EmployeeDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var dataAccessControl: UISwitch!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var scansLabel: UILabel!
    @IBOutlet weak var scanHistoryTableView: UITableView!

    weak var delegate: EmployeeDetailDelegate?
    var employeeID: String!
    private var employee: Employee?
    private var databaseRef: DatabaseReference!

    @IBAction func restrictDataAccessToggled(_ sender: UISwitch) {
        let isRestricted = sender.isOn
        let updates = ["dataAccess": isRestricted ? "false" : "true"]

        databaseRef.updateChildValues(updates) { error, _ in
            if let error = error {
                print("Failed to update restriction status: \(error.localizedDescription)")
            } else {
                print("Employee restriction status updated to \(isRestricted)")
            }
        }
    }
    
    override func viewDidLoad() {
        overrideUserInterfaceStyle = .light
        super.viewDidLoad()
        
        scanHistoryTableView.dataSource = self
        scanHistoryTableView.delegate = self
        
        databaseRef = Database.database().reference().child("users/employees").child(employeeID)

        fetchEmployeeData()
        setupDeleteButton()
        setupEditButton()
    }

    private func fetchEmployeeData() {
        databaseRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self, let data = snapshot.value as? [String: Any] else { return }

            if let fetchedEmployee = Employee(id: self.employeeID, data: data) {
                self.employee = fetchedEmployee
                self.updateEmployeeDetails()
            }
        }
    }

    private func updateEmployeeDetails() {
        guard let employee = employee else { return }
        nameLabel.text = employee.name
        dateLabel.text = employee.date
        scansLabel.text = "\(employee.scans)"
        dataAccessControl.isOn = !employee.dataAccess
        scanHistoryTableView.reloadData()
    }

    private func setupDeleteButton() {
        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("Delete Employee", for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)

        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            deleteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func setupEditButton() {
        let editButton = UIButton(type: .system)
        editButton.setTitle("Edit Employee", for: .normal)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)

        editButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editButton)

        NSLayoutConstraint.activate([
            editButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            editButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60)
        ])
    }

    @objc func deleteButtonTapped() {
        let alert = UIAlertController(
            title: "Confirm Deletion",
            message: "Are you sure you want to delete \(employee?.name ?? "this employee")?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.databaseRef.removeValue { error, _ in
                if error == nil {
                    self.delegate?.deleteEmployee(self.employee!)
                    self.navigationController?.popViewController(animated: true)
                }
            }
        })
        present(alert, animated: true, completion: nil)
    }

    @objc func editButtonTapped() {
        guard let employee = employee else { return }

        let alert = UIAlertController(title: "Edit Employee", message: "Update the employee's details.", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.text = employee.name
            textField.placeholder = "Name"
        }
        alert.addTextField { textField in
            textField.text = employee.date
            textField.placeholder = "Date (YYYY-MM-DD)"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?[0].text, !name.isEmpty,
                  let date = alert.textFields?[1].text, !date.isEmpty else { return }


            let updates: [String: Any] = ["name": name, "lastAccessed": date]
            self.databaseRef.updateChildValues(updates) { error, _ in
                if error == nil {
                    self.employee?.name = name
                    self.employee?.date = date
                    self.updateEmployeeDetails()
                    self.delegate?.updateEmployee(self.employee!)
                }
            }
        })

        present(alert, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return employee?.scanHistory.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScanHistoryCell", for: indexPath)
        cell.textLabel?.text = employee?.scanHistory[indexPath.row]
        cell.textLabel?.textColor = .blue
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedLink = employee?.scanHistory[indexPath.row], let url = URL(string: selectedLink) else { return }
        UIApplication.shared.open(url)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
