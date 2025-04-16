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
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

app = Flask(__name__)

cred = credentials.Certificate("jib-4338-hisa-firebase-adminsdk-c9uu0-6b2a83c10a.json")
firebase_admin.initialize_app(cred, {
    'storageBucket': 'jib-4338-hisa.firebasestorage.app',
    'databaseURL': 'https://jib-4338-hisa-default-rtdb.firebaseio.com/'
})

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


model_path = "yolov8n_trained.pt"
model = YOLO(model_path)

logging.getLogger("ultralytics").setLevel(logging.ERROR)

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

label_to_cls = {
    0: "Crack",
    1: "Dent",
    2: "Missing-head",
    3: "Paint-off",
    4: "Scratch"
}

test_transform = A.Compose([
    A.Resize(224, 224),
    A.Normalize(mean=(0.485, 0.456, 0.406), std=(0.229, 0.224, 0.225)),
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
    part_type = request.form.get('part_type', 'unknown_part')
    file_ext = file.filename.split('.')[-1].lower()

    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    date = datetime.now().strftime('%Y%m%d_%H%M%S')

    employee = request.form.get('name', 'unknown_user')
    file_id = f"{date}"
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

    save_to_firebase(user_id, filename, firebase_url, status, classification, confidence, part_type)
    os.remove(file_path)

    return jsonify({
        'message': 'File uploaded successfully',
        'file_url': firebase_url,
        'classification': status
    })

def classify_image(file_path):
    try:
        results = model(file_path)
        detections = results[0].boxes

        classifications = []
        for box in detections:
            cls_idx = int(box.cls[0].item())
            confidence = box.conf[0].item()
            label = label_to_cls.get(cls_idx, "Unknown")

            if confidence > 0.2:
                classifications.append((label, confidence))
        status = "Good Part"

        if classifications:
            best_label, best_conf = max(classifications, key=lambda x: x[1])
            status = "Bad Part"
        else:
            best_label, best_conf = "Good Part", 1.0

        return status, best_label, f"{best_conf:.2f}"
    except Exception as e:
        return f"Error processing image: {str(e)}"


def classify_video(video_path):
    try:
        cap = cv2.VideoCapture(video_path)
        frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        frame_interval = max(1, frame_count // 10)  # process every 10th frame
        classifications = []

        for i in range(frame_count):
            ret, frame = cap.read()
            if not ret:
                break
            if i % frame_interval == 0:
                frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

                results = model(frame_rgb)
                detections = results[0].boxes

                for box in detections:
                    cls_idx = int(box.cls[0].item())
                    confidence = box.conf[0].item()
                    label = label_to_cls.get(cls_idx, "Unknown")

                    if confidence > 0.2:
                        classifications.append((label, confidence))

        cap.release()

        status = "Good Part"
        if classifications:
            best_label, best_conf = max(classifications, key=lambda x: x[1])
            status = "Bad Part"
        else:
            best_label, best_conf = "Good Part", 1.0

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
        "part_type": part_type,
        "date": date.today().isoformat()
    })

    user_ref = db.reference(f"users/employees/{user_id}")
    scan_counter = user_ref.child("scanCounter").get() or 0
    user_ref.update({"scanCounter": scan_counter + 1})

    update_part_counts(part_type, status)

def update_part_counts(part_type, status):
    parts_ref = db.reference(f"parts/{part_type}")

    part_data = parts_ref.get() or {"threshold": 50, "good": 0, "bad": 0}
    good_count = part_data.get("good", 0)
    bad_count = part_data.get("bad", 0)

    if status == "Good Part":
        good_count += 1
    elif status == "Bad Part":
        bad_count += 1

    parts_ref.update({
        "good": good_count,
        "bad": bad_count
    })

    if good_count + bad_count > 0:
        failure_rate = bad_count / (good_count + bad_count)
    else:
        failure_rate = 0

    threshold = part_data.get("threshold", 50)
    if failure_rate > threshold / 100:
        send_email_to_managers(part_type, failure_rate, threshold)

    print(f"Updated part counts for {part_type}: Good = {good_count}, Bad = {bad_count}, Failure Rate = {failure_rate:.2f}")

def send_email_to_managers(part_type, failure_rate, threshold):
    managers_ref = db.reference("users/managers")
    managers_data = managers_ref.get()

    if not managers_data:
        print("No managers found.")
        return

    subject = f"Warning: {part_type} Failure Rate Exceeded"
    body = f"The failure rate for part {part_type} has exceeded the threshold.\n\n"
    body += f"Failure Rate: {failure_rate*100:.2f}%\n"
    body += f"Threshold: {threshold}%\n\n"
    body += "Please review the part's quality and take appropriate action."

    for manager_id, manager_info in managers_data.items():
        email = manager_info["email"]
        send_email(email, subject, body)

def send_email(to_email, subject, body):
    from_email = "replace"
    app_password = "replace"

    msg = MIMEMultipart()
    msg['From'] = from_email
    msg['To'] = to_email
    msg['Subject'] = subject

    msg.attach(MIMEText(body, 'plain'))

    try:
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(from_email, app_password)
        text = msg.as_string()
        server.sendmail(from_email, to_email, text)
        server.quit()
        print(f"Email sent to {to_email}")
    except Exception as e:
        print(f"Error sending email: {e}")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3333, debug=True)
