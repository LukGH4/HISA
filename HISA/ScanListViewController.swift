import UIKit
import Firebase
import FirebaseAuth
import AVKit
import FirebaseDatabaseInternal

class ScanListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ScanListImageViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var refreshButton: UIButton!
    
    var scans: [[String: String]] = [] // Renamed from `images` to `scans`
    var username: String = ""
    
    private let refreshControl = UIRefreshControl() // For pull-to-refresh
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTableView()
        fetchScansFromFirebase()
    }
    
    func setupUI() {
        // Customize refresh button
        refreshButton.layer.cornerRadius = 8
                refreshButton.layer.shadowColor = UIColor.black.cgColor
                refreshButton.layer.shadowOpacity = 0.3
                refreshButton.layer.shadowOffset = CGSize(width: 0, height: 2)
                refreshButton.layer.shadowRadius = 4
        // For system image (SF Symbols)
        if let image = UIImage(systemName: "arrow.clockwise.circle") {
            let scaledImage = image.withConfiguration(UIImage.SymbolConfiguration(pointSize: 30, weight: .regular, scale: .default))
            refreshButton.setImage(scaledImage, for: .normal)
        }
        
        // Add pull-to-refresh
        refreshControl.addTarget(self, action: #selector(refreshList), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ScanTableViewCell.self, forCellReuseIdentifier: "ScanCell") // Register custom cell
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemGroupedBackground
    }
    
    func fetchScansFromFirebase() {
        scans.removeAll()
        fetchImagesFromFirebase()
        fetchVideosFromFirebase()
    }
    
    func fetchImagesFromFirebase() {
        guard let user = Auth.auth().currentUser else {
            print("No user is signed in")
            return
        }
        
        let uid = user.uid
        let databaseRef = Database.database().reference().child("users").child("employees").child(uid)
        
        databaseRef.observeSingleEvent(of: .value) { snapshot in
            guard let employeeData = snapshot.value as? [String: Any],
                  let username = employeeData["name"] as? String,
                  let imagesData = employeeData["images"] as? [String: [String: Any]] else {
                print("No data found or incorrect structure")
                return
            }
            
            for (folderKey, imageDetails) in imagesData {
                self.scans.append([
                    "folderKey": folderKey,
                    "partType": imageDetails["part_type"] as? String ?? "Unknown Part", // Add part type
                    "date": imageDetails["date"] as? String ?? "",
                    "url": imageDetails["url"] as? String ?? "",
                    "status": imageDetails["status"] as? String ?? "",
                    "classification": imageDetails["classification"] as? String ?? "",
                    "confidence": imageDetails["confidence"] as? String ?? "",
                    "fileName": imageDetails["fileName"] as? String ?? ""
                ])
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func fetchVideosFromFirebase() {
        guard let user = Auth.auth().currentUser else {
            print("No user is signed in")
            return
        }
        
        let uid = user.uid
        let databaseRef = Database.database().reference().child("users").child("employees").child(uid)
        
        databaseRef.observeSingleEvent(of: .value) { snapshot in
            guard let employeeData = snapshot.value as? [String: Any],
                  let username = employeeData["name"] as? String,
                  let videosData = employeeData["videos"] as? [String: [String: Any]] else {
                print("No data found or incorrect structure")
                return
            }
            
            for (folderKey, videoDetails) in videosData {
                self.scans.append([
                    "folderKey": folderKey,
                    "partType": videoDetails["part_type"] as? String ?? "Unknown Part", // Add part type
                    "date": videoDetails["date"] as? String ?? "",
                    "url": videoDetails["url"] as? String ?? "",
                    "status": videoDetails["status"] as? String ?? "",
                    "classification": videoDetails["classification"] as? String ?? "",
                    "confidence": videoDetails["confidence"] as? String ?? "",
                    "fileName": videoDetails["fileName"] as? String ?? ""
                ])
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scans.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScanCell", for: indexPath) as! ScanTableViewCell
        let scan = scans[indexPath.row]
        
        cell.partTypeLabel.text = scan["partType"]
        cell.dateLabel.text = scan["date"]
        cell.statusLabel.text = scan["status"]
        
        if let confidence = scan["confidence"], let confidenceValue = Double(confidence) {
            cell.confidenceLabel.text = "\(Int(confidenceValue * 100))%"
        } else {
            cell.confidenceLabel.text = "N/A"
        }
        
        // Set status color
        if let status = scan["status"], status.contains("Bad") {
            cell.statusLabel.textColor = .systemRed
        } else {
            cell.statusLabel.textColor = .systemGreen
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80 // Adjust height as needed
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedScan = scans[indexPath.row]
        performSegue(withIdentifier: "ScanListImageViewController", sender: selectedScan)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ScanListImageViewController",
           let detailVC = segue.destination as? ScanListImageViewController,
           let selectedScan = sender as? [String: String] {
            detailVC.partType = selectedScan["partType"]
            detailVC.date = selectedScan["date"]
            detailVC.imageURL = selectedScan["url"]
            detailVC.folderKey = selectedScan["folderKey"]
            detailVC.videoURL = selectedScan["videoURL"]
            detailVC.status = selectedScan["status"]
            detailVC.classification = selectedScan["classification"]
            detailVC.confidence = selectedScan["confidence"]
            detailVC.fileName = selectedScan["fileName"]
            
            detailVC.delegate = self
        }
    }
    
    // MARK: - ScanListImageViewControllerDelegate
    
    func didDeleteScan() {
        reloadScanList()
    }
    
    // MARK: - Actions
    
    @objc func refreshList() {
        fetchScansFromFirebase()
        print("List page was refreshed.")
    }
    
    func reloadScanList() {
        scans.removeAll()
        tableView.reloadData()
        fetchScansFromFirebase()
    }
    
    @IBAction func refreshButtonTapped(_ sender: Any) {
        refreshList()
    }
}

// MARK: - Custom UITableViewCell

class ScanTableViewCell: UITableViewCell {
    
    let partTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    let confidenceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        contentView.addSubview(partTypeLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(confidenceLabel)
        
        partTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        confidenceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            partTypeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            partTypeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            partTypeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            dateLabel.topAnchor.constraint(equalTo: partTypeLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            statusLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            confidenceLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            confidenceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
    }
}
