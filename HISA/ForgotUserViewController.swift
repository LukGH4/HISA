//
//  ForgotUserViewController.swift
//  HISA
//
//  Created by Hoyeon Kang on 1/17/25.
//

import UIKit

class ForgotUserViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func submitButtonTapped(_ sender: Any) {
        // handle logic here
        let alert = UIAlertController(title: "Email Sent", message: "Please check your Honeywell email", preferredStyle: .alert)
            
        // Add an action (button) to the popup
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
            
        // Present the popup
        self.present(alert, animated: true, completion: nil)
    }
    
}

