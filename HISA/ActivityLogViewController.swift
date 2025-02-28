//
//  ActivityLogViewController.swift
//  HISA
//
//  Created by Barnabas Li on 2/27/25.
//


import UIKit
import FirebaseDatabase

class ActivityLogViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var activityLogs: [ActivityLog] = []
    let databaseRef = Database.database().reference().child("activity_log")
    let userRef = Database.database().reference().child("users/employees")
    let imageCache = NSCache<NSString, UIImage>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        fetchActivityLogs()
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
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear], from: date, to: now)
        
        if let minutes = components.minute, minutes < 60 {
            return minutes == 1 ? "1 min ago" : "\(minutes) mins ago"
        }
        if let hours = components.hour, hours < 24 {
            return hours == 1 ? "1 hr ago" : "\(hours) hrs ago"
        }
        if let days = components.day, days < 7 {
            return days == 1 ? "1d ago" : "\(days)d ago"
        }
        if let weeks = components.weekOfYear {
            return weeks == 1 ? "1w ago" : "\(weeks)w ago"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: date)
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
