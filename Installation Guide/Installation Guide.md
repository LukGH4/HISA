# Install Guide for Photo/Video Classification App

---

## Pre-requisites

Ensure the following software and hardware are available:

- **Mac Computer** with macOS 12.0 or later (required for iOS development)
- **Xcode 15+** ([Download Xcode](https://developer.apple.com/xcode/))
- **Python 3.9+** ([Download Python](https://www.python.org/downloads/))
- **Firebase Project** set up ([Firebase Console](https://console.firebase.google.com/))
- **Apple Developer Program Membership** ([Join here](https://developer.apple.com/programs/)) 
---

## Firebase Setup

1. **Create a Firebase Project:**
   - Go to the [Firebase Console](https://console.firebase.google.com/).
   - Click **Add Project** and follow the prompts.

2. **Enable Authentication:**
   - In the Firebase Console, go to **Authentication**.
   - Enable **Email/Password** sign-in method.

3. **Create a Realtime Database:**
   - Go to **Build > Realtime Database**.
   - Create a database and start in test mode.

4. **Enable Storage:**
   - Go to **Build > Storage**.
   - Create a default storage bucket.

5. **Generate Admin SDK Key:**
   - Go to **Project Settings > Service Accounts**.
   - Click **Generate new private key** and download the JSON file.
   - Place this file (`jib-4338-hisa-firebase-adminsdk-c9uu0-6b2a83c10a.json`) into your backend directory.

6. **Configure Firebase Rules:**
   - Update Realtime Database and Storage rules to allow read/write during development.

Example Development Rules:
```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

> ⚠️ Note: Update rules to more secure settings if making a production build!

---

## Dependent Libraries

The project uses the following main dependencies:

**Backend (Python):**
```bash
pip install -r requirements.txt
```

Main packages:
- Flask
- firebase-admin
- torch
- opencv-python
- albumentations
- ultralytics (YOLOv8)

**iOS App (Swift, via Swift Package Manager):**
- FirebaseAuth
- FirebaseFirestore
- FirebaseStorage

Add Firebase to your iOS project through Swift Package Manager:
- URL: `https://github.com/firebase/firebase-ios-sdk`

---

## Download Instructions

- Clone this repository:
```bash
git clone https://github.com/LukGH4/JIB-4338-HISA.git
```

---

## Build Instructions

### Backend
1. Navigate to backend directory:
```bash
cd backend
```
2. Create a virtual environment (optional but recommended):
```bash
python3 -m venv venv
source venv/bin/activate
```
3. Install dependencies:
```bash
pip install -r requirements.txt
```
4. Place your **Firebase Admin SDK key** (`jib-4338-hisa-firebase-adminsdk-c9uu0-6b2a83c10a.json`) into the backend root folder.

5. Place your YOLOv8 model file (`yolov8n_trained.pt`) into the backend root folder.

> ⚠️ **Important:**
> Update the `send_email()` function in `app.py` with a real Gmail address and App Password for sending email alerts. 
> You must enable [App Passwords in Gmail](https://support.google.com/accounts/answer/185833?hl=en) if using Gmail.

### iOS App Setup (Xcode)

1. Open the `.xcodeproj` or `.xcworkspace` file.
2. Install Firebase SDK via Swift Package Manager:
   - Open **Xcode > File > Add Packages...**
   - Enter: `https://github.com/firebase/firebase-ios-sdk`
   - Add **FirebaseAuth**, **FirebaseFirestore**, and **FirebaseStorage**.
3. Add the downloaded **GoogleService-Info.plist** to your project root.
4. Update the **Bundle Identifier** in Xcode to match your Firebase iOS app settings.
5. Set **iOS Deployment Target** to 15.0 or higher.
6. Add usage descriptions to `Info.plist`:
   ```xml
   <key>NSPhotoLibraryUsageDescription</key>
   <string>Access to your photo library is needed for classifying media.</string>
   <key>NSCameraUsageDescription</key>
   <string>Access to your camera is needed for uploading photos and videos.</string>
   ```
7. Ensure your app targets real devices (for camera/photo access).

---

## Installation of Application

- Create a folder called `/uploads` inside the backend directory (already auto-created if missing).
- Backend server listens on **port 3333** (`http://localhost:3333`).

---

## Run Instructions

### Backend
Run the Flask server locally:
```bash
python app.py
```
Server should start at `http://0.0.0.0:3333/`.


### iOS App
- Select a device and **Run** in Xcode.
- Login/signup with Firebase Authentication.
- Begin uploading photos or videos.

---

## Troubleshooting

| Issue | Solution |
| :---- | :------- |
| YOLO model not found | Ensure `yolov8n_trained.pt` is in backend root |
| Firebase connection errors | Confirm `serviceAccountKey.json` is correct and database/storage rules are permissive |
| App build fails | Check Firebase SDK is properly linked, and make sure to check if the bundle ID is correct |
| iOS app cannot access Photos or Camera | Ensure proper permissions in `Info.plist` |

---

## Publishing the iOS App (If needed)

### 1. Set Up App Store Connect
- Create a new app in [App Store Connect](https://appstoreconnect.apple.com/).
- Set the Bundle ID to match Xcode settings.
- Fill metadata (name, description, keywords, screenshots).

### 2. Prepare App for Release
- Set `iOS Deployment Target` (e.g., iOS 15.0 or higher).
- Use **Product > Archive** to create a build.
- Validate and Upload to App Store Connect.

### 4. Submit for Review
- Complete App Store Review submission.
- Respond to any issues flagged by Apple.
- Release upon approval!

> ⚡ **Note:**
> Apps using Firebase/Auth must have a proper Privacy Policy linked in App Store metadata.
