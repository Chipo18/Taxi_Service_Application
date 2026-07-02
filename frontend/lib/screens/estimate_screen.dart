import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'map_screen.dart';
import 'dart:math';

class EstimateScreen extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String pickupAddress;
  final String dropoffAddress;
  final int userId;

  const EstimateScreen({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.userId,
  });

  @override
  State<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends State<EstimateScreen> {
  Map<String, dynamic>? _estimate;
  bool _isLoading = true;
  bool _isBooking = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _getEstimate();
  }

  Future<void> _getEstimate() async {
    try {
      // Calculate distance using Haversine formula
      final distance = _calculateDistance(
        widget.pickupLat,
        widget.pickupLng,
        widget.dropoffLat,
        widget.dropoffLng,
      );

      final result = await ApiService.getEstimate(
        pickupLat: widget.pickupLat,
        pickupLng: widget.pickupLng,
        dropoffLat: widget.dropoffLat,
        dropoffLng: widget.dropoffLng,
        distanceKm: distance,
        durationMin: (distance * 3).round(), // estimate 3 min per km
      );

      setState(() {
        _estimate = result;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not get estimate';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double R = 6371;
    final double dLat = (lat2 - lat1) * pi / 180;
    final double dLng = (lng2 - lng1) * pi / 180;
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLng / 2) * sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<void> _confirmBooking() async {
    setState(() => _isBooking = true);
    try {
      final result = await ApiService.bookTrip({
        'user_id': widget.userId,
        'pickup_lat': widget.pickupLat,
        'pickup_lng': widget.pickupLng,
        'dropoff_lat': widget.dropoffLat,
        'dropoff_lng': widget.dropoffLng,
        'pickup_address': widget.pickupAddress,
        'dropoff_address': widget.dropoffAddress,
      });

      if (result.containsKey('trip_id')) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MapScreen(
                pickupLat: widget.pickupLat,
                pickupLng: widget.pickupLng,
                dropoffLat: widget.dropoffLat,
                dropoffLng: widget.dropoffLng,
                pickupAddress: widget.pickupAddress,
                dropoffAddress: widget.dropoffAddress,
                estimatedPrice: result['estimated_price'],
                tripId: result['trip_id'],
              ),
            ),
          );
        }
      } else {
        setState(() => _error = result['message'] ?? 'Booking failed');
      }
    } catch (e) {
      setState(() => _error = 'Could not connect to server');
    } finally {
      setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('Trip Estimate'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Route info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.pickupAddress,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 9),
                              child: Column(
                                children: [
                                  SizedBox(height: 2),
                                  Icon(Icons.more_vert, color: Colors.grey, size: 16),
                                  SizedBox(height: 2),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.dropoffAddress,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Price card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Estimated Price',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_estimate?['estimated_price'] ?? 0} TL',
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _InfoChip(
                                  icon: Icons.route,
                                  label: '${_estimate?['distance_km'] ?? 0} km',
                                ),
                                _InfoChip(
                                  icon: Icons.access_time,
                                  label: '~${_estimate?['duration_min'] ?? 0} min',
                                ),
                                _InfoChip(
                                  icon: Icons.nights_stay,
                                  label: (_estimate?['is_night_rate'] == true)
                                      ? 'Night Rate'
                                      : 'Day Rate',
                                  color: (_estimate?['is_night_rate'] == true)
                                      ? Colors.indigo
                                      : Colors.green,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Breakdown card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fare Breakdown',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            _BreakdownRow(
                              label: 'Base Fare',
                              value: '${_estimate?['breakdown']?['base_fare'] ?? 20} TL',
                            ),
                            _BreakdownRow(
                              label: 'Distance Charge',
                              value: '${_estimate?['breakdown']?['distance_charge'] ?? 0} TL',
                            ),
                            _BreakdownRow(
                              label: 'Time Charge',
                              value: '${_estimate?['breakdown']?['time_charge'] ?? 0} TL',
                            ),
                            if (_estimate?['is_night_rate'] == true)
                              _BreakdownRow(
                                label: 'Night Surcharge',
                                value: '×${_estimate?['breakdown']?['night_surcharge'] ?? 1.3}',
                                color: Colors.indigo,
                              ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      if (_error.isNotEmpty)
                        Text(
                          _error,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 8),

                      ElevatedButton(
                        onPressed: _isBooking ? null : _confirmBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isBooking
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Confirm Booking',
                                style: TextStyle(fontSize: 16, color: Colors.black),
                              ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BreakdownRow({
    required this.label,
    required this.value,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      ),
    );
  }
}