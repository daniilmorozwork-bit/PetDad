import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/map_events_repository.dart';
import 'map_events_state.dart';

/// Cubit для подій карти.
class MapEventsCubit extends Cubit<MapEventsState> {
  final MapEventsRepository _repository;

  MapEventsCubit(this._repository) : super(MapEventsState.initial());

  /// Завантажує всі активні події карти.
  Future<void> loadEvents({
    String? type,
  }) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final events = await _repository.getEvents(type: type);

      emit(
        state.copyWith(
          isLoading: false,
          events: events,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  /// Завантажує події поруч із координатами.
  Future<void> loadNearbyEvents({
    required double latitude,
    required double longitude,
    int radiusMeters = 3000,
    String? type,
  }) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final events = await _repository.getNearbyEvents(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        type: type,
      );

      emit(
        state.copyWith(
          isLoading: false,
          events: events,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  /// Завантажує одну подію.
  Future<void> loadEventById(String eventId) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final event = await _repository.getEventById(eventId);

      emit(
        state.copyWith(
          isLoading: false,
          selectedEvent: event,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  /// Вибір події на карті.
  void selectEventById(String eventId) {
    final selected = state.events.where((event) => event.id == eventId).firstOrNull;

    emit(
      state.copyWith(
        selectedEvent: selected,
        clearError: true,
        clearSuccess: true,
      ),
    );
  }

  /// Очищає службові повідомлення.
  void clearMessages() {
    emit(
      state.copyWith(
        clearError: true,
        clearSuccess: true,
      ),
    );
  }
}