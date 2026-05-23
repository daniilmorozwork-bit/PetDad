/// Допоміжні методи для форматування даних в інтерфейсі.
class AppFormatters {
  /// Форматує дату і час у зрозумілому для користувача вигляді.
  /// Приклад: 23.05.2026, 18:45
  static String dateTime(DateTime value) {
    final localValue = value.toLocal();

    final day = localValue.day.toString().padLeft(2, '0');
    final month = localValue.month.toString().padLeft(2, '0');
    final hour = localValue.hour.toString().padLeft(2, '0');
    final minute = localValue.minute.toString().padLeft(2, '0');

    return '$day.$month.${localValue.year}, $hour:$minute';
  }

  /// Форматує радіус пошуку.
  static String distance(int meters) {
    if (meters >= 1000) {
      final kilometers = meters / 1000;

      if (kilometers == kilometers.roundToDouble()) {
        return '${kilometers.round()} км';
      }

      return '${kilometers.toStringAsFixed(1)} км';
    }

    return '$meters м';
  }
}