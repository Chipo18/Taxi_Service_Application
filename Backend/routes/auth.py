from flask import Blueprint, request, jsonify
from models import db
from models.user import User
from werkzeug.security import generate_password_hash, check_password_hash
from flask_jwt_extended import create_access_token

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()

    username = data.get('username')
    email = data.get('email')
    password = data.get('password')

    if User.query.filter_by(email=email).first():
        return jsonify({'message': 'Email already exists'}), 400

    hashed_password = generate_password_hash(password)

    new_user = User(
        username=username,
        email=email,
        password=hashed_password
    )

    db.session.add(new_user)
    db.session.commit()

    return jsonify({'message': 'User registered successfully'}), 201

@auth_bp.route('/register/driver', methods=['POST'])
def register_driver():
    data = request.get_json()
    from models.driver import Driver

    username = data.get('username')
    email = data.get('email')
    password = data.get('password')
    car = data.get('car')
    license_number = data.get('license_number')

    if not all([username, email, password, car, license_number]):
        return jsonify({'message': 'All fields are required'}), 400

    if User.query.filter_by(email=email).first():
        return jsonify({'message': 'Email already exists'}), 400

    hashed_password = generate_password_hash(password)

    new_user = User(
        username=username,
        email=email,
        password=hashed_password,
        role='driver'
    )
    db.session.add(new_user)
    db.session.flush()

    new_driver = Driver(
        user_id=new_user.id,
        car_details=car,
        is_available=False,
        is_verified=False
    )
    db.session.add(new_driver)
    db.session.commit()

    return jsonify({'message': 'Driver registered successfully'}), 201

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()

    email = data.get('email')
    password = data.get('password')

    user = User.query.filter_by(email=email).first()

    if not user or not check_password_hash(user.password, password):
        return jsonify({'message': 'Invalid email or password'}), 401

    # Generate JWT token
    token = create_access_token(identity=str(user.id))

    return jsonify({
        'message': 'Login successful',
        'token': token,
        'user_id': user.id,
        'username': user.username,
        'role': user.role
    }), 200