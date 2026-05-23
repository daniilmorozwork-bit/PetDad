import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../models/map_event_model.dart';

/// Repository для подій карти.
class MapEventsRepository {
  final ApiClient _apiClient;

  MapEventsRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  /// Повертає активні події карти.
  Future<List<MapEventModel>> getEvents({
    double? north,
    double? south,
    double? east,
    double? west,
    String? type,
    String status = 'active',
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/map/events',
        queryParameters: {
          if (north != null) 'north': north,
          if (south != null) 'south': south,
          if (east != null) 'east': east,
          if (west != null) 'west': west,
          if (type != null) 'type': type,
          'status': status,
        },
      );

      final data = response.data as List<dynamic>;

      return data
          .map((item) => MapEventModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Повертає події поруч із заданими координатами.
  Future<List<MapEventModel>> getNearbyEvents({
    required double latitude,
    required double longitude,
    int radiusMeters = 3000,
    String? type,
    String status = 'active',
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/map/events/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radiusMeters': radiusMeters,
          if (type != null) 'type': type,
          'status': status,
        },
      );

      final data = response.data as List<dynamic>;

      return data
          .map((item) => MapEventModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Повертає одну подію карти.
  Future<MapEventModel> getEventById(String eventId) async {
    try {
      final response = await _apiClient.dio.get('/map/events/$eventId');

      return MapEventModel.fromJson(response.data as Map<String, dynamic>);
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