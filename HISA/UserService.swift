//
//  UserService.swift
//  HISA
//
//  Created by Luke Hammond on 1/25/25.
//

import FirebaseDatabase

class UserService {
    static let shared = UserService()

    private init() {}

    func fetchUserInfoAndPersist(userId: String) {
        let ref = Database.database().reference().child("users").child(userId)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                CurrentUser.shared.setUserData(userData)
            }
        }
    }
    
    func updateUserField(userId: String, updates: [String: Any], completion: @escaping (Error?) -> Void) {
        let ref = Database.database().reference().child("users").child(userId)
        ref.updateChildValues(updates) { error, _ in
            completion(error)
        }
    }
    
    func fetchUserByEmployeeId(employeeId: String, completion: @escaping (Bool) -> Void) {
            let ref = Database.database().reference().child("users")

            ref.observeSingleEvent(of: .value) { snapshot in
                var userFound = false
                for child in snapshot.children {
                    if let childSnapshot = child as? DataSnapshot,
                       let userData = childSnapshot.value as? [String: Any],
                       let storedEmployeeId = userData["id"] as? String,
                       storedEmployeeId == employeeId {
                        
                        // Add Firebase key to the user data dictionary
                        var userWithKeyData = userData
                        userWithKeyData["firebaseKey"] = childSnapshot.key

                        // Store in CurrentUser singleton
                        CurrentUser.shared.setUserData(userWithKeyData)
                        print("User found with Firebase key: \(childSnapshot.key)")
                        userFound = true
                        completion(true)
                        return
                    }
                }
                print("Employee ID not found in Firebase")
                completion(false)
            }
        }
}
