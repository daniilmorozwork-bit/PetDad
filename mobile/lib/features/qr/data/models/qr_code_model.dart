/// Модель QR-коду тварини.
class QrCodeModel {
  final String id;
  final String petId;
  final String token;
  final String publicUrl;
  final bool isActive;
  final String? revokedAt;
  final String createdAt;

  const QrCodeModel({
    required this.id,
    required this.petId,
    required this.token,
    required this.publicUrl,
    required this.isActive,
    required this.revokedAt,
    required this.createdAt,
  });

  factory QrCodeModel.fromJson(Map<String, dynamic> json) {
    return QrCodeModel(
      id: json['id'] as String? ?? '',
      petId: json['petId'] as String? ?? '',
      token: json['token'] as String? ?? '',
      publicUrl: json['publicUrl'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      revokedAt: json['revokedAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}