import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/current_location_model.dart';
import '../../data/repositories/current_location_repository.dart';
import 'current_location_state.dart';

/// Cubit поточного місцезнаходження.
class CurrentLocationCubit extends Cubit<CurrentLocationState> {
  final CurrentLocationRepository _repository;

  CurrentLocationCubit(this._repository)
      : super(CurrentLocationState.initial());

  /// Отримує геолокацію пристрою та синхронізує її з backend.
  /// Повертає координати, щоб екран карти одразу міг виконати пошук подій.
  Future<CurrentLocationModel?> loadCurrentLocation() async {
    emit(
      const CurrentLocationState(
        status: CurrentLocationStatus.loading,
        location: null,
        errorMessage: null,
      ),
    );

    try {
      final location = await _repository.getCurrentLocation();

      /**
       * Для відображення карти достатньо локально отриманих координат.
       * Якщо синхронізація з backend тимчасово не спрацює,
       * не блокуємо карту.
       */
      try {
        await _repository.syncCurrentLocation(location);
      } catch (_) {
        // Карта все одно може використовувати отримані координати.
      }

      emit(
        CurrentLocationState(
          status: CurrentLocationStatus.available,
          location: location,
          errorMessage: null,
        ),
      );

      return location;
    } catch (error) {
      emit(
        CurrentLocationState(
          status: CurrentLocationStatus.error,
          location: null,
          errorMessage:
              error.toString().replaceFirst('Exception: ', ''),
        ),
      );

      return null;
    }
  }
}