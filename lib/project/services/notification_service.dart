import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class  NotificationService {
  // Allow injecting a plugin instance for testing. If null, a default
  // FlutterLocalNotificationsPlugin is created.
  static FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Setter used by tests to replace the plugin with a mock.
  static set notificationsPlugin(FlutterLocalNotificationsPlugin plugin) =>
      _notificationsPlugin = plugin;

  // Callback để xử lý khi user click vào notification
  static Function(String?)? onNotificationTap;

  static Future<void> init() async {
    // Khởi tạo timezone
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi user tap vào notification
        if (response.payload != null && onNotificationTap != null) {
          onNotificationTap!(response.payload);
        }
      },
    );

    // Request permission cho iOS
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static Future<void> scheduleDailyReminder(int hour, int minute) async {
    await _notificationsPlugin.zonedSchedule(
      0,
      'Nhập chi tiêu hôm nay',
      'Đừng quên ghi lại các khoản chi trong ngày nhé!',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_notif',
          'Daily Reminder',
          channelDescription: 'Nhắc nhập chi tiêu hằng ngày',
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
      matchDateTimeComponents: DateTimeComponents.time, // lặp lại hàng ngày
      payload: 'add_input', // payload để biết cần mở màn hình nào
    );
  }

  static Future<void> cancelReminder() async {
    await _notificationsPlugin.cancel(0);
  }

  // Show an immediate notification (useful for testing on device/emulator)
  static Future<void> showTestNotification({
    int id = 999,
    String title = 'Test Notification',
    String body = 'This is a test',
    String? payload,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Channel',
          channelDescription: 'Channel for manual testing',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  // Expose the next scheduled time for testing
  static tz.TZDateTime nextInstanceOfTime(int hour, int minute) =>
      _nextInstanceOfTime(hour, minute);

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // Request permission cho Android 13+
  static Future<bool> requestPermission() async {
    if (await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled() ??
        false) {
      return true;
    }

    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final result =
        await androidImplementation?.requestNotificationsPermission();
    return result ?? false;
  }
}
