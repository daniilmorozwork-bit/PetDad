import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../models/sighting_model.dart';

/// Repository для роботи зі свідченнями.
class SightingsRepository {
  final ApiClient _apiClient;

  SightingsRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  /// Створює свідчення до активного SOS.
  Future<SightingModel> createSighting({
    required String lostReportId,
    required double latitude,
    required double longitude,
    int? accuracyMeters,
    required String seenAt,
    required String description,
    required String confidenceLevel,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/reports/lost/$lostReportId/sightings',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'accuracyMeters': accuracyMeters,
          'seenAt': seenAt,
          'description': description.trim(),
          'confidenceLevel': confidenceLevel,
        },
      );

      return SightingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Повертає список свідчень для конкретного SOS.
  Future<List<SightingModel>> getSightingsByLostReport(
    String lostReportId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/reports/lost/$lostReportId/sightings',
      );

      final data = response.data as List<dynamic>;

      return data
          .map((item) => SightingModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Повертає одне свідчення за id.
  Future<SightingModel> getSightingById(String sightingId) async {
    try {
      final response = await _apiClient.dio.get('/sightings/$sightingId');

      return SightingModel.fromJson(response.data as Map<String, dynamic>);
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