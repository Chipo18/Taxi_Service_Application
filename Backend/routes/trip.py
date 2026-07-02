from flask import Blueprint, request, jsonify
from models.trip import Trip
from models.driver import Driver
from models.pricing import Pricing
from models import db
from datetime import datetime
from utils.matching import find_nearest_driver, calculate_distance
from utils.pricing import estimate_fare
from flask_jwt_extended import jwt_required, get_jwt_identity
from sockets.location import socketio

trip_bp = Blueprint('trip', __name__)

@trip_bp.route('/book', methods=['POST'])
def book_trip():
    data = request.get_json()

    # Find nearest available verified driver
    driver = find_nearest_driver(
        data['pickup_lat'], 
        data['pickup_lng']
    )

    # Fallback to any available driver if none nearby
    if not driver:
        driver = Driver.query.filter_by(is_available=True).first()
    if not driver:
        return jsonify({"message": "No drivers available"}), 404

    # Calculate distance and fare
    distance_km = calculate_distance(
        data['pickup_lat'], data['pickup_lng'],
        data['dropoff_lat'], data['dropoff_lng']
    )
    fare_info = estimate_fare(distance_km)

    new_trip = Trip(
        user_id=data['user_id'],
        driver_id=driver.id,
        pickup_lat=data['pickup_lat'],
        pickup_lng=data['pickup_lng'],
        pickup_address=data.get('pickup_address'),
        dropoff_lat=data['dropoff_lat'],
        dropoff_lng=data['dropoff_lng'],
        dropoff_address=data.get('dropoff_address'),
        distance_km=round(distance_km, 2),
        estimated_price=fare_info['estimated_price'],
        status='assigned'
    )

    driver.is_available = False
    db.session.add(new_trip)
    db.session.commit()

    return jsonify({
        "message": "Trip booked successfully",
        "trip_id": new_trip.id,
        "driver_id": driver.id,
        "distance_km": round(distance_km, 2),
        "estimated_price": fare_info['estimated_price'],
        "is_night_rate": fare_info['is_night_rate']
    }), 201

@trip_bp.route('/user/<int:user_id>', methods=['GET'])
def get_user_trips(user_id):
    trips = Trip.query.filter_by(user_id=user_id).all()
    result = [{
        "id": t.id,
        "driver_id": t.driver_id,
        "pickup_address": t.pickup_address,
        "dropoff_address": t.dropoff_address,
        "status": t.status,
        "distance_km": t.distance_km,
        "estimated_price": t.estimated_price,
        "final_price": t.final_price,
        "requested_at": t.requested_at.isoformat() if t.requested_at else None
    } for t in trips]
    return jsonify(result), 200

@trip_bp.route('/active', methods=['GET'])
@jwt_required()
def get_active_trips():
    trips = Trip.query.filter(
        Trip.status.in_(['pending', 'assigned', 'accepted', 'in_progress'])
    ).all()
    result = [{
        "id": t.id,
        "driver_id": t.driver_id,
        "pickup_address": t.pickup_address,
        "dropoff_address": t.dropoff_address,
        "status": t.status,
        "distance_km": t.distance_km,
        "estimated_price": t.estimated_price,
        "requested_at": t.requested_at.isoformat() if t.requested_at else None
    } for t in trips]
    return jsonify(result), 200

@trip_bp.route('/accept/<int:trip_id>', methods=['POST'])
@jwt_required()
def accept_trip(trip_id):
    user_id = get_jwt_identity()
    trip = Trip.query.get_or_404(trip_id)
    driver = Driver.query.filter_by(user_id=int(user_id)).first()

    if not driver:
        return jsonify({'message': 'Driver not found'}), 404
    if trip.status not in ('pending', 'assigned'):
        return jsonify({'message': 'Trip is no longer available'}), 409

    trip.driver_id = driver.id
    trip.status = 'accepted'
    trip.accepted_at = datetime.utcnow()
    db.session.commit()

    # Notify passenger via WebSocket
    socketio.emit('trip:status_update', {
        'trip_id': trip_id,
        'status': 'accepted'
    }, to=f'trip_{trip_id}')

    return jsonify({'message': 'Trip accepted', 'trip': {
        'id': trip.id, 'status': trip.status
    }}), 200

@trip_bp.route('/start/<int:trip_id>', methods=['POST'])
@jwt_required()
def start_trip(trip_id):
    user_id = get_jwt_identity()
    trip = Trip.query.get_or_404(trip_id)
    driver = Driver.query.filter_by(user_id=int(user_id)).first()

    if not driver or trip.driver_id != driver.id:
        return jsonify({'message': 'Unauthorized'}), 403
    if trip.status != 'accepted':
        return jsonify({'message': 'Trip must be accepted before starting'}), 409

    trip.status = 'in_progress'
    trip.started_at = datetime.utcnow()
    db.session.commit()

    socketio.emit('trip:status_update', {'trip_id': trip_id, 'status': 'in_progress'}, to=f'trip_{trip_id}')

    return jsonify({'message': 'Trip started', 'trip': {
        'id': trip.id, 'status': trip.status
    }}), 200

@trip_bp.route('/complete/<int:trip_id>', methods=['POST'])
@jwt_required()
def complete_trip(trip_id):
    user_id = get_jwt_identity()
    trip = Trip.query.get_or_404(trip_id)
    driver = Driver.query.filter_by(user_id=int(user_id)).first()

    if not driver or trip.driver_id != driver.id:
        return jsonify({'message': 'Unauthorized'}), 403
    if trip.status != 'in_progress':
        return jsonify({'message': 'Trip is not in progress'}), 409

    trip.status = 'completed'
    trip.completed_at = datetime.utcnow()
    trip.final_price = trip.estimated_price
    driver.is_available = True
    db.session.commit()

    socketio.emit('trip:status_update', {'trip_id': trip_id, 'status': 'completed'}, to=f'trip_{trip_id}')

    return jsonify({'message': 'Trip completed', 'trip': {
        'id': trip.id, 'status': trip.status
    }}), 200

@trip_bp.route('/cancel/<int:trip_id>', methods=['POST'])
@jwt_required()
def cancel_trip(trip_id):
    data = request.get_json() or {}
    trip = Trip.query.get_or_404(trip_id)

    if trip.status in ('completed', 'cancelled'):
        return jsonify({'message': 'Trip cannot be cancelled'}), 409

    trip.status = 'cancelled'
    trip.cancel_reason = data.get('reason')

    if trip.driver_id:
        driver = Driver.query.get(trip.driver_id)
        if driver:
            driver.is_available = True

    db.session.commit()
    return jsonify({'message': 'Trip cancelled'}), 200

@trip_bp.route('/driver/history', methods=['GET'])
@jwt_required()
def get_driver_trips():
    user_id = get_jwt_identity()
    driver = Driver.query.filter_by(user_id=int(user_id)).first()
    if not driver:
        return jsonify([]), 200
    
    trips = Trip.query.filter_by(driver_id=driver.id).order_by(Trip.requested_at.desc()).all()
    result = [{
        "id": t.id,
        "driver_id": t.driver_id,
        "pickup_address": t.pickup_address,
        "dropoff_address": t.dropoff_address,
        "status": t.status,
        "distance_km": t.distance_km,
        "estimated_price": t.estimated_price,
        "final_price": t.final_price,
        "requested_at": t.requested_at.isoformat() if t.requested_at else None
    } for t in trips]
    return jsonify(result), 200