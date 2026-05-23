import 'map_location_model.dart';

/// Подія карти: SOS, свідчення, QR scan тощо.
class MapEventModel {
  final String id;
  final String type;
  final String status;
  final String title;
  final String? description;
  final MapLocationModel location;
  final String? sourceEntityType;
  final String? sourceEntityId;
  final String? petId;
  final double? distanceMeters;
  final String createdAt;

  const MapEventModel({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.location,
    required this.sourceEntityType,
    required this.sourceEntityId,
    required this.petId,
    required this.distanceMeters,
    required this.createdAt,
  });

  factory MapEventModel.fromJson(Map<String, dynamic> json) {
    return MapEventModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      location: MapLocationModel.fromJson(
        json['location'] as Map<String, dynamic>,
      ),
      sourceEntityType: json['sourceEntityType'] as String?,
      sourceEntityId: json['sourceEntityId'] as String?,
      petId: json['petId'] as String?,
      distanceMeters: _parseDouble(json['distanceMeters']),
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  bool get isLostPetEvent {
    return type == 'lost_pet' && sourceEntityType == 'lost_pet_report';
  }

  bool get isSightingEvent {
    return type == 'sighting' && sourceEntityType == 'sighting_report';
  }

  String get typeLabel {
    switch (type) {
      case 'lost_pet':
        return 'SOS';
      case 'sighting':
        return 'Свідчення';
      case 'found_pet':
        return 'Знайдена тварина';
      case 'qr_scan':
        return 'QR-сканування';
      case 'help_request':
        return 'Запит допомоги';
      default:
        return type;
    }
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