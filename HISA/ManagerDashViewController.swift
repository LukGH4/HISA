import FirebaseDatabase
import UIKit

class ManagerDashViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sortingSegmentedControl: UISegmentedControl!
    @IBOutlet weak var searchBar: UISearchBar!

    var employees: [Employee] = []
    var filteredEmployees: [Employee] = []
    let databaseRef = Database.database().reference().child("users/employees")

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

        fetchEmployees()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func fetchEmployees() {
        databaseRef.observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [String: [String: Any]] else { return }
            self.employees = value.compactMap { Employee(id: $0.key, data: $0.value) }
            self.filteredEmployees = self.employees
            self.sortEmployees()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    private func sortEmployees() {
        if sortingSegmentedControl.selectedSegmentIndex == 0 {
            filteredEmployees.sort { $0.name.lowercased() < $1.name.lowercased() }
        } else {
            filteredEmployees.sort { $0.scans > $1.scans }
        }
        tableView.reloadData()
    }

    @IBAction func sortingChanged(_ sender: UISegmentedControl) {
        sortEmployees()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredEmployees = employees
        } else {
            filteredEmployees = employees.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        sortEmployees()
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

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredEmployees.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let employee = filteredEmployees[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "EmployeeCell", for: indexPath) as! EmployeeTableViewCell
        cell.nameLabel.text = employee.name
        cell.scansLabel.text = "\(employee.scans)"
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
