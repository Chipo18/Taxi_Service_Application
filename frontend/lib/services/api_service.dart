import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.8.7:5000';

  // Save token to local storage
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Get token from local storage
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Remove token on logout
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  // Register
  static Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  // Book a trip
  static Future<Map<String, dynamic>> bookTrip(Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/trips/book'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // Get trip history
  static Future<List<dynamic>> getTripHistory(int userId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/trips/user/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  // Get pricing
  static Future<List<dynamic>> getPricing() async {
    final response = await http.get(Uri.parse('$baseUrl/pricing/'));
    return jsonDecode(response.body);
  }

  // Toggle driver availability
  static Future<Map<String, dynamic>> toggleDriverStatus(bool isAvailable) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/drivers/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'is_available': isAvailable}),
    );
    return jsonDecode(response.body);
  }
  // Get all users (admin only)
  static Future<List<dynamic>> getAdminUsers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  // Get all trips (admin only)
  static Future<List<dynamic>> getAdminTrips() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/trips'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  // Get all available drivers
  static Future<List<dynamic>> getDrivers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/drivers/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  // Cancel a trip
  static Future<Map<String, dynamic>> cancelTrip(int tripId, String reason) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/trips/cancel/$tripId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'reason': reason}),
    );
    return jsonDecode(response.body);
  }

  // Get price estimate
  static Future<Map<String, dynamic>> getEstimate({ 
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required double distanceKm,
    required int durationMin,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/booking/estimate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'dropoff_lat': dropoffLat,
        'dropoff_lng': dropoffLng,
        'distance_km': distanceKm,
        'duration_min': durationMin,
      }),
    );
    return jsonDecode(response.body);
  }

  // Get active trips for driver
  static Future<List<dynamic>> getActiveTrips() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/trips/active'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  // Accept a trip
  static Future<Map<String, dynamic>> acceptTrip(int tripId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/trips/accept/$tripId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  // Start a trip
  static Future<Map<String, dynamic>> startTrip(int tripId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/trips/start/$tripId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  // Complete a trip
  static Future<Map<String, dynamic>> completeTrip(int tripId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/trips/complete/$tripId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  // Get driver's own trip history
  static Future<List<dynamic>> getDriverTrips() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/trips/driver/history'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  // Register as driver
  static Future<Map<String, dynamic>> registerDriver(
      String username, String email, String password, String car, String license) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/driver'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'car': car,
        'license_number': license,
      }),
    );
    return jsonDecode(response.body);
  }

  // Get pending drivers
  static Future<List<dynamic>> getPendingDrivers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/drivers/pending'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  // Verify a driver
  static Future<Map<String, dynamic>> verifyDriver(int driverId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/drivers/$driverId/verify'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  // Reject a driver
  static Future<Map<String, dynamic>> rejectDriver(int driverId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/drivers/$driverId/reject'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  // Get driver profile
  static Future<Map<String, dynamic>> getDriverProfile() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/drivers/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }
}