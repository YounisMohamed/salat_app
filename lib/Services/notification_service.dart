import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Map<int, Map<String, String>> channels = {
    1: {"channelId": "_adhan_1", "channelName": "1", "soundFile": "adhan_1"},
    2: {"channelId": "_adhan_2", "channelName": "2", "soundFile": "adhan_2"},
    3: {"channelId": "_adhan_3", "channelName": "3", "soundFile": "adhan_3"},
    4: {"channelId": "_adhan_4", "channelName": "4", "soundFile": "adhan_4"},
    5: {"channelId": "_adhan_5", "channelName": "5", "soundFile": "adhan_5"},
    6: {"channelId": "_adhan_6", "channelName": "6", "soundFile": "adhan_6"},
    7: {"channelId": "_adhan_7", "channelName": "7", "soundFile": "adhan_7"},
    8: {"channelId": "_adhan_8", "channelName": "8", "soundFile": "adhan_8"},
    9: {"channelId": "_adhan_9", "channelName": "9", "soundFile": "adhan_9"},
    10: {
      "channelId": "_adhan_10",
      "channelName": "10",
      "soundFile": "adhan_10"
    },
  };

  static Future<void> init(String context) async {
    print("COMING FROM: $context");
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings("@mipmap/launcher_icon");
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onReceiveNoti,
      onDidReceiveBackgroundNotificationResponse: onReceiveNoti,
    );

    // Create all channels during initialization
    for (var channelData in channels.values) {
      final AndroidNotificationChannel channel = AndroidNotificationChannel(
          channelData['channelId']!, channelData['channelName']!,
          description: 'This channel is used for prayer reminders',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound(channelData['soundFile']!),
          playSound: true,
          audioAttributesUsage: AudioAttributesUsage.media);

      await notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  static Future<void> onReceiveNoti(NotificationResponse notResponse) async {}

  static Future<void> showInstantNotification(String title, String body) async {
    const NotificationDetails platformChannelSpecifies = NotificationDetails(
        android: AndroidNotificationDetails("channel_Id", "channel_Name",
            importance: Importance.high, priority: Priority.high),
        iOS: DarwinNotificationDetails());
    await notificationsPlugin.show(0, title, body, platformChannelSpecifies);
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required int soundNumber,
  }) async {
    final channelData = channels[soundNumber]!;
    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        channelData['channelId']!,
        channelData['channelName']!,
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(channelData['soundFile']!),
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
        audioAttributesUsage: AudioAttributesUsage.media,
      ),
    );

    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}
