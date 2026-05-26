import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      linux: LinuxInitializationSettings(defaultActionName: 'เปิด'),
      windows: WindowsInitializationSettings(
        appName: 'ระบบร้านตัดเย็บ',
        appUserModelId: 'com.example.sewing',
        guid: 'd3d8b214-bd38-4d5d-9ca0-6381f3214b39',
      ),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _plugin.initialize(settings: initializationSettings);
    _initialized = true;
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showJobCreated({
    required String jobId,
    required String title,
    required DateTime pickupDate,
  }) async {
    await _runSafely(() async {
      await init();
      final date = DateFormat('dd/MM/yyyy', 'th_TH').format(pickupDate);
      await _plugin.show(
        id: _notificationId(jobId),
        title: 'บันทึกงานใหม่แล้ว',
        body: '$title • วันรับ $date',
        notificationDetails: _details(),
        payload: jobId,
      );
    });
  }

  Future<void> showJobCompleted({
    required String jobId,
    required String title,
  }) async {
    await _runSafely(() async {
      await init();
      await _plugin.show(
        id: _notificationId('done_$jobId'),
        title: 'ยืนยันงานเสร็จแล้ว',
        body: '$title ถูกย้ายไปหน้าประวัติแล้ว',
        notificationDetails: _details(),
        payload: jobId,
      );
    });
  }

  Future<void> schedulePickupReminder({
    required String jobId,
    required String title,
    required DateTime pickupDate,
  }) async {
    await _runSafely(() async {
      if (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.macOS) {
        return;
      }
      await init();
      final now = tz.TZDateTime.now(tz.local);
      final scheduleAt = tz.TZDateTime(
        tz.local,
        pickupDate.year,
        pickupDate.month,
        pickupDate.day,
        9,
      );

      if (!scheduleAt.isAfter(now.add(const Duration(minutes: 1)))) {
        return;
      }

      await _plugin.zonedSchedule(
        id: _notificationId('pickup_$jobId'),
        title: 'แจ้งเตือนงานที่ต้องส่งวันนี้',
        body: '$title ถึงวันรับงานแล้ว',
        scheduledDate: scheduleAt,
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: jobId,
      );
    });
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'sewing_jobs',
        'แจ้งเตือนงานตัดเย็บ',
        channelDescription: 'แจ้งเตือนงานใหม่ วันรับงาน และงานที่ทำเสร็จ',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
  }

  int _notificationId(String value) {
    return value.codeUnits.fold<int>(0, (hash, unit) {
      return (hash * 31 + unit) & 0x7fffffff;
    });
  }

  Future<void> _runSafely(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Notification failures should not block saving or updating jobs.
    }
  }
}
