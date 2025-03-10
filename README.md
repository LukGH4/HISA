# Honeywell ML Part Intake Scanning App
 - Problem:  Need a consistent way to determine if a part is good or bad at a Maintenance Repair & Overhaul during part intake. Dependence on individuals to determine good and bad part is not a consistent way to perform the task on part intake. Inefficient use of part utilization. 
 
- Solution: Using Machine Learning (ML) Image Classification technology, an ML tech stack will be created and integrated with a Part Intake Scanning mobile app. The ML model will be trained using a good part and bad part image dataset. The good / bad part ML model produced will be integrated as part of the app to determine if the part is Good / Bad based on the image taken at the depot using the app in real-time. The app will also have an on-device self-learning mode that will be used as feedback into the ML training to fine tune and improve the results over time. 

# Release Notes

## Version 0.3.0

### Features
- **Integration of Part Types**:
  Parts are now categorized by type, with classifications stored in `Firebase` alongside other part data. Users must select a part type when submitting a scan.
 - **Improvements to Manager Page:**
     - Managers can now view a real-time activity feed on the home page, tracking when employees submit or delete scans or modify account information.
     - Managers can now access scan results directly.
     - Alerts have been implemented to notify managers when a part exceeds a modifiable failure threshold.
- **User Interface and Experience Improvements:**
     - Enhanced UI for the scan list and scan results pages, including improved organization.
     - A color-coded indicator based on part classification for quick visual identification.
     - Enhanced UI for the employees management page.
     - Profile pictures can now be uploaded for both employee and manager accounts.
- **User Feedback:**
  Users can now submit feedback on the accuracy of the `YOLOv8` model’s classifications.
- **Data Exporting:**
  User data can now be exported in a CSV format.

### Bug Fixes
- Resolved an issue where profile pictures occasionally failed to load due to asynchronous processing.
- Added a refresh button to update the scan list after deleting a photo or video.
- Fixed UI inconsistencies in the scan list page.
- Fixed UI bug for part type components.

### Known Issues
- **ML Model Classification Accuracy**:  
  The `YOLOv8` model requires additional training to improve its reliability.

## Version 0.2.0

### Features
- **Backend Setup**:  
  The backend has been set up using `Flask`, which handles user input, interacts with the ML model, and stores files in `Firebase Storage`. Metadata is saved in the `Firebase Realtime Database`.
- **ML Model**:  
  Implemented a trained `YOLOv8` model that can process photo and video input and return a binary classification.
- **Manager Screen Implementation**:  
  Managers can now view and manage employee information and past scans. These scans are displayed as direct links to the image or video in `Firebase`. The UI also supports search and filtering for convenience.
- **Improvements to Scanning Page**:  
  Users can now view and delete their past scans. Video recording functionality has been added, enabling users to scan parts through videos.
- **Improvements to Settings Page**:  
  Settings page now includes options to change an employee's name and password, along with a logout feature.

### Bug Fixes
- Fixed various alignment issues on the Sign Up, Settings, and Forgot Password screens.
- The keyboard now dismisses when pressing 'return' on empty inputs or tapping anywhere on the screen.
- Fixed issues with text boxes that allowed input when they shouldn't.
- Passwords are now hidden on the Login screen and Settings screen.
- Forced light mode consistency and fixed name not displaying in dark mode

### Known Issues
- **ML Model Classification Accuracy**:  
  The model requires further training, and the weights need to be adjusted. Currently, the classification results are not very accurate due to low confidence thresholds.
- **Data Access not functional**:  
  Restricting employee data access on the manager side is not yet functional, though the framework for this feature is in place.
  
## Version 0.1.0

### Features
- **User Account Creation**:  
  Users can create accounts and log in through the `Firebase` authentication system. There are two types of accounts: Employee and Manager. A "Forgot Password" feature is also implemented.
- **Separate Manager UI**:  
  For Manager accounts, the "scan" tab is replaced by an "employees" tab, where they can view basic employee information (name, last accessed, scan history) and change employee permissions.
- **Improvements to Scanning Interface**:  
  Scans are now stored under the respective employee's account, and employees can view their previous scans.
- **Implementation of Settings Screen**:  
  A basic implementation of the Settings screen has been added, allowing for profile management and integration with the backend.
- **General Improvements**:  
  Error handling on the Login screen has been enhanced, along with minor UI improvements across various screens.

### Bug Fixes
- **N/A**

### Known Issues
- **Scan History in Manager UI**:  
  Changes made to the backend are not yet reflected in the Manager UI's Scan History section.

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
  - **Backend**: Flask server and FireBase database for storing user information and hosting the model

---

# Future Plans
In upcoming releases, we plan to:
- Fully integrate machine learning capabilities for part evaluation.
- Develop a robust backend for data storage and ML model hosting.
- Improve UI responsiveness across all supported iOS versions.
- Introduce a detailed dashboard for statistics and user insights.
