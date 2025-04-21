# Honeywell ML Part Intake Scanning App

## Project Overview

### Problem
At Maintenance Repair & Overhaul centers, determining if a part is good or bad during intake is currently dependent on individual judgment, which are prone to human error, time-consuming, and inconsistent. Industries such as aerospace and construction require automated solutions for higher accuracy and efficiency.

### Solution
Our AI-powered computer vision model scans and evaluates parts in real-time, enabling technicians to scan parts on intake and automatically classify them as "Good" or "Bad" as well as detect defects with high accuracy.

---

## Key Features

### Machine Learning Integration
- Real-time classification using a trained `YOLOv8` model.
- Binary part status prediction: Good or Bad.
- Defect detection performed through image classification

### Statistics & Insights
- **Individual Part Statistics**
  - View historical performance metrics, confidence scores, and failure distributions per part.
  - Compare two or more parts graphically.
- **Employee Scan Statistics**
  - Each employee can access and analyze their own scan history.
  - Managers view global trends, failure rates, and scan distributions across all employees.

### Alert System
- Managers can define failure rate thresholds for parts.
- Receive in-app and email notifications when thresholds are exceeded.

### Manager & Employee Dashboards
- Real-time scan activity feeds.
- Enhanced account control, including permission and profile management.
- Part type categorization and color-coded status indicators.

### Data Exportation
- Export scan history and statistics in CSV or PDF format.

### UI Improvements
- Organized containers for better navigation.
- Color-coded failure indicators.
- Employee and manager profile image support.
- Fully styled and consistent user experience with `SwiftUI`.

---

## Known Issues
- **UI Inconsistencies**: Minor layout bugs exist across devices.
- **ML Accuracy Improvements**: Ongoing work needed to improve classification accuracy.

---

## Documentation

### [Installation Guide](https://github.com/LukGH4/JIB-4338-HISA/blob/main/Installation%20Guide/Installation%20Guide.md)

Step-by-step instructions to install and set up the app.

### [Detailed Design Document (PDF)](https://github.com/LukGH4/JIB-4338-HISA/blob/main/Design%20Document/Design%20Document.pdf)

---

## 🛠️ Technologies Used

- **Platform**: iOS (Tested on iOS 18.1)
- **Languages**: Swift
- **Frontend Frameworks**: `UIKit`, `SwiftUI`, `AVFoundation`
- **ML Stack**: YOLOv8, Vision Framework
- **Backend**: Flask API, Firebase Realtime DB & Firebase Storage

---

## 🔮 Future Development

- Full integration of CoreML and on-device model updates.
- Enhanced feedback loop for model retraining.
- Expand to Android for cross-platform support.
- Advanced analytics dashboard for business insights.
- Role-based access control and permissions refinement.

---
