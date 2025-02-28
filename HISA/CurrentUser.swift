//
//  CurrentUser.swift
//  HISA
//
//  Created by Luke Hammond on 1/25/25.
//

class CurrentUser {
    static let shared = CurrentUser()

    private var name: String?
    private var email: String?
    private var id: String?
    private var role: String?
    private var firebaseKey: String?

    private init() {}

    // MARK: - Setters
    func setUserData(_ data: [String: Any]) {
        self.name = data["name"] as? String
        self.email = data["email"] as? String
        self.id = data["id"] as? String
        self.role = data["role"] as? String
        self.firebaseKey = data["firebaseKey"] as? String
    }

    func clearUserData() {
        self.name = nil
        self.email = nil
        self.id = nil
        self.role = nil
        self.firebaseKey = nil
    }

    // MARK: - Getters
    func getName() -> String? {
        return name
    }

    func getEmail() -> String? {
        return email
    }

    func getId() -> String? {
        return id
    }

    func getRole() -> String? {
        return role
    }
    
    func getFirebaseKey() -> String? {
        return firebaseKey
    }
}
