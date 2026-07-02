from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db
from models.user import User
from models.driver import Driver
from models.trip import Trip
from models.pricing import Pricing

admin_bp = Blueprint('admin', __name__)

def admin_required(fn):
    from functools import wraps
    @wraps(fn)
    @jwt_required()
    def wrapper(*args, **kwargs):
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        if not user or user.role != 'admin':
            return jsonify({'message': 'Admin access required'}), 403
        return fn(*args, **kwargs)
    return wrapper

# -- Drivers --
@admin_bp.route('/drivers/pending', methods=['GET'])
@admin_required
def pending_drivers():
    from models.driver import Driver
    drivers = Driver.query.join(User).filter(
        Driver.is_verified == False,
        User.is_active == True
    ).all()
    result = [{'id': d.id, 'user_id': d.user_id, 'car_details': d.car_details} for d in drivers]
    return jsonify(result), 200

@admin_bp.route('/drivers/<int:driver_id>/verify', methods=['POST'])
@admin_required
def verify_driver(driver_id):
    driver = Driver.query.get(driver_id)
    if not driver:
        return jsonify({'message': 'Driver not found'}), 404
    driver.is_verified = True
    db.session.commit()
    return jsonify({'message': 'Driver verified successfully'}), 200

@admin_bp.route('/drivers/<int:driver_id>/reject', methods=['POST'])
@admin_required
def reject_driver(driver_id):
    from models.driver import Driver
    driver = Driver.query.get_or_404(driver_id)
    user = User.query.get(driver.user_id)
    if user:
        user.is_active = False
    # Mark driver as rejected by setting a flag
    driver.is_verified = False
    driver.is_available = False
    db.session.delete(driver)
    db.session.commit()
    return jsonify({'message': 'Driver rejected'}), 200

# -- Trips --
@admin_bp.route('/trips', methods=['GET'])
@admin_required
def all_trips():
    trips = Trip.query.order_by(Trip.requested_at.desc()).all()
    result = [{
        'id': t.id,
        'user_id': t.user_id,
        'driver_id': t.driver_id,
        'status': t.status,
        'distance_km': t.distance_km,
        'estimated_price': t.estimated_price,
        'requested_at': t.requested_at.isoformat() if t.requested_at else None
    } for t in trips]
    return jsonify(result), 200

# -- Users --
@admin_bp.route('/users', methods=['GET'])
@admin_required
def all_users():
    users = User.query.all()
    result = [{'id': u.id, 'username': u.username, 'email': u.email, 'role': u.role} for u in users]
    return jsonify(result), 200

@admin_bp.route('/users/<int:user_id>/deactivate', methods=['POST'])
@admin_required
def deactivate_user(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({'message': 'User not found'}), 404
    user.is_active = False
    db.session.commit()
    return jsonify({'message': 'User deactivated'}), 200