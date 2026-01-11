import sqlite3
from flask import Flask, request

app = Flask(__name__)

@app.route("/user")
def get_user():
    username = request.args.get('username')
    
    conn = sqlite3.connect('example.db')
    # CÁCH SỬA AN TOÀN: Dùng dấu ? làm placeholder
    # Truyền tham số dưới dạng một tuple (username,)
    query = "SELECT * FROM users WHERE username = ?"
    return conn.execute(query, (username,)).fetchall()

if __name__ == "__main__":
    app.run()