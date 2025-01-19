import UIKit
import AVFoundation

class ScanViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    // Camera components
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var capturePhotoOutput: AVCapturePhotoOutput!
    
    // UI Components
    @IBOutlet weak var cameraPreviewView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var discardButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var capturedImageView: UIImageView!
    
    // Popup components
    var popupView: UIView!
    var activityIndicator: UIActivityIndicatorView!
    var popupLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupPopupView()
        discardButton.isHidden = true
        captureButton.isEnabled = true
        captureButton.isHidden = false
        submitButton.isHidden = true
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
        let settings = AVCapturePhotoSettings()
        capturePhotoOutput.capturePhoto(with: settings, delegate: self)
        captureButton.isEnabled = false
        captureButton.isHidden = true
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
        
        // Show the popup
        showValidationPopup()
    }
    
    @IBAction func discardPhoto(_ sender: UIButton) {
        capturedImageView.image = nil
        capturedImageView.isHidden = true
        previewLayer.isHidden = false
        captureSession.startRunning()
        captureButton.isEnabled = true
        captureButton.isHidden = false
        cameraPreviewView.isHidden = false
        discardButton.isHidden = true
        submitButton.isHidden = true
        popupView.isHidden = true
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
        
        
    }
    
    
}
