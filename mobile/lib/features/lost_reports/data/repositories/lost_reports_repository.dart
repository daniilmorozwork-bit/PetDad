import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../models/lost_report_model.dart';

/// Repository для SOS-оголошень.
class LostReportsRepository {
  final ApiClient _apiClient;

  LostReportsRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  /// Створює SOS-оголошення.
  Future<LostReportModel> createLostReport({
    required String petId,
    required double latitude,
    required double longitude,
    int? accuracyMeters,
    required String lastSeenAt,
    required String description,
    String? contactPhone,
    double? rewardAmount,
    int searchRadiusMeters = 3000,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/reports/lost',
        data: {
          'petId': petId,
          'latitude': latitude,
          'longitude': longitude,
          'accuracyMeters': accuracyMeters,
          'lastSeenAt': lastSeenAt,
          'description': description.trim(),
          'contactPhone': _emptyToNull(contactPhone),
          'rewardAmount': rewardAmount,
          'searchRadiusMeters': searchRadiusMeters,
        },
      );

      return LostReportModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Повертає список SOS.
  Future<List<LostReportModel>> getLostReports({
    String status = 'active',
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/reports/lost',
        queryParameters: {
          'status': status,
        },
      );

      final data = response.data as List<dynamic>;

      return data
          .map((item) => LostReportModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Повертає одне SOS за id.
  Future<LostReportModel> getLostReportById(String reportId) async {
    try {
      final response = await _apiClient.dio.get('/reports/lost/$reportId');

      return LostReportModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Закриває SOS.
  Future<LostReportModel> closeLostReport({
    required String reportId,
    required String closeReason,
    String? closeComment,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '/reports/lost/$reportId/close',
        data: {
          'closeReason': closeReason,
          'closeComment': _emptyToNull(closeComment),
        },
      );

      return LostReportModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
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