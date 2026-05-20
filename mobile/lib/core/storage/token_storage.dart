import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Сервіс для безпечного зберігання accessToken та refreshToken.
class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  TokenStorage({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  /// Зберігає обидва токени після login/register.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Повертає accessToken.
  Future<String?> getAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  /// Повертає refreshToken.
  Future<String?> getRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  /// Очищає токени під час logout.
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}