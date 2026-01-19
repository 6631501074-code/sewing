import 'package:flutter/services.dart';

class ThaiToArabicDigitsFormatter extends TextInputFormatter {
  static const _th = ['๐','๑','๒','๓','๔','๕','๖','๗','๘','๙'];
  static const _ar = ['0','1','2','3','4','5','6','7','8','9'];

  static String normalize(String input) {
    var s = input.trim();

    // ไทย -> อารบิก
    for (int i = 0; i < _th.length; i++) {
      s = s.replaceAll(_th[i], _ar[i]);
    }

    // เก็บเฉพาะเลข + จุด
    s = s.replaceAll(RegExp(r'[^0-9.]'), '');

    // กันหลายจุด
    final parts = s.split('.');
    if (parts.length > 2) {
      s = '${parts.first}.${parts.sublist(1).join('')}';
    }
    return s;
  }

  static String to2dpOrEmpty(String input) {
    final s = normalize(input);
    if (s.isEmpty) return '';
    final v = double.tryParse(s);
    if (v == null) return '';
    return v.toStringAsFixed(2);
  }

  static String extractFirstNumber2dp(String text) {
    final normalized = normalize(text);
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(normalized);
    if (match == null) return '';
    return to2dpOrEmpty(match.group(0)!);
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final normalized = normalize(newValue.text);
    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }
}
