import UIKit
import AVKit
import AVFoundation
import Firebase
import FirebaseStorage
import FirebaseAuth

class ScanViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    
    // Camera components
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var capturePhotoOutput: AVCapturePhotoOutput!
    var videoOutput: AVCaptureMovieFileOutput!
    
    // UI Components
    @IBOutlet weak var cameraPreviewView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var discardButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var capturedImageView: UIImageView!
    @IBOutlet weak var scanListButton: UIButton!
    @IBOutlet weak var gridToggleButton: UIButton!
    
    @IBOutlet weak var recordToggleButton: UIButton!
    @IBOutlet weak var captureToggleButton: UIButton!
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var submitButtonR: UIButton!
    @IBOutlet weak var recordedVideoView: UIView!
    
    
    // Popup components
    var popupView: UIView!
    var activityIndicator: UIActivityIndicatorView!
    var popupLabel: UILabel!
    
    var gridLines: [UIView] = []
    var toggleGridState: Bool = false
    
    var isRecording = false
    var videoURL: URL?
    var isVideoMode: Bool = false
    
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        
        setupGridOverlay()
        setupGridToggleButton()
        
        setupPopupView()
        recordedVideoView.isHidden = true
        discardButton.isHidden = true
        captureButton.isEnabled = true
        captureButton.isHidden = false
        submitButton.isHidden = true
        submitButtonR.isHidden = true
        submitButtonR.isEnabled = false
        recordToggleButton.isHidden = false
        recordToggleButton.isEnabled = true
        captureToggleButton.isHidden = true
        captureToggleButton.isEnabled = false
        recordButton.isHidden = true
        recordButton.isEnabled = false
    
        
        // Ensure grid toggle is hidden initially and grid is off
        gridToggleButton.isHidden = false
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("No camera found")
            return
        }
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
            } else {
                print("Unable to add input to capture session")
                return
            }
        } catch {
            print("Error setting up camera input: \(error)")
            return
        }
        
        capturePhotoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(capturePhotoOutput) {
            captureSession.addOutput(capturePhotoOutput)
        } else {
            print("Unable to add output to capture session")
            return
        }
        
        videoOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            print("Unable to add video output")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewLayer.frame = self.cameraPreviewView.bounds
                self.cameraPreviewView.layer.addSublayer(self.previewLayer)
            }
        }
    }
    
    func setupPopupView() {
        // Create the popup view
        popupView = UIView(frame: CGRect(x: 50, y: self.view.frame.height / 2 - 100, width: self.view.frame.width - 100, height: 200))
        popupView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        popupView.layer.cornerRadius = 12
        popupView.isHidden = true
        self.view.addSubview(popupView)
        
        // Add activity indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        popupView.addSubview(activityIndicator)
        
        // Add popup label
        popupLabel = UILabel()
        popupLabel.translatesAutoresizingMaskIntoConstraints = false
        popupLabel.textColor = .white
        popupLabel.textAlignment = .center
        popupLabel.font = UIFont.systemFont(ofSize: 16)
        popupLabel.text = ""
        popupView.addSubview(popupLabel)
        
        // Set up constraints for centering the activity indicator and label
        NSLayoutConstraint.activate([
            // Center activity indicator horizontally and vertically within popupView
            activityIndicator.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: popupView.centerYAnchor, constant: -30), // Adjust to position above label
            
            // Center popup label horizontally within popupView
            popupLabel.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            popupLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 10) // Spacing below activity indicator
        ])
    }
    
    
    @IBAction func capturePhoto(_ sender: UIButton) {
        
        // Hide and remove grid before capturing photo
        gridLines.forEach { x in x.isHidden = true }
        gridToggleButton.isHidden = true
        
        let settings = AVCapturePhotoSettings()
        capturePhotoOutput.capturePhoto(with: settings, delegate: self)
        captureButton.isEnabled = false
        captureButton.isHidden = true
    }
    
    @IBAction func recordVideo(_ sender: UIButton) {
        gridLines.forEach { x in x.isHidden = true }
        gridToggleButton.isHidden = true
        
        if !isRecording {
            startRecording()
            recordButton.setImage(UIImage(systemName: "stop.circle"), for: .normal)
            recordToggleButton.isHidden = true
            recordToggleButton.isEnabled = false
            captureToggleButton.isHidden = true
            captureToggleButton.isEnabled = false
        } else {
            stopRecording()
            recordButton.setImage(UIImage(systemName: "record.circle"), for: .normal)
            recordToggleButton.isHidden = true
            recordToggleButton.isEnabled = false
            captureToggleButton.isHidden = false
            captureToggleButton.isEnabled = true
            recordButton.isHidden = true
            discardButton.isHidden = false
            discardButton.isEnabled = true
        }
        isRecording.toggle()
        
    }
    
    func startRecording() {
        let outputFilePath = NSTemporaryDirectory() + "video-\(UUID().uuidString).mov"
        let outputFileURL = URL(fileURLWithPath: outputFilePath)
        videoOutput.startRecording(to: outputFileURL, recordingDelegate: self)
        
    }
    
    func stopRecording() {
        videoOutput.stopRecording()
    }
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else {
            print("Error capturing photo: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        let capturedImage = UIImage(data: imageData)
        cameraPreviewView.isHidden = true
        capturedImageView.image = capturedImage
        capturedImageView.isHidden = false
        discardButton.isHidden = false
        submitButton.isHidden = false
        submitButton.isEnabled = true
        submitButtonR.isHidden = true
        submitButtonR.isEnabled = false
        scanListButton.isHidden = false
        recordToggleButton.isHidden = true
        captureToggleButton.isHidden = true
        
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
            return
        }
        
        videoURL = outputFileURL
        print("Video saved to: \(videoURL!.absoluteString)")
        
        submitButton.isHidden = true
        submitButton.isEnabled = false
        submitButtonR.isHidden = false
        submitButtonR.isEnabled = true
        recordToggleButton.isHidden = true
        captureToggleButton.isHidden = false
        
        cameraPreviewView.isHidden = true
        recordedVideoView.isHidden = false
        playVideoInSeparateView(url: videoURL!)
        
    }
    
    func playVideoInSeparateView(url: URL) {
        DispatchQueue.main.async {
            // Remove existing player if any
            self.playerLayer?.removeFromSuperlayer()
            
            // Create a new AVPlayer
            self.player = AVPlayer(url: url)
            self.playerLayer = AVPlayerLayer(player: self.player)
            self.playerLayer?.frame = self.recordedVideoView.bounds
            self.playerLayer?.videoGravity = .resizeAspectFill
            
            // Add AVPlayerLayer to the separate video preview view
            self.recordedVideoView.layer.addSublayer(self.playerLayer!)
            
            // Hide the captured image view and show the video preview
            self.capturedImageView.isHidden = true
            self.recordedVideoView.isHidden = false
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.restartVideo),
                name: .AVPlayerItemDidPlayToEndTime,
                object: self.player?.currentItem
            )

            // Start playback
            self.player?.play()
        }
    }
    
    @objc func restartVideo() {
        // Restart the video from the beginning
        self.player?.seek(to: .zero)
        self.player?.play()
    }
    
    @IBAction func discardPhoto(_ sender: UIButton) {
        capturedImageView.image = nil
        capturedImageView.isHidden = true
        previewLayer.isHidden = false
        captureSession.startRunning()
        
        cameraPreviewView.isHidden = false
        discardButton.isHidden = true
        submitButton.isHidden = true
        submitButtonR.isHidden = true
        popupView.isHidden = true
        
        if isVideoMode {
            recordedVideoView.isHidden = true
            recordButton.isEnabled = true
            recordButton.isHidden = false
            captureToggleButton.isHidden = false
        } else {
            captureButton.isEnabled = true
            captureButton.isHidden = false
            recordToggleButton.isHidden = false
        }

        // Reset grid toggle and hide grid
        gridToggleButton.isHidden = false
        gridLines.forEach { x in x.isHidden = !toggleGridState }
    }
    
    func showValidationPopup() {
        popupView.isHidden = false
        activityIndicator.startAnimating()
        popupLabel.text = "Validating..."
        
        // Simulate validation with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.popupLabel.text = "Validated: Good Part"
            
            // Dismiss the popup after a delay
            //            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            //                self.popupView.isHidden = true
            //            }
        }
    }
    
    @IBAction func submitPhoto(_ sender: Any) {
        // codes for submitting a photo to ML and database
        guard let capturedImage = capturedImageView.image else {
            print("No image to submit")
            return
        }
        // Show the popup
        showValidationPopup()
        
        guard let imageData = capturedImage.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to data")
            return
        }
        
        // Firebase Storage reference
        let uniqueFileName = "image-\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference().child("images/\(uniqueFileName)")
        
        // Upload image data to Firebase Storage
        let uploadTask = storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            // Get the download URL for the uploaded image
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error retrieving download URL: \(error.localizedDescription)")
                    return
                }
                
                guard let downloadURL = url else {
                    print("No download URL found")
                    return
                }
                
                // Format the current date and time
                let currentDate = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Customize as needed
                let formattedDate = dateFormatter.string(from: currentDate)
                
                // Save username and image URL to Firebase Realtime Database
                guard let user = Auth.auth().currentUser else {
                    print("No user is singed in")
                    return
                }
                let uid = user.uid
                
                
                let databaseRef = Database.database().reference()
                let newDirectory = databaseRef.child("users/employees/\(uid)/images").childByAutoId() // Generate a unique ID for each user // This line has been modified by Hoyeon Kang
                
                let newData: [String: Any] = [
                    "url": downloadURL.absoluteString,
                    "fileName": uniqueFileName,
                    "date": formattedDate
                ]
                
                newDirectory.setValue(newData) { error, _ in
                    if let error = error {
                        print("Error writing data to Firebase: \(error.localizedDescription)")
                    } else {
                        print("Username and image URL successfully saved to Firebase.")
                    }
                }
            }
        }
        
        // Monitor upload progress (optional)
        uploadTask.observe(.progress) { snapshot in
            let progress = Double(snapshot.progress?.completedUnitCount ?? 0) /
                           Double(snapshot.progress?.totalUnitCount ?? 1)
            print("Upload progress: \(progress * 100)%")
        }
        
        let alert = UIAlertController(title: "", message: "The photo has been successfully submitted", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func submitVideo(_ sender: Any) {
        guard let videoURL = self.videoURL else {
            print("No video to upload")
            return
        }
        
        let uniqueFileName = "video-\(UUID().uuidString).mov"
        let storageRef = Storage.storage().reference().child("videos/\(uniqueFileName)")
        
        let uploadTask = storageRef.putFile(from: videoURL, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading video: \(error.localizedDescription)")
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error retrieving video URL: \(error.localizedDescription)")
                    return
                }
                
                guard let downloadURL = url else {
                    print("No download URL found")
                    return
                }
                
                guard let user = Auth.auth().currentUser else {
                    print("No user signed in")
                    return
                }
                
                let uid = user.uid
                let databaseRef = Database.database().reference()
                let newVideoRef = databaseRef.child("users/employees/\(uid)/videos").childByAutoId()
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let formattedDate = dateFormatter.string(from: Date())

                let videoData: [String: Any] = [
                    "url": downloadURL.absoluteString,
                    "fileName": uniqueFileName,
                    "date": formattedDate
                ]
                
                newVideoRef.setValue(videoData) { error, _ in
                    if let error = error {
                        print("Error saving video to database: \(error.localizedDescription)")
                    } else {
                        print("Video successfully uploaded and saved.")
                    }
                }
            }
        }
        
        uploadTask.observe(.progress) { snapshot in
            let progress = Double(snapshot.progress?.completedUnitCount ?? 0) /
                           Double(snapshot.progress?.totalUnitCount ?? 1)
            print("Upload progress: \(progress * 100)%")
        }
        
        let alert = UIAlertController(title: "Success", message: "The video has been successfully submitted", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
        
    }
    
    
    
    
    func setupGridToggleButton() {
        gridToggleButton.addTarget(self, action: #selector(toggleGrid), for: .touchUpInside)
        gridToggleButton.isEnabled = true
    }
    
    func setupGridOverlay() {
        // Clear any existing grid lines
        gridLines.forEach { $0.removeFromSuperview() }
        gridLines.removeAll()

        let previewHeight = cameraPreviewView.bounds.height*1.2
        let previewWidth = cameraPreviewView.bounds.width
        let numLines = 3 // Number of grid divisions (e.g., 3x3 grid)

        // Horizontal lines
        for i in 1..<numLines {
            let yPosition = CGFloat(i) * (previewHeight / CGFloat(numLines))
            let line = UIView(frame: CGRect(x: 0, y: yPosition, width: previewWidth, height: 1))
            line.backgroundColor = UIColor.white.withAlphaComponent(0.7)
            gridLines.append(line)
            self.view.addSubview(line)
        }

        // Vertical lines
        for i in 1..<numLines {
            let xPosition = CGFloat(i) * (previewWidth / CGFloat(numLines))
            let line = UIView(frame: CGRect(x: xPosition, y: 0, width: 1, height: previewHeight))
            line.backgroundColor = UIColor.white.withAlphaComponent(0.7)
            gridLines.append(line)
            self.view.addSubview(line)
        }

        // Ensure grid lines are above the camera preview
        gridLines.forEach { x in
            self.view.bringSubviewToFront(x)
            x.isHidden = true
        }
    }
    
    @IBAction func toggleGrid(_ sender: UIButton) {
        if (toggleGridState) {
            toggleGridState = false
        } else {
            toggleGridState = true
        }

        // Update visibility
        gridLines.forEach { x in x.isHidden = !toggleGridState }
        
        let newImage: UIImage? = !toggleGridState ? UIImage(systemName: "grid.circle") : UIImage(systemName: "grid.circle.fill")
        sender.setImage(newImage, for: .normal)

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupGridOverlay()
    }
    
    
    @IBAction func RecordToggleClicked(_ sender: Any) {
        isVideoMode = true
        
        recordToggleButton.isHidden = true
        recordToggleButton.isEnabled = false
        captureToggleButton.isHidden = false
        captureToggleButton.isEnabled = true
        
        recordButton.isHidden = false
        recordButton.isEnabled = true
        discardButton.isHidden = true
        captureButton.isEnabled = false
        captureButton.isHidden = true
        
        
    }
    
    @IBAction func captureToggleClicked(_ sender: Any) {
        isVideoMode = false
        
        recordedVideoView.isHidden = true
        cameraPreviewView.isHidden = false
        
        recordToggleButton.isHidden = false
        recordToggleButton.isEnabled = true
        captureToggleButton.isHidden = true
        captureToggleButton.isEnabled = false
        
        recordButton.isHidden = true
        recordButton.isEnabled = false
        discardButton.isHidden = true
        captureButton.isEnabled = true
        captureButton.isHidden = false
        
    }
    
    
    
}
