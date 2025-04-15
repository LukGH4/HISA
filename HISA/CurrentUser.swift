import FirebaseDatabase

class CurrentUser {
    static let shared = CurrentUser()

    private var name: String?
    private var email: String?
    private var id: String?
    private var role: String?
    private var firebaseKey: String?
    private var phoneNumber: String?
    private var profileImageUrl: String?
    
    private var images: [String: Any]?
    private var videos: [String: Any]?

    private init() {}

    func setUserData(_ data: [String: Any]) {
        self.name = data["name"] as? String
        self.email = data["email"] as? String
        self.id = data["id"] as? String
        self.role = data["role"] as? String
        self.firebaseKey = data["firebaseKey"] as? String
        self.phoneNumber = data["phone number"] as? String
        self.profileImageUrl = data["profileImageUrl"] as? String
        
        self.images = data["images"] as? [String: Any]
        self.videos = data["videos"] as? [String: Any]

        updateUserInFirebase()
    }

    func clearUserData() {
        self.name = nil
        self.email = nil
        self.id = nil
        self.role = nil
        self.firebaseKey = nil
        self.phoneNumber = nil
        self.profileImageUrl = nil
        self.images = nil
        self.videos = nil
    }

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
    
    func getPhoneNumber() -> String? {
        return phoneNumber
    }
    
    func getProfileImageUrl() -> String? {
        return profileImageUrl
    }
    
    func getUserData() -> [String: Any] {
        return [
            "name": name ?? "",
            "email": email ?? "",
            "id": id ?? "",
            "role": role ?? "",
            "firebaseKey": firebaseKey ?? "",
            "phone number": phoneNumber ?? "",
            "profileImageUrl": profileImageUrl ?? "",
            "images": images ?? [:],
            "videos": videos ?? [:],
            "scans": scans
        ]
    }
    
    var scans: Int {
        let imageCount = images?.count ?? 0
        let videoCount = videos?.count ?? 0
        return imageCount + videoCount
    }

    private func updateUserInFirebase() {
        guard let firebaseKey = firebaseKey else {
            print("User does not have a valid firebase key.")
            return
        }

        let database = Database.database().reference()

        let managersRef = database.child("users").child("managers").child(firebaseKey)
        let employeesRef = database.child("users").child("employees").child(firebaseKey)

        managersRef.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                let userData: [String: Any] = self.getUserData()
                managersRef.updateChildValues(userData) { error, _ in
                    if let error = error {
                        print("Error updating manager data: \(error.localizedDescription)")
                    } else {
                        print("Manager data updated successfully.")
                    }
                }
            } else {
                employeesRef.observeSingleEvent(of: .value) { snapshot in
                    if snapshot.exists() {
                        let userData: [String: Any] = self.getUserData()
                        employeesRef.updateChildValues(userData) { error, _ in
                            if let error = error {
                                print("Error updating employee data: \(error.localizedDescription)")
                            } else {
                                print("Employee data updated successfully.")
                            }
                        }
                    } else {
                        print("User not found under managers or employees.")
                    }
                }
            }
        }
    }
}
