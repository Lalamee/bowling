class Validators {
  static String? notEmpty(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Обязательно заполните' : null;

  static String? integer(String? v) {
    if (v == null || v.trim().isEmpty) return 'Поле обязательно';
    return int.tryParse(v.trim()) != null ? null : 'Укажите целое число';
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Введите номер телефона';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return 'Неверный формат номера';
    return null;
  }

  static String? Function(String?) birth(DateTime? birthDate) {
    return (_) => birthDate == null ? 'Выберите дату' : null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите email';
    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Некорректный email';
    return null;
  }

  static String? validateExperience(String? total, String? bowling) {
    if (total == null || bowling == null) return null;
    final totalYears = int.tryParse(total.trim());
    final bowlingYears = int.tryParse(bowling.trim());
    if (totalYears == null || bowlingYears == null) return null;
    if (bowlingYears > totalYears) {
      return 'Стаж в боулинге не может превышать общий стаж';
    }
    return null;
  }

  static String? bowlingHistoryFormat(String? v) {
    if (v == null || v.trim().isEmpty) return 'Заполните поле';
    final pattern = RegExp(r'^\d+\s+лет\s+-\s+Боулинг\s+["\u00AB\u201D](.+?)["\u00BB\u201D]\s+\(с\s+\d{4}-\d{4}\)$');
    if (!pattern.hasMatch(v.trim())) {
      return 'Формат: 5 лет - Боулинг “Шары” (с 2005-2010)';
    }
    return null;
  }

  static String? bowlingHistorySoft(String? v) => null;

  static const String bowlingHistoryHintExample = 'Клуб «Кегли» — 02.2020–05.2022; Боул Страйк — 2018–01.2020';
  static const String bowlingHistoryHelper = 'Можно свободный текст: «Клуб Х — 2019–н.в.; Клуб Y — март 2017–08.2018».';

  static List<EmploymentEntry> parseEmploymentHistory(String input) {
    final chunks = input
        .split(RegExp(r'[;\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final List<EmploymentEntry> out = [];

    for (final raw in chunks) {
      String place = raw;
      DateTime? from;
      DateTime? to;

      final txt = raw.toLowerCase();

      final range = RegExp(
          r'(\d{1,2}\.\d{1,2}\.\d{4}|\d{1,2}\.\d{4}|[а-яa-z]+(?:\s+)?\d{4}|\d{4})\s*(?:[-–—]|по)\s*(\d{1,2}\.\d{1,2}\.\d{4}|\d{1,2}\.\d{4}|[а-яa-z]+(?:\s+)?\d{4}|\d{4}|н\.в\.|нв|настоящее|текущ)'
      );

      final since = RegExp(r'(?:^|[,;\s])с\s+(.+)$');

      final mRange = range.firstMatch(txt);
      if (mRange != null) {
        from = _parseDateLoose(mRange.group(1)!);
        final tail = mRange.group(2)!.trim();
        if (RegExp(r'н\.в\.|нв|настоящее|текущ').hasMatch(tail)) {
          to = null;
        } else {
          to = _parseDateLoose(tail);
        }
        final whole = mRange.group(0)!;
        place = raw.replaceFirst(RegExp(RegExp.escape(whole), caseSensitive: false), '').replaceAll(RegExp(r'[–—-]'), '').trim();
      } else {
        final mSince = since.firstMatch(txt);
        if (mSince != null) {
          from = _parseDateLoose(mSince.group(1)!);
          to = null;
          place = raw.substring(0, mSince.start).trim();
        }
      }

      if (place.isEmpty) place = raw;
      out.add(EmploymentEntry(place: place, from: from, to: to));
    }

    return out;
  }

  static DateTime? _parseDateLoose(String s) {
    final t = s.trim().toLowerCase();
    final full = RegExp(r'\b(0?[1-9]|[12]\d|3[01])\.(0?[1-9]|1[0-2])\.(19|20)\d{2}\b');
    final monthYearDot = RegExp(r'\b(0?[1-9]|1[0-2])\.(19|20)\d{2}\b');
    final monthWordYear = RegExp(r'\b([а-яa-z]+)\s+(19|20)\d{2}\b');
    final yearOnly = RegExp(r'\b(19|20)\d{2}\b');

    final m1 = full.firstMatch(t);
    if (m1 != null) {
      final d = int.parse(m1.group(1)!);
      final m = int.parse(m1.group(2)!);
      final y = int.parse(m1.group(3)! + t.substring(m1.start + m1.group(0)!.length - 2, m1.start + m1.group(0)!.length));
      return DateTime.tryParse('${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}');
    }

    final m2 = monthYearDot.firstMatch(t);
    if (m2 != null) {
      final mm = int.parse(m2.group(1)!);
      final yy = int.parse(m2.group(2)! + t.substring(m2.start + m2.group(0)!.length - 2, m2.start + m2.group(0)!.length));
      return DateTime.tryParse('${yy.toString().padLeft(4, '0')}-${mm.toString().padLeft(2, '0')}-01');
    }

    final m3 = monthWordYear.firstMatch(t);
    if (m3 != null) {
      final mon = m3.group(1)!;
      final yy = int.parse(m3.group(2)! + t.substring(m3.start + m3.group(0)!.length - 2, m3.start + m3.group(0)!.length));
      final map = {
        'январ': 1, 'феврал': 2, 'март': 3, 'апрел': 4, 'ма': 5, 'июн': 6, 'июл': 7, 'август': 8, 'сентябр': 9, 'октябр': 10, 'ноябр': 11, 'декабр': 12,
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
      };
      int mm = 1;
      for (final k in map.keys) {
        if (mon.startsWith(k)) {
          mm = map[k]!;
          break;
        }
      }
      return DateTime.tryParse('${yy.toString().padLeft(4, '0')}-${mm.toString().padLeft(2, '0')}-01');
    }

    final y = yearOnly.firstMatch(t);
    if (y != null) {
      final yy = int.parse(y.group(0)!);
      return DateTime.tryParse('${yy.toString().padLeft(4, '0')}-01-01');
    }

    return null;
  }
}

class EmploymentEntry {
  final String place;
  final DateTime? from;
  final DateTime? to;

  EmploymentEntry({required this.place, this.from, this.to});
}
