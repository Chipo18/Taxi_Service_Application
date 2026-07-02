from . import db

class Pricing(db.Model):
    __tablename__ = 'pricing'

    id = db.Column(db.Integer, primary_key=True)
    zone_name = db.Column(db.String(100), default='default')
    base_fare = db.Column(db.Float, nullable=False, default=20.0)
    price_per_km = db.Column(db.Float, nullable=False, default=10.0)
    minimum_fare = db.Column(db.Float, nullable=False, default=25.0)
    night_surcharge = db.Column(db.Float, default=1.3)
    is_active = db.Column(db.Boolean, default=True)

    def calculate_fare(self, distance_km, is_night=False):
        fare = self.base_fare + (distance_km * self.price_per_km)
        if is_night:
            fare *= self.night_surcharge
        return max(round(fare, 2), self.minimum_fare)

    def __repr__(self):
        return f"<Pricing {self.zone_name}>"