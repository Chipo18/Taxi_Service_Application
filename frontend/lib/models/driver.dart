class Driver {
  final int id;
  final int userId;
  final String? carDetails;
  final double? latitude;
  final double? longitude;
  final bool isAvailable;
  final bool isVerified;

  Driver({
    required this.id,
    required this.userId,
    this.carDetails,
    this.latitude,
    this.longitude,
    required this.isAvailable,
    required this.isVerified,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      userId: json['user_id'],
      carDetails: json['car_details'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isAvailable: json['available'] ?? false,
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'car_details': carDetails,
      'latitude': latitude,
      'longitude': longitude,
      'available': isAvailable,
      'is_verified': isVerified,
    };
  }
}