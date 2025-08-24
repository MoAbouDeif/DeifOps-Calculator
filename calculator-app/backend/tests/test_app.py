import pytest
from app import app
from models import CalculationModel


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


# --- /calculate endpoint ---


def test_calculate_add(client, monkeypatch):
    monkeypatch.setattr(CalculationModel, "create", lambda *a, **kw: None)
    resp = client.post("/calculate", json={"a": 5, "b": 3, "operation": "add"})
    assert resp.status_code == 200
    assert resp.get_json()["result"] == 8


def test_calculate_missing_params(client):
    resp = client.post("/calculate", json={})
    assert resp.status_code == 400


def test_calculate_invalid_numbers(client):
    resp = client.post("/calculate", json={"a": "x", "b": 2, "operation": "add"})
    assert resp.status_code == 400


def test_calculate_invalid_operation(client):
    resp = client.post("/calculate", json={"a": 1, "b": 2, "operation": "pow"})
    assert resp.status_code == 400


def test_calculate_divide_by_zero(client):
    resp = client.post("/calculate", json={"a": 1, "b": 0, "operation": "divide"})
    assert resp.status_code == 400


def test_calculate_large_numbers(client):
    resp = client.post("/calculate", json={"a": 1e200, "b": 1, "operation": "add"})
    assert resp.status_code == 400


def test_calculate_too_large(client):
    resp = client.post("/calculate", json={"a": 1e200, "b": 1e10, "operation": "add"})
    assert resp.status_code == 400


def test_calculate_db_error(client, monkeypatch):
    def fail(*a, **kw):
        raise Exception("DB error")

    monkeypatch.setattr(CalculationModel, "create", fail)
    resp = client.post("/calculate", json={"a": 1, "b": 2, "operation": "add"})
    assert resp.status_code == 500


# --- /history endpoint ---


def test_history_success(client, monkeypatch):
    monkeypatch.setattr(
        CalculationModel, "get_history", lambda *a, **kw: [{"op": "add"}]
    )
    resp = client.get("/history?limit=5")
    assert resp.status_code == 200
    assert "history" in resp.get_json()


def test_history_invalid_limit(client, monkeypatch):
    monkeypatch.setattr(CalculationModel, "get_history", lambda *a, **kw: [])
    resp = client.get("/history?limit=9999")
    assert resp.status_code == 200


def test_history_db_error(client, monkeypatch):
    def fail(*a, **kw):
        raise Exception("DB error")

    monkeypatch.setattr(CalculationModel, "get_history", fail)
    resp = client.get("/history")
    assert resp.status_code == 500


def test_calculate_invalid_type(client):
    resp = client.post("/calculate", json={"a": "foo", "b": "bar", "operation": "add"})
    assert resp.status_code == 400
