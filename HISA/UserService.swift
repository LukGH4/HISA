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

    func fetchUserInfoAndPersist(userId: String, completion: ((Bool) -> Void)? = nil) {
        let databaseRef = Database.database().reference()

        databaseRef.child("users/employees").child(userId).observeSingleEvent(of: .value) { snapshot in
            if var userData = snapshot.value as? [String: Any] {
                userData["firebaseKey"] = snapshot.key
                userData["role"] = "employee"
                CurrentUser.shared.setUserData(userData)
                completion?(true)
            } else {
                databaseRef.child("users/managers").child(userId).observeSingleEvent(of: .value) { snapshot in
                    if var userData = snapshot.value as? [String: Any] {
                        userData["firebaseKey"] = snapshot.key
                        userData["role"] = "manager"
                        CurrentUser.shared.setUserData(userData)
                        completion?(true)
                    } else {
                        completion?(false)
                    }
                }
            }
        }
    }

    func updateUserField(userId: String, updates: [String: Any], completion: @escaping (Error?) -> Void) {
        guard let userRole = CurrentUser.shared.getRole() else {
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
                       var userData = childSnapshot.value as? [String: Any],
                       let storedEmployeeId = userData["id"] as? String,
                       storedEmployeeId == employeeId {
                        
                        userData["firebaseKey"] = childSnapshot.key
                        userData["role"] = path.contains("managers") ? "manager" : "employee"
                        CurrentUser.shared.setUserData(userData)
                        completion(true)
                        return
                    }
                }
                completion(false)
            }
        }

        searchUser(in: "users/employees") { found in
            if found {
                completion(true)
            } else {
                searchUser(in: "users/managers", completion: completion)
            }
        }
    }
}
