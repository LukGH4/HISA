//
//  ChangePasswordViewController.swift
//  HISA
//
//  Created by nat on 2/15/25.
//

import UIKit
import FirebaseAuth

class ChangePasswordViewController: UIViewController {

    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var changePasswordButton: UIButton!

    var email: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
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

        guard let email = email else {
            showAlert(title: "Error", message: "Email not found.")
            return
        }

        changePassword(email: email, newPassword: newPassword)
    }

    private func changePassword(email: String, newPassword: String) {
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
                self.navigateToLoginPage()
            }
        }
    }
    
    private func navigateToLoginPage() {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
                self.present(loginVC, animated: true, completion: nil)
            }
        }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
}
