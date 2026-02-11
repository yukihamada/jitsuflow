import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// 予約リマインダー通知を管理するサービス
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// 通知プラグインを初期化する
  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  /// 予約の1時間前にリマインダー通知をスケジュールする
  static Future<void> scheduleBookingReminder({
    required int bookingId,
    required String className,
    required String dojoName,
    required DateTime classTime,
  }) async {
    final scheduledTime = classTime.subtract(const Duration(hours: 1));
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      bookingId,
      '$className まもなく開始',
      '$dojoName で1時間後にクラスが始まります',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'booking_reminders',
          '予約リマインダー',
          channelDescription: 'クラス開始1時間前の通知',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 指定した予約のリマインダー通知をキャンセルする
  static Future<void> cancelBookingReminder(int bookingId) async {
    await _notifications.cancel(bookingId);
  }

  /// すべてのリマインダー通知をキャンセルする
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
