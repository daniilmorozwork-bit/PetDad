import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Repository авторизації.
/// Відповідає за login, register, me та logout.
class AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  /// Вхід користувача.
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final authResponse = AuthResponseModel.fromJson(response.data);

      await _tokenStorage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      return authResponse;
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Реєстрація користувача.
  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'fullName': fullName.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'password': password,
        },
      );

      final authResponse = AuthResponseModel.fromJson(response.data);

      await _tokenStorage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      return authResponse;
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Отримання поточного користувача за accessToken.
  Future<UserModel> getMe() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      return UserModel.fromJson(response.data);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Logout на backend і очищення локальних токенів.
Future<void> logout() async {
  final accessToken = await _tokenStorage.getAccessToken();

  /// Спочатку очищаємо локальні токени.
  /// Це важливо, щоб SplashScreen не встиг повторно авторизувати користувача.
  await _tokenStorage.clearTokens();

  /// Після очищення пробуємо повідомити backend про logout.
  /// Передаємо старий accessToken вручну, бо interceptor уже не матиме токена.
  if (accessToken == null || accessToken.isEmpty) {
    return;
  }

  try {
    await _apiClient.dio.post(
      '/auth/logout',
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  } catch (_) {
    /// Якщо backend недоступний, локально користувач уже вийшов.
    /// Для MVP цього достатньо.
  }
}

  /// Перевіряє, чи є accessToken у сховищі.
  Future<bool> hasAccessToken() async {
    final token = await _tokenStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Перетворює DioException у нормальний текст помилки.
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