import '../../../../core/config/app_config.dart';
import '../../../lost_reports/data/models/location_model.dart';

/// Скорочені дані SOS, до якого належить свідчення.
class SightingLostReportModel {
  final String id;
  final String status;

  const SightingLostReportModel({
    required this.id,
    required this.status,
  });

  factory SightingLostReportModel.fromJson(Map<String, dynamic> json) {
    return SightingLostReportModel(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

/// Скорочені дані тварини у свідченні.
class SightingPetModel {
  final String id;
  final String name;
  final String species;
  final String? breed;
  final String color;
  final String status;
  final String? mainPhotoUrl;

  const SightingPetModel({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.color,
    required this.status,
    required this.mainPhotoUrl,
  });

  factory SightingPetModel.fromJson(Map<String, dynamic> json) {
    return SightingPetModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      species: json['species'] as String? ?? '',
      breed: json['breed'] as String?,
      color: json['color'] as String? ?? '',
      status: json['status'] as String? ?? '',
      mainPhotoUrl: json['mainPhotoUrl'] as String?,
    );
  }

  String? get fullMainPhotoUrl {
    return AppConfig.buildFileUrl(mainPhotoUrl);
  }
}

/// Модель свідчення про можливе місце перебування тварини.
class SightingModel {
  final String id;
  final String lostReportId;
  final String petId;
  final String reporterId;
  final String status;
  final String confidenceLevel;
  final String seenAt;
  final String description;
  final LocationModel location;
  final String? mapEventId;
  final SightingLostReportModel? lostReport;
  final SightingPetModel? pet;
  final String createdAt;
  final String updatedAt;

  const SightingModel({
    required this.id,
    required this.lostReportId,
    required this.petId,
    required this.reporterId,
    required this.status,
    required this.confidenceLevel,
    required this.seenAt,
    required this.description,
    required this.location,
    required this.mapEventId,
    required this.lostReport,
    required this.pet,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SightingModel.fromJson(Map<String, dynamic> json) {
    return SightingModel(
      id: json['id'] as String? ?? '',
      lostReportId: json['lostReportId'] as String? ?? '',
      petId: json['petId'] as String? ?? '',
      reporterId: json['reporterId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      confidenceLevel: json['confidenceLevel'] as String? ?? '',
      seenAt: json['seenAt'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: LocationModel.fromJson(
        json['location'] as Map<String, dynamic>,
      ),
      mapEventId: json['mapEventId'] as String?,
      lostReport: json['lostReport'] == null
          ? null
          : SightingLostReportModel.fromJson(
              json['lostReport'] as Map<String, dynamic>,
            ),
      pet: json['pet'] == null
          ? null
          : SightingPetModel.fromJson(
              json['pet'] as Map<String, dynamic>,
            ),
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}