//
//  EmployeeDetailViewController.swift
//  HISA
//
//  Created by Barnabas Li on 1/23/25.
//

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
        setupExportButton()
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
    
    private func formattedDate(from dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss"

        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        } else {
            return dateString
        }
    }


    private func updateEmployeeDetails() {
        guard let employee = employee else { return }
        nameLabel.text = employee.name
        dateLabel.text = formattedDate(from: employee.date)
        scansLabel.text = "\(employee.scans)"
        dataAccessControl.isOn = !employee.dataAccess
        scanHistoryTableView.reloadData()
    }
    
    private func setupExportButton() {
        let exportButton = UIButton(type: .system)
        exportButton.setTitle("Export", for: .normal)
        exportButton.addTarget(self, action: #selector(exportButtonTapped), for: .touchUpInside)

        exportButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(exportButton)

        NSLayoutConstraint.activate([
            exportButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exportButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -90)
        ])
    }

    private func setupDeleteButton() {
        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("Delete Employee", for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)

        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            deleteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -5)
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
            editButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -47.5)
        ])
    }
    
    @objc func exportButtonTapped() {
        print("Export Button is tapped.")
        
        guard let employee = self.employee else {
            print("No employee data available")
            return
        }

        let fileName = "\(employee.name)_Data.csv"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsDirectory.appendingPathComponent(fileName)

        var csvText = "Name,"
        csvText.append("\(employee.name)\n")
        
        csvText.append("ID,")
        csvText.append("\(employee.id)\n")
        
        csvText.append("Email,")
        csvText.append("\(employee.email)\n")
        
        csvText.append("Last Accessed,")
        csvText.append("\(employee.date)\n\n")


        csvText.append("Images\nFile Name,Part Type,Status,Classification,Confidence,Date,URL\n")
        for scan in employee.scanHistory where scan.url.contains("/images") {
            print("\(scan)")
            
            csvText.append("\"\(scan.fileName ?? "")\",")
            csvText.append("\"\(scan.part_type ?? "")\",")
            csvText.append("\"\(scan.status ?? "")\",")
            csvText.append("\"\(scan.classification ?? "")\",")
            csvText.append("\"\(scan.confidence ?? "")\",")
            csvText.append("\"\(scan.date ?? "")\",")
            csvText.append("\"\(scan.url)\"\n")
        }

        csvText.append("\nVideos\nFile Name,Part Type,Status,Classification,Confidence,Date,URL\n")
        for scan in employee.scanHistory where scan.url.contains("/videos") {
            print("\(scan)")
            
            csvText.append("\"\(scan.fileName ?? "")\",")
            csvText.append("\"\(scan.part_type ?? "")\",")
            csvText.append("\"\(scan.status ?? "")\",")
            csvText.append("\"\(scan.classification ?? "")\",")
            csvText.append("\"\(scan.confidence ?? "")\",")
            csvText.append("\"\(scan.date ?? "")\",")
            csvText.append("\"\(scan.url)\"\n")
        }


        do {
            try csvText.write(to: filePath, atomically: true, encoding: .utf8)
            shareFile(filePath: filePath)
        } catch {
            print("Error saving CSV file: \(error.localizedDescription)")
        }
    }
    
    func shareFile(filePath: URL) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath.path) {
            let activityVC = UIActivityViewController(activityItems: [filePath], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view
            self.present(activityVC, animated: true, completion: nil)
        } else {
            print("Error: File not found at \(filePath.path)")
        }
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
        cell.textLabel?.text = employee?.scanHistory[indexPath.row].name
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let scan = employee?.scanHistory[indexPath.row] else { return }

        performSegue(withIdentifier: "ManagerToScanListImageViewController", sender: scan)

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ManagerToScanListImageViewController",
           let scanVC = segue.destination as? ScanListImageViewController,
           let scan = sender as? Scan {
            scanVC.imageURL = scan.url
            scanVC.videoURL = scan.url
            scanVC.fileName = scan.fileName
            scanVC.partType = scan.partType
            scanVC.date = scan.date
            scanVC.folderKey = scan.folderKey
            scanVC.date = scan.date
            if let metadata = employee?.scanHistory.first(where: { $0.name == scan.name }) {
                scanVC.status = metadata.status
                scanVC.classification = metadata.classification
                scanVC.confidence = metadata.confidence
            }
            scanVC.isFromEmployeeDetail = true
        }
    }
}
