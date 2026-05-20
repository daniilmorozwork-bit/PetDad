/// Модель файлу фото тварини.
class PetFileModel {
  final String id;
  final String originalName;
  final String storedName;
  final String mimeType;
  final String extension;
  final int sizeBytes;
  final String url;
  final String createdAt;

  const PetFileModel({
    required this.id,
    required this.originalName,
    required this.storedName,
    required this.mimeType,
    required this.extension,
    required this.sizeBytes,
    required this.url,
    required this.createdAt,
  });

  factory PetFileModel.fromJson(Map<String, dynamic> json) {
    return PetFileModel(
      id: json['id'] as String? ?? '',
      originalName: json['originalName'] as String? ?? '',
      storedName: json['storedName'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? '',
      extension: json['extension'] as String? ?? '',
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      url: json['url'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

/// Модель фото тварини.
class PetPhotoModel {
  final String id;
  final String petId;
  final String fileId;
  final bool isMain;
  final int displayOrder;
  final PetFileModel file;
  final String createdAt;

  const PetPhotoModel({
    required this.id,
    required this.petId,
    required this.fileId,
    required this.isMain,
    required this.displayOrder,
    required this.file,
    required this.createdAt,
  });

  factory PetPhotoModel.fromJson(Map<String, dynamic> json) {
    return PetPhotoModel(
      id: json['id'] as String? ?? '',
      petId: json['petId'] as String? ?? '',
      fileId: json['fileId'] as String? ?? '',
      isMain: json['isMain'] as bool? ?? false,
      displayOrder: json['displayOrder'] as int? ?? 0,
      file: PetFileModel.fromJson(json['file'] as Map<String, dynamic>),
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

/// Модель тварини.
class PetModel {
  final String id;
  final String ownerId;
  final String name;
  final String species;
  final String? breed;
  final String gender;
  final String? birthDate;
  final String color;
  final double? weightKg;
  final String? specialMarks;
  final String? chipNumber;
  final bool isPublic;
  final String status;
  final String? mainPhotoUrl;
  final List<PetPhotoModel> photos;
  final String createdAt;
  final String updatedAt;

  const PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    required this.breed,
    required this.gender,
    required this.birthDate,
    required this.color,
    required this.weightKg,
    required this.specialMarks,
    required this.chipNumber,
    required this.isPublic,
    required this.status,
    required this.mainPhotoUrl,
    required this.photos,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    final photosJson = json['photos'] as List<dynamic>? ?? [];

    return PetModel(
      id: json['id'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      species: json['species'] as String? ?? '',
      breed: json['breed'] as String?,
      gender: json['gender'] as String? ?? '',
      birthDate: json['birthDate'] as String?,
      color: json['color'] as String? ?? '',
      weightKg: _parseDouble(json['weightKg']),
      specialMarks: json['specialMarks'] as String?,
      chipNumber: json['chipNumber'] as String?,
      isPublic: json['isPublic'] as bool? ?? true,
      status: json['status'] as String? ?? '',
      mainPhotoUrl: json['mainPhotoUrl'] as String?,
      photos: photosJson
          .map((photo) => PetPhotoModel.fromJson(photo as Map<String, dynamic>))
          .toList(),
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