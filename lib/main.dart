import 'package:awqatalsalah/LocationPickerScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'MainPage.dart';
import 'Services/notification_service.dart';
import 'Services/provider.dart';

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
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ReciterProvider()),
    ],
    child: const MyApp(),
  ));
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
