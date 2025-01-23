//
//  HomeViewContoller.swift
//  HISA
//
//  Created by Hoyeon Kang on 11/16/24.
//

import UIKit
import FirebaseDatabase

class HomeViewController: UIViewController, UITextFieldDelegate{
    @IBOutlet weak var uname: UITextField!
    
    var loggedInUsername: String?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Home Screen Loaded")
        fetchUserName()
    }
    
    
    // this doesn't work at the moment since the backend isn't finished, but it displays the name of the employee on the welcome screen. will likely need to modify
    func fetchUserName() {
            let ref = Database.database().reference()
            ref.child("users/employees").queryOrdered(byChild: "username").queryEqual(toValue: loggedInUsername).observeSingleEvent(of: .value) { snapshot in
                if let employee = snapshot.value as? [String: Any] {
                    for (_, data) in employee {
                        if let userData = data as? [String: Any],
                           let name = userData["name"] as? String {
                            self.uname.text = name
                            return
                        }
                    }
                }

                ref.child("users/managers").queryOrdered(byChild: "username").queryEqual(toValue: self.loggedInUsername).observeSingleEvent(of: .value) { snapshot in
                    if let manager = snapshot.value as? [String: Any] {
                        for (_, data) in manager {
                            if let userData = data as? [String: Any],
                               let name = userData["name"] as? String {
                                self.uname.text = name
                                return
                            }
                        }
                    }
                    self.uname.text = "Employee Name"
                }
            }
        }
}
