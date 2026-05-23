import 'package:equatable/equatable.dart';

import '../../data/models/map_event_model.dart';

/// Стан модуля карти.
class MapEventsState extends Equatable {
  final bool isLoading;
  final List<MapEventModel> events;
  final MapEventModel? selectedEvent;
  final String? errorMessage;
  final String? successMessage;

  const MapEventsState({
    required this.isLoading,
    required this.events,
    required this.selectedEvent,
    required this.errorMessage,
    required this.successMessage,
  });

  factory MapEventsState.initial() {
    return const MapEventsState(
      isLoading: false,
      events: [],
      selectedEvent: null,
      errorMessage: null,
      successMessage: null,
    );
  }

  MapEventsState copyWith({
    bool? isLoading,
    List<MapEventModel>? events,
    MapEventModel? selectedEvent,
    bool clearSelectedEvent = false,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return MapEventsState(
      isLoading: isLoading ?? this.isLoading,
      events: events ?? this.events,
      selectedEvent:
          clearSelectedEvent ? null : selectedEvent ?? this.selectedEvent,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        events,
        selectedEvent,
        errorMessage,
        successMessage,
      ];
}