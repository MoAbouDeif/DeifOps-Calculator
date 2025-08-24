import unittest
import json
from app import app
from unittest.mock import patch


class TestService(unittest.TestCase):

    def setUp(self):
        self.app = app
        self.app.config["TESTING"] = True
        self.client = self.app.test_client()

    @patch("app.CalculationModel.create")
    def test_addition(self, mock_create):
        response = self.client.post(
            "/calculate", json={"a": 5, "b": 3, "operation": "add"}
        )
        data = json.loads(response.data)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(data["result"], 8)
        mock_create.assert_called_once()

    @patch("app.CalculationModel.create")
    def test_division_by_zero(self, mock_create):
        response = self.client.post(
            "/calculate", json={"a": 5, "b": 0, "operation": "divide"}
        )
        data = json.loads(response.data)
        self.assertEqual(response.status_code, 400)
        self.assertEqual(data["error"], "Division by zero")
        mock_create.assert_not_called()

    @patch("app.CalculationModel.get_history")
    def test_get_history(self, mock_get_history):
        mock_history = [
            {
                "operand1": 5,
                "operand2": 3,
                "operation": "add",
                "result": 8,
                "created_at": "2023-08-08 12:00:00",
            }
        ]
        mock_get_history.return_value = mock_history

        response = self.client.get("/history")
        data = json.loads(response.data)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(data["history"], mock_history)
