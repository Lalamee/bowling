enum IdentifierKind { phone, email }

class LoginIdentifier {
  LoginIdentifier(this.kind, this.value);

  final IdentifierKind kind;
  final String value;
}

class LoginValidator {
  LoginValidator._();

  static final RegExp _emailRegex =
      RegExp(r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$', caseSensitive: false);

  static LoginIdentifier? normalize(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final phone = _normalizePhone(trimmed);
    if (phone != null) {
      return LoginIdentifier(IdentifierKind.phone, phone);
    }

    final email = _normalizeEmail(trimmed);
    if (email != null) {
      return LoginIdentifier(IdentifierKind.email, email);
    }

    return null;
  }

  static String? validate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Введите телефон или e-mail';
    }
    return normalize(raw) == null ? 'Введите телефон +7XXXXXXXXXX или e-mail' : null;
  }

  static String? _normalizePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('8')) {
      final rest = digits.substring(1);
      if (rest.length == 10) {
        return '+7$rest';
      }
    }
    if (digits.length == 10) {
      return '+7$digits';
    }
    if (digits.length == 11 && digits.startsWith('7')) {
      return '+7${digits.substring(1)}';
    }
    return null;
  }

  static String? _normalizeEmail(String value) {
    if (_emailRegex.hasMatch(value)) {
      return value.trim().toLowerCase();
    }
    return null;
  }
}
