import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'thai_number_formatter.dart';

class MeasureSlide extends StatefulWidget {
  final String label;
  final String unit;
  final TextEditingController controller;
  final bool isCurrent;
  final VoidCallback onDone;

  const MeasureSlide({
    super.key,
    required this.label,
    required this.unit,
    required this.controller,
    required this.isCurrent,
    required this.onDone,
  });

  @override
  State<MeasureSlide> createState() => _MeasureSlideState();
}

class _MeasureSlideState extends State<MeasureSlide> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant MeasureSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    // เมื่อเปลี่ยนเป็นฟิลด์ปัจจุบัน ให้ auto-focus
    if (widget.isCurrent && !oldWidget.isCurrent) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _formatTo2dp() {
    final formatted = ThaiToArabicDigitsFormatter.to2dpOrEmpty(widget.controller.text);
    widget.controller.text = formatted;
    widget.controller.selection = TextSelection.collapsed(offset: widget.controller.text.length);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.isCurrent ? 56 : 40,
                fontWeight: FontWeight.w900,
                height: 1.0,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '(หน่วย: ${widget.unit})',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black.withOpacity(0.45),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: 240,
              child: TextField(
                focusNode: _focusNode,
                controller: widget.controller,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  ThaiToArabicDigitsFormatter(),
                ],
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  hintText: 'ใส่ตัวเลข',
                  hintStyle: TextStyle(
                    fontSize: 24,
                    color: Colors.black.withOpacity(0.18),
                    fontWeight: FontWeight.w800,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF4F4F6),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  _formatTo2dp();
                  widget.onDone();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
