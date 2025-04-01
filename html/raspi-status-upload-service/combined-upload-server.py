from flask import Flask, request, jsonify
import os
import json

LIVE_DIR = "/usr/share/nginx/html"
HISTORY_DIR = "/usr/share/nginx/html/history"
MAX_ENTRIES = 288  # 24h bei 5-Min-Intervallen

app = Flask(__name__)
os.makedirs(LIVE_DIR, exist_ok=True)
os.makedirs(HISTORY_DIR, exist_ok=True)

@app.route("/upload/<host>.json", methods=["POST"])
def upload_combined(host):
    data = request.get_json()
    if not data or "timestamp" not in data:
        return "Invalid data", 400

    # Speichere aktuelle Live-Daten
    live_path = os.path.join(LIVE_DIR, f"{host}.json")
    with open(live_path, "w") as f:
        json.dump(data, f)

    # Hänge an Verlauf an
    history_path = os.path.join(HISTORY_DIR, f"{host}.json")
    if os.path.exists(history_path):
        with open(history_path, "r") as f:
            history = json.load(f)
    else:
        history = []

    history.append(data)
    if len(history) > MAX_ENTRIES:
        history = history[-MAX_ENTRIES:]

    with open(history_path, "w") as f:
        json.dump(history, f)

    return "OK", 200

@app.route("/history/<host>.json")
def get_history(host):
    path = os.path.join(HISTORY_DIR, f"{host}.json")
    if os.path.exists(path):
        with open(path) as f:
            return f.read(), 200, {"Content-Type": "application/json"}
    else:
        return jsonify([])


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=9091)
