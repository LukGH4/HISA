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
        
        // Made for test to see if the button is clicked, it goes to the next screen.
        if let tabBarController = storyboard?.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
            // Optionally set the selected tab (e.g., 1 for the second tab)
            tabBarController.selectedIndex = 0
                    
            if let window = UIApplication.shared.windows.first {
                 window.rootViewController = tabBarController
                 window.makeKeyAndVisible()
                 
                 // Optionally, add a transition animation
                 let transition = CATransition()
                 transition.type = .fade
                 transition.duration = 0.3
                 window.layer.add(transition, forKey: kCATransition)
             }
        }
        
        
    }
}
