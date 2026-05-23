import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/app_settings_model.dart';
import '../../data/repositories/settings_repository.dart';

/// Cubit локальних налаштувань застосунку.
class SettingsCubit extends Cubit<AppSettingsModel> {
  final SettingsRepository _repository;

  SettingsCubit(this._repository)
      : super(AppSettingsModel.defaults());

  /// Завантажує збережені налаштування при запуску застосунку.
  Future<void> loadSettings() async {
    final settings = await _repository.loadSettings();
    emit(settings);
  }

  /// Змінює тему застосунку.
  Future<void> changeTheme(
    AppThemePreference preference,
  ) async {
    await _repository.saveThemePreference(preference);

    emit(
      state.copyWith(
        themePreference: preference,
      ),
    );
  }

  /// Вмикає або вимикає використання геолокації.
  Future<void> changeUseCurrentLocation(bool value) async {
    await _repository.saveUseCurrentLocation(value);

    emit(
      state.copyWith(
        useCurrentLocation: value,
      ),
    );
  }

  /// Змінює стандартний радіус пошуку.
  Future<void> changeDefaultSearchRadius(int value) async {
    await _repository.saveDefaultSearchRadius(value);

    emit(
      state.copyWith(
        defaultSearchRadiusMeters: value,
      ),
    );
  }
}