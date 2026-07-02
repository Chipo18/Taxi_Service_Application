from flask import Flask, jsonify
from flask_jwt_extended import JWTManager
from models import db
from models.user import User
from models.driver import Driver
from models.trip import Trip
from models.pricing import Pricing
from routes.auth import auth_bp
from routes.driver import driver_bp
from routes.trip import trip_bp
from routes.pricing import pricing_bp
from routes.admin import admin_bp
from routes.booking import booking_bp
from sockets.location import init_socketio

app = Flask(__name__)

app.config.from_object('config.Config')

db.init_app(app)
jwt = JWTManager(app)
socketio = init_socketio(app)

app.register_blueprint(auth_bp, url_prefix='/auth')
app.register_blueprint(driver_bp, url_prefix='/drivers')
app.register_blueprint(trip_bp, url_prefix='/trips')
app.register_blueprint(pricing_bp, url_prefix='/pricing')
app.register_blueprint(admin_bp, url_prefix='/admin')
app.register_blueprint(booking_bp, url_prefix='/booking')
#with app.app_context():
#    db.drop_all()
#    db.create_all()

@app.route('/')
def test():
    return jsonify({'message': 'Backend is working!'})

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)