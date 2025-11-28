import 'package:flutter_test/flutter_test.dart';

import 'package:bowling_market/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('notEmpty enforces non-blank strings', () {
      expect(Validators.notEmpty(null), isNotNull);
      expect(Validators.notEmpty('   '), isNotNull);
      expect(Validators.notEmpty('value'), isNull);
    });

    test('phone validates 11 digits after stripping formatting', () {
      expect(Validators.phone('+7 (999) 555-00-11'), isNull);
      expect(Validators.phone('7999555011'), isNotNull);
      expect(Validators.phone(''), isNotNull);
    });

    test('validateExperience ensures bowling years do not exceed total', () {
      expect(Validators.validateExperience('10', '4'), isNull);
      expect(Validators.validateExperience('3', '5'), isNotNull);
      expect(Validators.validateExperience('3', ''), isNull);
    });

    test('parseEmploymentHistory splits semi-colon separated ranges', () {
      final entries = Validators.parseEmploymentHistory('Клуб X 2019-2021; Клуб Y с 2022');
      expect(entries, hasLength(2));
      expect(entries.first.place.toLowerCase(), contains('клуб x'));
      expect(entries.first.from?.year, equals(2019));
      expect(entries.first.to?.year, equals(2021));
      expect(entries.last.place.toLowerCase(), contains('клуб y'));
      expect(entries.last.from?.year, equals(2022));
      expect(entries.last.to, isNull);
    });
  });
}
