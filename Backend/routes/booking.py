from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from utils.pricing import estimate_fare

booking_bp = Blueprint('booking', __name__)

@booking_bp.route('/estimate', methods=['POST'])
@jwt_required()
def estimate():
    data = request.get_json()
    required = ['pickup_lat', 'pickup_lng', 'dropoff_lat', 'dropoff_lng',
                'distance_km', 'duration_min']
    if not all(k in data for k in required):
        return jsonify({'error': 'Missing required fields'}), 400

    result = estimate_fare(
        distance_km=data['distance_km'],
        duration_min=data['duration_min'],
    )
    return jsonify(result), 200