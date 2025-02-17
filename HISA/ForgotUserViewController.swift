//
//  ForgotUserViewController.swift
//  HISA
//
//  Created by Hoyeon Kang on 1/17/25.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class ForgotUserViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        idTextField.delegate = self

        overrideUserInterfaceStyle = .light

        // Fix text field appearance
        configureTextField(emailTextField)
        configureTextField(idTextField)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    private func configureTextField(_ textField: UITextField) {
        textField.backgroundColor = .white
        textField.textColor = .black
    }


    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @IBAction func submitButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
              let id = idTextField.text, !id.isEmpty else {
            showAlert(title: "Error", message: "Please enter both email and ID.")
            return
        }

        verifyUser(email: email, id: id)
    }

    private func verifyUser(email: String, id: String) {
        let employeesRef = Database.database().reference().child("users").child("employees")
        employeesRef.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                if let employeesData = snapshot.value as? [String: Any] {
                    if let employeeData = employeesData[id] as? [String: Any] {
                        if let dataEmail = employeeData["email"] as? String,
                           dataEmail == email {
                            self.showAlert(title: "Error", message: "To be implemented...")
                        } else {
                            self.showAlert(title: "Error", message: "Invalid email or ID.")
                        }
                    } else {
                        self.showAlert(title: "Error", message: "User not found.")
                    }
                }
            } else {
                self.showAlert(title: "Error", message: "No employees data found.")
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
