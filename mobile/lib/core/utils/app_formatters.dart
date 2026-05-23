/// Допоміжні методи для форматування даних в інтерфейсі.
class AppFormatters {
  /// Форматує дату й час у зрозумілому вигляді.
  /// Приклад: 23.05.2026, 18:45
  static String dateTime(DateTime value) {
    final localValue = value.toLocal();

    final day = localValue.day.toString().padLeft(2, '0');
    final month = localValue.month.toString().padLeft(2, '0');
    final hour = localValue.hour.toString().padLeft(2, '0');
    final minute = localValue.minute.toString().padLeft(2, '0');

    return '$day.$month.${localValue.year}, $hour:$minute';
  }

  /// Форматує ISO-рядок дати й часу.
  static String dateTimeFromIso(
    String? value, {
    String emptyValue = 'Не вказано',
  }) {
    if (value == null || value.isEmpty) {
      return emptyValue;
    }

    final parsedValue = DateTime.tryParse(value);

    if (parsedValue == null) {
      return emptyValue;
    }

    return dateTime(parsedValue);
  }

  /// Форматує дату без часу.
  /// Приклад: 23.05.2026
  static String dateFromIso(
    String? value, {
    String emptyValue = 'Не вказано',
  }) {
    if (value == null || value.isEmpty) {
      return emptyValue;
    }

    final parsedValue = DateTime.tryParse(value)?.toLocal();

    if (parsedValue == null) {
      return emptyValue;
    }

    final day = parsedValue.day.toString().padLeft(2, '0');
    final month = parsedValue.month.toString().padLeft(2, '0');

    return '$day.$month.${parsedValue.year}';
  }

  /// Форматує відстань або радіус.
  /// Приклад: 450 м, 3 км, 1.5 км.
  static String distance(num meters) {
    if (meters >= 1000) {
      final kilometers = meters / 1000;

      if (kilometers == kilometers.roundToDouble()) {
        return '${kilometers.round()} км';
      }

      return '${kilometers.toStringAsFixed(1)} км';
    }

    return '${meters.round()} м';
  }

  /// Форматує суму без привʼязки до конкретної валюти.
  static String amount(
    double? value, {
    String emptyValue = 'Не вказано',
  }) {
    if (value == null) {
      return emptyValue;
    }

    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(2);
  }
}