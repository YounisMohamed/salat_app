import 'package:awqatalsalah/Services/WorkManagerService.dart';
import 'package:awqatalsalah/Services/response.dart';
import 'package:awqatalsalah/mainFlow/settingsPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Services/api.dart';
import '../Services/notification_service.dart';
import '../Services/provider.dart';
import 'LocationPickerScreen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Future<void> _prayerTimesFuture;
  late SharedPreferences _prefs;

  final List<String> prayerNamesForNotifications = [
    "Fajr",
    "Shuruq",
    "Dhuhr",
    "Asr",
    "Maghrib",
    "Isha",
  ];

  Map<String, bool> notificationPreferences = {};

  @override
  void initState() {
    super.initState();
    _initNotificationsPreferences();
    _prayerTimesFuture = fetchPrayerTimes().then((_) {
      fetchPrayerTimesAndScheduleNotifications();
    }).then((_) {
      WorkManagerService.registerTask();
    });
  }

  Future<void> _initNotificationsPreferences() async {
    _prefs = await SharedPreferences.getInstance();

    // Load notification preferences
    setState(() {
      notificationPreferences = {
        for (var prayer in prayerNamesForNotifications)
          prayer: _prefs.getBool('notification_$prayer') ?? true
      };
    });
  }

  void _toggleNotification(String prayer) async {
    setState(() {
      notificationPreferences[prayer] = !notificationPreferences[prayer]!;
    });

    // Save the updated preference
    await _prefs.setBool(
        'notification_$prayer', notificationPreferences[prayer]!);
    await fetchPrayerTimesAndScheduleNotifications();
  }

  Future<void> fetchPrayerTimesAndScheduleNotifications() async {
    await NotificationService.notificationsPlugin.cancelAll();
    final reciterProvider =
        Provider.of<ReciterProvider>(context, listen: false);
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    print("All scheduled notifications cleared In main page.");
    //await fetchPrayerTimes();

    if (_prayerData != null) {
      final Map<String, String> prayerTimes = {
        "Fajr": _prayerData!.timings.fajr,
        "Shuruq": _prayerData!.timings.sunrise,
        "Dhuhr": _prayerData!.timings.dhuhr,
        "Asr": _prayerData!.timings.asr,
        "Maghrib": _prayerData!.timings.maghrib,
        "Isha": _prayerData!.timings.isha,
      };

      for (int i = 0; i < prayerTimes.length; i++) {
        String prayerName = prayerTimes.keys.toList()[i];
        String? prayerTime = prayerTimes[prayerName];
        if (!notificationPreferences[prayerName]!) continue;
        try {
          final DateTime now = DateTime.now();

          final DateTime parsedTime = DateFormat("HH:mm").parse(prayerTime!);
          DateTime scheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            parsedTime.hour,
            parsedTime.minute,
          );

          // If the prayer time has already passed for today, schedule for the next day (EDGE CASE FOR FAJR)
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

          if (languageProvider.selectedLanguage == 2) {
            String bodyArabic = "($hour:$minute)" " حان وقت الصلاة";
            await NotificationService.scheduleNotification(
                id: prayerName.hashCode,
                title: "$prayerName Prayer",
                body: bodyArabic,
                scheduledTime: scheduledTime,
                soundNumber: reciterProvider.selectedReciter);
          } else {
            await NotificationService.scheduleNotification(
                id: prayerName.hashCode,
                title: "$prayerName Prayer",
                body: "($hour:$minute) It's time for $prayerName prayer.",
                scheduledTime: scheduledTime,
                soundNumber: reciterProvider.selectedReciter);
          }

          print("scheduled time $scheduledTime for prayer $prayerName");
        } catch (e) {
          print("Error scheduling notification for $prayerName: $e");
        }
        print("PRAYER NAME HASHCODE: ${prayerName.hashCode}");
      }
      List<PendingNotificationRequest> finalActive = await NotificationService
          .notificationsPlugin
          .pendingNotificationRequests();
      for (int i = 0; i < finalActive.length; i++) {
        print(
            "Active ${i + 1} is ${finalActive[i].body} HASH CODE: ${finalActive[i].id}");
      }
    } else {
      print("error");
    }
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
    print("SET LAT LON ON MAIN PAGE");
  }

  final Api _api = Api();
  AdhanResponse? _prayerData;

  Future<void> fetchPrayerTimesFromApi(SharedPreferences prefs) async {
    final methodProvider = Provider.of<MethodProvider>(context, listen: false);
    if (!latlonSet || lat.isEmpty || lon.isEmpty) {
      print("lat lon is not set $latlonSet");
      print("lat is empty ${lat.isEmpty}");
      print("lon is empty ${lon.isEmpty}");

      print("Location data missing, cannot fetch prayer times");
      return;
    }

    final now = DateTime.now();
    String day = now.day < 10 ? "0${now.day}" : "${now.day}";
    String month = now.month < 10 ? "0${now.month}" : "${now.month}";
    final date = "$day-$month-${now.year}";

    try {
      print("Fetching prayer times from API");
      print("SELECTED METHOD: ${methodProvider.selectedMethod}");
      final response = await _api.getTimings(
          date: date,
          lat: lat,
          lon: lon,
          method: methodProvider.selectedMethod);
      if (!response.isSuccess) {
        throw Exception("API CALL FAILED FROM WM");
      }

      setState(() {
        _prayerData = response.data;
      });

      cachePrayerTimes(response.data, prefs, now);
    } catch (e) {
      print('Error fetching prayer times from API: $e');
    }
  }

  Future<void> cachePrayerTimes(
      AdhanResponse? response, SharedPreferences prefs, DateTime now) async {
    try {
      prefs.setString('fajr', response!.timings.fajr);
      prefs.setString('sunrise', response.timings.sunrise);
      prefs.setString('dhuhr', response.timings.dhuhr);
      prefs.setString('asr', response.timings.asr);
      prefs.setString('sunset', response.timings.sunset);
      prefs.setString('maghrib', response.timings.maghrib);
      prefs.setString('isha', response.timings.isha);
      prefs.setInt('lastUpdated', now.millisecondsSinceEpoch);

      print("Prayer times cached successfully");
    } catch (e) {
      print("Error caching prayer times: $e");
    }
  }

  Future<void> fetchPrayerTimes({bool forceRefresh = false}) async {
    await setLatLon();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    print(notificationPreferences);

    // Check if 24 hours have passed since the last update
    final lastUpdatedTimestamp = prefs.getInt('lastUpdated') ?? 0;
    final lastUpdated =
        DateTime.fromMillisecondsSinceEpoch(lastUpdatedTimestamp);

    if (!forceRefresh && now.difference(lastUpdated).inHours < 12) {
      // Load from SharedPreferences
      print("Loading prayer times from cache");
      final cachedTimings = {
        'Fajr': prefs.getString('fajr'),
        'Sunrise': prefs.getString('sunrise'),
        'Dhuhr': prefs.getString('dhuhr'),
        'Asr': prefs.getString('asr'),
        'Sunset': prefs.getString('sunset'),
        'Maghrib': prefs.getString('maghrib'),
        'Isha': prefs.getString('isha'),
      };

      // Validate cache data completeness
      if (cachedTimings.values.any((value) => value == null)) {
        print("Cached data incomplete, triggering API fetch");
        await fetchPrayerTimesFromApi(prefs);
        return;
      }

      // Rebuild prayer data
      setState(() {
        _prayerData = AdhanResponse.fromJson({
          'data': {'timings': cachedTimings},
        });
      });
    } else {
      // Fetch new data from API
      await fetchPrayerTimesFromApi(prefs);
      await fetchPrayerTimesAndScheduleNotifications();
    }
  }

  List<Map<String, String>> get prayerTimes {
    String warningString = "CLICK REFRESH, NO INTERNET";
    if (_prayerData == null) {
      return [
        {'name': 'Fajr', 'time': warningString},
        {'name': 'Shuruq', 'time': warningString},
        {'name': 'Dhuhr', 'time': warningString},
        {'name': 'Asr', 'time': warningString},
        {'name': 'Maghrib', 'time': warningString},
        {'name': 'Isha', 'time': warningString},
      ];
    }

    // Convert times to hh:mm AM/PM
    String formatTime(String? time) {
      if (time == null) return 'N/A';
      try {
        final parsedTime = DateFormat("HH:mm").parse(time);
        return DateFormat("hh:mm a").format(parsedTime);
      } catch (e) {
        print('Error formatting time $time: $e');
        return 'Invalid Time';
      }
    }

    return [
      {'name': 'Fajr', 'time': formatTime(_prayerData!.timings.fajr)},
      {'name': 'Shuruq', 'time': formatTime(_prayerData!.timings.sunrise)},
      {'name': 'Dhuhr', 'time': formatTime(_prayerData!.timings.dhuhr)},
      {'name': 'Asr', 'time': formatTime(_prayerData!.timings.asr)},
      {'name': 'Maghrib', 'time': formatTime(_prayerData!.timings.maghrib)},
      {'name': 'Isha', 'time': formatTime(_prayerData!.timings.isha)},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final translations = languageProvider.translations;
    final theme = Theme.of(context); // Fetch current theme colors

    return Scaffold(
      backgroundColor:
          theme.colorScheme.surface.withOpacity(0.1), // Light gradient
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.primaryColor, // Use theme primary color
        title: Text(
          translations['title']!,
          style: GoogleFonts.nunito(
            fontSize: 21,
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () async {
            setState(() {
              _prayerTimesFuture = fetchPrayerTimes(forceRefresh: true);
            });
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  translations['prayerTimesRefreshed']!,
                  style: GoogleFonts.nunito(),
                ),
                backgroundColor: theme.primaryColor,
                duration: const Duration(milliseconds: 1000),
              ),
            );
          },
          icon: Icon(Icons.refresh, color: theme.colorScheme.onPrimary),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: _prayerTimesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: theme.primaryColor,
                ),
              );
            }

            if (_prayerData == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      translations['locationRequired'] ??
                          "Set Your Location First",
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LocationPickerScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on,
                              color: theme.colorScheme.onPrimary),
                          const SizedBox(width: 8),
                          Text(
                            translations['goToLocationScreen'] ??
                                "Set Location",
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Flexible(
                  flex: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      itemCount: prayerTimes.length,
                      separatorBuilder: (context, index) => Divider(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final prayer = prayerTimes[index];
                        final nextPrayerDetails = calculateNextPrayer();
                        final nextPrayerName =
                            nextPrayerDetails["nextPrayerName"];
                        bool isHighlighted = prayer['name'] == nextPrayerName;

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? theme.colorScheme.primary.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isHighlighted
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary
                                        .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getPrayerIcon(prayer['name']!),
                                color: isHighlighted
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              translations[prayer['name']] ?? prayer['name']!,
                              style: GoogleFonts.nunito(
                                fontWeight: isHighlighted
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: isHighlighted ? 18 : 16,
                                color: isHighlighted
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  languageProvider.selectedLanguage == 2
                                      ? prayer['time']
                                          .toString()
                                          .replaceAll("PM", "مسائا")
                                          .replaceAll("AM", "صباحا")
                                      : prayer['time']!,
                                  style: GoogleFonts.nunito(
                                    fontWeight: isHighlighted
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: isHighlighted ? 18 : 16,
                                    color: isHighlighted
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _toggleNotification(prayer['name']!);
                                    });
                                  },
                                  icon: Icon(
                                    notificationPreferences[prayer['name']!]!
                                        ? Icons.notifications_active
                                        : Icons.notifications_none,
                                    color: notificationPreferences[
                                            prayer['name']!]!
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Flexible(
                  flex: 4,
                  child: _buildBottomSection(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    final reciterProvider = Provider.of<ReciterProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final translations = languageProvider.translations;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: StreamBuilder<DateTime>(
              stream: Stream.periodic(
                const Duration(seconds: 1),
                (_) => DateTime.now(),
              ),
              builder: (context, snapshot) {
                final nextPrayerDetails = calculateNextPrayer();
                final nextPrayerName = nextPrayerDetails["nextPrayerName"];
                final timeUntilNextPrayer =
                    nextPrayerDetails["timeUntilNextPrayer"];
                final now = snapshot.data ?? DateTime.now();
                final currentTime = DateFormat('h:mm:ss a').format(now);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageProvider.selectedLanguage == 2
                          ? currentTime
                              .toString()
                              .replaceAll("PM", "مسائا")
                              .replaceAll("AM", "صباحا")
                          : currentTime,
                      style: GoogleFonts.nunito(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "${translations["nextPrayer"]}: ",
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          TextSpan(
                            text: nextPrayerName ?? 'None',
                            style: GoogleFonts.nunito(
                              fontSize: 22,
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${translations["timeUntil"]}",
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      timeUntilNextPrayer ?? 'None',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.settings,
                          size: 20,
                          color: theme.colorScheme.onPrimary.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await _showReciterDialog(
                            context, reciterProvider, languageProvider);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Text(
                          translations[reciterProvider.selectedReciterName]!,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showReciterDialog(
      BuildContext context,
      ReciterProvider reciterProvider,
      LanguageProvider languageProvider) async {
    final theme = Theme.of(context);
    final translations = languageProvider.translations;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Column(
                children: [
                  Icon(
                    Icons.mic_rounded,
                    size: 40,
                    color: theme.primaryColor.withOpacity(0.8),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    translations["selectAReciter"]!,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    width: 60,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: reciterProvider.reciters.length,
                  itemBuilder: (context, index) {
                    final entry =
                        reciterProvider.reciters.entries.elementAt(index);
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          child: Text(
                            "${entry.key}",
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          translations[entry.value]!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () async {
                          await reciterProvider.setReciter(entry.key);
                          Navigator.of(context).pop();
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hoverColor: theme.primaryColor.withOpacity(0.05),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    translations["cancel"]!,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutSine,
        );
        return ScaleTransition(
          scale: curvedAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return Icons.wb_twilight;
      case 'sunrise':
        return Icons.wb_sunny;
      case 'dhuhr':
        return Icons.light_mode;
      case 'asr':
        return Icons.wb_sunny_outlined;
      case 'maghrib':
        return Icons.nights_stay_outlined;
      case 'isha':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }

  Map<String, dynamic> calculateNextPrayer() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final translations = languageProvider.translations;
    final now = DateTime.now();

    DateTime? nextPrayerTime;
    String? nextPrayerName;
    Duration? timeLeft;

    for (var prayer in prayerTimes) {
      final prayerDateTime = DateFormat('h:mm a').parse(prayer['time']!);
      final todayPrayerTime = DateTime(
        now.year,
        now.month,
        now.day,
        prayerDateTime.hour,
        prayerDateTime.minute,
      );

      if (now.isBefore(todayPrayerTime)) {
        nextPrayerTime = todayPrayerTime;
        nextPrayerName = translations[prayer['name']];
        timeLeft = todayPrayerTime.difference(now);
        break;
      }
    }

    // Handle transition to the next day's Fajr
    if (nextPrayerTime == null) {
      final fajrTime = DateFormat('h:mm a').parse(prayerTimes.first['time']!);
      final nextDayFajrTime = DateTime(
        now.year,
        now.month,
        now.day + 1,
        fajrTime.hour,
        fajrTime.minute,
      );

      nextPrayerTime = nextDayFajrTime;
      nextPrayerName = translations[prayerTimes.first['name']];
      timeLeft = nextDayFajrTime.difference(now);
    }

    String timeUntilNextPrayer = timeLeft != null
        ? "${timeLeft.inHours}h ${timeLeft.inMinutes.remainder(60)}m"
        : "None";

    return {
      "nextPrayerName": nextPrayerName,
      "timeUntilNextPrayer": timeUntilNextPrayer,
    };
  }
}
