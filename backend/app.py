import os
import uuid
import firebase_admin
import torch
from firebase_admin import credentials, storage, db
from flask import Flask, request, jsonify
from datetime import date
import cv2
import albumentations as A
from albumentations.pytorch import ToTensorV2
from ultralytics import YOLO
import logging

app = Flask(__name__)

# Initialize Firebase Admin SDK
cred = credentials.Certificate("jib-4338-hisa-firebase-adminsdk-c9uu0-6b2a83c10a.json")
firebase_admin.initialize_app(cred, {
    'storageBucket': 'jib-4338-hisa.firebasestorage.app',
    'databaseURL': 'https://jib-4338-hisa-default-rtdb.firebaseio.com/'
})

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


model_path = "yolov8n_trained.pt"  # Path to the saved model
model = YOLO(model_path)  # Load trained YOLOv8 model

logging.getLogger("ultralytics").setLevel(logging.ERROR)

# Load trained weights (ensure the checkpoint matches EfficientNet's architecture)
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

label_to_cls = {
    0: "crack",
    1: "dent",
    2: "missing-head",
    3: "paint-off",
    4: "scratch"
}

test_transform = A.Compose([
    A.Resize(224, 224),  # Resize frames to match model input size
    A.Normalize(mean=(0.485, 0.456, 0.406), std=(0.229, 0.224, 0.225)),  # Standard normalization
    ToTensorV2()
])

#testing
@app.route('/')
def home():
    return "Flask server is running!"
#end testing

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['file']
    user_id = request.form.get('user_id', 'unknown_user')
    part_type = request.form.get('part_type', 'unknown_part')  # Get part_type from form data
    file_ext = file.filename.split('.')[-1].lower()
    
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    file_id = str(uuid.uuid4())
    filename = f"{file_id}.{file_ext}"
    file_path = os.path.join(UPLOAD_FOLDER, filename)
    file.save(file_path)

    status, classification, confidence = None, None, None
    if file_path.lower().endswith(('.png', '.jpg', '.jpeg')):
        status, classification, confidence = classify_image(file_path)
        storage_path = f"images/{filename}"
    elif file_path.lower().endswith(('.mp4', '.avi', '.mov')):
        status, classification, confidence = classify_video(file_path)
        storage_path = f"videos/{filename}"
    else:
        return jsonify({'error': 'Unsupported file format'}), 400

    bucket = storage.bucket()
    blob = bucket.blob(storage_path)
    blob.upload_from_filename(file_path)

    firebase_url = f"https://firebasestorage.googleapis.com/v0/b/jib-4338-hisa.firebasestorage.app/o/{storage_path.replace('/', '%2F')}?alt=media"
    
    save_to_firebase(user_id, filename, firebase_url, status, classification, confidence, part_type)  # Pass part_type
    os.remove(file_path)

    return jsonify({
        'message': 'File uploaded successfully',
        'file_url': firebase_url,
        'classification': status
    })

def classify_image(file_path):
    try:
        results = model(file_path)  # Run YOLOv8 inference
        detections = results[0].boxes  # Get detection results

        classifications = []
        for box in detections:
            cls_idx = int(box.cls[0].item())  # Get class index
            confidence = box.conf[0].item()  # Confidence score
            label = label_to_cls.get(cls_idx, "Unknown")

            if confidence > 0.2:  # Threshold
                classifications.append((label, confidence))
        status = "Good Part"

        if classifications:
            best_label, best_conf = max(classifications, key=lambda x: x[1]) # Get highest confidence label
            status = "Bad Part"
        else:
            best_label, best_conf = "Good Part", 1.0  # Default case

        return status, best_label, f"{best_conf:.2f}"
    except Exception as e:
        return f"Error processing image: {str(e)}"


def classify_video(video_path):
    try:
        cap = cv2.VideoCapture(video_path)
        frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        frame_interval = max(1, frame_count // 10)  # Process every 10th frame
        classifications = []

        for i in range(frame_count):
            ret, frame = cap.read()
            if not ret:
                break
            if i % frame_interval == 0:
                frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

                # Run YOLOv8 inference on the frame
                results = model(frame_rgb)
                detections = results[0].boxes  # Get detection results

                for box in detections:
                    cls_idx = int(box.cls[0].item())  # Get class index
                    confidence = box.conf[0].item()  # Confidence score
                    label = label_to_cls.get(cls_idx, "Unknown")

                    if confidence > 0.2:  # Threshold
                        classifications.append((label, confidence))

        cap.release()

        status = "Good Part"
        if classifications:
            best_label, best_conf = max(classifications, key=lambda x: x[1])  # Get highest confidence label
            status = "Bad Part"
        else:
            best_label, best_conf = "Good Part", 1.0  # Default case

        return status, best_label, f"{best_conf:.2f}"
    
    except Exception as e:
        return f"Error processing video: {str(e)}"


def save_to_firebase(user_id, filename, file_url, status, classification, confidence, part_type):
    ref_type = "images" if filename.lower().endswith(('.png', '.jpg', '.jpeg')) else "videos"
    ref = db.reference(f"users/employees/{user_id}/{ref_type}").push()
    ref.set({
        "fileName": filename,
        "url": file_url,
        "status": status,
        "classification": classification,
        "confidence": confidence,
        "part_type": part_type,  # Add part_type to the database
        "date": date.today().isoformat()
    })

    # Increment scan counter for the user
    user_ref = db.reference(f"users/employees/{user_id}")
    scan_counter = user_ref.child("scanCounter").get() or 0
    user_ref.update({"scanCounter": scan_counter + 1})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3333, debug=True)
