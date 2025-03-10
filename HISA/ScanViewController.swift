//
//  ScanViewController.swift
//  HISA
//
//  Created by Barnabas Li on 2/17/25.
//


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
    
    var partTypePicker: UIPickerView!
    var partTypePopupView: UIView!
    var partTypes: [String] = []
    
    var partTypeDisplayButton: UIButton!
    
    var selectedPartType: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Submit button:", submitButton as Any)
        setupCamera()
        
        setupGridOverlay()
        setupGridToggleButton()
        setupPartTypeDisplayButton()
        setupPartTypePopup()
        
        partTypes = ["Wing", "Engine", "Window", "Wheel"]
        
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
        
        // Show the part type popup
        showPartTypePopup()
        partTypeDisplayButton.isHidden = false // Show the display button
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
            
            // Show the part type popup
            showPartTypePopup()
            partTypeDisplayButton.isHidden = false // Show the display button
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
            //self.playerLayer?.videoGravity = .resizeAspectFill
            
            // Add AVPlayerLayer to the separate video preview view
            self.recordedVideoView.layer.addSublayer(self.playerLayer!)
            self.recordedVideoView.backgroundColor = .clear
            
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
        partTypeDisplayButton.isHidden = true // Hide the display button
        selectedPartType = ""
        
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
        print("Submit button pressed")
        guard let capturedImage = capturedImageView.image else {
            print("No image to submit")
            return
        }
        guard !selectedPartType.isEmpty else {
            print("No part type selected")
            showPopup(message: "Please select a part type before submitting.")
            return
        }
        self.logActivity(action: "submitted a photo scan")
        guard let imageData = capturedImage.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to data")
            return
        }
        
        let userId = Auth.auth().currentUser?.uid ?? "unknown_user"
        
        let url = URL(string: "http://172.16.20.49:3333/upload")! // replace
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        // Append user ID
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)
        
        // Append part type
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"part_type\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(selectedPartType)\r\n".data(using: .utf8)!)
        
        // Append image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error uploading image: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("Upload response:", jsonResponse)
                
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Upload Successful",
                                                  message: "Classification: \(jsonResponse["classification"] ?? "Unknown")",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        task.resume()
    }

    func showPopup(message: String) {
        DispatchQueue.main.async {
            self.popupView.isHidden = false
            self.popupLabel.text = message
        }
    }
    
    @IBAction func submitVideo(_ sender: Any) {
        guard let videoURL = self.videoURL else {
            print("No video to upload")
            return
        }
        guard !selectedPartType.isEmpty else {
            print("No part type selected")
            showPopup(message: "Please select a part type before submitting.")
            return
        }
        self.logActivity(action: "submitted a video scan")
        
        let userId = Auth.auth().currentUser?.uid ?? "unknown_user"
        
        let url = URL(string: "http://172.16.20.49:3333/upload")! // replace
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        // Append user ID
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)
        
        // Append part type
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"part_type\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(selectedPartType)\r\n".data(using: .utf8)!)
        
        // Append video data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"video.mov\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/quicktime\r\n\r\n".data(using: .utf8)!)
        do {
            let videoData = try Data(contentsOf: videoURL)
            body.append(videoData)
        } catch {
            print("Error reading video data: \(error.localizedDescription)")
            return
        }
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error uploading video: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("Upload response:", jsonResponse)
                
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Upload Successful",
                                                  message: "Classification: \(jsonResponse["classification"] ?? "Unknown")",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        
        task.resume()
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
    

    func setupPartTypePopup() {
        // Create the popup view
        partTypePopupView = UIView()
        partTypePopupView.translatesAutoresizingMaskIntoConstraints = false
        partTypePopupView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        partTypePopupView.layer.cornerRadius = 16
        partTypePopupView.layer.masksToBounds = true
        partTypePopupView.isHidden = true
        self.view.addSubview(partTypePopupView)

        // Add a blur effect
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        partTypePopupView.addSubview(blurView)

        // Add a vibrancy effect
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(vibrancyView)

        // Add a title label
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Select Part Type"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        vibrancyView.contentView.addSubview(titleLabel)

        // Add a UIPickerView
        partTypePicker = UIPickerView()
        partTypePicker.translatesAutoresizingMaskIntoConstraints = false
        partTypePicker.delegate = self
        partTypePicker.dataSource = self
        vibrancyView.contentView.addSubview(partTypePicker)

        // Add a submit button
        let submitButton = UIButton(type: .system)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.setTitle("Confirm", for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 8
        submitButton.addTarget(self, action: #selector(submitPartType), for: .touchUpInside)
        vibrancyView.contentView.addSubview(submitButton)

        // Add a cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelPartTypeSelection), for: .touchUpInside)
        vibrancyView.contentView.addSubview(cancelButton)

        // Use a UIStackView to organize the buttons
        let buttonStackView = UIStackView(arrangedSubviews: [cancelButton, submitButton])
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 16
        vibrancyView.contentView.addSubview(buttonStackView)

        // Constraints for the popup view
        NSLayoutConstraint.activate([
            partTypePopupView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            partTypePopupView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            partTypePopupView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8),
            partTypePopupView.heightAnchor.constraint(equalToConstant: 300),

            // Blur and vibrancy effects
            blurView.topAnchor.constraint(equalTo: partTypePopupView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: partTypePopupView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: partTypePopupView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: partTypePopupView.bottomAnchor),

            vibrancyView.topAnchor.constraint(equalTo: blurView.topAnchor),
            vibrancyView.leadingAnchor.constraint(equalTo: blurView.leadingAnchor),
            vibrancyView.trailingAnchor.constraint(equalTo: blurView.trailingAnchor),
            vibrancyView.bottomAnchor.constraint(equalTo: blurView.bottomAnchor),

            // Title label
            titleLabel.topAnchor.constraint(equalTo: vibrancyView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: vibrancyView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: vibrancyView.trailingAnchor, constant: -20),

            // Picker view
            partTypePicker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            partTypePicker.leadingAnchor.constraint(equalTo: vibrancyView.leadingAnchor, constant: 20),
            partTypePicker.trailingAnchor.constraint(equalTo: vibrancyView.trailingAnchor, constant: -20),
            partTypePicker.heightAnchor.constraint(equalToConstant: 120),

            // Button stack view
            buttonStackView.topAnchor.constraint(equalTo: partTypePicker.bottomAnchor, constant: 20),
            buttonStackView.leadingAnchor.constraint(equalTo: vibrancyView.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: vibrancyView.trailingAnchor, constant: -20),
            buttonStackView.bottomAnchor.constraint(equalTo: vibrancyView.bottomAnchor, constant: -20),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc func showPartTypePopup() {
        partTypePopupView.isHidden = false
        partTypePopupView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        partTypePopupView.alpha = 0

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            self.partTypePopupView.transform = .identity
            self.partTypePopupView.alpha = 1
        }, completion: nil)
    }

    @objc func cancelPartTypeSelection() {
        UIView.animate(withDuration: 0.2, animations: {
            self.partTypePopupView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.partTypePopupView.alpha = 0
        }, completion: { _ in
            self.partTypePopupView.isHidden = true
        })
    }
    
    @objc func submitPartType() {
        selectedPartType = partTypes[partTypePicker.selectedRow(inComponent: 0)]
        print("Selected part type: \(selectedPartType)")

        // Update the part type display button
        partTypeDisplayButton.setTitle("Part Type: \(selectedPartType)", for: .normal)
        partTypeDisplayButton.isHidden = false
        

        // Hide the popup with animation
        UIView.animate(withDuration: 0.2, animations: {
            self.partTypePopupView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.partTypePopupView.alpha = 0
        }, completion: { _ in
            self.partTypePopupView.isHidden = true
        })

    }
    
    func setupPartTypeDisplayButton() {
            partTypeDisplayButton = UIButton(type: .system)
            partTypeDisplayButton.translatesAutoresizingMaskIntoConstraints = false
            partTypeDisplayButton.setTitle("Part Type: Not Selected", for: .normal)
            partTypeDisplayButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            partTypeDisplayButton.setTitleColor(.white, for: .normal)
            partTypeDisplayButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            partTypeDisplayButton.layer.cornerRadius = 8
            partTypeDisplayButton.addTarget(self, action: #selector(showPartTypePopup), for: .touchUpInside)
            partTypeDisplayButton.isHidden = true // Hide initially
            self.view.addSubview(partTypeDisplayButton)

            // Constraints for the button
            NSLayoutConstraint.activate([
                partTypeDisplayButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20),
                partTypeDisplayButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -30),
                partTypeDisplayButton.heightAnchor.constraint(equalToConstant: 40),
                partTypeDisplayButton.widthAnchor.constraint(equalToConstant: 200)
            ])
        }
    

}

extension ScanViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return partTypes.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return partTypes[row]
    }
}
