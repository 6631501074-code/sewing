class ThaiSpokenNumberParser {
  static const Map<String, int> digit = {
    'ศูนย์': 0,
    'หนึ่ง': 1,
    'เอ็ด': 1,
    'สอง': 2,
    'ยี่': 2,
    'สาม': 3,
    'สี่': 4,
    'ห้า': 5,
    'หก': 6,
    'เจ็ด': 7,
    'แปด': 8,
    'เก้า': 9,
  };

  static String extractNumber2dp(String text) {
    if (text.trim().isEmpty) return '';

    var s = text.replaceAll(' ', '');

    // ตัดคำที่มักติดมาจากงานคุณ
    const noise = [
      'เอว','สะโพก','เป้า','ต้นขา','ยาว','ขากว้าง','นิ้ว','เซน','เซนติเมตร','จุด'
    ];
    for (final w in noise) {
      // ไม่ลบ "จุด" ทั้งหมดนะ (ไว้แยกทศนิยม) แต่บางครั้ง stt ได้ "จุด" เป็นคำ
      if (w == 'จุด') continue;
      s = s.replaceAll(w, '');
    }

    // 1) ถ้ามีตัวเลขจริง ๆ อยู่แล้ว (32.5 / ๓๒.๕ / 32)
    final fromDigits = _extractDigitsLike(s);
    if (fromDigits.isNotEmpty) {
      final v = double.tryParse(fromDigits);
      if (v == null) return '';
      return v.toStringAsFixed(2);
    }

    // 2) ถ้าเป็นคำไทยล้วน (สามสิบสองจุดห้า)
    final v = _parseThaiNumberWords(s);
    if (v == null) return '';

    return v.toStringAsFixed(2);
  }

  static String _extractDigitsLike(String s) {
    const th = ['๐','๑','๒','๓','๔','๕','๖','๗','๘','๙'];
    const ar = ['0','1','2','3','4','5','6','7','8','9'];

    var t = s;
    for (int i = 0; i < th.length; i++) {
      t = t.replaceAll(th[i], ar[i]);
    }

    final match = RegExp(r'\d+(\.\d+)?').firstMatch(t);
    return match?.group(0) ?? '';
  }

  static double? _parseThaiNumberWords(String s) {
    if (s.isEmpty) return null;

    // split ทศนิยม
    final parts = s.split('จุด');
    final intPart = parts[0];
    final fracPart = parts.length > 1 ? parts[1] : '';

    final intValue = _parseThaiInt(intPart);
    if (intValue == null) return null;

    double value = intValue.toDouble();

    if (fracPart.isNotEmpty) {
      final digits = _thaiDigitsSequence(fracPart);
      if (digits == null) return null;
      final fracStr = digits.join();
      value = double.parse('$intValue.$fracStr');
    }

    return value;
  }

  static int? _parseThaiInt(String s) {
    if (s.isEmpty) return 0;

    // ร้อย
    if (s.contains('ร้อย')) {
      final idx = s.indexOf('ร้อย');
      final left = s.substring(0, idx);
      final right = s.substring(idx + 'ร้อย'.length);

      final h = _parseThaiInt(left);
      if (h == null) return null;
      final hundreds = (h == 0 ? 1 : h) * 100;

      final rest = _parseThaiInt(right);
      if (rest == null) return null;
      return hundreds + rest;
    }

    // สิบ
    if (s.contains('สิบ')) {
      final idx = s.indexOf('สิบ');
      final left = s.substring(0, idx);
      final right = s.substring(idx + 'สิบ'.length);

      int tens;
      if (left.isEmpty) {
        tens = 1; // "สิบ" = 10
      } else if (left == 'ยี่') {
        tens = 2;
      } else {
        final d = digit[left];
        if (d == null) return null;
        tens = d;
      }

      int total = tens * 10;

      if (right.isNotEmpty) {
        final u = digit[right];
        if (u == null) return null;
        total += u;
      }
      return total;
    }

    // หน่วย
    final u = digit[s];
    if (u == null) return null;
    return u;
  }

  static List<int>? _thaiDigitsSequence(String s) {
    if (s.isEmpty) return [];

    final out = <int>[];
    final keys = digit.keys.toList()..sort((a, b) => b.length.compareTo(a.length));

    int i = 0;
    while (i < s.length) {
      String? hit;
      for (final k in keys) {
        if (s.startsWith(k, i)) {
          hit = k;
          break;
        }
      }
      if (hit == null) return null;
      out.add(digit[hit]!);
      i += hit.length;
    }
    return out;
  }
}
