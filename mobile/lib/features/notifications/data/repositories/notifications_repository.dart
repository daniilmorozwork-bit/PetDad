import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../models/notification_model.dart';

/// Repository для внутрішніх повідомлень.
class NotificationsRepository {
  final ApiClient _apiClient;

  NotificationsRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  /// Повертає повідомлення поточного користувача.
  Future<List<NotificationModel>> getMyNotifications() async {
    try {
      final response = await _apiClient.dio.get('/notifications');

      final data = response.data as List<dynamic>;

      return data
          .map(
            (item) => NotificationModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Позначає повідомлення як прочитане.
  Future<NotificationModel> markAsRead(String notificationId) async {
    try {
      final response = await _apiClient.dio.patch(
        '/notifications/$notificationId/read',
      );

      return NotificationModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Exception _handleDioError(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];

      if (message is String) {
        return Exception(message);
      }

      if (message is List) {
        return Exception(message.join('\n'));
      }
    }

    if (error.type == DioExceptionType.connectionError) {
      return Exception(
        'Не вдалося підключитися до сервера. Перевірте, чи запущений backend.',
      );
    }

    return Exception('Сталася помилка запиту');
  }
}