import 'package:equatable/equatable.dart';

import '../../data/models/current_location_model.dart';

/// Поточний стан отримання геолокації.
enum CurrentLocationStatus {
  initial,
  loading,
  available,
  error,
}

/// Стан модуля поточного місцезнаходження.
class CurrentLocationState extends Equatable {
  final CurrentLocationStatus status;
  final CurrentLocationModel? location;
  final String? errorMessage;

  const CurrentLocationState({
    required this.status,
    required this.location,
    required this.errorMessage,
  });

  factory CurrentLocationState.initial() {
    return const CurrentLocationState(
      status: CurrentLocationStatus.initial,
      location: null,
      errorMessage: null,
    );
  }

  bool get isLoading => status == CurrentLocationStatus.loading;

  bool get hasLocation => location != null;

  @override
  List<Object?> get props => [
        status,
        location?.latitude,
        location?.longitude,
        location?.accuracyMeters,
        errorMessage,
      ];
}