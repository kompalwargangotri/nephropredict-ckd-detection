import os
import tempfile

db_file = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
db_file.close()
os.environ["NEPHROPREDICT_DB_PATH"] = db_file.name

from backend.api import app

app.config["TESTING"] = True

def test_health_endpoint():
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200
    assert response.get_json()["status"] == "online"

def test_prediction_and_history():
    client = app.test_client()
    response = client.post("/predict", json={"PatientName": "Test Patient"})
    payload = response.get_json()
    assert response.status_code == 200
    assert payload["success"] is True
    assert payload["prediction"] in (0, 1)
    assert 0.0 <= payload["probability"] <= 1.0

    history = client.get("/history")
    assert history.status_code == 200
    assert len(history.get_json()["history"]) >= 1

def test_invalid_numeric_input_returns_error():
    client = app.test_client()
    response = client.post("/predict", json={"Age": "invalid"})
    assert response.status_code == 500
    assert response.get_json()["success"] is False
