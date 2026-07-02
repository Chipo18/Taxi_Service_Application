from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.driver import Driver
from models import db

driver_bp = Blueprint('driver', __name__)

@driver_bp.route('/', methods=['GET'])
def get_drivers():
    drivers = Driver.query.all()
    result = [
        {
            "id": d.id,
            "name": f"Driver {d.id}",
            "car": d.car_details,
            "available": d.is_available,
            "latitude": d.latitude,
            "longitude": d.longitude
        }
        for d in drivers
    ]
    return jsonify(result), 200

@driver_bp.route('/', methods=['POST'])
def add_driver():
    data = request.get_json()

    if 'user_id' not in data:
        return jsonify({"error": "user_id is required"}), 400

    new_driver = Driver(
        user_id=data['user_id'],
        car_details=data.get('car'),
        is_available=True
    )

    db.session.add(new_driver)
    db.session.commit()
    return jsonify({
        "message": "Driver added successfully",
        "driver": {
            "id": new_driver.id,
            "name": f"Driver {new_driver.id}",
            "car": new_driver.car_details,
            "available": new_driver.is_available
        }
    }), 201

@driver_bp.route('/<int:driver_id>', methods=['PUT'])
def update_driver(driver_id):
    driver = Driver.query.get(driver_id)
    if not driver:
        return jsonify({"message": "Driver not found"}), 404
    data = request.get_json()
    driver.is_available = data.get('available', driver.is_available)
    db.session.commit()
    return jsonify({"message": "Driver updated successfully"}), 200

@driver_bp.route('/status', methods=['POST'])
@jwt_required()
def toggle_status():
    user_id = get_jwt_identity()
    driver = Driver.query.filter_by(user_id=int(user_id)).first()
    if not driver:
        return jsonify({'message': 'Driver not found'}), 404
    if not driver.is_verified:
        return jsonify({'message': 'Your account is pending admin verification'}), 403

    data = request.get_json()
    driver.is_available = data.get('is_available', not driver.is_available)
    db.session.commit()

    return jsonify({'is_available': driver.is_available}), 200

@driver_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_profile():
    user_id = get_jwt_identity()
    driver = Driver.query.filter_by(user_id=int(user_id)).first()
    if not driver:
        return jsonify({
            'is_verified': False,
            'is_available': False,
            'is_rejected': True,
            'message': 'Your account has been rejected by an admin'
        }), 200
    return jsonify({
        'id': driver.id,
        'is_verified': driver.is_verified,
        'is_available': driver.is_available,
        'is_rejected': False,
        'car_details': driver.car_details,
    }), 200