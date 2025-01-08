import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static Future<void> onReceiveNoti(NotificationResponse notResponse) async {}
  static Future<void> init() async {
    //
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings("@mipmap/launcher_icon");
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iOSSettings);
    await notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onReceiveNoti,
      onDidReceiveBackgroundNotificationResponse: onReceiveNoti,
    );
    // Request Permission for android:
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleNotification(
      {required int id,
      required String title,
      required String body,
      required DateTime scheduledTime}) async {
    await notificationsPlugin.zonedSchedule(
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminder Channel',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}
