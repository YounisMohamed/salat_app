import 'package:awqatalsalah/AppRouter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'Services/WorkManagerService.dart';
import 'Services/notification_service.dart';
import 'Services/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init("Main");
  await WorkManagerService.init();
  tz.initializeTimeZones();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ReciterProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => MethodProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Prayer Times',
      locale: Locale(languageProvider.selectedLanguage == 2 ? "ar" : "en"),
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: themeProvider.selectedTheme),
        useMaterial3: true,
      ),
      home: Directionality(
          textDirection: languageProvider.selectedLanguage == 2
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: const AppRouter()),
    );
  }
}
