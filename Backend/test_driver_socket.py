import socketio
import time

sio = socketio.Client()

@sio.on('connect')
def on_connect():
    print('Driver connected!')
    # Join driver personal room
    sio.emit('driver:join_personal_room', {'token': 'test'})
    
    # Simulate driver moving - send location updates
    for i in range(10):
        lat = 35.1200 + (i * 0.0010)
        lng = 32.8470 + (i * 0.0010)
        print(f'Sending location: {lat}, {lng}')
        sio.emit('driver:location_update', {
            'driver_id': 1,
            'lat': lat,
            'lng': lng,
            'trip_id': 56
        })
        time.sleep(3)

sio.connect('http://127.0.0.1:5000')
sio.wait()