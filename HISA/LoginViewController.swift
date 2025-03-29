// LoginViewController.swift
import UIKit
import FirebaseAuth
import FirebaseDatabase // or FirebaseFirestore, depending on your setup

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var managerLoginButton: UIButton!
    @IBOutlet weak var employeeLoginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        authenticateUser(email: emailTextField.text, password: passwordTextField.text)
    }
    
    @IBAction func managerLoginButtonTapped(_ sender: Any) {
        authenticateUser(email: "manager@manager.com", password: "manager1234")
    }
    
    @IBAction func employeeLoginButtonTapped(_ sender: Any) {
        authenticateUser(email: "b@b.com", password: "bbbbbb")
    }

    private func authenticateUser(email: String?, password: String?) {
        guard let email = email, !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email.")
            return
        }

        guard let password = password, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter your password.")
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                self.showAlert(title: "Login Failed", message: error.localizedDescription)
            } else {
                self.handleSuccessfulLogin(user: authResult?.user, email: email)
            }
        }
    }
    
    private func handleSuccessfulLogin(user: User?, email: String) {
        guard let user = user else { return }
        let ref = Database.database().reference()
        let userRef = ref.child("users").child("managers").child(user.uid)
        UserService.shared.fetchUserInfoAndPersist(userId: user.uid)

        userRef.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                self.navigateToTabBar(identifier: "ManagerTabBarController")
            } else {
                self.checkEmployeeAccess(ref: ref, email: email)
            }
        }
    }
    
    private func checkEmployeeAccess(ref: DatabaseReference, email: String) {
        let employeesRef = ref.child("users").child("employees")
        employeesRef.observeSingleEvent(of: .value) { snapshot in
            for child in snapshot.children {
                if let snap = child as? DataSnapshot,
                   let value = snap.value as? [String: Any],
                   let storedEmail = value["email"] as? String, storedEmail.caseInsensitiveCompare(email) == .orderedSame {
                    
                    if let dataAccess = value["dataAccess"] as? String, dataAccess.lowercased() == "false" {
                        self.showAlert(title: "Access Denied", message: "Your access has been restricted by a manager.")
                        try? Auth.auth().signOut()
                        return
                    }
                    self.navigateToTabBar(identifier: "MainTabBarController")
                    return
                }
            }
            self.showAlert(title: "Error", message: "Failed to retrieve user data.")
        }
    }

    private func navigateToTabBar(identifier: String) {
        if let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: identifier) as? UITabBarController {
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

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
}
