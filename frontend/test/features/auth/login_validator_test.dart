import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/auth/validators/login_validator.dart';

void main() {
  group('LoginValidator.normalize', () {
    test('normalizes russian phone with spaces and symbols', () {
      final identifier = LoginValidator.normalize('+7 (999) 123-45-67');
      expect(identifier, isNotNull);
      expect(identifier!.kind, IdentifierKind.phone);
      expect(identifier.value, '+79991234567');
    });

    test('normalizes phone starting with 8', () {
      final identifier = LoginValidator.normalize('8 912 000 11 22');
      expect(identifier, isNotNull);
      expect(identifier!.value, '+79120001122');
    });

    test('normalizes email to lowercase and trims', () {
      final identifier = LoginValidator.normalize(' Owner@Mail.COM ');
      expect(identifier, isNotNull);
      expect(identifier!.kind, IdentifierKind.email);
      expect(identifier.value, 'owner@mail.com');
    });

    test('returns null for invalid input', () {
      expect(LoginValidator.normalize('12345'), isNull);
      expect(LoginValidator.normalize('owner@com'), isNull);
      expect(LoginValidator.normalize(''), isNull);
    });
  });

  group('LoginValidator.validate', () {
    test('returns error for empty value', () {
      expect(LoginValidator.validate(' '), isNotNull);
    });

    test('returns null for valid phone', () {
      expect(LoginValidator.validate('+7 999 123 45 67'), isNull);
    });

    test('returns null for valid email', () {
      expect(LoginValidator.validate('user@example.com'), isNull);
    });

    test('returns error for invalid login', () {
      expect(LoginValidator.validate('user@invalid'), isNotNull);
    });
  });
}
