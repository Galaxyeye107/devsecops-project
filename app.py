import sqlite3
from flask import Flask, request

# ❌ GITLEAKS: Hardcoded secret (API key giả để test)
AWS_SECRET_ACCESS_KEY = "AKIA1234567890FAKEKEY"
DB_PASSWORD = "SuperSecretPassword123!"

app = Flask(__name__)

@app.route("/user")
def get_user():
    # ❌ SEMGREP: User input không validate
    username = request.args.get("username")

    conn = sqlite3.connect("example.db")
    cursor = conn.cursor()

    # ❌ SEMGREP: SQL Injection (string interpolation)
    query = f"SELECT * FROM users WHERE username = '{username}'"
    cursor.execute(query)

    result = cursor.fetchall()
    conn.close()

    return {"data": result}

if __name__ == "__main__":
    # ❌ SEMGREP: Flask debug mode enabled
    app.run(debug=True)
