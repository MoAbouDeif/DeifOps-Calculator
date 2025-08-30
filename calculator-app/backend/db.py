import os
from flask_mysqldb import MySQL
from dotenv import load_dotenv

load_dotenv()


def init_db(app):
    app.config["MYSQL_HOST"] = os.getenv("MYSQL_HOST", "localhost")
    app.config["MYSQL_USER"] = os.getenv("MYSQL_USER", "calc_user")
    app.config["MYSQL_PASSWORD"] = os.getenv("MYSQL_PASSWORD", "securepassword")
    app.config["MYSQL_DB"] = os.getenv("MYSQL_DB", "calc_db")
    app.config["MYSQL_CURSORCLASS"] = "DictCursor"

    mysql = MySQL(app)

    # Create table if it doesn't exist
    with app.app_context():
        try:
            cur = mysql.connection.cursor()
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS calculations (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    operand1 FLOAT NOT NULL,
                    operand2 FLOAT NOT NULL,
                    operation VARCHAR(10) NOT NULL,
                    result FLOAT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """
            )
            mysql.connection.commit()
            cur.close()
            app.logger.info("Database table initialized successfully")
        except Exception as e:
            app.logger.error(f"Error creating table: {str(e)}")

    return mysql
