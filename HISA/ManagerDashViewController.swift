//
//  ManagerDashViewController.swift
//  HISA
//
//  Created by Barnabas Li on 1/23/25.
//

import FirebaseDatabase
import FirebaseDatabaseInternal
import UIKit

class ManagerDashViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var filterButton: UIButton!

    var employees: [Employee] = []
    var filteredEmployees: [Employee] = []
    let databaseRef = Database.database().reference().child("users/employees")
    let imageCache = NSCache<NSString, UIImage>()

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        
        searchBar.layer.borderWidth = 0
        searchBar.layer.borderColor = UIColor.clear.cgColor
        searchBar.layer.cornerRadius = 10
        searchBar.clipsToBounds = true
        searchBar.backgroundImage = UIImage()
        searchBar.barTintColor = UIColor.clear
        searchBar.isTranslucent = true
        
        filterButton.isUserInteractionEnabled = true
        filterButton.alpha = 1.0
        view.bringSubviewToFront(filterButton)

        fetchEmployees()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func filterButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Sort Employees", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Sort by Name", style: .default, handler: { _ in
            self.sortEmployees(by: "name")
        }))
        
        alert.addAction(UIAlertAction(title: "Sort by Scans", style: .default, handler: { _ in
            self.sortEmployees(by: "scans")
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }

    private func fetchEmployees() {
        databaseRef.observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [String: [String: Any]] else { return }
            self.employees = value.compactMap { Employee(id: $0.key, data: $0.value) }
            self.filteredEmployees = self.employees
            self.sortEmployees(by: "name")
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    private func sortEmployees(by criteria: String) {
        if criteria == "name" {
            filteredEmployees.sort { $0.name.lowercased() < $1.name.lowercased() }
        } else if criteria == "scans" {
            filteredEmployees.sort { $0.scans > $1.scans }
        }
        tableView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredEmployees = employees
        } else {
            filteredEmployees = employees.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        sortEmployees(by: "name")
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text?.isEmpty ?? true {
            searchBar.resignFirstResponder()
        }
    }

    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        let touchPoint = sender.location(in: self.view)
        if !searchBar.frame.contains(touchPoint) {
            searchBar.resignFirstResponder()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredEmployees.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let employee = filteredEmployees[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "EmployeeCell", for: indexPath) as! EmployeeTableViewCell
        cell.nameLabel.text = employee.name
        cell.scansLabel.text = "Number of scans: \(employee.scans)"
        cell.profileImageView.image = UIImage(named: "defaultProfileImage")

        if let profileImageUrl = employee.profileImageUrl, let url = URL(string: profileImageUrl) {
            let cacheKey = NSString(string: profileImageUrl)
            
            // Image caching
            if let cachedImage = imageCache.object(forKey: cacheKey) {
                cell.profileImageView.image = cachedImage
            } else {
                URLSession.shared.dataTask(with: url) { data, _, error in
                    if let data = data, error == nil, let image = UIImage(data: data) {
                        self.imageCache.setObject(image, forKey: cacheKey)
                        DispatchQueue.main.async {
                            if let updatedCell = tableView.cellForRow(at: indexPath) as? EmployeeTableViewCell {
                                updatedCell.profileImageView.image = image
                            }
                        }
                    }
                }.resume()
            }
        }
        return cell
    }



    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedEmployee = filteredEmployees[indexPath.row]
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
