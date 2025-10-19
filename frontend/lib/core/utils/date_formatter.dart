/// Утилита для форматирования дат для Backend API
class DateFormatter {
  /// Форматирует DateTime в LocalDate формат для Backend (yyyy-MM-dd)
  static String toLocalDate(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  /// Форматирует DateTime в LocalDateTime формат для Backend (yyyy-MM-ddTHH:mm:ss)
  static String toLocalDateTime(DateTime date) {
    return date.toIso8601String().split('.')[0];
  }

  /// Парсит LocalDate из Backend
  static DateTime? parseLocalDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Парсит LocalDateTime из Backend
  static DateTime? parseLocalDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return null;
    try {
      return DateTime.parse(dateTimeStr);
    } catch (e) {
      return null;
    }
  }
}
