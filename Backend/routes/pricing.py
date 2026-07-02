from flask import Blueprint, request, jsonify
from models import db
from models.pricing import Pricing

pricing_bp = Blueprint('pricing', __name__)

@pricing_bp.route('/', methods=['GET'])
def get_pricing():
    pricing = Pricing.query.filter_by(is_active=True).all()
    result = [{
        'id': p.id,
        'zone_name': p.zone_name,
        'base_fare': p.base_fare,
        'price_per_km': p.price_per_km,
        'minimum_fare': p.minimum_fare,
        'night_surcharge': p.night_surcharge
    } for p in pricing]
    return jsonify(result), 200

@pricing_bp.route('/', methods=['POST'])
def create_pricing():
    data = request.get_json()

    new_pricing = Pricing(
        zone_name=data.get('zone_name', 'default'),
        base_fare=data['base_fare'],
        price_per_km=data['price_per_km'],
        minimum_fare=data['minimum_fare'],
        night_surcharge=data.get('night_surcharge', 1.3)
    )

    db.session.add(new_pricing)
    db.session.commit()

    return jsonify({'message': 'Pricing created successfully'}), 201

@pricing_bp.route('/<int:pricing_id>', methods=['PUT'])
def update_pricing(pricing_id):
    pricing = Pricing.query.get(pricing_id)
    if not pricing:
        return jsonify({'message': 'Pricing not found'}), 404

    data = request.get_json()
    pricing.base_fare = data.get('base_fare', pricing.base_fare)
    pricing.price_per_km = data.get('price_per_km', pricing.price_per_km)
    pricing.minimum_fare = data.get('minimum_fare', pricing.minimum_fare)
    pricing.night_surcharge = data.get('night_surcharge', pricing.night_surcharge)

    db.session.commit()
    return jsonify({'message': 'Pricing updated successfully'}), 200