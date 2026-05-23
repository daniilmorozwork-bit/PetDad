/// Модель внутрішнього повідомлення користувача.
class NotificationModel {
  final String id;
  final String recipientId;
  final String type;
  final String title;
  final String body;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic>? data;
  final String? readAt;
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    required this.entityType,
    required this.entityId,
    required this.data,
    required this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];

    return NotificationModel(
      id: json['id'] as String? ?? '',
      recipientId: json['recipientId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      entityType: json['entityType'] as String?,
      entityId: json['entityId'] as String?,
      data: rawData is Map<String, dynamic> ? rawData : null,
      readAt: json['readAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  /// Повідомлення ще не було прочитане.
  bool get isUnread => readAt == null;

  /// Людська назва типу повідомлення.
  String get typeLabel {
    switch (type) {
      case 'lost_pet_created':
        return 'SOS';
      case 'lost_pet_nearby':
        return 'SOS поруч';
      case 'new_sighting':
        return 'Свідчення';
      case 'qr_scanned':
        return 'QR-код';
      case 'report_status_changed':
        return 'Статус SOS';
      default:
        return 'Повідомлення';
    }
  }
}