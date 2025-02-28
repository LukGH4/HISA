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
        overrideUserInterfaceStyle = .light
        uname.backgroundColor = .white
        uname.textColor = .black
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
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let currentDate = dateFormatter.string(from: Date())
                    
                    employeesRef.child("lastAccessed").setValue(currentDate) { error, _ in
                        if let error = error {
                            print("Error updating lastAccessed: \(error.localizedDescription)")
                        } else {
                            print("lastAccessed updated successfully")
                        }
                    }
                } else {
                    managersRef.observeSingleEvent(of: .value) { snapshot in
                        if snapshot.exists(), let data = snapshot.value as? [String: Any], let name = data["name"] as? String {
                            self.uname.text = name
                            
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            let currentDate = dateFormatter.string(from: Date())
                            
                            managersRef.child("lastAccessed").setValue(currentDate) { error, _ in
                                if let error = error {
                                    print("Error updating lastAccessed: \(error.localizedDescription)")
                                } else {
                                    print("lastAccessed updated successfully")
                                }
                            }
                        } else {
                            print("User not found in employees or managers.")
                        }
                    }
                }
            }
        }
    }
}
