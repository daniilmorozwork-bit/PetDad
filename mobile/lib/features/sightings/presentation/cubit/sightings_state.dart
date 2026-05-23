import 'package:equatable/equatable.dart';

import '../../data/models/sighting_model.dart';

/// Стан модуля свідчень.
class SightingsState extends Equatable {
  final bool isLoading;
  final List<SightingModel> sightings;
  final SightingModel? selectedSighting;
  final String? errorMessage;
  final String? successMessage;

  const SightingsState({
    required this.isLoading,
    required this.sightings,
    required this.selectedSighting,
    required this.errorMessage,
    required this.successMessage,
  });

  factory SightingsState.initial() {
    return const SightingsState(
      isLoading: false,
      sightings: [],
      selectedSighting: null,
      errorMessage: null,
      successMessage: null,
    );
  }

  SightingsState copyWith({
    bool? isLoading,
    List<SightingModel>? sightings,
    SightingModel? selectedSighting,
    bool clearSelectedSighting = false,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return SightingsState(
      isLoading: isLoading ?? this.isLoading,
      sightings: sightings ?? this.sightings,
      selectedSighting: clearSelectedSighting
          ? null
          : selectedSighting ?? this.selectedSighting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        sightings,
        selectedSighting,
        errorMessage,
        successMessage,
      ];
}