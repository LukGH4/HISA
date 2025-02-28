//
//  ScanListImageViewController.swift
//  HISA
//
//  Created by Hoyeon Kang on 1/22/25.
//

import UIKit
import AVKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class ScanListImageViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var playbutton: UIButton!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var classificationLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    var isFromEmployeeDetail: Bool = false
    
    
    var imageURL: String?
    var username: String?
    var date: String?
    var folderKey: String?
    
    var videoURL: String?
    var status: String?
    var classification: String?
    var confidence: String?
    var fileName: String?
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    let videoExtensions = ["mp4", "mov", "avi", "mkv"]

    
    override func viewDidLoad() {
        super.viewDidLoad()
        if isFromEmployeeDetail {
                deleteButton.isEnabled = false
                deleteButton.alpha = 0.5
            }
        usernameLabel.text = username
        dateLabel.text = date
        statusLabel.text = status
        classificationLabel.text = classification
        confidenceLabel.text = confidence
        if let fileName = fileName, !videoExtensions.contains(where: { fileName.hasSuffix(".\($0)") }) {
            imageView.isHidden = false
            videoView.isHidden = true
            playbutton.isHidden = true
            // Load and display the image asynchronously
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url) {
                        DispatchQueue.main.async {
                            self.imageView.image = UIImage(data: data)
                        }
                    }
                }
            }
        } else { //video
            imageView.isHidden = true
            videoView.isHidden = false
            playbutton.isHidden = false
            
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
    
    @IBAction func deletePhoto(_ sender: Any) {
        guard let folderKey = folderKey else {
            print("Folder key is missing!")
            return
        }

        // Step 1: Reference Firebase Realtime Database and Storage
        var databaseRef: DatabaseReference?
        guard let user = Auth.auth().currentUser else {
            print("No user is signed in")
            return
        }
        
        if let fileName = fileName, !videoExtensions.contains(where: { fileName.hasSuffix(".\($0)") }) {
            let uid = user.uid
            databaseRef = Database.database().reference().child("users/employees/\(uid)/images/\(folderKey)") //this line is modified for testing the uid by Hoyeon Kang
            
            let storageRef = Storage.storage().reference(forURL: imageURL ?? "")

            // Step 2: Delete the file from Firebase Storage
            storageRef.delete { error in
                if let error = error {
                    print("Error deleting file from Firebase Storage: \(error.localizedDescription)")
                } else {
                    print("File deleted successfully from Firebase Storage.")

                    // Step 3: Delete the folder from Firebase Realtime Database
                    databaseRef!.removeValue { error, _ in
                        if let error = error {
                            print("Error deleting folder from Firebase Database: \(error.localizedDescription)")
                        } else {
                            print("Folder deleted successfully from Firebase Database.")

                            // Navigate back to the previous screen
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            }
            
            let alert = UIAlertController(title: "", message: "The photo has been successfully deleted", preferredStyle: .alert)
            self.logActivity(action: "Deleted a scan")
            
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            
            self.present(alert, animated: true, completion: nil)
            
        } else { //video
            let uid = user.uid
            databaseRef = Database.database().reference().child("users/employees/\(uid)/videos/\(folderKey)") //this line is modified for testing the uid by Hoyeon Kang
            
            let storageRef = Storage.storage().reference(forURL: imageURL ?? "")

            // Step 2: Delete the file from Firebase Storage
            storageRef.delete { error in
                if let error = error {
                    print("Error deleting file from Firebase Storage: \(error.localizedDescription)")
                } else {
                    print("File deleted successfully from Firebase Storage.")

                    // Step 3: Delete the folder from Firebase Realtime Database
                    databaseRef!.removeValue { error, _ in
                        if let error = error {
                            print("Error deleting folder from Firebase Database: \(error.localizedDescription)")
                        } else {
                            print("Folder deleted successfully from Firebase Database.")

                            // Navigate back to the previous screen
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            }
            
            let alert = UIAlertController(title: "", message: "The photo has been successfully deleted", preferredStyle: .alert)
            self.logActivity(action: "Deleted a scan")
            
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            
            self.present(alert, animated: true, completion: nil)
            
        }
        

    }
    
    @IBAction func playVideo(_ sender: UIButton) {
        if player?.rate == 0 {
            player?.play()
            playbutton.setImage(UIImage(systemName: "pause.circle"), for: .normal)
        } else {
            player?.pause()
            playbutton.setImage(UIImage(systemName: "play.circle"), for: .normal)
        }
    }
    
    @objc func videoDidFinishPlaying() {
        player?.seek(to: CMTime.zero) // Restart the video
        player?.play()
    }
}

