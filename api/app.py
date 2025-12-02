from flask import Flask
from pymongo import MongoClient
import os

app = Flask(__name__)

print("Acctually I am preety cool API")

client = MongoClient(os.getenv("MONGODB_URI", "mongodb://localhost:27017"))

@app.route('/health')
def health():
    try:
        client.admin.command('ping')
        return {"status": "ok", "database": "up"}
    except:
        return {"status": "ok", "database": "down"}, 503

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=os.getenv("PORT", 5000))