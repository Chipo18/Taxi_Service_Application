import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'map_picker_screen.dart';
import 'estimate_screen.dart';

class BookTripScreen extends StatefulWidget {
  const BookTripScreen({super.key});

  @override
  State<BookTripScreen> createState() => _BookTripScreenState();
}

class _BookTripScreenState extends State<BookTripScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  bool _isLoading = false;
  bool _isGettingLocation = false;
  String _message = '';
  double? _pickupLat;
  double? _pickupLng;
  double? _dropoffLat;
  double? _dropoffLng;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _pickupLat = 35.1189;
          _pickupLng = 32.8464;
          _pickupController.text = 'Current Location (Lefke)';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _pickupLat = position.latitude;
        _pickupLng = position.longitude;
        _pickupController.text =
            'Current Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      });
    } catch (e) {
      setState(() {
        _pickupLat = 35.1189;
        _pickupLng = 32.8464;
        _pickupController.text = 'Current Location (Lefke)';
      });
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _bookTrip() async {
    if (_pickupLat == null || _pickupLng == null) {
      setState(() => _message = 'Getting your location, please wait...');
      return;
    }

    if (_dropoffLat == null || _dropoffLng == null) {
      setState(() => _message = 'Please select a dropoff location on the map');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EstimateScreen(
            pickupLat: _pickupLat!,
            pickupLng: _pickupLng!,
            dropoffLat: _dropoffLat!,
            dropoffLng: _dropoffLng!,
            pickupAddress: _pickupController.text,
            dropoffAddress: _dropoffController.text,
            userId: userId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('Book a Ride'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Where are you going?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pickupController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Pickup Location',
                prefixIcon: _isGettingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.my_location, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapPickerScreen(
                      initialLat: _pickupLat ?? 35.1189,
                      initialLng: _pickupLng ?? 32.8464,
                    ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _dropoffLat = result.latitude;
                    _dropoffLng = result.longitude;
                    _dropoffController.text =
                        'Selected (${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)})';
                  });
                }
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: _dropoffController,
                  decoration: InputDecoration(
                    labelText: 'Dropoff Location',
                    prefixIcon:
                        const Icon(Icons.location_on, color: Colors.red),
                    suffixIcon: const Icon(Icons.map, color: Colors.amber),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _message.contains('booked')
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _message.contains('booked')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading || _isGettingLocation ? null : _bookTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Book Ride',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}