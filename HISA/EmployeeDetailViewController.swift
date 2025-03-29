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
        setupExportButtons()
        setupDeleteButton()
        setupEditButton()
        navigationController?.navigationBar.prefersLargeTitles = true
            navigationController?.navigationBar.barTintColor = UIColor.systemBlue
            navigationController?.navigationBar.tintColor = .white
            navigationController?.navigationBar.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 18, weight: .bold)
            ]
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
        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = UIColor.label

        dateLabel.text = formattedDate(from: employee.date)
        dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        dateLabel.textColor = UIColor.secondaryLabel

        scansLabel.text = "\(employee.scans)"
        scansLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        scansLabel.textColor = UIColor.secondaryLabel
        dataAccessControl.isOn = !employee.dataAccess
        scanHistoryTableView.reloadData()
        scanHistoryTableView.separatorStyle = .singleLine
        scanHistoryTableView.separatorColor = UIColor.lightGray
        scanHistoryTableView.rowHeight = UITableView.automaticDimension
        scanHistoryTableView.estimatedRowHeight = 50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScanHistoryCell", for: indexPath)
        let scan = employee?.scanHistory[indexPath.row]
        cell.textLabel?.text = scan?.fileName
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cell.selectionStyle = .none
        cell.contentView.layer.cornerRadius = 10
        cell.contentView.layer.masksToBounds = true
        cell.contentView.backgroundColor = UIColor.systemGray6
        return cell
    }

    @objc func exportPartTapped() {
        print("Export Part Button tapped")
        performSegue(withIdentifier: "toManagerPartList", sender: self)
    }

    private func setupExportButtons() {
        let exportAllButton = UIButton(type: .system)
        exportAllButton.setTitle("Export All", for: .normal)
        exportAllButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        exportAllButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        exportAllButton.tintColor = .white
        exportAllButton.layer.cornerRadius = 8
        exportAllButton.layer.masksToBounds = true
        exportAllButton.addTarget(self, action: #selector(exportButtonTapped), for: .touchUpInside)

        let exportCustomButton = UIButton(type: .system)
        exportCustomButton.setTitle("Export a Part", for: .normal)
        exportCustomButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        exportCustomButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
        exportCustomButton.tintColor = .white
        exportCustomButton.layer.cornerRadius = 8
        exportCustomButton.layer.masksToBounds = true
        exportCustomButton.addTarget(self, action: #selector(exportPartTapped), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [exportAllButton, exportCustomButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            buttonStack.widthAnchor.constraint(equalToConstant: 240),
            buttonStack.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupDeleteButton() {
        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        deleteButton.tintColor = .systemRed
        deleteButton.layer.cornerRadius = 8
        deleteButton.layer.masksToBounds = true
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)

        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            deleteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            deleteButton.widthAnchor.constraint(equalToConstant: 120),
            deleteButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupEditButton() {
        let editButton = UIButton(type: .system)
        editButton.setTitle("Edit", for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        editButton.tintColor = .systemBlue
        editButton.layer.cornerRadius = 8
        editButton.layer.masksToBounds = true
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)

        editButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editButton)

        NSLayoutConstraint.activate([
            editButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            editButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            editButton.widthAnchor.constraint(equalToConstant: 120),
            editButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc func exportButtonTapped() {
        print("Export Button is tapped.")
        exportFormat()
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
    
    func exportFormat() {
        let alert = UIAlertController(title: "Export Format", message: "Choose a format to export the data:", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Export as CSV", style: .default, handler: { _ in
            self.exportAsCSV()
        }))
        
        alert.addAction(UIAlertAction(title: "Export as PDF", style: .default, handler: { _ in
            self.exportAsPDF()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    func exportAsCSV() {
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
    
    func exportAsPDF() {
        guard let employee = self.employee else {
            print("No employee data available")
            return
        }

        let fileName = "\(employee.name)_Data.pdf"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsDirectory.appendingPathComponent(fileName)

        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let margin: CGFloat = 20.0

        // Build the full string
        var content = ""
        content += "Name: \(employee.name)\n"
        content += "ID: \(employee.id)\n"
        content += "Email: \(employee.email)\n"
        content += "Last Accessed: \(employee.date)\n\n"

        content += "Images:\n\n"
        for scan in employee.scanHistory where scan.url.contains("/images") {
            content += "File Name: \(scan.fileName ?? "")\n"
            content += "Part Type: \(scan.part_type ?? "")\n"
            content += "Status: \(scan.status ?? "")\n"
            content += "Classification: \(scan.classification ?? "")\n"
            content += "Confidence: \(scan.confidence ?? "")\n"
            content += "Date: \(scan.date ?? "")\n"
            content += "URL: \(scan.url)\n"
            content += "--------------------------------------\n"
        }

        content += "\nVideos:\n\n"
        for scan in employee.scanHistory where scan.url.contains("/videos") {
            content += "File Name: \(scan.fileName ?? "")\n"
            content += "Part Type: \(scan.part_type ?? "")\n"
            content += "Status: \(scan.status ?? "")\n"
            content += "Classification: \(scan.classification ?? "")\n"
            content += "Confidence: \(scan.confidence ?? "")\n"
            content += "Date: \(scan.date ?? "")\n"
            content += "URL: \(scan.url)\n"
            content += "--------------------------------------\n"
        }

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .left

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .paragraphStyle: paragraphStyle
        ]

        let attributedText = NSAttributedString(string: content, attributes: attributes)

        do {
            try renderer.writePDF(to: filePath) { context in
                var currentOffset: CGFloat = margin
                let textRect = CGRect(x: margin, y: margin, width: pageWidth - 2 * margin, height: pageHeight - 2 * margin)

                let framesetter = CTFramesetterCreateWithAttributedString(attributedText as CFAttributedString)

                var currentRange = CFRange(location: 0, length: 0)
                let fullLength = attributedText.length

                while currentRange.location < fullLength {
                    context.beginPage()
                    
                    let cgContext = context.cgContext
                    cgContext.translateBy(x: 0, y: pageHeight)
                    cgContext.scaleBy(x: 1.0, y: -1.0)

                    let path = CGMutablePath()
                    path.addRect(textRect)

                    let frame = CTFramesetterCreateFrame(framesetter, currentRange, path, nil)
                    CTFrameDraw(frame, context.cgContext)

                    // Update the range for next page
                    let visibleRange = CTFrameGetVisibleStringRange(frame)
                    currentRange.location += visibleRange.length
                }
            }

            print("PDF created at: \(filePath)")
            shareFile(filePath: filePath)

        } catch {
            print("Could not create PDF file: \(error.localizedDescription)")
        }
    }

    @objc func deleteButtonTapped() {
        let alert = UIAlertController(
            title: "Confirm Deletion",
            message: "Are you sure you want to delete \(employee?.name ?? "this employee")?",
            preferredStyle: .alert
        )
        alert.view.tintColor = .systemRed

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        cancelAction.setValue(UIColor.systemBlue, forKey: "titleTextColor")
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.databaseRef.removeValue { error, _ in
                if error == nil {
                    self.delegate?.deleteEmployee(self.employee!)
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        deleteAction.setValue(UIColor.systemRed, forKey: "titleTextColor")
        
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        
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
        
        if segue.identifier == "toManagerPartList",
           let destinationVC = segue.destination as? ManagerPartListController {
            destinationVC.employeeID = self.employeeID
        }
    }
}
