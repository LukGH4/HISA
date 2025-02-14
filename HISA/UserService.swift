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
        let databaseRef = Database.database().reference()
        
        // Check employees first
        databaseRef.child("users/employees").child(userId).observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                CurrentUser.shared.setUserData(userData)
            } else {
                // If not found, check managers
                databaseRef.child("users/managers").child(userId).observeSingleEvent(of: .value) { snapshot in
                    if let userData = snapshot.value as? [String: Any] {
                        CurrentUser.shared.setUserData(userData)
                    }
                }
            }
        }
    }

    func updateUserField(userId: String, updates: [String: Any], completion: @escaping (Error?) -> Void) {
        guard let userRole = CurrentUser.shared.getRole() else {
            print("Error: User role not found")
            completion(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "User role not found"]))
            return
        }

        let userPath = userRole == "manager" ? "users/managers" : "users/employees"
        let ref = Database.database().reference().child(userPath).child(userId)

        ref.updateChildValues(updates) { error, _ in
            completion(error)
        }
    }

    func fetchUserByEmployeeId(employeeId: String, completion: @escaping (Bool) -> Void) {
        let databaseRef = Database.database().reference()

        func searchUser(in path: String, completion: @escaping (Bool) -> Void) {
            databaseRef.child(path).observeSingleEvent(of: .value) { snapshot in
                for child in snapshot.children {
                    if let childSnapshot = child as? DataSnapshot,
                       let userData = childSnapshot.value as? [String: Any],
                       let storedEmployeeId = userData["id"] as? String,
                       storedEmployeeId == employeeId {
                        
                        // Add Firebase key to the user data dictionary
                        var userWithKeyData = userData
                        userWithKeyData["firebaseKey"] = childSnapshot.key

                        // Determine role and store in CurrentUser
                        userWithKeyData["role"] = path.contains("managers") ? "manager" : "employee"
                        CurrentUser.shared.setUserData(userWithKeyData)

                        print("User found in \(path) with Firebase key: \(childSnapshot.key)")
                        completion(true)
                        return
                    }
                }
                completion(false)
            }
        }

        // Search in employees first, then managers
        searchUser(in: "users/employees") { found in
            if found {
                completion(true)
            } else {
                searchUser(in: "users/managers", completion: completion)
            }
        }
    }
}
