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

  static Future<void> showInstantNotification(String title, String body) async {
    const NotificationDetails platformChannelSpecifies = NotificationDetails(
        android: AndroidNotificationDetails("channel_Id", "channel_Name",
            importance: Importance.high, priority: Priority.high),
        iOS: DarwinNotificationDetails());
    await notificationsPlugin.show(0, title, body, platformChannelSpecifies);
  }

  static Future<void> showScheduleNotification(
      {required id,
      required String title,
      required String body,
      required DateTime scheduledTime}) async {
    const NotificationDetails platformChannelSpecifies = NotificationDetails(
        android: AndroidNotificationDetails("channel_Id", "channel_Name",
            importance: Importance.high, priority: Priority.high),
        iOS: DarwinNotificationDetails());
    await notificationsPlugin.zonedSchedule(0, title, body,
        tz.TZDateTime.from(scheduledTime, tz.local), platformChannelSpecifies,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime);
  }
}
