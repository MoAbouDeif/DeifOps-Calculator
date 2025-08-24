import os
from flask_mysqldb import MySQL
from dotenv import load_dotenv

load_dotenv()


def init_db(app):
    app.config["MYSQL_HOST"] = os.getenv("MYSQL_HOST", "localhost")
    app.config["MYSQL_USER"] = os.getenv("MYSQL_USER", "moabodaif")
    app.config["MYSQL_PASSWORD"] = os.getenv("MYSQL_PASSWORD", "password")
    app.config["MYSQL_DB"] = os.getenv("MYSQL_DB", "calculator_db")
    app.config["MYSQL_CURSORCLASS"] = "DictCursor"

    return MySQL(app)
