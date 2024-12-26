import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static Future<void> onReceiveNoti(NotificationResponse notResponse) async {}
  static Future<void> init() async {
    // @mipmap/prayerpngicon.png
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings("prayerpngicon.png");
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

  static Future<void> showInstantNotification(
      String title, String Body) async {}
}
