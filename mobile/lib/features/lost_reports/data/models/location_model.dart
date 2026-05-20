/// Модель геолокації, яку повертає backend.
class LocationModel {
  final String id;
  final double latitude;
  final double longitude;
  final int? accuracyMeters;
  final String? address;
  final String? city;
  final String source;
  final String createdAt;

  const LocationModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.address,
    required this.city,
    required this.source,
    required this.createdAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String? ?? '',
      latitude: _parseDouble(json['latitude']) ?? 0,
      longitude: _parseDouble(json['longitude']) ?? 0,
      accuracyMeters: json['accuracyMeters'] as int?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      source: json['source'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }
}