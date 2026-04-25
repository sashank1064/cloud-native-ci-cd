from app import app


def test_home():
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200
    assert response.content_type.startswith("text/html")
    body = response.get_data(as_text=True)
    assert "Cloud Native CI/CD Project" in body
    assert "user-service" in body
    assert "A real Flask microservice" in body
    assert "Project Architecture" in body
    assert "Live Request Flow" in body
    assert "Terraform" in body
    assert "ALB Ingress" in body
    assert "Demo business endpoint" in body


def test_api_info():
    client = app.test_client()
    response = client.get("/api/info")
    assert response.status_code == 200
    payload = response.get_json()
    assert payload["project"] == "Cloud Native CI/CD Project"
    assert payload["service"] == "user-service"
    assert payload["message"] == "hello from the cloud native user service"
    assert payload["endpoints"]["health"] == "/health"
    assert payload["endpoints"]["status"] == "/status"
    assert payload["endpoints"]["users_demo"] == "/users/demo"
    assert payload["endpoints"]["version"] == "/version"
    assert len(payload["architecture"]) == 4
    assert payload["request_flow"][-1] == "Flask Pod"


def test_version():
    client = app.test_client()
    response = client.get("/version")
    assert response.status_code == 200
    payload = response.get_json()
    assert payload["service"] == "user-service"
    assert payload["environment"] == "dev"
    assert payload["version"] == "v1"
    assert payload["image_tag"] == "v1"


def test_status():
    client = app.test_client()
    response = client.get("/status")
    assert response.status_code == 200
    payload = response.get_json()
    assert payload["application"] == "running"
    assert payload["deployment"] == "Kubernetes / Helm"


def test_users_demo():
    client = app.test_client()
    response = client.get("/users/demo")
    assert response.status_code == 200
    payload = response.get_json()
    assert payload["count"] == 3
    assert payload["users"][0]["status"] == "active"


def test_health():
    client = app.test_client()
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json()["status"] == "ok"
