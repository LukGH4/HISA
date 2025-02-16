import UIKit

class SettingsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var currentNameLabel: UITextField!
    @IBOutlet weak var currentEmployeeIdLabel: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var employeeIdTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        currentNameLabel.isUserInteractionEnabled = false
        currentEmployeeIdLabel.isUserInteractionEnabled = false
        
        nameTextField.delegate = self
        employeeIdTextField.delegate = self

        if let employeeId = CurrentUser.shared.getId() {
            UserService.shared.fetchUserByEmployeeId(employeeId: employeeId) { success in
                if success {
                    self.loadCurrentUserData()
                } else {
                    self.showAlert(title: "Error", message: "User not found.")
                }
            }
        } else {
            showAlert(title: "Error", message: "Employee ID not found.")
        }
    }

    private func loadCurrentUserData() {
        let currentUser = CurrentUser.shared
        currentNameLabel.text = currentUser.getName()
        currentEmployeeIdLabel.text = currentUser.getId()
    }
    
    private func validateInputFields() -> Bool {
        guard let updatedName = nameTextField.text, !updatedName.isEmpty else {
            showAlert(title: "Input Error", message: "Name cannot be empty.")
            return false
        }

        guard let updatedEmployeeId = employeeIdTextField.text, !updatedEmployeeId.isEmpty else {
            showAlert(title: "Input Error", message: "Employee ID cannot be empty.")
            return false
        }

        let employeeIdPattern = "^[0-9]{4,10}$"
        let employeeIdPredicate = NSPredicate(format: "SELF MATCHES %@", employeeIdPattern)
        if !employeeIdPredicate.evaluate(with: updatedEmployeeId) {
            showAlert(title: "Input Error", message: "Employee ID must be numeric and between 4-10 digits.")
            return false
        }

        return true
    }

    @IBAction func submitButtonTapped(_ sender: UIButton) {
        if validateInputFields() {
                updateUserData()
        }
    }
    
    private func clearInputFields() {
        nameTextField.text = ""
        employeeIdTextField.text = ""
    }
    
    private func updateUserData() {
        guard let firebaseKey = CurrentUser.shared.getFirebaseKey() else {
            print("Error: Firebase key not found")
            showAlert(title: "Error", message: "Unable to update user profile.")
            return
        }

        let updatedName = nameTextField.text ?? ""
        let updatedEmployeeId = employeeIdTextField.text ?? ""

        let updates: [String: Any] = [
            "name": updatedName,
            "id": updatedEmployeeId
        ]

        UserService.shared.updateUserField(userId: firebaseKey, updates: updates) { error in
            if let error = error {
                print("Failed to update user data: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: "Failed to update your profile.")
            } else {
                print("User data successfully updated for Firebase key: \(firebaseKey)")
                self.showAlert(title: "Success", message: "Profile updated successfully.")
                
                self.clearInputFields()
                
                CurrentUser.shared.setUserData(updates)
                self.loadCurrentUserData()
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text?.isEmpty ?? true {
            textField.resignFirstResponder()
        }
        return true
    }
}
