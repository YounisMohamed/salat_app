import 'package:awqatalsalah/MainPage.dart';
import 'package:awqatalsalah/younisText.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  String lat = "";
  String lon = "";
  String address = "";
  bool latlonSet = false;
  bool isLoading = false;
  String locationMessage = "";
  late Future<void> _futureSetLatLon;

  @override
  void initState() {
    super.initState();
    _futureSetLatLon = setLatLon();
  }

  Future<Position> _getLocation() async {
    setState(() {
      isLoading = true;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location services.")),
      );
      return Future.error("Please Open Location");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission is denied.")),
        );
        return Future.error("Location denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Location permission is permanently denied.")),
      );
      return Future.error("Permenantly Denied");
    }

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
    );
    return await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
  }

  void addLatLonToPrefs(String latitude, String longitude) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lat', latitude);
    await prefs.setString('lon', longitude);
    await prefs.setBool("latlonSet", true);
    getAddressFromLatLon(latitude, longitude);
  }

  void clearPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lat', "");
    await prefs.setString('lon', "");
    await prefs.setBool("latlonSet", false);
  }

  Future<void> setLatLon() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    lat = prefs.getString('lat') ?? '';
    lon = prefs.getString('lon') ?? '';
    latlonSet = prefs.getBool("latlonSet") ?? false;
    if (latlonSet) {
      locationMessage = "Location Located\nLatitude: $lat\nLongitude: $lon";
      await getAddressFromLatLon(lat, lon);
    } else {
      locationMessage = "";
    }
  }

  Future<void> getAddressFromLatLon(String latitude, String longitude) async {
    try {
      double lat = double.parse(latitude);
      double lon = double.parse(longitude);
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          address =
              "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        address = "Failed to fetch address: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _futureSetLatLon,
        builder: (context, snapshot) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.purple.shade50,
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.location_on,
                      size: 80,
                      color: Colors.purple.shade400,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Location Required",
                      style: GoogleFonts.dmSans(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "We need your location to provide accurate prayer times for your area",
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              try {
                                _getLocation().then((value) {
                                  addLatLonToPrefs("${value.latitude}",
                                      "${value.longitude}");
                                  setState(() {
                                    setLatLon();
                                  });
                                });
                              } catch (e) {
                                setState(() {
                                  locationMessage = e.toString();
                                });
                              }
                            },
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Get Location",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    if (locationMessage.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            YounisText(
                              locationMessage,
                              color: Colors.black54,
                            ),
                            if (address.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                address,
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (latlonSet && !isLoading)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const MainPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Proceed to App",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
