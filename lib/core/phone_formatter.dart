import 'package:flutter/services.dart';

/// Formats a phone number string for display in the client form.
///
/// Two modes auto-detected from the input:
///   * Domestic French (default): groups of 2 from the start.
///     `0612345678` → `06 12 34 56 78`.
///   * International: when the input starts with `+`. The country code is
///     held to 2 digits (covering FR, ES, IT, DE…); the remainder is grouped
///     by 2 with a leading single digit when the remaining length is odd.
///     `+33612345678` → `+33 6 12 34 56 78`.
///
/// All non-digit characters are stripped before regrouping, so the function
/// is idempotent: applying it to an already-formatted value yields the same
/// string. Pasted input with dots, dashes, parens etc. is normalized.
String formatPhoneInput(String input) {
  final hasPlus = input.startsWith('+');
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return hasPlus ? '+' : '';

  if (hasPlus) {
    if (digits.length <= 2) return '+$digits';
    final cc = digits.substring(0, 2);
    final rest = digits.substring(2);
    return '+$cc ${_groupBy2(rest, leadingOne: rest.length.isOdd)}';
  }

  return _groupBy2(digits, leadingOne: false);
}

String _groupBy2(String digits, {required bool leadingOne}) {
  if (digits.isEmpty) return '';
  final groups = <String>[];
  var i = 0;
  if (leadingOne) {
    groups.add(digits[0]);
    i = 1;
  }
  while (i < digits.length) {
    final end = (i + 2).clamp(0, digits.length);
    groups.add(digits.substring(i, end));
    i = end;
  }
  return groups.join(' ');
}

/// [TextInputFormatter] that pipes every edit through [formatPhoneInput].
/// The cursor jumps to the end after each keystroke — acceptable for a phone
/// number that is typed left-to-right.
class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatPhoneInput(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
