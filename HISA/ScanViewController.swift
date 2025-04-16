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
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var capturePhotoOutput: AVCapturePhotoOutput!
    var videoOutput: AVCaptureMovieFileOutput!
    
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
        popupView = UIView(frame: CGRect(x: 50, y: self.view.frame.height / 2 - 100, width: self.view.frame.width - 100, height: 200))
        popupView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        popupView.layer.cornerRadius = 12
        popupView.isHidden = true
        self.view.addSubview(popupView)
        
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        popupView.addSubview(activityIndicator)
        
        popupLabel = UILabel()
        popupLabel.translatesAutoresizingMaskIntoConstraints = false
        popupLabel.textColor = .white
        popupLabel.textAlignment = .center
        popupLabel.font = UIFont.systemFont(ofSize: 16)
        popupLabel.text = ""
        popupView.addSubview(popupLabel)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: popupView.centerYAnchor, constant: -30),
            popupLabel.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            popupLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 10)
        ])
    }
    
    @IBAction func capturePhoto(_ sender: UIButton) {
        gridLines.forEach { x in x.isHidden = true }
        gridToggleButton.isHidden = true
        let settings = AVCapturePhotoSettings()
        capturePhotoOutput.capturePhoto(with: settings, delegate: self)
        captureButton.isEnabled = false
        captureButton.isHidden = true
        
        showPartTypePopup()
        partTypeDisplayButton.isHidden = false
    }
    
    @IBAction func recordVideo(_ sender: UIButton) {
        gridLines.forEach { x in x.isHidden = true }
        gridToggleButton.isHidden = true
        
        if !isRecording {
            startRecording()
            let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .regular)
            let stopImage = UIImage(systemName: "stop.circle", withConfiguration: config)
            recordButton.setImage(stopImage, for: .normal)
            recordToggleButton.isHidden = true
            recordToggleButton.isEnabled = false
            captureToggleButton.isHidden = true
            captureToggleButton.isEnabled = false
        } else {
            stopRecording()
            recordButton.setImage(UIImage(named: "Record Button"), for: .normal)
            recordToggleButton.isHidden = true
            recordToggleButton.isEnabled = false
            captureToggleButton.isHidden = false
            captureToggleButton.isEnabled = true
            recordButton.isHidden = true
            discardButton.isHidden = false
            discardButton.isEnabled = true
            
            showPartTypePopup()
            partTypeDisplayButton.isHidden = false
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
        discardButton.isHidden = false
        discardButton.isEnabled = true
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
        discardButton.isEnabled = true
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
            self.playerLayer?.removeFromSuperlayer()
            
            self.player = AVPlayer(url: url)
            self.playerLayer = AVPlayerLayer(player: self.player)
            self.playerLayer?.frame = self.recordedVideoView.bounds

            self.recordedVideoView.layer.addSublayer(self.playerLayer!)
            self.recordedVideoView.backgroundColor = .clear
            
            self.capturedImageView.isHidden = true
            self.recordedVideoView.isHidden = false
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.restartVideo),
                name: .AVPlayerItemDidPlayToEndTime,
                object: self.player?.currentItem
            )

            self.player?.play()
        }
    }
    
    @objc func restartVideo() {
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

        partTypeDisplayButton.setTitle("Part Type: Not Selected", for: .normal)
        partTypeDisplayButton.isHidden = true
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

        gridToggleButton.isHidden = false
        gridLines.forEach { x in x.isHidden = !toggleGridState }
    }
    
    func showValidationPopup() {
        popupView.isHidden = false
        activityIndicator.startAnimating()
        popupLabel.text = "Validating..."
        
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
        
        let url = URL(string: "http://192.168.68.114:3333/upload")! // replace
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"part_type\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(selectedPartType)\r\n".data(using: .utf8)!)
        
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
            let alert = UIAlertController(title: "Missing Part Type", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
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
        
        let url = URL(string: "http://192.168.68.114:3333/upload")! // replace
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"part_type\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(selectedPartType)\r\n".data(using: .utf8)!)
        
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
        gridLines.forEach { $0.removeFromSuperview() }
        gridLines.removeAll()

        let previewHeight = cameraPreviewView.bounds.height*1.2
        let previewWidth = cameraPreviewView.bounds.width
        let numLines = 3

        for i in 1..<numLines {
            let yPosition = CGFloat(i) * (previewHeight / CGFloat(numLines))
            let line = UIView(frame: CGRect(x: 0, y: yPosition, width: previewWidth, height: 1))
            line.backgroundColor = UIColor.white.withAlphaComponent(0.7)
            gridLines.append(line)
            self.view.addSubview(line)
        }

        for i in 1..<numLines {
            let xPosition = CGFloat(i) * (previewWidth / CGFloat(numLines))
            let line = UIView(frame: CGRect(x: xPosition, y: 0, width: 1, height: previewHeight))
            line.backgroundColor = UIColor.white.withAlphaComponent(0.7)
            gridLines.append(line)
            self.view.addSubview(line)
        }

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
        partTypePopupView = UIView()
        partTypePopupView.translatesAutoresizingMaskIntoConstraints = false
        partTypePopupView.backgroundColor = UIColor.systemBackground
        partTypePopupView.layer.cornerRadius = 12
        partTypePopupView.layer.masksToBounds = true
        partTypePopupView.layer.borderWidth = 1
        partTypePopupView.layer.borderColor = UIColor.separator.cgColor
        partTypePopupView.isHidden = true
        self.view.addSubview(partTypePopupView)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Select Part Type"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        partTypePopupView.addSubview(titleLabel)

        partTypePicker = UIPickerView()
        partTypePicker.translatesAutoresizingMaskIntoConstraints = false
        partTypePicker.delegate = self
        partTypePicker.dataSource = self
        partTypePicker.backgroundColor = .clear
        partTypePopupView.addSubview(partTypePicker)

        let submitButton = UIButton(type: .system)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.setTitle("Confirm", for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        submitButton.setTitleColor(.black, for: .normal)
        submitButton.layer.cornerRadius = 8
        submitButton.backgroundColor = .systemGray.withAlphaComponent(0.1)
        submitButton.addTarget(self, action: #selector(submitPartType), for: .touchUpInside)
        partTypePopupView.addSubview(submitButton)

        let cancelButton = UIButton(type: .system)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.setTitleColor(.black, for: .normal)
        cancelButton.layer.cornerRadius = 8
        cancelButton.backgroundColor = .systemGray.withAlphaComponent(0.1)
        cancelButton.addTarget(self, action: #selector(cancelPartTypeSelection), for: .touchUpInside)
        partTypePopupView.addSubview(cancelButton)

        let buttonStackView = UIStackView(arrangedSubviews: [cancelButton, submitButton])
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 16
        partTypePopupView.addSubview(buttonStackView)

        NSLayoutConstraint.activate([
            partTypePopupView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            partTypePopupView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            partTypePopupView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8),
            partTypePopupView.heightAnchor.constraint(equalToConstant: 300),

            titleLabel.topAnchor.constraint(equalTo: partTypePopupView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: partTypePopupView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: partTypePopupView.trailingAnchor, constant: -20),

            partTypePicker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            partTypePicker.leadingAnchor.constraint(equalTo: partTypePopupView.leadingAnchor, constant: 20),
            partTypePicker.trailingAnchor.constraint(equalTo: partTypePopupView.trailingAnchor, constant: -20),
            partTypePicker.heightAnchor.constraint(equalToConstant: 120),

            buttonStackView.topAnchor.constraint(equalTo: partTypePicker.bottomAnchor, constant: 20),
            buttonStackView.leadingAnchor.constraint(equalTo: partTypePopupView.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: partTypePopupView.trailingAnchor, constant: -20),
            buttonStackView.bottomAnchor.constraint(equalTo: partTypePopupView.bottomAnchor, constant: -20),
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

        partTypeDisplayButton.setTitle("Part Type: \(selectedPartType)", for: .normal)
        partTypeDisplayButton.isHidden = false
        
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
        partTypeDisplayButton.layer.masksToBounds = false

        partTypeDisplayButton.layer.shadowColor = UIColor.black.cgColor
        partTypeDisplayButton.layer.shadowOpacity = 0.3
        partTypeDisplayButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        partTypeDisplayButton.layer.shadowRadius = 4

        partTypeDisplayButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

        partTypeDisplayButton.addTarget(self, action: #selector(showPartTypePopup), for: .touchUpInside)
        partTypeDisplayButton.addTarget(self, action: #selector(animateButtonTap(_:)), for: .touchDown)
        partTypeDisplayButton.addTarget(self, action: #selector(animateButtonRelease(_:)), for: .touchUpOutside)
        partTypeDisplayButton.addTarget(self, action: #selector(animateButtonRelease(_:)), for: .touchCancel)

        partTypeDisplayButton.isHidden = true
        self.view.addSubview(partTypeDisplayButton)

        NSLayoutConstraint.activate([
            partTypeDisplayButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            partTypeDisplayButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -30),
            partTypeDisplayButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc func animateButtonTap(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }

    @objc func animateButtonRelease(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform.identity
        }
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
