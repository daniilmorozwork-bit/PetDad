/// Публічний профіль тварини, який повертається за QR token.
/// Тут немає приватних даних власника.
class PublicPetProfileModel {
  final String id;
  final String name;
  final String species;
  final String? breed;
  final String gender;
  final String color;
  final String? specialMarks;
  final String status;
  final String? mainPhotoUrl;

  const PublicPetProfileModel({
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

  factory PublicPetProfileModel.fromJson(Map<String, dynamic> json) {
    return PublicPetProfileModel(
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
}