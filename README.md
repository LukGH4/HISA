# Honeywell ML Part Intake Scanning App
 - Problem:  Need a consistent way to determine if a part is good or bad at a Maintenance Repair & Overhaul during part intake. Dependence on individuals to determine good and bad part is not a consistent way to perform the task on part intake. Inefficient use of part utilization. 
 
- Solution: Using Machine Learning (ML) Image Classification technology, an ML tech stack will be created and integrated with a Part Intake Scanning mobile app. The ML model will be trained using a good part and bad part image dataset. The good / bad part ML model produced will be integrated as part of the app to determine if the part is Good / Bad based on the image taken at the depot using the app in real-time. The app will also have an on-device self-learning mode that will be used as feedback into the ML training to fine tune and improve the results over time. 
# Release Notes

## Version 0.0.0

### Features
- **In-App Camera Functionality**:  
  Users can access the device's camera directly within the app, enabling part scanning and image capture. This feature uses `UIKit` and `AVFoundation` to handle camera access and interactivity.
- **Core Scanning Interface**:  
  Implementation of the "Scan/Photo" button for initiating scans and capturing images. This aligns with the app's core use case for field technicians.
- **Basic Interaction Workflow**:  
  Introduced the "Delete/Discard" button, allowing users to remove unwanted scans or images directly from the interface.
- **Simulated Scan Evaluation Feedback**:  
  A basic simulation showcases the process of receiving and displaying scan evaluations from the machine learning model, providing a preview of future functionality.

### Bug Fixes
- **N/A**:  
  As this is the first release, there were no pre-existing bugs to address.

### Known Issues
- **UI Responsiveness on Older Devices**:  
  Some UI elements may display misaligned on devices running iOS versions earlier than 17. Compatibility fixes are planned.
- **Awkward Photo Timings**:
  After taking a photo, there is a slight delay before the captured image is displayed
- **Unfinished Scenes**:
  Login, Stats, and Settings Scenes need to be finished

---

# Rationale

The **core functionality** of this application revolves around enabling field technicians to scan and evaluate parts effectively. This release focuses on implementing foundational features critical for user interaction:
- The **camera integration** and **scan button** are the primary tools technicians will use.
- Simulating the scan evaluation process offers insight into how the app will function when the machine learning model is fully integrated.

Our goal for this demo was to establish the basic interaction pipeline and provide a tangible starting point for further development. Future work will expand on these foundations, including integrating the machine learning model for real-time evaluations and implementing robust data storage.

---

# Technologies Used

- **Platform**: iOS (tested on iOS 18.1)
- **Development Environment**: Xcode IDE
- **Languages**: Swift
- **Frameworks**: 
  - `UIKit`: For UI design and interactivity
  - `AVFoundation`: For camera access and handling
- **Future Technology Plans**:
  - **Machine Learning**: CoreML and Vision Framework for part evaluation
  - **Backend**: Flask server and MySQL database for storing user information and hosting the model

---

# Future Plans
In upcoming releases, we plan to:
- Fully integrate machine learning capabilities for part evaluation.
- Develop a robust backend for data storage and ML model hosting.
- Improve UI responsiveness across all supported iOS versions.
- Introduce a detailed dashboard for statistics and user insights.
