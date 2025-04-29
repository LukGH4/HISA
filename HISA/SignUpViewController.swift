import UIKit
import FirebaseAuth
import FirebaseDatabase

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var createButton: UIButton!
    
    var activeTextField: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()
        [nameTextField, emailTextField, idTextField, phoneNumberTextField, passwordTextField, confirmPasswordTextField].forEach { $0?.delegate = self }
        
        passwordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            emailTextField.becomeFirstResponder()
        } else if textField == emailTextField {
            idTextField.becomeFirstResponder()
        } else if textField == idTextField {
            phoneNumberTextField.becomeFirstResponder()
        } else if textField == phoneNumberTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            confirmPasswordTextField.becomeFirstResponder()
        } else if textField == confirmPasswordTextField {
            createButtonTapped(self)
        }
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    @IBAction func createButtonTapped(_ sender: Any) {
        guard let name = nameTextField.text, !name.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let id = idTextField.text, !id.isEmpty,
              let phoneNumber = phoneNumberTextField.text, !phoneNumber.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields.")
            return
        }
        
        if password != confirmPassword {
            showAlert(title: "Error", message: "Passwords do not match.")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.showAlert(title: "Sign Up Failed", message: error.localizedDescription)
                return
            }
            
            guard let userId = authResult?.user.uid else { return }
            
            let userValues: [String: Any] = [
                "name": name,
                "email": email,
                "id": id,
                "role": "employee",
                "phone number": phoneNumber,
                "dataAccess": "True",
                "lastAccessed": "1900-01-01",
                "firebaseKey": userId
            ]
            
            let ref = Database.database().reference().child("users").child("employees").child(userId)
            ref.setValue(userValues) { error, _ in
                if let error = error {
                    self.showAlert(title: "Error", message: "Failed to save user data: \(error.localizedDescription)")
                } else {
                    if let user = Auth.auth().currentUser {
                        UserService.shared.fetchUserInfoAndPersist(userId: user.uid)
                    }
                    
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

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
           let activeTextField = self.activeTextField {
            let screenHeight = UIScreen.main.bounds.height
            let bottomOfTextField = activeTextField.convert(activeTextField.bounds, to: view).maxY
            let keyboardHeight = keyboardFrame.height
            let offset = bottomOfTextField + keyboardHeight - screenHeight
            if offset > 0 {
                view.frame.origin.y -= offset
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        view.frame.origin.y = 0
    }
}
