import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double estimatedPrice;
  final int tripId;

  const MapScreen({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    this.pickupAddress,
    this.dropoffAddress,
    required this.estimatedPrice,
    required this.tripId,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  IO.Socket? _socket;
  String _tripStatus = 'Waiting for driver...';
  bool _driverFound = false;

  @override
  void initState() {
    super.initState();
    _setMarkers();
    _connectSocket();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _mapController?.dispose();
    super.dispose();
  }

  void _setMarkers() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(widget.pickupLat, widget.pickupLng),
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: widget.pickupAddress ?? 'Pickup location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      _markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(widget.dropoffLat, widget.dropoffLng),
          infoWindow: InfoWindow(
            title: 'Dropoff',
            snippet: widget.dropoffAddress ?? 'Dropoff location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  Future<void> _connectSocket() async {
    // Disconnect any existing socket first
    _socket?.disconnect();
    _socket = null;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // Connect to the backend WebSocket
    _socket = IO.io(
      'http://192.168.8.7:5000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      print('Socket connected');
      // Join the trip room to receive updates
      _socket!.emit('trip:join', {'token': token, 'trip_id': widget.tripId});
    });

    // Listen for driver location updates
    _socket!.on('driver:location', (data) {
      final lat = data['lat'];
      final lng = data['lng'];
      if (lat != null && lng != null) {
        _updateDriverMarker(lat.toDouble(), lng.toDouble());
      }
    });

    // Listen for trip status updates
    _socket!.on('trip:status_update', (data) {
      final status = data['status'];
      String message = '';
      switch (status) {
        case 'accepted':
          message = 'Driver accepted your trip!';
          break;
        case 'in_progress':
          message = 'Your trip has started!';
          break;
        case 'completed':
          message = 'Trip completed!';
          break;
        case 'cancelled':
          message = 'Trip was cancelled';
          break;
        default:
          message = 'Status: $status';
      }
      setState(() => _tripStatus = message);

      // Show a snackbar notification for important status changes
      if (status == 'accepted' || status == 'in_progress' || status == 'completed') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: status == 'completed' ? Colors.green : Colors.amber,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Navigate back to home when trip is completed
      if (status == 'completed' && mounted) {
        Future.delayed(const Duration(seconds: 3), () {
          _socket?.disconnect();
          Navigator.of(context).popUntil((route) => route.isFirst);
        });
      }
    });

    _socket!.onDisconnect((_) => print('Socket disconnected'));
    _socket!.onError((err) => print('Socket error: $err'));
  }

  void _updateDriverMarker(double lat, double lng) {
    setState(() {
      _driverFound = true;
      _tripStatus = 'Driver is on the way!';
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(lat, lng),
          infoWindow: const InfoWindow(title: 'Your Driver'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(lat, lng)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('Track Your Ride'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.pickupLat, widget.pickupLng),
              zoom: 14,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trip in Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.estimatedPrice} TL',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        _driverFound ? Icons.local_taxi : Icons.hourglass_empty,
                        color: _driverFound ? Colors.blue : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _tripStatus,
                        style: TextStyle(
                          color: _driverFound ? Colors.blue : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.pickupAddress ?? 'Pickup location',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.dropoffAddress ?? 'Dropoff location',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // Show confirmation dialog
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Cancel Trip'),
                          content: const Text('Are you sure you want to cancel this trip?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Yes, Cancel',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          final result = await ApiService.cancelTrip(widget.tripId, 'Cancelled by passenger');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['message'] ?? 'Trip cancelled')),
                            );
                            _socket?.disconnect();
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Trip cancelled')),
                            );
                            _socket?.disconnect();
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel Trip',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}