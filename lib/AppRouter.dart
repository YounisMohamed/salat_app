import 'package:awqatalsalah/LocationPickerScreen.dart';
import 'package:awqatalsalah/MainPage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRouter extends StatefulWidget {
  AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  @override
  void initState() {
    setLatLon();
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
    print("SET LAT LON ON MAIN ^");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          future: setLatLon(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF128C7E),
                ),
              );
            }
            return latlonSet ? const MainPage() : const LocationPickerScreen();
          }),
    );
  }
}
