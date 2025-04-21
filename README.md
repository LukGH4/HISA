# Honeywell ML Part Intake Scanning App

## Version 1.0 Release

## Overview

### Problem Statement  
At Maintenance Repair & Overhaul (MRO) centers, the process of determining whether a part is in good condition or defective is currently reliant on manual human inspection. This results in inconsistencies, inefficiencies, and higher error rates, which are especially problematic in industries like aerospace and construction.

### Solution  
The Honeywell ML Part Intake Scanning App provides an AI-powered solution to automate part evaluation. By leveraging image classification through a YOLOv8-based machine learning model, the mobile app can classify parts in real-time as either **Good** or **Bad** directly during intake. The system also identifies specific defect types, aiding technicians and decision-makers in immediate analysis. This can integrate seamlessly into an industrial workflow and provide a solution for automating part intake scanning.

---

## Features

### ML-Powered Real-Time Scanning
- On-device part classification using a trained `YOLOv8` image classification model.
- Binary evaluation: classifies parts as **Good** or **Bad**.
- Defect detection via bounding box classification with confidence scoring.

### Analytics & Statistics Dashboard
- **Part Statistics:**
  - Historical data tracking per part.
  - Failure rate trends, confidence metrics, and defect breakdowns visualized in charts.
  - Compare two or more parts side-by-side with visual data overlays.
- **Employee Statistics:**
  - Personal scan history and defect distribution insights.
  - Global manager view with company-wide scan trends and failure rates.
  - Filtering by name, part type, and date range.

### Alert System
- Threshold-based alerts for part failure rates.
- Configurable warning thresholds set by managers.
- Notifications via in-app banners and automated email alerts.

### Role-Based Dashboards
- **Manager Dashboard:**
  - Live activity feed of employee scans and actions.
  - Access to individual and aggregate performance insights.
  - View and manage employee profiles and permissions.
- **Employee Dashboard:**
  - View personal scan history and profile.
  - Track individual accuracy and scan patterns over time.

### Export & Reporting Tools
- Export scan history and statistics in `.CSV` and `.PDF` formats.
- Manager-level export options for internal reporting or audits.

---

## Known Issues

- **UI Inconsistencies**: Some minor layout bugs persist across different screen sizes and iOS versions. These will be addressed in future UI polish updates.
- **Model Accuracy**: While the YOLOv8 model performs well in controlled environments, further data is needed for robust performance across edge cases.
- **Data Access Permissions**: Fine-grained access control is not yet fully implemented, but the framework is in place.

---

## Documentation & Resources

-  **[Installation Guide (Hosted on GitHub)](https://github.com/LukGH4/JIB-4338-HISA/blob/main/Installation%20Guide/Installation%20Guide.md)**  
  Step-by-step guide for setting up and running the app on a supported iOS device.

-  **[Detailed Design Document (PDF)](https://github.com/LukGH4/JIB-4338-HISA/blob/main/Design%20Document/Design%20Document.pdf)**  
  Architecture, feature breakdown, design rationale, and technical stack description.

-  **Source Code Repository**  
  Browse the full codebase, including ML model integration, frontend components, and backend API:  
  [GitHub Repository](https://github.com/LukGH4/JIB-4338-HISA)

---

## Technologies Used

- **Platform**: iOS (Tested on iOS 18.1)
- **Programming Language**: Swift
- **Frontend Frameworks**: `SwiftUI`, `UIKit`, `AVFoundation`
- **Machine Learning Stack**:
  - `YOLOv8` (Ultralytics) for object detection and classification
  - `CoreML` & `Vision Framework` for on-device inference (planned)
- **Backend**:
  - `Flask API` for image processing and ML model inference
  - `Firebase Realtime Database` and `Firebase Storage` for scan storage and metadata

---
