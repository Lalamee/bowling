class PhoneUtils {
  PhoneUtils._();

  /// Normalizes Russian phone numbers to `+7XXXXXXXXXX` when possible.
  /// Returns the original trimmed input if normalization rules are not met.
  static String normalize(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return raw;

    final digits = raw.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 11 && digits.startsWith('8')) {
      return '+7${digits.substring(1)}';
    }

    if (digits.length == 11 && digits.startsWith('7')) {
      return '+7${digits.substring(1)}';
    }

    if (raw.startsWith('+')) {
      final candidate = '+$digits';
      return RegExp(r'^\+7\d{10}$').hasMatch(candidate) ? candidate : raw;
    }

    return raw;
  }
}
