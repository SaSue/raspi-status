from flask import Flask, jsonify
import os

UPLOAD_DIR = "/usr/share/nginx/html"

app = Flask(__name__)

@app.route("/list")
def list_json_files():
    files = [f for f in os.listdir(UPLOAD_DIR) if f.endswith(".json")]
    return jsonify(files)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=9092)
