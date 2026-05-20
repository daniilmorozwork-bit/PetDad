import 'package:flutter/foundation.dart';

/// Глобальна конфігурація застосунку.
class AppConfig {
  /// Базова адреса backend без /api/v1.
  /// Потрібна для відкриття файлів з /uploads.
  static String get backendBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:3000';
      default:
        return 'http://localhost:3000';
    }
  }

  /// Базова адреса API.
  static String get apiBaseUrl {
    return '$backendBaseUrl/api/v1';
  }

  /// Перетворює відносний URL файлу з backend у повний URL.
  /// Наприклад: /uploads/pets/photo.jpg -> http://localhost:3000/uploads/pets/photo.jpg
  static String? buildFileUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) {
      return null;
    }

    if (relativeUrl.startsWith('http')) {
      return relativeUrl;
    }

    return '$backendBaseUrl$relativeUrl';
  }
}