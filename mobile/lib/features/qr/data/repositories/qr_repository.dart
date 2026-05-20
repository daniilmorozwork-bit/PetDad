import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../models/public_pet_profile_model.dart';
import '../models/qr_code_model.dart';

/// Repository для роботи з QR-кодами.
class QrRepository {
  final ApiClient _apiClient;

  QrRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  /// Створює QR-код для тварини або повертає вже існуючий активний.
  Future<QrCodeModel> generateQrForPet(String petId) async {
    try {
      final response = await _apiClient.dio.post('/pets/$petId/qr-code');

      return QrCodeModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Повертає активний QR-код тварини.
  Future<QrCodeModel> getActiveQrForPet(String petId) async {
    try {
      final response = await _apiClient.dio.get('/pets/$petId/qr-code');

      return QrCodeModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Перевипускає QR-код.
  Future<QrCodeModel> reissueQrForPet(String petId) async {
    try {
      final response = await _apiClient.dio.post(
        '/pets/$petId/qr-code/reissue',
      );

      return QrCodeModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Отримує публічний профіль тварини за QR token.
  Future<PublicPetProfileModel> getPublicPetProfile(String token) async {
    try {
      final response = await _apiClient.dio.get('/qr/$token');

      return PublicPetProfileModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Реєструє сканування QR.
  Future<void> registerScan({
    required String token,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
  }) async {
    try {
      await _apiClient.dio.post(
        '/qr/$token/scan',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'accuracyMeters': accuracyMeters,
        },
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

    if (error.response?.statusCode == 404) {
      return Exception('QR-код ще не створено');
    }

    if (error.type == DioExceptionType.connectionError) {
      return Exception(
        'Не вдалося підключитися до сервера. Перевірте, чи запущений backend.',
      );
    }

    return Exception('Сталася помилка запиту');
  }
}