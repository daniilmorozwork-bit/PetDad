import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings_model.dart';

/// Repository локальних налаштувань застосунку.
/// Для таких даних не потрібен backend: вони стосуються конкретного пристрою.
class SettingsRepository {
  static const _themeKey = 'settings_theme';
  static const _useCurrentLocationKey = 'settings_use_current_location';
  static const _defaultRadiusKey = 'settings_default_radius_meters';

  final SharedPreferencesAsync _preferences;

  SettingsRepository({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  /// Завантажує локальні налаштування.
  Future<AppSettingsModel> loadSettings() async {
    final themeValue = await _preferences.getString(_themeKey);
    final useCurrentLocation =
        await _preferences.getBool(_useCurrentLocationKey);
    final defaultRadius =
        await _preferences.getInt(_defaultRadiusKey);

    final themePreference = AppThemePreference.values.firstWhere(
      (value) => value.name == themeValue,
      orElse: () => AppThemePreference.system,
    );

    return AppSettingsModel(
      themePreference: themePreference,
      useCurrentLocation: useCurrentLocation ?? true,
      defaultSearchRadiusMeters: defaultRadius ?? 5000,
    );
  }

  /// Зберігає вибрану тему.
  Future<void> saveThemePreference(
    AppThemePreference preference,
  ) async {
    await _preferences.setString(
      _themeKey,
      preference.name,
    );
  }

  /// Зберігає дозвіл застосунку використовувати геолокацію.
  Future<void> saveUseCurrentLocation(bool value) async {
    await _preferences.setBool(
      _useCurrentLocationKey,
      value,
    );
  }

  /// Зберігає стандартний радіус пошуку подій.
  Future<void> saveDefaultSearchRadius(int value) async {
    await _preferences.setInt(
      _defaultRadiusKey,
      value,
    );
  }
}