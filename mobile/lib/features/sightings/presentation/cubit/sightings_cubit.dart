import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/sightings_repository.dart';
import 'sightings_state.dart';

/// Cubit для роботи зі свідченнями.
class SightingsCubit extends Cubit<SightingsState> {
  final SightingsRepository _repository;

  SightingsCubit(this._repository) : super(SightingsState.initial());

  /// Завантажує свідчення для конкретного SOS.
  Future<void> loadSightingsByLostReport(String lostReportId) async {
    emit(
      state.copyWith(
        isLoading: true,
        sightings: const [],
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final sightings =
          await _repository.getSightingsByLostReport(lostReportId);

      emit(
        state.copyWith(
          isLoading: false,
          sightings: sightings,
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

  /// Завантажує деталі одного свідчення.
  Future<void> loadSightingById(String sightingId) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearSelectedSighting: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final sighting = await _repository.getSightingById(sightingId);

      emit(
        state.copyWith(
          isLoading: false,
          selectedSighting: sighting,
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

  /// Створює нове свідчення.
  Future<void> createSighting({
    required String lostReportId,
    required double latitude,
    required double longitude,
    int? accuracyMeters,
    required String seenAt,
    required String description,
    required String confidenceLevel,
  }) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final sighting = await _repository.createSighting(
        lostReportId: lostReportId,
        latitude: latitude,
        longitude: longitude,
        accuracyMeters: accuracyMeters,
        seenAt: seenAt,
        description: description,
        confidenceLevel: confidenceLevel,
      );

      final sightings =
          await _repository.getSightingsByLostReport(lostReportId);

      emit(
        state.copyWith(
          isLoading: false,
          sightings: sightings,
          selectedSighting: sighting,
          successMessage: 'Свідчення додано',
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