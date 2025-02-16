//
//  HomeViewContoller.swift
//  HISA
//
//  Created by Hoyeon Kang on 11/16/24.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class HomeViewController: UIViewController, UITextFieldDelegate{
    @IBOutlet weak var uname: UITextField!
    
    var loggedInUsername: String?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Home Screen Loaded")
        fetchUserName()
    }
    

    // This code is modified by Hoyeon Kang
    func fetchUserName() {
            let ref = Database.database().reference()
        
        if let user = Auth.auth().currentUser {
            let uid = user.uid
            let employeesRef = ref.child("users/employees").child(uid)
            let managersRef = ref.child("users/managers").child(uid)
            
            
            uname.isUserInteractionEnabled = false

            employeesRef.observeSingleEvent(of: .value) { snapshot in
                if snapshot.exists(), let data = snapshot.value as? [String: Any], let name = data["name"] as? String {
                    self.uname.text = name
                } else {

                    managersRef.observeSingleEvent(of: .value) { snapshot in
                        if snapshot.exists(), let data = snapshot.value as? [String: Any], let name = data["name"] as? String {
                            self.uname.text = name
                        } else {
                            print("User not found in employees or managers.")
                        }
                    }
                }
            }
            
            
            
        }
            
            
//            ref.child("users/employees").queryOrdered(byChild: "username").queryEqual(toValue: loggedInUsername).observeSingleEvent(of: .value) { snapshot in
//                if let employee = snapshot.value as? [String: Any] {
//                    for (_, data) in employee {
//                        if let userData = data as? [String: Any],
//                           let name = userData["name"] as? String {
//                            self.uname.text = name
//                            return
//                        }
//                    }
//                }
//
//                ref.child("users/managers").queryOrdered(byChild: "username").queryEqual(toValue: self.loggedInUsername).observeSingleEvent(of: .value) { snapshot in
//                    if let manager = snapshot.value as? [String: Any] {
//                        for (_, data) in manager {
//                            if let userData = data as? [String: Any],
//                               let name = userData["name"] as? String {
//                                self.uname.text = name
//                                return
//                            }
//                        }
//                    }
//                    self.uname.text = "Employee Name"
//                }
//            }
        }
}
