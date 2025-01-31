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
DEFAULT_PIN = "1234"  # Set your desired default pin here

# MongoDB setup
client = MongoClient("mongodb://localhost:27017/")
db = client['gpsx']
users_collection = db['users']
data_collection = db['data']

def is_valid_number(number):
    """Check if the phone number is valid."""
    pattern = r'^\d{10}$'
    return bool(re.match(pattern, number))

def is_valid_email(email):
    """Check if the email format is valid."""
    return '@' in email and '.' in email

# User Registration
@app.route('/register', methods=['POST'])
def register():
    """Register a new user."""
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
        return jsonify({'error': 'Number already registered'}), 400

    hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')
    users_collection.insert_one({'name': name, 'email': email, 'number': number, 'password': hashed_password})
    return jsonify({'message': 'User registered successfully'}), 201

# User Login
@app.route('/login', methods=['POST'])
def login():
    """Login the user and return a JWT token."""
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
    """Validate the JWT token."""
    return jsonify({'message': 'Token is valid'}), 200

# Protected Route to fetch logs
@app.route('/logs', methods=['GET'])
@jwt_required()
def logs():
    """Fetch the GPS logs for the logged-in user."""
    user_email = get_jwt_identity()
    user_logs = data_collection.find({'email': user_email})
    logs = [{'latitude': log['latitude'], 'longitude': log['longitude'], 'timestamp': log['timestamp']} for log in user_logs]
    return jsonify({'logs': logs}), 200

# Add Data Route for GPS logs
@app.route('/add_data', methods=['POST'])
@jwt_required()
def add_data():
    """Add GPS coordinates and status for the user."""
    user_email = get_jwt_identity()
    data = request.get_json()
    latitude = data.get('latitude')
    longitude = data.get('longitude')
    battery = data.get('battery', 0)
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

# Fetch latest GPS Status
@app.route('/fetch_status', methods=['GET'])
@jwt_required()
def fetch_status():
    """Fetch the latest GPS data and status for the logged-in user."""
    user_email = get_jwt_identity()
    latest_data = data_collection.find_one(
        {'email': user_email}, 
        sort=[('timestamp', -1)]
    )
    
    if not latest_data:
        return jsonify({'error': 'No data found for this user'}), 404

    return jsonify({
        'latitude': latest_data.get('latitude'),
        'longitude': latest_data.get('longitude'),
        'battery': latest_data.get('battery'),
        'status': latest_data.get('status'),
        'timestamp': latest_data.get('timestamp')
    }), 200

# Toggle Anti-Theft Mode
@app.route('/toggle_anti_theft', methods=['POST'])
@jwt_required()
def toggle_anti_theft():
    """Toggle the anti-theft mode for the user."""
    user_email = get_jwt_identity()
    data = request.get_json()
    anti_theft = data.get('anti_theft')  # Expecting True/False from the request

    if anti_theft is None:
        return jsonify({'error': 'Missing anti_theft value'}), 400

    result = users_collection.update_one(
        {'email': user_email}, 
        {'$set': {'anti_theft': anti_theft}},
        upsert=True  # Creates a document if one doesn't already exist
    )

    if result.modified_count > 0 or result.upserted_id:
        return jsonify({'message': 'Anti-theft mode updated successfully'}), 200
    else:
        return jsonify({'message': 'No changes made'}), 304

# Get Anti-Theft Mode Status
@app.route('/get_anti_theft', methods=['GET'])
@jwt_required()
def get_anti_theft():
    """Get the current status of anti-theft mode."""
    user_email = get_jwt_identity()

    user_data = users_collection.find_one({'email': user_email}, {'_id': 0, 'anti_theft': 1})
    if not user_data or 'anti_theft' not in user_data:
        return jsonify({'anti_theft': False}), 200
    
    return jsonify({'anti_theft': user_data['anti_theft']}), 200

@app.route('/update_device_id', methods=['POST'])
@jwt_required()
def update_device_id():
    """Update the device ID for the user."""
    user_email = get_jwt_identity()
    data = request.get_json()
    device_id = data.get('device_id')

    if not device_id:
        return jsonify({'error': 'Device ID is required'}), 400

    result = users_collection.update_one(
        {'email': user_email},
        {'$set': {'device_id': device_id}},
        upsert=True
    )

    if result.modified_count > 0 or result.upserted_id:
        return jsonify({'message': 'Device ID updated successfully'}), 200
    else:
        return jsonify({'message': 'No changes made'}), 304
# Update Vehicle Number
@app.route('/update_pin', methods=['POST'])
@jwt_required()
def update_pin():
    """Update the device pin for the user."""
    user_email = get_jwt_identity()
    data = request.get_json()
    device_id = data.get('device_id')
    new_pin = data.get('pin')

    if not device_id or not new_pin:
        return jsonify({'error': 'Device ID and pin are required'}), 400

    # Verify that the device ID corresponds to the user's email
    user = users_collection.find_one({'email': user_email})
    if not user or user.get('device_id') != device_id:
        return jsonify({'error': 'Invalid device ID for this user'}), 403

    # Update the user's pin in the database
    result = users_collection.update_one(
        {'email': user_email},
        {'$set': {'pin': new_pin}},
        upsert=True
    )

    if result.modified_count > 0 or result.upserted_id:
        return jsonify({'message': 'Pin updated successfully'}), 200
    else:
        return jsonify({'message': 'No changes made'}), 304
@app.route('/update_vehicle_number', methods=['POST'])
@jwt_required()
def update_vehicle_number():
    """Update the vehicle number for the user."""
    user_email = get_jwt_identity()
    data = request.get_json()
    vehicle_number = data.get('vehicle_number')
    
    if not vehicle_number:
        return jsonify({'error': 'Vehicle number is required'}), 400
    
    result = users_collection.update_one(
        {'email': user_email},
        {'$set': {'vehicle_number': vehicle_number}},
        upsert=True
    )
    
    if result.modified_count > 0 or result.upserted_id:
        return jsonify({'message': 'Vehicle number updated successfully'}), 200
    else:
        return jsonify({'message': 'No changes made'}), 304
# Fetch Vehicle Number
@app.route('/get_vehicle_number', methods=['GET'])
@jwt_required()
def get_vehicle_number():
    """Get the stored vehicle number."""
    user_email = get_jwt_identity()
    user_data = users_collection.find_one({'email': user_email}, {'_id': 0, 'vehicle_number': 1})
    
    if not user_data or 'vehicle_number' not in user_data:
        return jsonify({'vehicle_number': None}), 200
    
    return jsonify({'vehicle_number': user_data['vehicle_number']}), 200

# Fetch device id
@app.route('/get_device_id', methods=['GET'])
@jwt_required()
def get_device_id():
    """Get the stored device ID."""
    user_email = get_jwt_identity()
    user_data = users_collection.find_one({'email': user_email}, {'_id': 0, 'device_id': 1})

    if not user_data or 'device_id' not in user_data:
        return jsonify({'device_id': None}), 200

    return jsonify({'device_id': user_data['device_id']}), 200


if __name__ == '__main__':
    app.run(debug=True)
