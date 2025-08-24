class CalculationModel:
    @staticmethod
    def create(mysql, operand1, operand2, operation, result):
        # Validate operation type to prevent SQLi
        valid_operations = {"add", "subtract", "multiply", "divide"}
        if operation not in valid_operations:
            raise ValueError("Invalid operation type")

        cur = mysql.connection.cursor()
        cur.execute(
            "INSERT INTO calculations (operand1, operand2, operation, result) "
            "VALUES (%s, %s, %s, %s)",
            (operand1, operand2, operation, result),
        )
        mysql.connection.commit()
        cur.close()

    @staticmethod
    def get_history(mysql, limit=10):
        # Validate limit to prevent SQLi
        try:
            limit = int(limit)
            if limit <= 0 or limit > 100:
                limit = 10
        except (TypeError, ValueError):
            limit = 10

        cur = mysql.connection.cursor()
        cur.execute(
            "SELECT operand1, operand2, operation, result, created_at "
            "FROM calculations "
            "ORDER BY created_at DESC "
            "LIMIT %s",
            (limit,),
        )
        history = cur.fetchall()
        cur.close()
        return history
