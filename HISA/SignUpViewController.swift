// SignUpViewController.swift
// HISA

import UIKit
import FirebaseAuth
import FirebaseDatabase // or FirebaseFirestore, depending on your setup

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var createButton: UIButton!
    
    var activeTextField: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set self as the delegate for the text fields
        nameTextField.delegate = self
        emailTextField.delegate = self
        idTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        
        // Subscribe to keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // Handle the "Return" key press in the text fields
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            emailTextField.becomeFirstResponder() // Move to the email field
        } else if textField == emailTextField {
            idTextField.becomeFirstResponder() // Move to the ID field
        } else if textField == idTextField {
            passwordTextField.becomeFirstResponder() // Move to the password field
        } else if textField == passwordTextField {
            confirmPasswordTextField.becomeFirstResponder() // Move to the confirm password field
        } else if textField == confirmPasswordTextField {
            createButtonTapped(self) // Trigger the sign-up when pressing return on confirm password field
        }
        return true
    }

    // Dismiss the keyboard when tapping outside of a text field
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true) // Dismisses the keyboard
    }

    @IBAction func createButtonTapped(_ sender: Any) {
        // Ensure that all fields are filled out
        guard let name = nameTextField.text, !name.isEmpty else {
            showAlert(title: "Error", message: "Please enter your name.")
            return
        }
        
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email.")
            return
        }
        
        guard let id = idTextField.text, !id.isEmpty else {
            showAlert(title: "Error", message: "Please enter your ID.")
            return
        }
        
        guard let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter your password.")
            return
        }
        
        guard let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(title: "Error", message: "Please confirm your password.")
            return
        }
        
        // Check if password and confirm password match
        if password != confirmPassword {
            showAlert(title: "Error", message: "Passwords do not match.")
            return
        }

        // Firebase authentication to create a new user with email and password
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                // Show alert for failed sign-up
                self.showAlert(title: "Sign Up Failed", message: error.localizedDescription)
            } else {
                // After user is created, set the user role in Firebase
                let userId = authResult?.user.uid
                let ref = Database.database().reference().child("users").child(userId ?? "")

                // You can adjust the role logic as needed (e.g., based on user input or default to "user")
                let userRole = "user" // Default role, you can change this based on your requirement
                let userValues = [
                    "name": name,
                    "email": email,
                    "id": id,
                    "role": userRole
                ]

                ref.setValue(userValues) { error, _ in
                    if let error = error {
                        self.showAlert(title: "Error", message: "Failed to save user data: \(error.localizedDescription)")
                    } else {
                        // Successful sign-up and role assignment, navigate to the next screen
                        if let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
                            tabBarController.selectedIndex = 0
                            
                            if let window = UIApplication.shared.windows.first {
                                window.rootViewController = tabBarController
                                window.makeKeyAndVisible()
                                
                                let transition = CATransition()
                                transition.type = .fade
                                transition.duration = 0.3
                                window.layer.add(transition, forKey: kCATransition)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Helper function to show alerts
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // Handle keyboard appearance
    @objc func keyboardWillShow(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            if let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                if let activeTextField = self.activeTextField {
                    let screenHeight = UIScreen.main.bounds.height
                    let bottomOfTextField = activeTextField.convert(activeTextField.bounds, to: view).maxY
                    let keyboardHeight = keyboardFrame.height
                    let offset = bottomOfTextField + keyboardHeight - screenHeight
                    if offset > 0 {
                        view.frame.origin.y -= offset // Move the view up
                    }
                }
            }
        }
    }
    
    // Handle keyboard hiding
    @objc func keyboardWillHide(_ notification: Notification) {
        view.frame.origin.y = 0 // Reset the view's position when keyboard disappears
    }
}
