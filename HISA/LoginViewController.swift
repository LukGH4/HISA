// LoginViewController.swift
import UIKit
import FirebaseAuth
import FirebaseDatabase // or FirebaseFirestore, depending on your setup

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the view controller as the delegate of the text fields
        emailTextField.delegate = self
        passwordTextField.delegate = self
        passwordTextField.isSecureTextEntry = true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            loginButtonTapped(self)
        }
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    @IBAction func loginButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email.")
            return
        }

        guard let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter your password.")
            return
        }

        // Firebase Authentication for email and password
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                self.showAlert(title: "Login Failed", message: error.localizedDescription)
            } else {
                // Successful login, now check user role
                if let user = authResult?.user {
                    let ref = Database.database().reference() // or Firestore
                    let userRef = ref.child("users").child("managers").child(user.uid)
                    UserService.shared.fetchUserInfoAndPersist(userId: user.uid)

                    userRef.observeSingleEvent(of: .value, with: { snapshot in
                        if snapshot.exists() {
                            if let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: "ManagerTabBarController") as? UITabBarController {
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
                        } else {
                            // Navigate to regular user tab controller
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
                    })
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
}
