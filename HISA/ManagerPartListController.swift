//
//  ManagerPartListController.swift
//  HISA
//
//  Created by Hoyeon Kang on 3/22/25.
//

import UIKit
import FirebaseDatabase

class ManagerPartListController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    weak var delegate: EmployeeDetailDelegate?
    var employeeID: String!
    private var employee: Employee?
    private var databaseRef: DatabaseReference!
    var partTypes: [String] = []

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        databaseRef = Database.database().reference().child("users/employees").child(employeeID)

        fetchEmployeeData()
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
        
        let allPartTypes = employee.scanHistory.compactMap { $0.part_type }
        partTypes = Array(Set(allPartTypes)).sorted()
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return partTypes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PartCell", for: indexPath)
        cell.textLabel?.text = partTypes[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPartType = partTypes[indexPath.row]
        presentExportFormatOptions(for: selectedPartType)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func presentExportFormatOptions(for partType: String) {
        let alert = UIAlertController(title: "Export", message: "Export all scans for part type: \(partType)", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Export as CSV", style: .default) { _ in
            self.exportScans(of: partType, as: "csv")
        })

        alert.addAction(UIAlertAction(title: "Export as PDF", style: .default) { _ in
            self.exportScans(of: partType, as: "pdf")
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func exportScans(of partType: String, as format: String) {
        guard let employee = employee else { return }
        let matchingScans = employee.scanHistory.filter { $0.partType == partType }
        
        let fileName = "\(employee.name)_\(partType)_Data.\(format)"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsDirectory.appendingPathComponent(fileName)

        switch format {
        case "csv":
            var csvText = "File Name,Part Type,Status,Classification,Confidence,Date,URL\n"
            for scan in matchingScans {
                csvText += "\"\(scan.fileName ?? "")\","
                csvText += "\"\(scan.partType ?? "")\","
                csvText += "\"\(scan.status ?? "")\","
                csvText += "\"\(scan.classification ?? "")\","
                csvText += "\"\(scan.confidence ?? "")\","
                csvText += "\"\(scan.date ?? "")\","
                csvText += "\"\(scan.url)\"\n"
            }
            try? csvText.write(to: filePath, atomically: true, encoding: .utf8)

        case "pdf":
            let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle
            ]

            var content = ""
            for scan in matchingScans {
                content += "File Name: \(scan.fileName ?? "")\n"
                content += "Part Type: \(scan.partType ?? "")\n"
                content += "Status: \(scan.status ?? "")\n"
                content += "Classification: \(scan.classification ?? "")\n"
                content += "Confidence: \(scan.confidence ?? "")\n"
                content += "Date: \(scan.date ?? "")\n"
                content += "URL: \(scan.url)\n"
                content += "------------------------------\n"
            }

            try? renderer.writePDF(to: filePath) { context in
                context.beginPage()
                content.draw(in: CGRect(x: 20, y: 20, width: 555, height: 800), withAttributes: attributes)
            }

        default: break
        }

        shareFile(filePath: filePath)
    }

    private func shareFile(filePath: URL) {
        let activityVC = UIActivityViewController(activityItems: [filePath], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        self.present(activityVC, animated: true)
    }

}
