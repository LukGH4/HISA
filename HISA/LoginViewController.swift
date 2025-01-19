//
//  LoginViewController.swift
//  HISA
//
//  Created by Barnabas Li on 1/16/25.
//


import UIKit
import FirebaseDatabase

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func loginButtonTapped(_ sender: Any) {
        // handle logic here
        let alert = UIAlertController(title: "Login Failed", message: "Wrong Username or Password", preferredStyle: .alert)
            
        // Add an action (button) to the popup
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
            
        // Present the popup
        self.present(alert, animated: true, completion: nil)
    }
}
