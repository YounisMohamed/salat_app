import 'package:awqatalsalah/LocationPickerScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'MainPage.dart';
import 'Services/notification_service.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Handle background task
      print("Executing task: $task with inputData: $inputData");

      // Example: Fetch prayer times and schedule notifications
      // Ensure this logic doesn't depend on the main app context
      if (task == "schedulePrayerNotifications") {
        // Simulate a task, e.g., logging or scheduling notifications
        print("Background task running for prayer notifications.");
      }

      return Future.value(true);
    } catch (e, stackTrace) {
      print("Error in background task: $e");
      print(stackTrace);
      return Future.value(false);
    }
  });
}

String lat = "";
String lon = "";
bool latlonSet = false;

Future<void> setLatLon() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  lat = prefs.getString('lat') ?? '';
  lon = prefs.getString('lon') ?? '';
  latlonSet = prefs.getBool("latlonSet") ?? false;
  print(latlonSet);
  print("SET LAT LON ON MAIN ^");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setLatLon();
  await NotificationService.init();
  tz.initializeTimeZones();
  Workmanager().initialize(callbackDispatcher);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prayer Times',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: latlonSet ? MainPage() : LocationPickerScreen(),
    );
  }
}
