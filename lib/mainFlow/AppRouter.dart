import 'package:awqatalsalah/mainFlow/settingsPageAtTheStart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'LocationPickerScreen.dart';
import 'MainPage.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  late Future<void> _future;

  @override
  void initState() {
    _future = setLatLon().then((_) {
      _checkFirstLaunch();
    });
    super.initState();
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
    print("SET LAT LON ON APP ROUTER");
  }

  bool _isFirstLaunch = true;
  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      prefs.setBool('isFirstLaunch', false);
    }

    setState(() {
      _isFirstLaunch = isFirstLaunch;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF128C7E),
                ),
              );
            }
            if (_isFirstLaunch) {
              return const SettingsPageAtTheStart();
            }
            if (latlonSet) {
              return const MainPage();
            }
            return const LocationPickerScreen();
          }),
    );
  }
}
