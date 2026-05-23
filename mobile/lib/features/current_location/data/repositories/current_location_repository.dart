import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/api/api_client.dart';
import '../models/current_location_model.dart';

/// Repository для отримання поточного місцезнаходження
/// та синхронізації його з backend.
class CurrentLocationRepository {
  final ApiClient _apiClient;

  CurrentLocationRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  /// Отримує поточні координати пристрою.
  Future<CurrentLocationModel> getCurrentLocation() async {
    /**
     * Для мобільних платформ перевіряємо,
     * чи увімкнені системні служби геолокації.
     *
     * Для web цю перевірку пропускаємо:
     * браузер сам керує доступністю геолокації та дозволами.
     */
    if (!kIsWeb) {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Увімкніть геолокацію на пристрої та повторіть спробу.',
        );
      }
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'Доступ до геолокації не надано.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Доступ до геолокації заблоковано. Дозвольте його в налаштуваннях браузера або пристрою.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    return CurrentLocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy.round(),
    );
  }

  /// Передає поточну позицію користувача у backend.
  /// Backend зберігає її для подальшої роботи зі сповіщеннями поруч.
  Future<void> syncCurrentLocation(
    CurrentLocationModel location,
  ) async {
    await _apiClient.dio.patch(
      '/users/me/location',
      data: {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'accuracyMeters': location.accuracyMeters,
      },
    );
  }
}