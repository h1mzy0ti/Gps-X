from flask import Flask, request, jsonify
from flask_jwt_extended import (
    JWTManager, create_access_token, jwt_required, get_jwt_identity
)
from flask_bcrypt import Bcrypt
from pymongo import MongoClient
from datetime import datetime, timedelta
import secrets
import re
from flask_cors import CORS

app = Flask(__name__)
app.config['JWT_SECRET_KEY'] = secrets.token_hex(32)  # Secure key
jwt = JWTManager(app)
bcrypt = Bcrypt(app)
CORS(app)

# MongoDB setup
client = MongoClient("mongodb://localhost:27017/")
db = client['gpsx']
users_collection = db['users']
data_collection = db['data']

def is_valid_number(number):
    pattern = r'^\d{10}$'
    
    # Check if the phone number matches the pattern
    if re.match(pattern, number):
        return True
    return False
def is_valid_email(email):
    return '@' in email and '.' in email

# User Registration
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    number = data.get('number')
    password = data.get('password')

    if not name or not email or not password:
        return jsonify({'error': 'All fields are required'}), 400

    if not is_valid_email(email):
        return jsonify({'error': 'Invalid email format'}), 400

    if users_collection.find_one({'email': email}):
        return jsonify({'error': 'Email already exists'}), 400

    if not is_valid_number(number):
        return jsonify({'error': 'Invalid phone number format'}), 400

    if users_collection.find_one({'number': number}):
        return jsonify({'error': 'number already registered'}), 400

    hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')
    users_collection.insert_one({'name': name, 'email': email, 'number':  'number', 'password': hashed_password})
    return jsonify({'message': 'User registered successfully'}), 201

# User Login
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({'error': 'Email and password are required'}), 400

    user = users_collection.find_one({'email': email})
    if not user or not bcrypt.check_password_hash(user['password'], password):
        return jsonify({'error': 'Invalid email or password'}), 401

    access_token = create_access_token(identity=user['email'], expires_delta=timedelta(days=7))
    return jsonify({'token': access_token}), 200

# Token Validation Route
@app.route('/validate_token', methods=['GET'])
@jwt_required()
def validate_token():
    return jsonify({'message': 'Token is valid'}), 200

# Protected Route
@app.route('/logs', methods=['GET'])
@jwt_required()
def logs():
    user_email = get_jwt_identity()
    user_logs = data_collection.find({'email': user_email})
    logs = [{'latitude': log['latitude'], 'longitude': log['longitude'], 'timestamp': log['timestamp']} for log in user_logs]
    return jsonify({'logs': logs}), 200

# Add Data
@app.route('/add_data', methods=['POST'])
@jwt_required()
def add_data():
    user_email = get_jwt_identity()
    data = request.get_json()
    latitude = data.get('latitude')
    longitude = data.get('longitude')
    battery = data.get('battery')
    status = data.get('status')

    if not latitude or not longitude or not battery or not status:
        return jsonify({'error': 'Missing fields in request'}), 400

    data_collection.insert_one({
        'email': user_email,
        'latitude': latitude,
        'longitude': longitude,
        'battery': battery,
        'status': status,
        'timestamp': datetime.utcnow()
    })
    return jsonify({'message': 'Data logged successfully'}), 201

if __name__ == '__main__':
    app.run(debug=True)
