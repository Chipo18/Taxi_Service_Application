from models.pricing import Pricing
from datetime import datetime

def estimate_fare(distance_km, duration_min=5, zone='default'):
    pricing = Pricing.query.filter_by(zone_name=zone, is_active=True).first()

    current_hour = datetime.utcnow().hour
    is_night = current_hour >= 22 or current_hour < 6

    if not pricing:
        base_fare = 200.0
        price_per_km = 100.0
        minimum_fare = 250.0
        night_surcharge = 13.0 if is_night else 1.0
        fare = (base_fare + (distance_km * price_per_km)) * night_surcharge
        estimated = max(round(fare, 2), minimum_fare)
    else:
        base_fare = pricing.base_fare
        price_per_km = pricing.price_per_km
        minimum_fare = pricing.minimum_fare
        night_surcharge = pricing.night_surcharge if is_night else 1.0
        fare = (base_fare + (distance_km * price_per_km)) * night_surcharge
        estimated = max(round(fare, 2), minimum_fare)

    return {
        'estimated_price': estimated,
        'distance_km': round(distance_km, 2),
        'duration_min': round(duration_min),
        'is_night_rate': is_night,
        'breakdown': {
            'base_fare': base_fare,
            'distance_charge': round(distance_km * price_per_km, 2),
            'time_charge': round(duration_min * 2.0, 2),
            'night_surcharge': night_surcharge,
        },
    }