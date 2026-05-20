import '../../../../core/config/app_config.dart';
import 'location_model.dart';

/// Дані тварини всередині SOS.
class LostReportPetModel {
  final String id;
  final String name;
  final String species;
  final String? breed;
  final String gender;
  final String color;
  final String? specialMarks;
  final String status;
  final String? mainPhotoUrl;

  const LostReportPetModel({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.gender,
    required this.color,
    required this.specialMarks,
    required this.status,
    required this.mainPhotoUrl,
  });

  factory LostReportPetModel.fromJson(Map<String, dynamic> json) {
    return LostReportPetModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      species: json['species'] as String? ?? '',
      breed: json['breed'] as String?,
      gender: json['gender'] as String? ?? '',
      color: json['color'] as String? ?? '',
      specialMarks: json['specialMarks'] as String?,
      status: json['status'] as String? ?? '',
      mainPhotoUrl: json['mainPhotoUrl'] as String?,
    );
  }

  /// Повний URL фото для Image.network.
  String? get fullMainPhotoUrl {
    return AppConfig.buildFileUrl(mainPhotoUrl);
  }
}

/// Модель SOS-оголошення.
class LostReportModel {
  final String id;
  final String petId;
  final String ownerId;
  final String status;
  final LostReportPetModel pet;
  final LocationModel lastSeenLocation;
  final String lastSeenAt;
  final String description;
  final String? contactPhone;
  final double? rewardAmount;
  final int searchRadiusMeters;
  final String? closeReason;
  final String? closeComment;
  final String? closedAt;
  final String createdAt;
  final String updatedAt;

  const LostReportModel({
    required this.id,
    required this.petId,
    required this.ownerId,
    required this.status,
    required this.pet,
    required this.lastSeenLocation,
    required this.lastSeenAt,
    required this.description,
    required this.contactPhone,
    required this.rewardAmount,
    required this.searchRadiusMeters,
    required this.closeReason,
    required this.closeComment,
    required this.closedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LostReportModel.fromJson(Map<String, dynamic> json) {
    return LostReportModel(
      id: json['id'] as String? ?? '',
      petId: json['petId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      pet: LostReportPetModel.fromJson(
        json['pet'] as Map<String, dynamic>,
      ),
      lastSeenLocation: LocationModel.fromJson(
        json['lastSeenLocation'] as Map<String, dynamic>,
      ),
      lastSeenAt: json['lastSeenAt'] as String? ?? '',
      description: json['description'] as String? ?? '',
      contactPhone: json['contactPhone'] as String?,
      rewardAmount: _parseDouble(json['rewardAmount']),
      searchRadiusMeters: json['searchRadiusMeters'] as int? ?? 3000,
      closeReason: json['closeReason'] as String?,
      closeComment: json['closeComment'] as String?,
      closedAt: json['closedAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
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