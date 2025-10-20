class PhoneUtils {
  PhoneUtils._();

  /// Normalizes a phone number to E.164-like format expected by backend.
  ///
  /// Keeps the leading `+` if present, otherwise attempts to infer the
  /// Russian `+7` country code from 10/11-digit inputs. Falls back to the
  /// trimmed original value when normalization is not possible.
  static String normalize(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return raw;

    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return raw.startsWith('+') ? raw : '+${raw}';
    }

    if (raw.startsWith('+')) {
      return '+$digits';
    }

    if (digits.length == 11 && digits.startsWith('8')) {
      return '+7${digits.substring(1)}';
    }

    if (digits.length == 11 && digits.startsWith('7')) {
      return '+$digits';
    }

    if (digits.length == 10) {
      return '+7$digits';
    }

    if (digits.length > 0) {
      return '+$digits';
    }

    return raw;
  }
}
