//
//  ScanListViewController.swift
//  HISA
//
//  Created by Hoyeon Kang on 1/22/25.
//

import UIKit
import Firebase

class ScanListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    
    var images: [[String: String]] = []
    var username: String = ""
        
        
        
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
        fetchImagesFromFirebase()
    }
    
    func fetchImagesFromFirebase() {
        // Reference to the Firebase Database
        let databaseRef = Database.database().reference().child("users").child("employees").child("employee1")

        // Observe and fetch data
        databaseRef.observeSingleEvent(of: .value) { snapshot in
            guard let employeeData = snapshot.value as? [String: Any],
                  let username = employeeData["username"] as? String,
                  let imagesData = employeeData["images"] as? [String: [String: Any]] else {
                print("No data found or incorrect structure")
                return
            }

            // Iterate through each folder and fetch details
            for (folderKey, imageDetails) in imagesData {
                let date = imageDetails["date"] as? String ?? ""
                let url = imageDetails["url"] as? String ?? ""

                // Add details to the images array
                self.images.append([
                    "folderKey": folderKey,
                    "username": username, // Include the username
                    "date": date,
                    "url": url
                ])
            }

            // Reload table view after data fetch
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return images.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let image = images[indexPath.row]
        cell.textLabel?.text = image["username"]
        cell.detailTextLabel?.text = image["date"]
        cell.backgroundColor = indexPath.row % 2 == 0 ? .gray : .darkGray
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedImage = images[indexPath.row]
        performSegue(withIdentifier: "ScanListImageViewController", sender: selectedImage)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ScanListImageViewController",
           let detailVC = segue.destination as? ScanListImageViewController,
           let selectedImage = sender as? [String: String] {
            detailVC.username = selectedImage["username"]
            detailVC.date = selectedImage["date"]
            detailVC.imageURL = selectedImage["url"]
            detailVC.folderKey = selectedImage["folderKey"]
        }
    }
    

    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag else { return }
        print("Tapped on row at index: \(index)")
        performSegue(withIdentifier: "ScanListImageViewController", sender: index)
        
    
    }

    
    
}
