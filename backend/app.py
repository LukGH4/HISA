import os
import uuid
import firebase_admin
from firebase_admin import credentials, storage, db
from flask import Flask, request, jsonify
from PIL import Image
from datetime import date, timedelta
import cv2

app = Flask(__name__)

# Initialize Firebase Admin SDK
cred = credentials.Certificate("jib-4338-hisa-firebase-adminsdk-c9uu0-6b2a83c10a.json")  # Replace with your Firebase service account key
firebase_admin.initialize_app(cred, {
    'storageBucket': 'jib-4338-hisa.firebasestorage.app',  # Replace with your Firebase Storage bucket
    'databaseURL': 'https://jib-4338-hisa-default-rtdb.firebaseio.com/'  # Replace with your Firebase Realtime Database URL
})

# Create an uploads directory
UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


@app.route('/upload', methods=['POST'])
def upload_file():
    """Handles file upload, ML classification, and Firebase storage."""
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['file']
    user_id = request.form.get('user_id', 'unknown_user')  # Get user ID from the request
    file_ext = file.filename.split('.')[-1].lower()
    
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    # Generate a unique filename
    file_id = str(uuid.uuid4())
    filename = f"{file_id}.{file_ext}"
    file_path = os.path.join(UPLOAD_FOLDER, filename)

    # Save the file locally
    file.save(file_path)

    # Mock ML model classification
    classification = run_mock_ml_model(file_path)

    # Upload to Firebase Storage
    bucket = storage.bucket()
    blob = ""
    if file_path.lower().endswith(('.png', '.jpg', '.jpeg')):
        blob = bucket.blob(f"images/{filename}")
    elif file_path.lower().endswith(('.mp4', '.avi', '.mov')):
        blob = bucket.blob(f"videos/{filename}")
    blob.upload_from_filename(file_path)

    # Generate a Firebase-compatible URL
    bucket_name = "jib-4338-hisa.firebasestorage.app"  # Replace with your bucket name
    file_type = "images" if file_path.lower().endswith(('.png', '.jpg', '.jpeg')) else "videos"
    firebase_url = f"https://firebasestorage.googleapis.com/v0/b/{bucket_name}/o/{file_type}%2F{filename}?alt=media"

    # Generate a signed URL to get the token
    expiration_time = timedelta(days=7)  # URL expires in 7 days
    signed_url = blob.generate_signed_url(expiration=expiration_time)

    # Extract the token from the signed URL
    from urllib.parse import urlparse, parse_qs
    parsed_url = urlparse(signed_url)
    token = parse_qs(parsed_url.query).get('Signature', [''])[0]

    # Append the token to the Firebase URL
    firebase_url_with_token = f"{firebase_url}&token={token}"

    # Store metadata in Firebase Realtime Database
    save_to_firebase(user_id, filename, firebase_url_with_token, classification)

    # Cleanup local file
    os.remove(file_path)

    return jsonify({
        'message': 'File uploaded successfully',
        'file_url': firebase_url_with_token,
        'classification': classification
    })


def run_mock_ml_model(file_path):
    """Replace this with your actual ML model inference."""
    try:
        # Process image
        if file_path.lower().endswith(('.png', '.jpg', '.jpeg')):
            img = Image.open(file_path)
            img.verify()
            return "Good Part"  # Mock result (replace with real inference)
        
        # Process video
        elif file_path.lower().endswith(('.mp4', '.avi', '.mov')):
            cap = cv2.VideoCapture(file_path)
            ret, _ = cap.read()
            cap.release()
            return "Bad Part" if not ret else "Good Part"

    except Exception as e:
        return f"Error processing file: {str(e)}"


def save_to_firebase(user_id, filename, file_url, classification):
    """Save metadata to Firebase Realtime Database."""
    if filename.lower().endswith(('.png', '.jpg', '.jpeg')):
        ref = db.reference(f"users/employees/{user_id}/images").push()
    elif filename.lower().endswith(('.mp4', '.avi', '.mov')):
        ref = db.reference(f"users/employees/{user_id}/videos").push()
    ref.set({
        "fileName": filename,
        "url": file_url,
        "classification": classification,
        "date": date.today().isoformat()
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3333, debug=True)