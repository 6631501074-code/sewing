import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'firestore_service.dart';

import 'garment_dialog.dart';
import 'measure_slide.dart';
import 'thai_spoken_number_parser.dart';
import 'thai_number_formatter.dart';
import 'save_customer_dialog.dart';

class MiccPage extends StatefulWidget {
  final int openPickerRequest;
  final GarmentType initialGarmentType;
  final WorkCategory initialCategory;
  final String? packageFolderId;
  final String? packageFolderName;

  const MiccPage({
    super.key,
    this.openPickerRequest = 0,
    this.initialGarmentType = GarmentType.none,
    this.initialCategory = WorkCategory.daily,
    this.packageFolderId,
    this.packageFolderName,
  });

  @override
  State<MiccPage> createState() => _MicPageState();
}

class _MicPageState extends State<MiccPage> {
  final _fs = FirestoreService();

  GarmentType _selected = GarmentType.none;

  bool get _isPackageFolderFlow =>
      (widget.packageFolderId ?? '').trim().isNotEmpty;

  final PageController _pageController = PageController(viewportFraction: 0.78);
  int _pageIndex = 0;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;
  String? _localeId;

  // ✅ โหมดพูดไหลต่อ
  bool _autoContinue = true;
  bool _restarting = false;
  bool _pickerOpening = false;

  Completer<void>? _waitPageChange;

  late Map<String, TextEditingController> _controllers = {};

  List<_MeasureField> get _fields {
    if (_selected == GarmentType.shirt) {
      return const [
        _MeasureField(keyName: 'อก', label: 'อก', unit: 'นิ้ว'),
        _MeasureField(keyName: 'รอบเอว', label: 'รอบเอว', unit: 'นิ้ว'),
        _MeasureField(keyName: 'รอบชาย', label: 'รอบชาย', unit: 'นิ้ว'),
        _MeasureField(keyName: 'บ่า', label: 'บ่า', unit: 'นิ้ว'),
        _MeasureField(keyName: 'แขนยาว', label: 'แขนยาว', unit: 'นิ้ว'),
        _MeasureField(keyName: 'แขนกว้าง', label: 'แขนกว้าง', unit: 'นิ้ว'),
        _MeasureField(keyName: 'รอบศอก', label: 'รอบศอก', unit: 'นิ้ว'),
        _MeasureField(keyName: 'ต้นแขน', label: 'ต้นแขน', unit: 'นิ้ว'),
        _MeasureField(keyName: 'เสื้อยาว', label: 'เสื้อยาว', unit: 'นิ้ว'),
        _MeasureField(keyName: 'บ่าหน้า', label: 'บ่าหน้า', unit: 'นิ้ว'),
        _MeasureField(keyName: 'บ่าหลัง', label: 'บ่าหลัง', unit: 'นิ้ว'),
        _MeasureField(keyName: 'ยาวหลัง', label: 'ยาวหลัง', unit: 'นิ้ว'),
      ];
    } else {
      // กางเกง
      return const [
        _MeasureField(keyName: 'เอว', label: 'เอว', unit: 'นิ้ว'),
        _MeasureField(keyName: 'สะโพก', label: 'สะโพก', unit: 'นิ้ว'),
        _MeasureField(keyName: 'เป้า', label: 'เป้า', unit: 'นิ้ว'),
        _MeasureField(keyName: 'ต้นขา', label: 'ต้นขา', unit: 'นิ้ว'),
        _MeasureField(keyName: 'ยาว', label: 'ยาว', unit: 'นิ้ว'),
        _MeasureField(keyName: 'ขากว้าง', label: 'ขากว้าง', unit: 'นิ้ว'),
      ];
    }
  }

  void _initializeControllers() {
    // ล้างการควบคุมเก่าก่อน (ถ้ามี)
    for (final c in _controllers.values) {
      c.dispose();
    }
    // สร้างการควบคุมใหม่สำหรับฟิลด์ปัจจุบัน
    _controllers = {
      for (final f in _fields) f.keyName: TextEditingController(),
    };
  }

  @override
  void initState() {
    super.initState();
    _selected = widget.initialGarmentType;
    _initializeControllers();
    _initSpeechFlow();
    if (widget.openPickerRequest > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGarmentPickerFromNavigation();
      });
    }
  }

  @override
  void didUpdateWidget(covariant MiccPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialGarmentType != oldWidget.initialGarmentType &&
        widget.initialGarmentType != GarmentType.none) {
      setState(() {
        _selected = widget.initialGarmentType;
        _initializeControllers();
        _pageIndex = 0;
        _pageController.jumpToPage(0);
      });
    }
    if (widget.openPickerRequest != oldWidget.openPickerRequest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGarmentPickerFromNavigation();
      });
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _initSpeechFlow() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;

    if (status.isPermanentlyDenied) {
      _toast('ไมค์ถูกปิดถาวร → ไปเปิดใน Settings');
      await openAppSettings();
      setState(() => _speechReady = false);
      return;
    }
    if (!status.isGranted) {
      _toast('ยังไม่ได้อนุญาตไมค์');
      setState(() => _speechReady = false);
      return;
    }

    final ok = await _speech.initialize(
      onStatus: (s) {
        if (!mounted) return;
        setState(() => _isListening = (s == 'listening'));
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _isListening = false);

        if (e.errorMsg.contains('error_speech_timeout')) {
          _toast(
            'หมดเวลารอฟังเสียง: ถ้าใช้อีมูเลเตอร์ให้เปิดเสียงไมค์จากเครื่อง หรือทดสอบบนมือถือจริง',
          );
        } else {
          _toast('ระบบฟังเสียงมีปัญหา: ${e.errorMsg}');
        }
      },
    );

    if (!mounted) return;
    setState(() => _speechReady = ok);

    if (!ok) {
      _toast('ระบบฟังเสียงไม่พร้อมใช้งาน');
      return;
    }

    // หา locale ไทยอัตโนมัติ
    try {
      final locales = await _speech.locales();
      final th = locales.where(
        (l) =>
            l.localeId.toLowerCase().startsWith('th') ||
            l.name.toLowerCase().contains('thai'),
      );
      if (!mounted) return;
      setState(() => _localeId = th.isNotEmpty ? th.first.localeId : null);
    } catch (_) {
      if (!mounted) return;
      setState(() => _localeId = null);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    _speech.stop();
    super.dispose();
  }

  Future<void> _ensureSelected() async {
    if (_selected != GarmentType.none) return;
    final result = await showGarmentDialog(context);
    if (result != null) {
      setState(() {
        _selected = result;
        _initializeControllers();
        _pageIndex = 0;
        _pageController.jumpToPage(0);
      });
    }
  }

  Future<void> _showGarmentPickerFromNavigation() async {
    if (!mounted || _pickerOpening) return;
    _pickerOpening = true;
    final result = await showGarmentDialog(context);
    if (mounted && result != null) {
      setState(() {
        _selected = result;
        _initializeControllers();
        _pageIndex = 0;
        _pageController.jumpToPage(0);
      });
    }
    _pickerOpening = false;
  }

  // ✅ ขอให้การเลื่อนหน้า "เสร็จ" ก่อนค่อยทำต่อ
  Future<void> _goNextFieldAndWait() async {
    if (_pageIndex >= _fields.length - 1) return;

    _waitPageChange = Completer<void>();

    _pageController.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );

    // รอ onPageChanged มาปลดล็อก
    await _waitPageChange!.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () {},
    );
  }

  // ✅ ฟัง 1 รอบ (แต่ทำให้ “ไหลต่อ” ด้วยการเรียกซ้ำเอง)
  Future<void> _startListeningOnce() async {
    if (!_speechReady) return;

    final currentKey = _fields[_pageIndex].keyName;
    final c = _controllers[currentKey]!;

    await _speech.listen(
      localeId: _localeId ?? 'th_TH',
      partialResults: true,
      listenMode: stt.ListenMode.confirmation,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
      onResult: (result) async {
        if (!result.finalResult) return;

        final number = ThaiSpokenNumberParser.extractNumber2dp(
          result.recognizedWords,
        );

        // ❌ จับเลขไม่ได้
        if (number.isEmpty) {
          _toast('จับเลขไม่ได้ ลองพูดแบบ: "สามสิบสองจุดห้า" หรือ "32.5"');

          // ถ้าต้องการให้ฟังต่อแม้จับไม่ได้
          if (_autoContinue && mounted) {
            await Future.delayed(const Duration(milliseconds: 250));
            if (!_restarting && !_isListening) {
              _restarting = true;
              await _startListeningOnce();
              _restarting = false;
            }
          }
          return;
        }

        // ✅ ใส่ค่า
        c.text = number;
        c.selection = TextSelection.collapsed(offset: c.text.length);

        // ✅ ถ้าครบทุกช่องแล้วหยุด
        if (_pageIndex >= _fields.length - 1) {
          await _speech.stop();
          _toast('ครบทุกสัดส่วนแล้ว ✅');
          return;
        }

        // ✅ ไปช่องถัดไป และรอให้ page เปลี่ยนจริง
        await _goNextFieldAndWait();

        // ✅ ฟังต่ออัตโนมัติ (ถ้ายังเปิด autoContinue และ user ยังไม่กดหยุด)
        if (_autoContinue && mounted) {
          await Future.delayed(const Duration(milliseconds: 200));
          if (!_restarting && !_isListening) {
            _restarting = true;
            await _startListeningOnce();
            _restarting = false;
          }
        }
      },
    );
  }

  Future<void> _onMicTap() async {
    await _ensureSelected();
    if (_selected == GarmentType.none) return;

    final mic = await Permission.microphone.status;
    if (!mic.isGranted) {
      _toast('กรุณาอนุญาตไมค์ก่อน');
      return;
    }

    if (!_speechReady) {
      await _initSpeechFlow();
      if (!_speechReady) return;
    }

    // ✅ ถ้ากำลังฟังอยู่ -> กดเพื่อหยุด
    if (_isListening) {
      _autoContinue = false;
      await _speech.stop();
      _toast('หยุดฟังแล้ว');
      return;
    }

    // ✅ เริ่มฟังแบบไหลต่อ
    _autoContinue = true;
    await _startListeningOnce();
  }

  void _clearAll() {
    for (final c in _controllers.values) {
      c.clear();
    }
    setState(() => _pageIndex = 0);
    _pageController.jumpToPage(0);
  }

  Future<void> _save() async {
    await _ensureSelected();
    if (!mounted) return;
    if (_selected == GarmentType.none) return;

    final measures = <String, String>{
      for (final f in _fields)
        f.keyName: ThaiToArabicDigitsFormatter.to2dpOrEmpty(
          _controllers[f.keyName]!.text,
        ),
    };

    final result = await showSaveCustomerDialog(
      context: context,
      garmentType: _selected,
      measures: measures,
      initialCategory: _isPackageFolderFlow
          ? WorkCategory.package
          : widget.initialCategory,
      initialPackageName: widget.packageFolderName ?? '',
      packageFolderId: widget.packageFolderId ?? '',
      lockCategory: _isPackageFolderFlow,
    );

    if (result == null) return;

    try {
      // ✅ เลือก default status ของงานใหม่ (เช่น doing)
      final jobId = await _fs.createJob(
        customer: result,
        measures: measures,
        garmentType: _selected,
        status: 'doing',
        packageFolderId: widget.packageFolderId,
      );

      debugPrint('✅ Saved jobId=$jobId');
      _toast('บันทึกลงระบบแล้ว ✅');
    } catch (e) {
      debugPrint('❌ Save error: $e');
      _toast('บันทึกไม่สำเร็จ ❌');
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUse = _selected != GarmentType.none;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // เลือกประเภท
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final result = await showGarmentDialog(context);
                    if (result != null) {
                      setState(() {
                        _selected = result;
                        _initializeControllers();
                        _pageIndex = 0;
                        _pageController.jumpToPage(0);
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          canUse
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: canUse ? Colors.blueAccent : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            canUse
                                ? 'เลือก: ${garmentTypeLabel(_selected)}'
                                : 'ยังไม่ได้เลือกประเภท',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          'เลือก',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.blueAccent.withOpacity(0.9),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // PageView แนวตั้ง
              Expanded(
                child: IgnorePointer(
                  ignoring: !canUse,
                  child: Opacity(
                    opacity: canUse ? 1 : 0.45,
                    child: PageView.builder(
                      scrollDirection: Axis.vertical,
                      controller: _pageController,
                      itemCount: _fields.length,
                      onPageChanged: (i) {
                        setState(() => _pageIndex = i);
                        // ✅ ปลดล็อกรอ page change (สำหรับ autoContinue)
                        if (_waitPageChange != null &&
                            !_waitPageChange!.isCompleted) {
                          _waitPageChange!.complete();
                        }
                      },
                      itemBuilder: (context, i) {
                        final isCurrent = i == _pageIndex;
                        final f = _fields[i];

                        return AnimatedScale(
                          duration: const Duration(milliseconds: 180),
                          scale: isCurrent ? 1.0 : 0.92,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: isCurrent ? 1.0 : 0.28,
                            child: MeasureSlide(
                              label: f.label,
                              unit: f.unit,
                              controller: _controllers[f.keyName]!,
                              isCurrent: isCurrent,
                              onDone: () async {
                                // กด done จากคีย์บอร์ด => ไปถัดไป
                                await _goNextFieldAndWait();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ปุ่มล่าง
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 44),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: canUse ? _clearAll : null,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF8F8F8F),
                        ),
                        child: const Text(
                          'ล้างค่า',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canUse ? _save : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          'บันทึก',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 52),
            ],
          ),
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: GestureDetector(
          onTap: canUse ? _onMicTap : () async => _ensureSelected(),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: canUse
                  ? Colors.blueAccent
                  : Colors.blueAccent.withOpacity(0.35),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              _isListening ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}

class _MeasureField {
  final String keyName;
  final String label;
  final String unit;
  const _MeasureField({
    required this.keyName,
    required this.label,
    required this.unit,
  });
}
