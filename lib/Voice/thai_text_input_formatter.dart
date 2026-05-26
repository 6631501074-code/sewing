import 'package:flutter/services.dart';

class ThaiTextInputFormatter {
  static final name = FilteringTextInputFormatter.allow(
    RegExp(r"[ก-๙a-zA-Z0-9\s\.\-_'()/,]+"),
  );

  static final note = FilteringTextInputFormatter.allow(
    RegExp(r"[ก-๙a-zA-Z0-9\s\.\-_'()/,#:;!?\n]+"),
  );
}
