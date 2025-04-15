import UIKit
import FirebaseDatabase

extension UIViewController {
    func checkFailureRates(completion: @escaping (String?) -> Void) {
        let ref = Database.database().reference()
        ref.child("users").child("employees").observeSingleEvent(of: .value) { snapshot in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            
            var localPartTypes: [String: [String: Any]] = [:]
            let group = DispatchGroup()
            
            for employeeSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                let imagesRef = employeeSnapshot.childSnapshot(forPath: "images")
                let videosRef = employeeSnapshot.childSnapshot(forPath: "videos")
                
                for imageSnapshot in imagesRef.children.allObjects as! [DataSnapshot] {
                    if let partType = imageSnapshot.childSnapshot(forPath: "part_type").value as? String,
                       let status = imageSnapshot.childSnapshot(forPath: "status").value as? String {
                        var partTypeEntry = localPartTypes[partType] ?? ["good": 0, "bad": 0]
                        if status == "Good Part" {
                            partTypeEntry["good"] = (partTypeEntry["good"] as? Int ?? 0) + 1
                        } else {
                            partTypeEntry["bad"] = (partTypeEntry["bad"] as? Int ?? 0) + 1
                        }
                        localPartTypes[partType] = partTypeEntry
                    }
                }
                
                for videoSnapshot in videosRef.children.allObjects as! [DataSnapshot] {
                    if let partType = videoSnapshot.childSnapshot(forPath: "part_type").value as? String,
                       let status = videoSnapshot.childSnapshot(forPath: "status").value as? String {
                        var partTypeEntry = localPartTypes[partType] ?? ["good": 0, "bad": 0]
                        if status == "Good Part" {
                            partTypeEntry["good"] = (partTypeEntry["good"] as? Int ?? 0) + 1
                        } else {
                            partTypeEntry["bad"] = (partTypeEntry["bad"] as? Int ?? 0) + 1
                        }
                        localPartTypes[partType] = partTypeEntry
                    }
                }
            }
            
            self.checkFailureRates(in: localPartTypes, completion: completion)
        }
    }
    
    private func checkFailureRates(in partTypes: [String: [String: Any]], completion: @escaping (String?) -> Void) {
        var alertMessage = "The following parts have surpassed the failure threshold:\n"
        var hasHighFailureRate = false
        var thresholdFetchCount = 0
        let totalPartTypes = partTypes.count
        var partMessages: [String] = []
        let failureRateThreshold: Double = -1.0

        guard totalPartTypes > 0 else {
            completion(nil)
            return
        }

        for (partType, statusCounts) in partTypes {
            if let goodCount = statusCounts["good"] as? Int,
               let badCount = statusCounts["bad"] as? Int {
                let total = goodCount + badCount
                let failureRatio = total > 0 ? (Double(badCount) / Double(total)) * 100 : 0.0

                self.fetchThreshold(for: partType) { threshold in
                    let partTypeThreshold = threshold ?? failureRateThreshold
                    if failureRatio > partTypeThreshold {
                        partMessages.append("\(partType): \(String(format: "%.2f", failureRatio))%")
                        hasHighFailureRate = true
                    }
                    thresholdFetchCount += 1

                    if thresholdFetchCount == totalPartTypes {
                        if hasHighFailureRate {
                            alertMessage += partMessages.joined(separator: "\n")
                            completion(alertMessage)
                        } else {
                            completion(nil)
                        }
                    }
                }
            } else {
                thresholdFetchCount += 1
                if thresholdFetchCount == totalPartTypes && !hasHighFailureRate {
                    completion(nil)
                }
            }
        }
    }

    private func fetchThreshold(for partType: String, completion: @escaping (Double?) -> Void) {
        let partsRef = Database.database().reference().child("parts").child(partType)

        partsRef.observeSingleEvent(of: .value, with: { snapshot in
            if let data = snapshot.value as? [String: Any], let storedThreshold = data["threshold"] as? Double {
                completion(storedThreshold)
            } else {
                completion(nil)
            }
        }) { error in
            print("Error retrieving threshold for part type \(partType): \(error.localizedDescription)")
            completion(nil)
        }
    }
}


class ActivityLogViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var activityLogs: [ActivityLog] = []
    let databaseRef = Database.database().reference().child("activity_log")
    let userRef = Database.database().reference().child("users/employees")
    let imageCache = NSCache<NSString, UIImage>()

    let welcomeLabel = UILabel()
    let alertButton = UIButton(type: .system)
    let profileImageView = UIImageView()
    var partTypes: [String: [String: Any]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light

        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false

        setupTopBar()
        fetchActivityLogs()
        loadProfileImageIfAvailable()
    }
    
    private func fetchPartTypes() {
        let ref = Database.database().reference()
        ref.child("users").child("employees").observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                var localPartTypes: [String: [String: Any]] = [:]
                
                for employeeSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                    let imagesRef = employeeSnapshot.childSnapshot(forPath: "images")
                    let videosRef = employeeSnapshot.childSnapshot(forPath: "videos")

                    for imageSnapshot in imagesRef.children.allObjects as! [DataSnapshot] {
                        if let partType = imageSnapshot.childSnapshot(forPath: "part_type").value as? String,
                           let status = imageSnapshot.childSnapshot(forPath: "status").value as? String {
                            var partTypeEntry = localPartTypes[partType] ?? ["good": 0, "bad": 0]
                            if status == "Good Part" {
                                partTypeEntry["good"] = (partTypeEntry["good"] as? Int ?? 0) + 1
                            } else {
                                partTypeEntry["bad"] = (partTypeEntry["bad"] as? Int ?? 0) + 1
                            }
                            localPartTypes[partType] = partTypeEntry
                        }
                    }

                    for videoSnapshot in videosRef.children.allObjects as! [DataSnapshot] {
                        if let partType = videoSnapshot.childSnapshot(forPath: "part_type").value as? String,
                           let status = videoSnapshot.childSnapshot(forPath: "status").value as? String {
                            var partTypeEntry = localPartTypes[partType] ?? ["good": 0, "bad": 0]
                            if status == "Good Part" {
                                partTypeEntry["good"] = (partTypeEntry["good"] as? Int ?? 0) + 1
                            } else {
                                partTypeEntry["bad"] = (partTypeEntry["bad"] as? Int ?? 0) + 1
                            }
                            localPartTypes[partType] = partTypeEntry
                        }
                    }
                }
                
                self.partTypes = localPartTypes
            }
        })
    }

    private func setupTopBar() {
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.cornerRadius = 25
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.image = UIImage(data: try! Data(contentsOf: URL(string: "https://firebasestorage.googleapis.com:443/v0/b/jib-4338-hisa.firebasestorage.app/o/profile_pictures%2FaGYOd0Z6M7NQsMrF1mJvPvSVA4j1.jpg?alt=media&token=1d00bdcb-5134-424f-a46a-e4c03277bb0e")!))
        view.addSubview(profileImageView)

        let welcomeText = NSMutableAttributedString(
            string: "Welcome,\n",
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.gray,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)
            ]
        )
        welcomeText.append(
            NSAttributedString(
                string: "John Manager",
                attributes: [
                    NSAttributedString.Key.foregroundColor: UIColor.black,
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)
                ]
            )
        )

        welcomeLabel.attributedText = welcomeText
        welcomeLabel.numberOfLines = 0
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(welcomeLabel)

        alertButton.setImage(UIImage(systemName: "bell"), for: .normal)
        alertButton.tintColor = .black
        alertButton.addTarget(self, action: #selector(alertButtonTapped), for: .touchUpInside)
        alertButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(alertButton)

        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.heightAnchor.constraint(equalToConstant: 50),

            welcomeLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            welcomeLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),

            alertButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            alertButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor)
        ])
    }

    @objc private func alertButtonTapped() {
        let alert = UIAlertController(title: "Checking Failure Rates", message: "Please wait...", preferredStyle: .alert)
        present(alert, animated: true)
        
        checkFailureRates { [weak self] message in
            DispatchQueue.main.async {
                alert.dismiss(animated: true) {
                    if let message = message {
                        let resultAlert = UIAlertController(title: "High Failure Rate Alert",
                                                          message: message,
                                                          preferredStyle: .alert)
                        resultAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(resultAlert, animated: true)
                    } else {
                        let resultAlert = UIAlertController(title: "No Issues Found",
                                                          message: "All parts are within acceptable failure rates.",
                                                          preferredStyle: .alert)
                        resultAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(resultAlert, animated: true)
                    }
                }
            }
        }
    }

    private func loadProfileImageIfAvailable() {
        guard let employeeId = CurrentUser.shared.getFirebaseKey() else { return }
        
        let employeePath = "users/employees/\(employeeId)/profileImageUrl"
        let managerPath = "users/managers/\(employeeId)/profileImageUrl"
        
        tryLoadProfileImage(from: employeePath, or: managerPath)
    }

    private func tryLoadProfileImage(from employeePath: String, or managerPath: String) {
        let paths = [employeePath, managerPath]
        var imageLoaded = false
        var remainingPaths = paths.count

        for path in paths {
            let components = path.split(separator: "/").map { String($0) }
            var ref = Database.database().reference()

            for comp in components {
                ref = ref.child(comp)
            }

            ref.observeSingleEvent(of: .value) { snapshot in
                if let urlString = snapshot.value as? String, let url = URL(string: urlString) {
                    URLSession.shared.dataTask(with: url) { data, _, error in
                        if let data = data, error == nil {
                            DispatchQueue.main.async {
                                self.profileImageView.image = UIImage(data: data)
                            }
                            imageLoaded = true
                        }

                        remainingPaths -= 1
                        if remainingPaths == 0 && !imageLoaded {
                            DispatchQueue.main.async {
                                self.profileImageView.image = UIImage(named: "defaultProfileImage")
                            }
                        }
                    }.resume()
                } else {
                    remainingPaths -= 1
                    if remainingPaths == 0 && !imageLoaded {
                        DispatchQueue.main.async {
                            self.profileImageView.image = UIImage(named: "defaultProfileImage")
                        }
                    }
                }
            }
        }
    }

    private func fetchActivityLogs() {
        databaseRef.queryOrdered(byChild: "timestamp").queryLimited(toLast: 25).observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [String: [String: Any]] else { return }
            var logs: [ActivityLog] = []
            let group = DispatchGroup()
            var logIDs: [String] = []

            let sortedEntries = value.sorted {
                ($0.value["timestamp"] as? TimeInterval ?? 0) > ($1.value["timestamp"] as? TimeInterval ?? 0)
            }

            for (key, data) in sortedEntries {
                guard var log = ActivityLog(id: key, data: data) else { continue }
                logIDs.append(key)

                group.enter()
                self.userRef.child(log.employeeID).observeSingleEvent(of: .value) { userSnapshot in
                    if let userData = userSnapshot.value as? [String: Any],
                       let name = userData["name"] as? String {
                        log.employeeName = name
                    }
                    logs.append(log)
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.activityLogs = logs.sorted { $0.timestamp > $1.timestamp }
                self.tableView.reloadData()
                self.deleteOldLogs(keepingIDs: logIDs)
            }
        }
    }

    private func deleteOldLogs(keepingIDs: [String]) {
        databaseRef.observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [String: Any] else { return }

            for (key, _) in value {
                if !keepingIDs.contains(key) {
                    self.databaseRef.child(key).removeValue()
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activityLogs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityLogCell", for: indexPath) as! ActivityLogTableViewCell
        let log = activityLogs[indexPath.row]

        cell.nameLabel.text = "\(log.employeeName)"
        cell.activityLabel.text = "\(log.action)"
        cell.timeLabel.text = log.formattedTimestamp()
        cell.profileImageView.image = UIImage(named: "defaultProfileImage")

        fetchProfileImage(for: log.employeeID, imageView: cell.profileImageView)

        return cell
    }

    private func fetchProfileImage(for employeeID: String, imageView: UIImageView) {
        userRef.child(employeeID).observeSingleEvent(of: .value) { snapshot in
            guard let userData = snapshot.value as? [String: Any],
                  let profileImageUrl = userData["profileImageUrl"] as? String,
                  let url = URL(string: profileImageUrl) else { return }

            let cacheKey = NSString(string: profileImageUrl)
            if let cachedImage = self.imageCache.object(forKey: cacheKey) {
                imageView.image = cachedImage
            } else {
                URLSession.shared.dataTask(with: url) { data, _, error in
                    if let data = data, error == nil, let image = UIImage(data: data) {
                        self.imageCache.setObject(image, forKey: cacheKey)
                        DispatchQueue.main.async {
                            imageView.image = image
                        }
                    }
                }.resume()
            }
        }
    }
}

class ActivityLogTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var activityLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        makeImageViewCircular()
    }

    private func makeImageViewCircular() {
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 1.0
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor
    }
}

import Foundation

struct ActivityLog {
    var id: String
    var employeeID: String
    var employeeName: String
    var action: String
    var timestamp: TimeInterval

    init?(id: String, data: [String: Any]) {
        guard let employeeID = data["userId"] as? String,
              let action = data["action"] as? String,
              let timestamp = data["timestamp"] as? TimeInterval else { return nil }

        self.id = id
        self.employeeID = employeeID
        self.employeeName = ""
        self.action = action
        self.timestamp = timestamp
    }

    func formattedTimestamp() -> String {
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let now = Date()
        let interval = now.timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        let weeks = Int(interval / 604800)

        if minutes < 60 {
            return minutes == 1 ? "1 min ago" : "\(minutes) mins ago"
        }
        if hours < 24 {
            return hours == 1 ? "1 hr ago" : "\(hours) hrs ago"
        }
        if days < 7 {
            return days == 1 ? "1d ago" : "\(days)d ago"
        }
        if weeks >= 1 {
            return weeks == 1 ? "1w ago" : "\(weeks)w ago"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: date)
    }
}
