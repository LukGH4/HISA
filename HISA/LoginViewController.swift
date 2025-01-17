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
    }
}
