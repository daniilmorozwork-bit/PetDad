/// Поточне місцезнаходження пристрою.
class CurrentLocationModel {
  final double latitude;
  final double longitude;
  final int accuracyMeters;

  const CurrentLocationModel({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });
}