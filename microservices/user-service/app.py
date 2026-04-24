from flask import Flask, jsonify
import os

app = Flask(__name__)

SERVICE_NAME = os.getenv("SERVICE_NAME", "user-service")
ENVIRONMENT = os.getenv("ENVIRONMENT", "dev")
VERSION = os.getenv("VERSION", "v1")


@app.route("/")
def home():
    return jsonify(
        {
            "service": SERVICE_NAME,
            "environment": ENVIRONMENT,
            "version": VERSION,
            "message": "user service is up",
        }
    )


@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200


@app.route("/ready")
def ready():
    return jsonify({"status": "ready"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
