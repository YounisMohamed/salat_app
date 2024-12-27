import 'package:awqatalsalah/response.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'LocationPickerScreen.dart';
import 'Services/notification_service.dart';
import 'api.dart';

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
      registerPrayerNotificationTask();
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
    print("All scheduled notifications cleared.");
    await fetchPrayerTimes();

    if (_prayerData != null) {
      final Map<String, String> prayerTimes = {
        "Fajr": _prayerData!.timings.fajr,
        "Shuruq": _prayerData!.timings.sunrise,
        "Dhuhr": _prayerData!.timings.dhuhr,
        "Asr": _prayerData!.timings.asr,
        "Maghrib": _prayerData!.timings.maghrib,
        "Isha": _prayerData!.timings.isha,
      };
      // TODO : FIX THE FUCKING BUG, ONLY THE LAST NOTIFICATION IS BEING FIRED!!!
      for (int i = 0; i < prayerTimes.length; i++) {
        String prayerName = prayerTimes.keys.toList()[i];
        String? prayerTime = prayerTimes[prayerName];
        if (!notificationPreferences[prayerName]!) continue;
        try {
          final DateTime now = DateTime.now();

          // Parse the prayer time into a DateTime object
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
          // for testing purposes

          String hour = parsedTime.hour < 9
              ? "0" + parsedTime.hour.toString()
              : parsedTime.hour.toString();
          String minute = parsedTime.minute < 9
              ? "0" + parsedTime.minute.toString()
              : parsedTime.minute.toString();

          await NotificationService.scheduleNotification(
            id: prayerName.hashCode,
            title: "Prayer Time: $prayerName",
            body: "($hour:$minute) It's time for $prayerName prayer.",
            scheduledTime: scheduledTime,
          );

          print("scheduled time ${scheduledTime} for prayer ${prayerName}");
        } catch (e) {
          print("Error scheduling notification for $prayerName: $e");
        }
      }
      List<PendingNotificationRequest> active = await NotificationService
          .notificationsPlugin
          .pendingNotificationRequests();
      for (int i = 0; i < active.length; i++) {
        print("Active ${i + 1} is ${active[i].body}");
      }
    } else {
      print("error");
    }
  }

  void registerPrayerNotificationTask() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, String> prayerTimes = {
      "Fajr": prefs.getString("fajr") ?? "",
      "Dhuhr": prefs.getString("dhuhr") ?? "",
      "Asr": prefs.getString("asr") ?? "",
      "Maghrib": prefs.getString("maghrib") ?? "",
      "Isha": prefs.getString("isha") ?? "",
    };

    Workmanager().registerPeriodicTask(
      "dailyPrayerNotifications", // Unique task name
      "schedulePrayerNotifications", // Callback function name
      inputData: prayerTimes, // Pass prayer times
      frequency: const Duration(hours: 12), // Run daily
    );
    await fetchPrayerTimesAndScheduleNotifications();
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

  final api _api = api();
  AdhanResponse? _prayerData;

  Future<void> fetchPrayerTimesFromApi(SharedPreferences prefs) async {
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
      final response = await _api.getTimings(date: date, lat: lat, lon: lon);

      setState(() {
        _prayerData = response;
      });

      // Cache the prayer times
      cachePrayerTimes(response, prefs, now);
    } catch (e) {
      print('Error fetching prayer times from API: $e');
    }
  }

  Future<void> cachePrayerTimes(
      AdhanResponse response, SharedPreferences prefs, DateTime now) async {
    try {
      prefs.setString('fajr', response.timings.fajr);
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prayer Times"),
        centerTitle: true,
        leading: IconButton(
          onPressed: () async {
            await fetchPrayerTimes(forceRefresh: true);
            setState(() {
              _prayerTimesFuture = fetchPrayerTimes(forceRefresh: true);
            });
            HapticFeedback.lightImpact(); // Optional: Provide haptic feedback
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Prayer Times Refreshed'),
                duration:
                    Duration(milliseconds: 1000), // Adjust duration as needed
              ),
            );
          },
          icon: const Icon(Icons.refresh),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: _prayerTimesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_prayerData == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("Set Your Location Fisrt: "),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const LocationPickerScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                      ),
                      child: const Text(
                        "Press Here to Locate ❌",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Flexible(
                  flex:
                      3, // Adjust the flex to control the upper section height
                  child: ListView.separated(
                    itemCount: prayerTimes.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final prayer = prayerTimes[index];
                      final nextPrayerDetails = calculateNextPrayer();
                      final nextPrayerName =
                          nextPrayerDetails["nextPrayerName"];
                      bool isHighlighted = prayer['name'] == nextPrayerName;

                      return ListTile(
                        title: Text(
                          prayer['name']!,
                          style: TextStyle(
                            fontWeight: isHighlighted
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: isHighlighted ? 18 : 16,
                            color: isHighlighted ? Colors.teal : Colors.black,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              prayer['time']!,
                              style: TextStyle(
                                fontWeight: isHighlighted
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: isHighlighted ? 18 : 16,
                                color:
                                    isHighlighted ? Colors.teal : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: () async {
                                setState(() {
                                  _toggleNotification(prayer['name']!);
                                });
                              },
                              icon: notificationPreferences[prayer['name']!]!
                                  ? const Icon(Icons.notifications_active)
                                  : const Icon(Icons.notifications_none),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Flexible(
                  flex: 2, // Adjust flex for bottom section as needed
                  child: _bottomSection(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bottomSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            child: StreamBuilder<DateTime>(
              stream: Stream.periodic(
                  const Duration(seconds: 1), (_) => DateTime.now()),
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
                      "Current Time: $currentTime",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Next Prayer: ",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: nextPrayerName ?? 'None',
                            style: GoogleFonts.poppins(
                              fontSize: 21,
                              color: Colors.brown,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: "\nTime Left: ",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: timeUntilNextPrayer,
                            style: GoogleFonts.poppins(
                              fontSize: 21,
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const LocationPickerScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                      ),
                      child: Text(
                        latlonSet ? "Location Located ✅" : "Locate Me ❌",
                        style: TextStyle(
                          fontSize: latlonSet ? 14 : 16,
                          color: latlonSet ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                      ),
                      child: const Text(
                        "Choose Reciter",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> calculateNextPrayer() {
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
        nextPrayerName = prayer['name'];
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
      nextPrayerName = prayerTimes.first['name'];
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
