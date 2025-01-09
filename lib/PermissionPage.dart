import 'package:awqatalsalah/LocationPickerScreen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PermissionPage(),
    );
  }
}

class PermissionPage extends StatelessWidget {
  const PermissionPage({super.key});

  Future<void> _requestPermissions(BuildContext context) async {
    final locationStatus = await Permission.locationWhenInUse.request();
    final notificationStatus = await Permission.notification.request();
    final alarmStatus = await Permission.scheduleExactAlarm.request();

    if (locationStatus.isGranted &&
        alarmStatus.isGranted &&
        notificationStatus.isGranted) {
      _showSnackBar(context, 'All permissions granted!', Colors.green);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
      );
    } else {
      _showSnackBar(context, 'Some permissions are missing!', Colors.redAccent);
      if (locationStatus.isPermanentlyDenied ||
          alarmStatus.isPermanentlyDenied ||
          notificationStatus.isPermanentlyDenied) {
        _showSettingsDialog(context);
      }
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
            'Some permissions were permanently denied. Please enable them in the app settings to ensure the app functions properly.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(ctx);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text, textAlign: TextAlign.center),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade400],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.lock,
                  size: 100,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(height: 20),
                Text(
                  'App Permissions Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'To provide you with the best experience, we need the following permissions:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.blue),
                  title: const Text('Location Permission'),
                  subtitle: const Text(
                      'To access your location for accurate prayer times.'),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.blue),
                  title: const Text('Notification Permission'),
                  subtitle: const Text('To notify you about the prayer times.'),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _requestPermissions(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Grant Permissions',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
