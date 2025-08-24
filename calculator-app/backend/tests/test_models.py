import pytest
from models import CalculationModel


class FakeCursor:
    def __init__(self):
        self.executed = False
        self.closed = False

    def execute(self, query, params=None):
        self.executed = True

    def fetchall(self):
        return [
            {
                "operand1": 1,
                "operand2": 2,
                "operation": "add",
                "result": 3,
                "created_at": "now",
            }
        ]

    def close(self):
        self.closed = True


class FakeConnection:
    def __init__(self):
        self.cursor_obj = FakeCursor()
        self.committed = False

    def cursor(self):
        return self.cursor_obj

    def commit(self):
        self.committed = True


class FakeMySQL:
    def __init__(self):
        self.connection = FakeConnection()


def test_create_valid_operation():
    mysql = FakeMySQL()
    CalculationModel.create(mysql, 1, 2, "add", 3)
    assert mysql.connection.committed
    assert mysql.connection.cursor_obj.executed
    assert mysql.connection.cursor_obj.closed


def test_create_invalid_operation():
    mysql = FakeMySQL()
    with pytest.raises(ValueError):
        CalculationModel.create(mysql, 1, 2, "power", 3)


def test_get_history_valid_limit():
    mysql = FakeMySQL()
    history = CalculationModel.get_history(mysql, 5)
    assert len(history) == 1
    assert mysql.connection.cursor_obj.executed
    assert mysql.connection.cursor_obj.closed


def test_get_history_invalid_limit():
    mysql = FakeMySQL()
    history = CalculationModel.get_history(mysql, -10)
    assert len(history) == 1
