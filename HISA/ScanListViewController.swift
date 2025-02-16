//
//  ScanListViewController.swift
//  HISA
//
//  Created by Hoyeon Kang on 1/22/25.
//

import UIKit
import Firebase
import FirebaseAuth
import AVKit

class ScanListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var mediaItems: [[String: String]] = []
    var username: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        // Do any additional setup after loading the view.
        fetchMediaFromFirebase()
    }
    
    func fetchMediaFromFirebase() {
        // Reference to the Firebase Database
        guard let user = Auth.auth().currentUser else {
            print("No user is signed in")
            return
        }

        let uid = user.uid
        let databaseRef = Database.database().reference().child("users").child("employees").child(uid)

        // Observe and fetch data
        databaseRef.observeSingleEvent(of: .value) { snapshot in
            guard let employeeData = snapshot.value as? [String: Any],
                  let username = employeeData["name"] as? String else {
                print("No data found or incorrect structure")
                return
            }

            // Fetch images
            if let imagesData = employeeData["images"] as? [String: [String: Any]] {
                for (folderKey, imageDetails) in imagesData {
                    let date = imageDetails["date"] as? String ?? ""
                    let url = imageDetails["url"] as? String ?? ""

                    // Add details to the mediaItems array
                    self.mediaItems.append([
                        "type": "image",
                        "folderKey": folderKey,
                        "username": username,
                        "date": date,
                        "url": url
                    ])
                }
            }

            // Fetch videos
            if let videosData = employeeData["videos"] as? [String: [String: Any]] {
                for (folderKey, videoDetails) in videosData {
                    let date = videoDetails["date"] as? String ?? ""
                    let url = videoDetails["url"] as? String ?? ""

                    // Add details to the mediaItems array
                    self.mediaItems.append([
                        "type": "video",
                        "folderKey": folderKey,
                        "username": username,
                        "date": date,
                        "url": url
                    ])
                }
            }

            // Reload table view after data fetch
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let item = mediaItems[indexPath.row]
        cell.textLabel?.text = item["username"]
        cell.detailTextLabel?.text = "Date: \(item["date"] ?? "") | Type: \(item["type"] ?? "")"
        cell.backgroundColor = indexPath.row % 2 == 0 ? .lightGray : .darkGray
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = mediaItems[indexPath.row]
        if let mediaURLString = selectedItem["url"], let mediaURL = URL(string: mediaURLString) {
            // Check if the media is a video
            if selectedItem["type"] == "video" {
                let player = AVPlayer(url: mediaURL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                // Present the video player
                present(playerViewController, animated: true) {
                    player.play()
                }
            } else if selectedItem["type"] == "image" {
                // Navigate to the image detail view
                performSegue(withIdentifier: "ScanListImageViewController", sender: selectedItem)
            }
        } else {
            print("Invalid media URL")
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ScanListImageViewController",
           let detailVC = segue.destination as? ScanListImageViewController,
           let selectedItem = sender as? [String: String] {
            // Pass media details to the detail view controller
            detailVC.username = selectedItem["username"]
            detailVC.date = selectedItem["date"]
            detailVC.imageURL = selectedItem["url"]
            detailVC.folderKey = selectedItem["folderKey"]
        }
    }

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag else { return }
        let selectedItem = mediaItems[index]
        if let mediaURLString = selectedItem["url"], let mediaURL = URL(string: mediaURLString) {
            // Check if the media is a video
            if selectedItem["type"] == "video" {
                let player = AVPlayer(url: mediaURL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                // Present the video player
                present(playerViewController, animated: true) {
                    player.play()
                }
            } else if selectedItem["type"] == "image" {
                // Navigate to the image detail view
                performSegue(withIdentifier: "ScanListImageViewController", sender: selectedItem)
            }
        }
    }

}
