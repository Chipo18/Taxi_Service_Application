import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  String _username = '';
  bool _isAvailable = false;
  bool _isVerified = true;
  bool _isRejected = false;
  bool _isLoading = false;
  List<dynamic> _activeTrips = [];
  List<dynamic> _tripHistory = [];
  bool _isLoadingTrips = false;
  bool _isLoadingHistory = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _checkVerificationStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
    });
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final result = await ApiService.getDriverProfile();
      setState(() {
        _isVerified = result['is_verified'] ?? false;
        _isAvailable = result['is_available'] ?? false;
        _isRejected = result['is_rejected'] ?? false;
      });
      if (_isVerified) {
        _loadActiveTrips();
        _loadTripHistory();
      }
    } catch (e) {
      // Driver record not found — account was rejected
      setState(() {
        _isVerified = false;
        _isRejected = true;
      });
    }
  }

  Future<void> _loadActiveTrips() async {
    setState(() => _isLoadingTrips = true);
    try {
      final trips = await ApiService.getActiveTrips();
      setState(() => _activeTrips = trips);
    } catch (e) {
      // handle error
    } finally {
      setState(() => _isLoadingTrips = false);
    }
  }

  Future<void> _loadTripHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final trips = await ApiService.getDriverTrips();
      setState(() => _tripHistory = trips
          .where((t) =>
              t['status'] == 'completed' || t['status'] == 'cancelled')
          .toList());
    } catch (e) {
      // handle error
    } finally {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _toggleAvailability() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.toggleDriverStatus(!_isAvailable);
      if (result.containsKey('is_available')) {
        setState(() => _isAvailable = result['is_available']);
      } else if (result.containsKey('message')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTripStatus(int tripId, String action) async {
    try {
      Map<String, dynamic> result;
      if (action == 'accept') {
        result = await ApiService.acceptTrip(tripId);
      } else if (action == 'start') {
        result = await ApiService.startTrip(tripId);
      } else {
        result = await ApiService.completeTrip(tripId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Updated')),
        );
        _loadActiveTrips();
        _loadTripHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update trip')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await ApiService.removeToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusCard() {
    if (_isRejected) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel, size: 40, color: Colors.red),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Rejected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your driver application was rejected.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (!_isVerified) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.hourglass_empty, size: 40, color: Colors.orange),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Pending Verification',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'An admin needs to verify your account before you can accept trips.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _isAvailable ? Icons.check_circle : Icons.cancel,
            size: 40,
            color: _isAvailable ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $_username!',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  _isAvailable ? 'You are Online' : 'You are Offline',
                  style: TextStyle(
                    color: _isAvailable ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _toggleAvailability,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAvailable ? Colors.red : Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _isAvailable ? 'Go Offline' : 'Go Online',
                    style: const TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkVerificationStatus,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active Trips'),
            Tab(text: 'Trip History'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatusCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _isLoadingTrips
                    ? const Center(child: CircularProgressIndicator())
                    : _activeTrips.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_taxi,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('No active trips',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _activeTrips.length,
                            itemBuilder: (context, index) {
                              final trip = _activeTrips[index];
                              return _buildTripCard(trip, showActions: true);
                            },
                          ),
                _isLoadingHistory
                    ? const Center(child: CircularProgressIndicator())
                    : _tripHistory.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('No trip history',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _tripHistory.length,
                            itemBuilder: (context, index) {
                              final trip = _tripHistory[index];
                              return _buildTripCard(trip, showActions: false);
                            },
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip,
      {required bool showActions}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trip #${trip['id']}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(trip['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trip['status'],
                  style: TextStyle(
                    color: _statusColor(trip['status']),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.green, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trip['pickup_address'] ?? 'Unknown pickup',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trip['dropoff_address'] ?? 'Unknown dropoff',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${trip['estimated_price'] ?? 0} TL • ${trip['distance_km'] ?? 0} km',
            style: const TextStyle(
                color: Colors.amber, fontWeight: FontWeight.bold),
          ),
          if (showActions) ...[
            const SizedBox(height: 12),
            if (trip['status'] == 'pending' || trip['status'] == 'assigned')
              ElevatedButton(
                onPressed: () => _updateTripStatus(trip['id'], 'accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Accept Trip',
                    style: TextStyle(color: Colors.white)),
              ),
            if (trip['status'] == 'accepted')
              ElevatedButton(
                onPressed: () => _updateTripStatus(trip['id'], 'start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Start Trip',
                    style: TextStyle(color: Colors.white)),
              ),
            if (trip['status'] == 'in_progress')
              ElevatedButton(
                onPressed: () => _updateTripStatus(trip['id'], 'complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Complete Trip',
                    style: TextStyle(color: Colors.black)),
              ),
          ],
        ],
      ),
    );
  }
}