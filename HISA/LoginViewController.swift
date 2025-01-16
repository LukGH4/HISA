//
//  LoginViewController.swift
//  HISA
//
//  Created by Barnabas Li on 1/16/25.
//


import UIKit
import FirebaseDatabase

class LoginViewController: UIViewController {

    var usernameTextField: UITextField!
    var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        usernameTextField = UITextField()
        usernameTextField.placeholder = "Username"
        usernameTextField.frame = CGRect(x: 50, y: 200, width: 300, height: 40)
        usernameTextField.borderStyle = .roundedRect
        self.view.addSubview(usernameTextField)

        passwordTextField = UITextField()
        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.frame = CGRect(x: 50, y: 250, width: 300, height: 40)
        passwordTextField.borderStyle = .roundedRect
        self.view.addSubview(passwordTextField)

        let loginButton = UIButton()
        loginButton.setTitle("Login", for: .normal)
        loginButton.frame = CGRect(x: 50, y: 300, width: 300, height: 50)
        loginButton.backgroundColor = .blue
        loginButton.layer.cornerRadius = 10
        self.view.addSubview(loginButton)

        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
    }

    @objc func loginTapped() {
        let username = usernameTextField.text!
        let id = passwordTextField.text!
        
        if username.isEmpty || id.isEmpty {
            showAlert(message: "Username and ID cannot be empty")
            return
        }
        
        let ref = Database.database().reference()
        
        
        // check employees usernames and passwords in firebase
        ref.child("users/employees").queryOrdered(byChild: "username").queryEqual(toValue: username).observeSingleEvent(of: .value) { snapshot in
            if let employee = snapshot.value as? [String: Any] {
                for (_, data) in employee {
                    if let userData = data as? [String: Any],
                       let idFromDB = userData["id"] as? Int, idFromDB == Int(id) {
                        self.transitionToHome()
                        return
                    }
                }
            }
            // query to check managers if not found in employees
            ref.child("users/managers").queryOrdered(byChild: "username").queryEqual(toValue: username).observeSingleEvent(of: .value) { snapshot in
                if let manager = snapshot.value as? [String: Any] {
                    for (_, data) in manager {
                        if let userData = data as? [String: Any],
                           let idFromDB = userData["id"] as? Int, idFromDB == Int(id) {
                            self.transitionToHome()
                            return
                        }
                    }
                }
                self.showAlert(message: "Invalid username or ID")
            }
        }
    }


    func transitionToHome() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let tabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
            if let viewControllers = tabBarController.viewControllers {
                for viewController in viewControllers {
                    if let homeVC = viewController as? HomeViewController {
                        homeVC.loggedInUsername = usernameTextField.text
                        break
                    }
                }
            }
            self.view.window?.rootViewController = tabBarController
            self.view.window?.makeKeyAndVisible()
        }
    }


    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
