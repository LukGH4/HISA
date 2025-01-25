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
}
