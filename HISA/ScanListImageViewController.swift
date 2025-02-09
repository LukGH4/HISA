//
//  ScanListImageViewController.swift
//  HISA
//
//  Created by Hoyeon Kang on 1/22/25.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class ScanListImageViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    var imageURL: String?
    var username: String?
    var date: String?
    var folderKey: String?
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Set the username and date
        usernameLabel.text = username
        dateLabel.text = date

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
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        
        self.present(alert, animated: true, completion: nil)
    }
}

