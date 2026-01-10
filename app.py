import sqlite3
from flask import Flask, request

app = Flask(__name__)

@app.route("/user")
def get_user():
    username = request.args.get('username')
    # LỖI BẢO MẬT: SQL Injection (CWE-89)
    # Nối chuỗi trực tiếp từ input người dùng vào câu truy vấn
    query = "SELECT * FROM users WHERE username = '" + username + "'"
    conn = sqlite3.connect('example.db')
    return conn.execute(query).fetchall()

if __name__ == "__main__":
    app.run()
