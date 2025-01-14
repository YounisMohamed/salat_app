import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'api.dart';
import 'notification_service.dart';

class WorkManagerService {
  static const String TEST_NOTIFICATION_TASK = 'periodic_task_take_7';
  static const Duration REFRESH_INTERVAL = Duration(hours: 4);

  static Future<void> init() async {
    print("[WorkManager] Initializing...");
    await Workmanager().initialize(callbackDispatcher);
    print("[WorkManager] Initialized successfully");
  }

  static Future<void> registerTask() async {
    print("[WorkManager] Registering periodic task");

    await Workmanager().registerPeriodicTask(
      TEST_NOTIFICATION_TASK,
      TEST_NOTIFICATION_TASK,
      frequency: REFRESH_INTERVAL,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );

    print("[WorkManager] Tasks registered successfully");
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      print("[WorkManager] Retrieving preferences...");
      final lat = prefs.getString("lat") ?? "";
      final lon = prefs.getString("lon") ?? "";
      print("[WorkManager] Location: lat=$lat, lon=$lon");

      if (lat.isEmpty || lon.isEmpty) {
        print("[WorkManager] ERROR: No location found");
        throw Exception("No location found");
      }

      final method = prefs.getInt("method") ?? 5;
      final reciter = prefs.getInt("reciter") ?? 1;
      tz.initializeTimeZones();

      final List<String> prayerNamesForNotifications = [
        "Fajr",
        "Shuruq",
        "Dhuhr",
        "Asr",
        "Maghrib",
        "Isha",
      ];

      Map<String, bool> notificationPreferences = {
        for (var prayer in prayerNamesForNotifications)
          prayer: prefs.getBool('notification_$prayer') ?? true
      };

      print(
          "[WorkManager] Fetching prayer times with method=$method, reciter=$reciter");
      print("[WorkManager] Notification preferences: $notificationPreferences");

      await fetchPrayerTimesFromApi(
          lat, lon, method, reciter, notificationPreferences);

      print("[WorkManager] Task completed successfully");
      return Future.value(true);
    } catch (e, stackTrace) {
      print("[WorkManager] Task failed with error: $e");
      print("[WorkManager] Stack trace: $stackTrace");
      return Future.value(false);
    }
  });
}

Future<void> fetchPrayerTimesFromApi(String lat, String lon, int method,
    int reciter, Map<String, bool> notificationPreferences) async {
  final Api api = Api();
  final now = DateTime.now();
  String day = now.day < 10 ? "0${now.day}" : "${now.day}";
  String month = now.month < 10 ? "0${now.month}" : "${now.month}";
  final date = "$day-$month-${now.year}";

  try {
    print("[WorkManager] Starting API fetch...");
    final response =
        await api.getTimings(date: date, lat: lat, lon: lon, method: method);
    if (!response.isSuccess) {
      throw Exception("API CALL FAILED FROM WM");
    }

    print("[WorkManager] Response validation successful");
    tz.initializeTimeZones();
    await NotificationService.init("Work Manager");

    final timings = response.data!.timings;
    final Map<String, String> prayerTimes = {
      "Fajr": timings.fajr,
      "Shuruq": timings.sunrise,
      "Dhuhr": timings.dhuhr,
      "Asr": timings.asr,
      "Maghrib": timings.maghrib,
      "Isha": timings.isha,
    };

    final active = await NotificationService.notificationsPlugin
        .pendingNotificationRequests();
    print("[WorkManager] Current active notifications: ${active.length}");

    List<String> existingPrayers = [];
    for (var notification in active) {
      String title = notification.title ?? "";
      if (title.contains("Prayer")) {
        String prayerName = title.split(" ")[0];
        existingPrayers.add(prayerName);
      }
    }

    print("[WorkManager] Existing notifications array created");

    for (int i = 0; i < prayerTimes.length; i++) {
      String prayerName = prayerTimes.keys.toList()[i];
      String? prayerTime = prayerTimes[prayerName];

      if (!notificationPreferences[prayerName]!) {
        print("[WorkManager] Skipping $prayerName - notifications disabled");
        continue;
      }

      try {
        final DateTime parsedTime = DateFormat("HH:mm").parse(prayerTime!);
        DateTime scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          parsedTime.hour,
          parsedTime.minute,
        );

        if (scheduledTime.isBefore(now)) {
          scheduledTime = DateTime(
            now.year,
            now.month,
            now.day + 1,
            parsedTime.hour,
            parsedTime.minute,
          );
        }

        String hour = parsedTime.hour < 9
            ? "0${parsedTime.hour}"
            : parsedTime.hour.toString();
        String minute = parsedTime.minute < 9
            ? "0${parsedTime.minute}"
            : parsedTime.minute.toString();

        if (existingPrayers.contains(prayerName)) {
          print(
              "[WorkManager] Notification for $prayerName already exists for same time. Skipping.");
          continue;
        }

        print(
            "[WorkManager] Scheduling notification for $prayerName at $hour:$minute");

        await NotificationService.scheduleNotification(
            id: prayerName.hashCode,
            title: "$prayerName Prayer",
            body: "($hour:$minute) It's time for $prayerName prayer.",
            scheduledTime: scheduledTime,
            soundNumber: reciter);

        print(
            "[WorkManager] Successfully scheduled notification for $prayerName");
      } catch (e, stackTrace) {
        print("[WorkManager] Error scheduling $prayerName notification:");
        print("[WorkManager] Error: $e");
        print("[WorkManager] StackTrace: $stackTrace");
      }
    }

    // Print final active notifications for verification
    final finalActive = await NotificationService.notificationsPlugin
        .pendingNotificationRequests();
    print("[WorkManager] Final scheduled notifications: ${finalActive.length}");
    for (var notification in finalActive) {
      print(
          "[WorkManager] Active notification: ${notification.id} - ${notification.body}");
    }
  } catch (e, stackTrace) {
    print("[WorkManager] Critical error in fetchPrayerTimesFromApi:");
    print("[WorkManager] Error: $e");
    print("[WorkManager] StackTrace: $stackTrace");
    rethrow;
  }
}
