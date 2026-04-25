from datetime import datetime, timezone
from flask import Flask, jsonify, render_template, request
import json
import os
import socket
import time

app = Flask(__name__)

PROJECT_NAME = os.getenv("PROJECT_NAME", "Cloud Native CI/CD Project")
SERVICE_NAME = os.getenv("SERVICE_NAME", "user-service")
ENVIRONMENT = os.getenv("ENVIRONMENT", "dev")
VERSION = os.getenv("VERSION", "v1")
IMAGE_TAG = os.getenv("IMAGE_TAG", VERSION)
GIT_COMMIT = os.getenv("GIT_COMMIT", "local")
BUILD_DATE = os.getenv("BUILD_DATE", "local")
AWS_REGION = os.getenv("AWS_REGION", "local")
CLUSTER_NAME = os.getenv("CLUSTER_NAME", "local")

DEMO_USERS = [
    {
        "id": 1,
        "name": "Ava Patel",
        "role": "platform engineer",
        "status": "active",
    },
    {
        "id": 2,
        "name": "Noah Kim",
        "role": "backend developer",
        "status": "active",
    },
    {
        "id": 3,
        "name": "Mia Johnson",
        "role": "release manager",
        "status": "active",
    },
]


@app.before_request
def start_request_timer():
    request.start_time = time.perf_counter()


@app.after_request
def log_request(response):
    duration_ms = round((time.perf_counter() - request.start_time) * 1000, 2)
    log_entry = {
        "event": "request_completed",
        "method": request.method,
        "path": request.path,
        "status_code": response.status_code,
        "duration_ms": duration_ms,
        "service": SERVICE_NAME,
        "environment": ENVIRONMENT,
    }
    app.logger.info(json.dumps(log_entry))
    return response


def service_info():
    return {
        "project": PROJECT_NAME,
        "service": SERVICE_NAME,
        "environment": ENVIRONMENT,
        "version": VERSION,
        "release": {
            "image_tag": IMAGE_TAG,
            "git_commit": GIT_COMMIT,
            "build_date": BUILD_DATE,
            "aws_region": AWS_REGION,
            "cluster_name": CLUSTER_NAME,
        },
        "message": "hello from the cloud native user service",
        "hostname": socket.gethostname(),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "endpoints": {
            "home": "/",
            "api_info": "/api/info",
            "health": "/health",
            "ready": "/ready",
            "status": "/status",
            "users_demo": "/users/demo",
            "version": "/version",
        },
        "architecture": [
            "Terraform provisions VPC, EKS, ECR, IAM, and load balancer support.",
            "Docker packages the Flask service into a deployable image.",
            "Helm deploys the app as Kubernetes pods behind a ClusterIP service.",
            "AWS Load Balancer Controller connects ingress traffic to the service.",
        ],
        "request_flow": [
            "User",
            "AWS Application Load Balancer",
            "Kubernetes Ingress",
            "ClusterIP Service",
            "Flask Pod",
        ],
    }


@app.route("/")
def home():
    return render_template("index.html", info=service_info())


@app.route("/api/info")
def api_info():
    return jsonify(service_info())


@app.route("/version")
def version():
    return jsonify(
        {
            "project": PROJECT_NAME,
            "service": SERVICE_NAME,
            "environment": ENVIRONMENT,
            "version": VERSION,
            "image_tag": IMAGE_TAG,
            "git_commit": GIT_COMMIT,
            "build_date": BUILD_DATE,
        }
    )


@app.route("/status")
def status():
    return jsonify(
        {
            "application": "running",
            "health_check": "passing",
            "readiness_check": "passing",
            "container": "gunicorn on port 5000",
            "deployment": "Kubernetes / Helm",
            "service": SERVICE_NAME,
            "environment": ENVIRONMENT,
            "version": VERSION,
        }
    )


@app.route("/users/demo")
def users_demo():
    return jsonify(
        {
            "service": SERVICE_NAME,
            "count": len(DEMO_USERS),
            "users": DEMO_USERS,
        }
    )


@app.route("/health")
def health():
    return jsonify(
        {
            "status": "ok",
            "service": SERVICE_NAME,
        }
    ), 200


@app.route("/ready")
def ready():
    return jsonify({"status": "ready"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
