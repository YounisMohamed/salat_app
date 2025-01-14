import 'package:awqatalsalah/LocationPickerScreen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.blue,
          secondary: Colors.green,
          background: Colors.blue.shade50,
          onBackground: Colors.blue.shade900,
          surface: Colors.white,
          onSurface: Colors.blue.shade700,
          error: Colors.redAccent,
        ),
      ),
      home: const PermissionPage(),
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
      _showSnackBar(context, 'All permissions granted!',
          Theme.of(context).colorScheme.secondary);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
      );
    } else {
      _showSnackBar(context, 'Some permissions are missing!',
          Theme.of(context).colorScheme.error);
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
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(ctx);
            },
            child: Text(
              'Open Settings',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
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
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.background,
            ],
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
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'App Permissions Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'To provide you with the best experience, we need the following permissions:',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ListTile(
                  leading:
                      Icon(Icons.location_on, color: theme.colorScheme.primary),
                  title: const Text('Location Permission'),
                  subtitle: const Text(
                      'To access your location for accurate prayer times.'),
                ),
                ListTile(
                  leading: Icon(Icons.notifications,
                      color: theme.colorScheme.primary),
                  title: const Text('Notification Permission'),
                  subtitle: const Text('To notify you about the prayer times.'),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _requestPermissions(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Grant Permissions',
                    style: TextStyle(
                        fontSize: 18, color: theme.colorScheme.onPrimary),
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
