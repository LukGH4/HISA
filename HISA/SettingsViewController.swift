import UIKit
import FirebaseAuth

class SettingsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var currentEmployeeIdLabel: UITextField!
    @IBOutlet weak var employeeIdTextField: UITextField!
    @IBOutlet weak var newNameTextField: UITextField!
    @IBOutlet weak var changeNameButton: UIButton!
    
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var changePasswordButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        currentEmployeeIdLabel.isUserInteractionEnabled = false
        
        newNameTextField.delegate = self
        newPasswordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        newPasswordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true

        setupTapGesture()
        
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

    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func loadCurrentUserData() {
        let currentUser = CurrentUser.shared
        currentEmployeeIdLabel.text = currentUser.getId()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == newNameTextField || textField == newPasswordTextField || textField == confirmPasswordTextField {
            if textField.text?.isEmpty ?? true {
                textField.resignFirstResponder()
            }
        }
        return true
    }
    
    @IBAction func changeNameButtonTapped(_ sender: Any) {
        guard let newName = newNameTextField.text, !newName.isEmpty else {
            showAlert(title: "Error", message: "Please enter a new name.")
            return
        }
        showChangeNameConfirmationAlert(newName: newName)
    }

    private func showChangeNameConfirmationAlert(newName: String) {
        let alert = UIAlertController(title: "Change Name", message: "Are you sure you want to change your name?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Change Name", style: .destructive, handler: { _ in
            self.changeName(newName: newName)
        }))
        present(alert, animated: true, completion: nil)
    }

    private func changeName(newName: String) {
        guard let firebaseKey = CurrentUser.shared.getFirebaseKey() else {
            showAlert(title: "Error", message: "Unable to update user profile.")
            return
        }
        
        let updates: [String: Any] = ["name": newName]

        UserService.shared.updateUserField(userId: firebaseKey, updates: updates) { error in
            if let error = error {
                self.showAlert(title: "Error", message: "Failed to update your profile.")
            } else {
                self.showAlert(title: "Success", message: "Profile updated, please log back to view changes.")
                CurrentUser.shared.setUserData(updates)
                self.loadCurrentUserData()
            }
        }
    }

    @IBAction func changePasswordButtonTapped(_ sender: Any) {
        guard let newPassword = newPasswordTextField.text, !newPassword.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(title: "Error", message: "Please enter both new password and confirm password.")
            return
        }

        if newPassword != confirmPassword {
            showAlert(title: "Error", message: "Passwords do not match.")
            return
        }
        let alert = UIAlertController(title: "Change Password", message: "Are you sure you want to change your password?", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Change Password", style: .destructive, handler: { _ in
            self.changePassword(newPassword: newPassword)
        }))

        present(alert, animated: true, completion: nil)
    }
    
    private func changePassword(newPassword: String) {
        guard let currentUser = Auth.auth().currentUser else {
            showAlert(title: "Error", message: "User not authenticated.")
            return
        }
        currentUser.updatePassword(to: newPassword) { error in
            if let error = error {
                self.showAlert(title: "Error", message: error.localizedDescription)
            } else {
                self.showAlert(title: "Success", message: "Password changed successfully.")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        showLogoutConfirmationAlert()
    }
    
    private func showLogoutConfirmationAlert() {
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to log out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
            self.logoutUser()
        }))
        present(alert, animated: true, completion: nil)
    }

    private func logoutUser() {
        CurrentUser.shared.clearUserData()
        do {
            try Auth.auth().signOut()
            print("User signed out successfully")
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
        navigateToLoginScreen()
    }

    private func navigateToLoginScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
            loginViewController.modalPresentationStyle = .fullScreen
            present(loginViewController, animated: true, completion: nil)
        }
    }
}
