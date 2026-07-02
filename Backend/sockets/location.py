from flask_socketio import SocketIO, emit, join_room, leave_room
from datetime import datetime

socketio = SocketIO()

def init_socketio(app):
    socketio.init_app(app, cors_allowed_origins="*")
    return socketio

@socketio.on('connect')
def handle_connect():
    print('Client connected')

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

@socketio.on('driver:location_update')
def handle_location_update(data):
    driver_id = data.get('driver_id')
    lat = data.get('lat')
    lng = data.get('lng')
    trip_id = data.get('trip_id')

    print(f'Location update received: driver={driver_id}, lat={lat}, lng={lng}, trip={trip_id}')

    if trip_id:
        print(f'Emitting to room: trip_{trip_id}')
        emit('driver:location', {'lat': lat, 'lng': lng}, to=f'trip_{trip_id}')

@socketio.on('trip:join')
def handle_join_trip(data):
    trip_id = data.get('trip_id')
    if trip_id:
        room = f'trip_{trip_id}'
        join_room(room)
        print(f'Joined room: {room}')
        emit('trip:joined', {'room': room, 'trip_id': trip_id})

@socketio.on('trip:leave')
def handle_leave_trip(data):
    trip_id = data.get('trip_id')
    if trip_id:
        leave_room(f'trip_{trip_id}')

@socketio.on('driver:join_personal_room')
def handle_driver_room(data):
    print('Driver joined personal room')