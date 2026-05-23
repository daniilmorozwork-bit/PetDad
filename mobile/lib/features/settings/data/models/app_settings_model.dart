import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Доступні варіанти теми інтерфейсу.
enum AppThemePreference {
  system,
  light,
  dark,
}

/// Локальні налаштування застосунку.
/// Ці параметри зберігаються на конкретному пристрої.
class AppSettingsModel extends Equatable {
  final AppThemePreference themePreference;
  final bool useCurrentLocation;
  final int defaultSearchRadiusMeters;

  const AppSettingsModel({
    required this.themePreference,
    required this.useCurrentLocation,
    required this.defaultSearchRadiusMeters,
  });

  /// Початкові значення для нового користувача або нового пристрою.
  factory AppSettingsModel.defaults() {
    return const AppSettingsModel(
      themePreference: AppThemePreference.system,
      useCurrentLocation: true,
      defaultSearchRadiusMeters: 5000,
    );
  }

  /// Перетворює власний enum у ThemeMode Flutter.
  ThemeMode get themeMode {
    switch (themePreference) {
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.system:
        return ThemeMode.system;
    }
  }

  AppSettingsModel copyWith({
    AppThemePreference? themePreference,
    bool? useCurrentLocation,
    int? defaultSearchRadiusMeters,
  }) {
    return AppSettingsModel(
      themePreference: themePreference ?? this.themePreference,
      useCurrentLocation:
          useCurrentLocation ?? this.useCurrentLocation,
      defaultSearchRadiusMeters:
          defaultSearchRadiusMeters ?? this.defaultSearchRadiusMeters,
    );
  }

  @override
  List<Object?> get props => [
        themePreference,
        useCurrentLocation,
        defaultSearchRadiusMeters,
      ];
}