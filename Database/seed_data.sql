USE taxi_service_db;

INSERT INTO pricing (zone_name, base_fare, price_per_km, minimum_fare, night_surcharge, is_active)
VALUES
    ('default', 200.0, 100.0, 250.0, 13.0, 1),
    ('Lefke', 200.0, 100.0, 250.0, 13.0, 1),
    ('Guzelyurt', 250.0, 120.0, 300.0, 13.0, 1),
    ('Nicosia', 300.0, 140.0, 350.0, 14.0, 1);