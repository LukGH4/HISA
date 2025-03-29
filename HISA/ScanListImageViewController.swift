import UIKit
import AVKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class ScanListImageViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var partTypeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var classificationLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    @IBOutlet weak var topBannerView: UIView!
    @IBOutlet weak var bottomBannerView: UIView!
    
    @IBOutlet weak var descriptionView: UIView!
    
    var isFromEmployeeDetail: Bool = false
    
    var imageURL: String?
    var partType: String?
    var date: String?
    var folderKey: String?
    
    var videoURL: String?
    var status: String?
    var classification: String?
    var confidence: String?
    var fileName: String?
    
    weak var delegate: ScanListImageViewControllerDelegate?
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    let videoExtensions = ["mp4", "mov", "avi", "mkv"]
    
    let circularProgress = CircularProgressView(frame: CGRect(x: 45, y: 630, width: 60, height: 60))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupGestures()
        loadMedia()
    }
    
    func setupUI() {
        // Set part type label
        partTypeLabel.text = partType
        partTypeLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        partTypeLabel.textColor = .white
        
        // Set date label
        dateLabel.text = date
        dateLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        dateLabel.textColor = .darkGray
        
        // Set status label
        if let status = status, status.contains("Bad") {
            topBannerView.backgroundColor = UIColor.systemRed
            bottomBannerView.backgroundColor = UIColor.systemRed
        } else {
            topBannerView.backgroundColor = UIColor.systemGreen
            bottomBannerView.backgroundColor = UIColor.systemGreen
        }
        statusLabel.text = status
        statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        statusLabel.textColor = .white
        
        // Set classification label
        classificationLabel.text = classification
        classificationLabel.font = UIFont.systemFont(ofSize: 25, weight: .medium)
        classificationLabel.textColor = .white
        
        // Set confidence label
        if let confidenceString = confidence,
           let confidenceValue = Double(confidenceString) {
            let percentage = Int(confidenceValue * 100)
            confidenceLabel.text = "\(percentage)%"
        }
        confidenceLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        confidenceLabel.textColor = .white
        
        // Add circular progress view
        view.addSubview(circularProgress)
        if let confidenceString = confidence,
           let confidenceValue = Double(confidenceString) {
            let progress = CGFloat(confidenceValue)
            circularProgress.setProgress(to: progress)
        }
    }
    
    func setupGestures() {
        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleDescriptionView))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(imageTapGesture)
        
        let videoTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleDescriptionView))
        videoView.isUserInteractionEnabled = true
        videoView.addGestureRecognizer(videoTapGesture)
    }
    
    func loadMedia() {
        if let fileName = fileName, !videoExtensions.contains(where: { fileName.hasSuffix(".\($0)") }) {
            // Load image
            imageView.isHidden = false
            videoView.isHidden = true
            playButton.isHidden = true
            
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url) {
                        DispatchQueue.main.async {
                            self.imageView.image = UIImage(data: data)
                        }
                    }
                }
            }
        } else {
            // Load video
            imageView.isHidden = true
            videoView.isHidden = false
            playButton.isHidden = false
            
            if let videoURLString = imageURL, let url = URL(string: videoURLString) {
                player = AVPlayer(url: url)
                playerLayer = AVPlayerLayer(player: player)
                playerLayer?.frame = videoView.bounds
                playerLayer?.videoGravity = .resizeAspectFill
                videoView.layer.addSublayer(playerLayer!)
                
                NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
            }
        }
    }
    
    @IBAction func deletePhoto(_ sender: Any) {
        guard let folderKey = folderKey else {
            print("Folder key is missing!")
            return
        }

        var databaseRef: DatabaseReference?
        guard let user = Auth.auth().currentUser else {
            print("No user is signed in")
            return
        }
        
        // Determine whether we are deleting an image or a video
        if let fileName = fileName, !videoExtensions.contains(where: { fileName.hasSuffix(".\($0)") }) {
            // Handle image deletion
            let uid = user.uid
            databaseRef = Database.database().reference().child("users/employees/\(uid)/images/\(folderKey)")
            
            let storageRef = Storage.storage().reference(forURL: imageURL ?? "")

            storageRef.delete { error in
                if let error = error {
                    print("Error deleting file from Firebase Storage: \(error.localizedDescription)")
                } else {
                    print("File deleted successfully from Firebase Storage.")

                    // Remove from database
                    databaseRef!.removeValue { error, _ in
                        if let error = error {
                            print("Error deleting folder from Firebase Database: \(error.localizedDescription)")
                        } else {
                            print("Folder deleted successfully from Firebase Database.")

                            // Update part count if applicable
                            if let partType = self.partType, let status = self.status {
                                self.updatePartCounts(partType: partType, status: status)
                            }

                            self.logActivity(action: "deleted a scan")
                            self.delegate?.didDeleteScan()

                            let alert = UIAlertController(title: "", message: "The photo has been successfully deleted", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                                if self.isFromEmployeeDetail {
                                    self.navigationController?.popViewController(animated: true)
                                } else {
                                    self.dismiss(animated: true, completion: nil)
                                }
                            }
                            alert.addAction(okAction)
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
        } else {
            let uid = user.uid
            databaseRef = Database.database().reference().child("users/employees/\(uid)/videos/\(folderKey)")
            
            let storageRef = Storage.storage().reference(forURL: imageURL ?? "")

            storageRef.delete { error in
                if let error = error {
                    print("Error deleting file from Firebase Storage: \(error.localizedDescription)")
                } else {
                    print("File deleted successfully from Firebase Storage.")

                    databaseRef!.removeValue { error, _ in
                        if let error = error {
                            print("Error deleting folder from Firebase Database: \(error.localizedDescription)")
                        } else {
                            print("Folder deleted successfully from Firebase Database.")

                            if let partType = self.partType, let status = self.status {
                                self.updatePartCounts(partType: partType, status: status)
                            }

                            self.logActivity(action: "deleted a scan")
                            self.delegate?.didDeleteScan()

                            let alert = UIAlertController(title: "", message: "The video has been successfully deleted", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                                if self.isFromEmployeeDetail {
                                    self.navigationController?.popViewController(animated: true)
                                } else {
                                    self.dismiss(animated: true, completion: nil)
                                }
                            }
                            alert.addAction(okAction)
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    func updatePartCounts(partType: String, status: String) {
        let partRef = Database.database().reference().child("parts/\(partType)")
        
        partRef.observeSingleEvent(of: .value) { snapshot in
            guard var partData = snapshot.value as? [String: Any] else {
                print("Error fetching part data.")
                return
            }

            var goodCount = partData["good"] as? Int ?? 0
            var badCount = partData["bad"] as? Int ?? 0

            if status == "Good Part" {
                goodCount -= 1
            } else if status == "Bad Part" {
                badCount -= 1
            }

            partData["good"] = goodCount
            partData["bad"] = badCount
            partRef.updateChildValues(partData) { error, _ in
                if let error = error {
                    print("Error updating part counts: \(error.localizedDescription)")
                } else {
                    print("Part counts updated successfully.")
                }
            }
        }
    }
    
    @IBAction func playVideo(_ sender: UIButton) {
        if player?.rate == 0 {
            player?.play()
            playButton.setImage(UIImage(systemName: "pause.circle"), for: .normal)
        } else {
            player?.pause()
            playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
        }
    }
    
    @objc func videoDidFinishPlaying() {
        player?.seek(to: CMTime.zero)
        player?.play()
    }
    
    @objc func toggleDescriptionView() {
        descriptionView.isHidden.toggle()
        circularProgress.isHidden.toggle()
    }
    
    func logActivity(action: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("activity_log").childByAutoId()
        let logEntry: [String: Any] = [
            "userId": userId,
            "action": action,
            "timestamp": ServerValue.timestamp()
        ]
        ref.setValue(logEntry)
    }
}

protocol ScanListImageViewControllerDelegate: AnyObject {
    func didDeleteScan()
}

