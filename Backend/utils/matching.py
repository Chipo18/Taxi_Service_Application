import math
from models.driver import Driver

def calculate_distance(lat1, lng1, lat2, lng2):
    # Haversine formula 
    R = 6371
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)
    a = math.sin(dphi/2)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

def find_nearest_driver(pickup_lat, pickup_lng, max_radius_km=10.0):
    available_drivers = Driver.query.filter_by(
        is_available=True, 
        is_verified=True
    ).all()

    candidates = []
    for driver in available_drivers:
        if driver.latitude is None or driver.longitude is None:
            continue
        dist = calculate_distance(pickup_lat, pickup_lng, driver.latitude, driver.longitude)
        if dist <= max_radius_km:
            candidates.append((dist, driver))

    if not candidates:
        return None

    # Return the closest driver
    candidates.sort(key=lambda x: x[0])
    return candidates[0][1]

def get_nearby_drivers(pickup_lat, pickup_lng, max_radius_km=10.0):
    available_drivers = Driver.query.filter_by(
        is_available=True,
        is_verified=True
    ).all()

    results = []
    for driver in available_drivers:
        if driver.latitude is None or driver.longitude is None:
            continue
        dist = calculate_distance(pickup_lat, pickup_lng, driver.latitude, driver.longitude)
        if dist <= max_radius_km:
            results.append({
                'driver_id': driver.id,
                'distance_km': round(dist, 2),
                'lat': driver.latitude,
                'lng': driver.longitude
            })

    results.sort(key=lambda x: x['distance_km'])
    return results