import 'package:flutter/foundation.dart';

/// Глобальна конфігурація застосунку.
/// Тут зберігаємо базову адресу backend API.
class AppConfig {
  /// Для Android Emulator localhost комп'ютера доступний як 10.0.2.2.
  /// Для Chrome / Windows Desktop можна використовувати localhost.
  ///
  /// Якщо тестуєш на фізичному телефоні, заміни адресу на IP комп'ютера
  /// у локальній мережі, наприклад:
  /// http://192.168.1.25:3000/api/v1
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000/api/v1';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:3000/api/v1';
      default:
        return 'http://localhost:3000/api/v1';
    }
  }
}