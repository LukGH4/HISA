import UIKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class SettingsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private let profileImageView = UIImageView()
    private let editProfileImageButton = UIButton()
    private let personalInfoStackView = UIStackView()
    private let logoutButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        overrideUserInterfaceStyle = .light
        title = "Settings"

        setupProfileSection()
        setupPersonalInfoSection()
        setupActivityIndicator()
        setupTapGesture()
        loadUserData()
        loadProfileImageIfAvailable()
    }

    private func setupProfileSection() {
        profileImageView.layer.cornerRadius = 50
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.image = UIImage(named: "defaultProfileImage")
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.systemBlue.cgColor
        view.addSubview(profileImageView)

        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100)
        ])

        editProfileImageButton.setImage(UIImage(systemName: "pencil.circle.fill"), for: .normal)
        editProfileImageButton.tintColor = .systemBlue
        editProfileImageButton.addTarget(self, action: #selector(uploadProfilePictureButtonTapped), for: .touchUpInside)
        view.addSubview(editProfileImageButton)

        editProfileImageButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            editProfileImageButton.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 5),
            editProfileImageButton.trailingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 5),
            editProfileImageButton.widthAnchor.constraint(equalToConstant: 30),
            editProfileImageButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupPersonalInfoSection() {
        personalInfoStackView.axis = .vertical
        personalInfoStackView.spacing = 24
        view.addSubview(personalInfoStackView)

        personalInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            personalInfoStackView.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 40),
            personalInfoStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            personalInfoStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func renderUserData() {
        personalInfoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let userData = CurrentUser.shared.getUserData()

        let idRowStackView = UIStackView()
        idRowStackView.axis = .horizontal
        idRowStackView.alignment = .center
        idRowStackView.spacing = 24
        personalInfoStackView.addArrangedSubview(idRowStackView)

        let idIconImageView = UIImageView()
        idIconImageView.image = UIImage(systemName: "creditcard")
        idIconImageView.tintColor = .gray
        idIconImageView.contentMode = .scaleAspectFit
        idRowStackView.addArrangedSubview(idIconImageView)

        idIconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            idIconImageView.widthAnchor.constraint(equalToConstant: 24),
            idIconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])

        let idInfoLabel = UILabel()
        idInfoLabel.text = "ID"
        idInfoLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        idInfoLabel.textColor = .black
        idRowStackView.addArrangedSubview(idInfoLabel)

        let idSpacerView = UIView()
        idSpacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        idRowStackView.addArrangedSubview(idSpacerView)

        let idValueLabel = UILabel()
        idValueLabel.text = CurrentUser.shared.getId() ?? "Unknown"
        idValueLabel.font = UIFont.systemFont(ofSize: 16)
        idValueLabel.textColor = .darkGray
        idValueLabel.numberOfLines = 0
        idRowStackView.addArrangedSubview(idValueLabel)

        let scansRowStackView = UIStackView()
        scansRowStackView.axis = .horizontal
        scansRowStackView.alignment = .center
        scansRowStackView.spacing = 24
        personalInfoStackView.addArrangedSubview(scansRowStackView)

        let scansIconImageView = UIImageView()
        scansIconImageView.image = UIImage(systemName: "camera.viewfinder")
        scansIconImageView.tintColor = .gray
        scansIconImageView.contentMode = .scaleAspectFit
        scansRowStackView.addArrangedSubview(scansIconImageView)

        scansIconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scansIconImageView.widthAnchor.constraint(equalToConstant: 24),
            scansIconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])

        let scansInfoLabel = UILabel()
        scansInfoLabel.text = "Scans"
        scansInfoLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        scansInfoLabel.textColor = .black
        scansRowStackView.addArrangedSubview(scansInfoLabel)

        let scansSpacerView = UIView()
        scansSpacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        scansRowStackView.addArrangedSubview(scansSpacerView)

        let scansValueLabel = UILabel()
        scansValueLabel.text = "\(CurrentUser.shared.scans)"
        scansValueLabel.font = UIFont.systemFont(ofSize: 16)
        scansValueLabel.textColor = .darkGray
        scansValueLabel.numberOfLines = 0
        scansRowStackView.addArrangedSubview(scansValueLabel)

        let personalInfoContainer = UIView()
        personalInfoContainer.backgroundColor = UIColor.systemGray6
        personalInfoContainer.layer.cornerRadius = 12
        personalInfoContainer.translatesAutoresizingMaskIntoConstraints = false

        let personalInfoLabel = UILabel()
        personalInfoLabel.text = "Personal Information"
        personalInfoLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        personalInfoLabel.textColor = .gray
        personalInfoLabel.translatesAutoresizingMaskIntoConstraints = false

        let personalInfoInnerStack = UIStackView()
        personalInfoInnerStack.axis = .vertical
        personalInfoInnerStack.spacing = 24
        personalInfoInnerStack.translatesAutoresizingMaskIntoConstraints = false

        addPersonalInfoRow(label: "Name", value: CurrentUser.shared.getName() ?? "", key: "name", iconName: "person", stackView: personalInfoInnerStack)
        addPersonalInfoRow(label: "E-mail", value: CurrentUser.shared.getEmail() ?? "", key: "email", iconName: "envelope", stackView: personalInfoInnerStack)
        addPersonalInfoRow(label: "Phone", value: CurrentUser.shared.getPhoneNumber() ?? "", key: "phone number", iconName: "phone", stackView: personalInfoInnerStack)

        personalInfoContainer.addSubview(personalInfoLabel)
        personalInfoContainer.addSubview(personalInfoInnerStack)
        personalInfoStackView.addArrangedSubview(personalInfoContainer)

        NSLayoutConstraint.activate([
            personalInfoLabel.topAnchor.constraint(equalTo: personalInfoContainer.topAnchor, constant: 16),
            personalInfoLabel.leadingAnchor.constraint(equalTo: personalInfoContainer.leadingAnchor, constant: 16),

            personalInfoInnerStack.topAnchor.constraint(equalTo: personalInfoLabel.bottomAnchor, constant: 16),
            personalInfoInnerStack.leadingAnchor.constraint(equalTo: personalInfoContainer.leadingAnchor, constant: 16),
            personalInfoInnerStack.trailingAnchor.constraint(equalTo: personalInfoContainer.trailingAnchor, constant: -16),
            personalInfoInnerStack.bottomAnchor.constraint(equalTo: personalInfoContainer.bottomAnchor, constant: -16)
        ])

        let changePasswordButton = UIButton(type: .system)
        changePasswordButton.setTitle("Change Password", for: .normal)
        changePasswordButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        changePasswordButton.addTarget(self, action: #selector(changePasswordButtonTapped), for: .touchUpInside)
        personalInfoStackView.addArrangedSubview(changePasswordButton)

        logoutButton.setTitle("Log Out", for: .normal)
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        logoutButton.setTitleColor(.red, for: .normal)
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
        personalInfoStackView.addArrangedSubview(logoutButton)
    }

    private func addPersonalInfoRow(label: String, value: String, key: String? = nil, iconName: String, isEditable: Bool = true, stackView: UIStackView) {
        let rowStackView = UIStackView()
        rowStackView.axis = .horizontal
        rowStackView.alignment = .center
        rowStackView.spacing = 24
        stackView.addArrangedSubview(rowStackView)

        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: iconName)
        iconImageView.tintColor = .gray
        iconImageView.contentMode = .scaleAspectFit
        rowStackView.addArrangedSubview(iconImageView)

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])

        let textStackView = UIStackView()
        textStackView.axis = .vertical
        textStackView.spacing = 4
        rowStackView.addArrangedSubview(textStackView)

        let infoLabel = UILabel()
        infoLabel.text = label
        infoLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        infoLabel.textColor = .black
        textStackView.addArrangedSubview(infoLabel)

        let infoValue = UILabel()
        infoValue.text = value
        infoValue.font = UIFont.systemFont(ofSize: 16)
        infoValue.textColor = .darkGray
        infoValue.numberOfLines = 0
        textStackView.addArrangedSubview(infoValue)

        let spacerView = UIView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        rowStackView.addArrangedSubview(spacerView)

        if isEditable, let key = key {
            let editButton = UIButton(type: .system)
            editButton.setImage(UIImage(systemName: "pencil"), for: .normal)
            editButton.tintColor = .systemBlue
            editButton.addAction(UIAction { [weak self] _ in
                self?.showEditAlert(for: key, currentValue: value)
            }, for: .touchUpInside)
            rowStackView.addArrangedSubview(editButton)

            editButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                editButton.widthAnchor.constraint(equalToConstant: 30),
                editButton.heightAnchor.constraint(equalToConstant: 30)
            ])
        }
    }

    private func showEditAlert(for fieldKey: String, currentValue: String?) {
        let fieldName = fieldKey.capitalized
        let alert = UIAlertController(title: "Edit \(fieldName)", message: nil, preferredStyle: .alert)
        if fieldKey == "profileImageUrl" {
            alert.message = "Tap below to update your profile picture."
            alert.addAction(UIAlertAction(title: "Change Profile Image", style: .default, handler: { [weak self] _ in
                self?.uploadProfilePictureButtonTapped()
            }))
        } else {
            alert.addTextField { textField in
                textField.text = currentValue
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
                guard let newValue = alert.textFields?.first?.text,
                      !newValue.isEmpty,
                      let userId = CurrentUser.shared.getFirebaseKey() else {
                    self?.showAlert(title: "Error", message: "Field cannot be empty")
                    return
                }
                self?.showLoading()
                UserService.shared.updateUserField(userId: userId, updates: [fieldKey: newValue]) { error in
                    DispatchQueue.main.async {
                        self?.hideLoading()
                        if let error = error {
                            self?.showAlert(title: "Error", message: error.localizedDescription)
                        } else {
                            self?.showAlert(title: "Success", message: "\(fieldName) updated")
                            self?.logActivity(action: "updated \(fieldKey)")
                            var updatedData = CurrentUser.shared.getUserData()
                            updatedData[fieldKey] = newValue
                            CurrentUser.shared.setUserData(updatedData)
                            self?.renderUserData()
                        }
                    }
                }
            }))
        }
        present(alert, animated: true)
    }

    private func setupActivityIndicator() {
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
    }

    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(uploadProfilePictureButtonTapped))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tapGesture)
    }

    private func loadUserData() {
        guard let userId = CurrentUser.shared.getFirebaseKey() else { return }
        
        showLoading()
        UserService.shared.fetchUserInfoAndPersist(userId: userId) { [weak self] success in
            DispatchQueue.main.async {
                self?.hideLoading()
                if success {
                    self?.renderUserData()
                } else {
                    self?.showAlert(title: "Error", message: "Failed to load user data")
                }
            }
        }
    }

    @objc func changePasswordButtonTapped() {
        let alert = UIAlertController(title: "Change Password", message: "Enter your new password", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "New password"
            textField.isSecureTextEntry = true
        }
        alert.addTextField { textField in
            textField.placeholder = "Confirm password"
            textField.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Change", style: .default, handler: { [weak self] _ in
            guard let password = alert.textFields?[0].text,
                  let confirm = alert.textFields?[1].text,
                  !password.isEmpty, !confirm.isEmpty else {
                self?.showAlert(title: "Error", message: "Passwords cannot be empty")
                return
            }
            
            guard password == confirm else {
                self?.showAlert(title: "Error", message: "Passwords don't match")
                return
            }
            
            self?.showLoading()
            Auth.auth().currentUser?.updatePassword(to: password) { error in
                DispatchQueue.main.async {
                    self?.hideLoading()
                    if let error = error {
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    } else {
                        self?.showAlert(title: "Success", message: "Password changed successfully")
                        self?.logActivity(action: "changed password")
                    }
                }
            }
        }))
        present(alert, animated: true)
    }

    @IBAction func logoutButtonTapped(_ sender: UIButton) {
           showLogoutConfirmationAlert()
       }
       
       private func showLogoutConfirmationAlert() {
           let alert = UIAlertController(title: "Logout", message: "Are you sure you want to log out?", preferredStyle: .alert)
           alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
           alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
               self.logoutUser()
           }))
           present(alert, animated: true, completion: nil)
       }

       private func logoutUser() {
           CurrentUser.shared.clearUserData()
           do {
               try Auth.auth().signOut()
               print("User signed out successfully")
           } catch let signOutError as NSError {
               print("Error signing out: \(signOutError.localizedDescription)")
           }
           navigateToLoginScreen()
       }

    private func navigateToLoginScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let window = windowScene.windows.first
                window?.rootViewController = loginViewController
                window?.makeKeyAndVisible()
            }
        }
    }

    @objc private func uploadProfilePictureButtonTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            showAlert(title: "Error", message: "Failed to select image")
            return
        }
        
        profileImageView.image = image
        uploadProfileImage(image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func uploadProfileImage(_ image: UIImage) {
        guard let userId = CurrentUser.shared.getFirebaseKey() else { return }
        
        showLoading()
        let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
        
        guard let uploadData = image.jpegData(compressionQuality: 0.7) else {
            hideLoading()
            showAlert(title: "Error", message: "Failed to process image")
            return
        }
        
        storageRef.putData(uploadData, metadata: nil) { [weak self] _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.hideLoading()
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
                return
            }
            
            storageRef.downloadURL { url, error in
                DispatchQueue.main.async {
                    self?.hideLoading()
                    
                    if let error = error {
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                        return
                    }
                    
                    guard let downloadURL = url else {
                        self?.showAlert(title: "Error", message: "Failed to get download URL")
                        return
                    }
                    
                    let updates = ["profileImageUrl": downloadURL.absoluteString]
                    UserService.shared.updateUserField(userId: userId, updates: updates) { error in
                        if let error = error {
                            self?.showAlert(title: "Error", message: error.localizedDescription)
                        } else {
                            CurrentUser.shared.setUserData(["profileImageUrl": downloadURL.absoluteString])
                            self?.showAlert(title: "Success", message: "Profile image updated")
                        }
                    }
                }
            }
        }
    }

    private func showLoading() {
        view.isUserInteractionEnabled = false
        activityIndicator.startAnimating()
    }

    private func hideLoading() {
        view.isUserInteractionEnabled = true
        activityIndicator.stopAnimating()
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func logActivity(action: String) {
        print("User \(CurrentUser.shared.getId() ?? "") \(action)")
    }
    
    private func loadProfileImageIfAvailable() {
        guard let userId = CurrentUser.shared.getFirebaseKey() else { return }
        
        let database = Database.database().reference()
        let employeeRef = database.child("users/employees/\(userId)/profileImageUrl")
        let managerRef = database.child("users/managers/\(userId)/profileImageUrl")

        func loadImage(from ref: DatabaseReference) {
            ref.observeSingleEvent(of: .value) { snapshot in
                if let urlString = snapshot.value as? String, let url = URL(string: urlString) {
                    URLSession.shared.dataTask(with: url) { data, _, error in
                        DispatchQueue.main.async {
                            if let data = data, error == nil {
                                self.profileImageView.image = UIImage(data: data)
                            } else {
                                self.profileImageView.image = UIImage(named: "defaultProfileImage")
                            }
                        }
                    }.resume()
                } else {
                    DispatchQueue.main.async {
                        self.profileImageView.image = UIImage(named: "defaultProfileImage")
                    }
                }
            }
        }
        employeeRef.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                loadImage(from: employeeRef)
            } else {
                loadImage(from: managerRef)
            }
        }
    }
}
