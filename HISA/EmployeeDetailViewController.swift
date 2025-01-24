// EmployeeDetailViewController.swift
// HISA
// Created by Barnabas Li on 1/23/25.

//DATA IS HARDCODED AT THE MOMEMT, everything will be moved to database once it is fully set up

import UIKit

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
    var employee: Employee!

    override func viewDidLoad() {
        super.viewDidLoad()

        updateEmployeeDetails()
        scanHistoryTableView.dataSource = self
        scanHistoryTableView.delegate = self

        setupDeleteButton()
        setupEditButton()
    }

    private func updateEmployeeDetails() {
        nameLabel.text = employee.name
        dateLabel.text = employee.date
        scansLabel.text = "\(employee.scans)"
        dataAccessControl.isOn = employee.dataAccess
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
            message: "Are you sure you want to delete \(employee.name)?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.deleteEmployee(self.employee)
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true, completion: nil)
    }

    @objc func editButtonTapped() {
        let alert = UIAlertController(title: "Edit Employee", message: "Update the employee's details.", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.text = self.employee.name
            textField.placeholder = "Name"
        }
        alert.addTextField { textField in
            textField.text = self.employee.date
            textField.placeholder = "Date (YYYY-MM-DD)"
        }
        alert.addTextField { textField in
            textField.text = "\(self.employee.scans)"
            textField.placeholder = "Number of Scans"
            textField.keyboardType = .numberPad
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?[0].text, !name.isEmpty,
                  let date = alert.textFields?[1].text, !date.isEmpty,
                  let scansText = alert.textFields?[2].text, let scans = Int(scansText) else { return }

            self.employee.name = name
            self.employee.date = date
            self.employee.scans = scans
            self.updateEmployeeDetails()
            self.delegate?.updateEmployee(self.employee)
        })

        present(alert, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return employee.scanHistory.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScanHistoryCell", for: indexPath)
        cell.textLabel?.text = employee.scanHistory[indexPath.row]
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
}
