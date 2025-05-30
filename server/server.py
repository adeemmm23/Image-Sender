import os
import logging
from flask import Flask, request, jsonify
from model import check

app = Flask(__name__)

UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Configure logging
logging.basicConfig(level=logging.DEBUG)


@app.route('/', methods=['POST'])
def main():
    if 'file' not in request.files:
        logging.error("Missing required image")
        return jsonify({"error": "Missing required image"}), 400

    file = request.files['file']

    if file.filename == '':
        logging.error("No selected file")
        return jsonify({"error": "No selected file"}), 400

    if file:
        file_path = os.path.join(UPLOAD_FOLDER, file.filename)
        file.save(file_path)
        logging.info(f"File saved to {file_path}")

        # Ensure file is saved and accessible
        if not os.path.exists(file_path):
            logging.error(f"File not found after saving: {file_path}")
            return jsonify({"error": "File not found after saving"}), 500

        # Check file size
        file_size = os.path.getsize(file_path)
        logging.info(f"File size: {file_size} bytes")

    try:
        data = check(file_path)
    except Exception as e:
        logging.error(f"Error processing file with model: {e}")
        return jsonify({"error": "Error processing file with model"}), 500

    return jsonify(data)


if __name__ == '__main__':
    print("Starting server...")
    app.run(debug=True, host='0.0.0.0')
