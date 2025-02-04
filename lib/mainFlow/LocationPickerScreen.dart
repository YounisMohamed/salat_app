import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Services/provider.dart';
import 'MainPage.dart';

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
  bool addressSet = false;
  bool isLoading = false;
  String locationMessage = "";
  late Future<void> _futureSetLatLon;

  @override
  void initState() {
    super.initState();
    _futureSetLatLon = setLatLon();
  }

  Future<Position> _getLocation(LanguageProvider languageProvider) async {
    final translations = languageProvider.translations;
    setState(() {
      isLoading = true;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translations["pleaseEnableLocationServices"]!)),
      );
      return Future.error("Please Open Location");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translations["locationPermissionIsDenied"]!)),
        );
        return Future.error("Location denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(translations["locationPermissionIsPermanentlyDenied"]!)),
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

  Future<void> addLatLonToPrefs(String latitude, String longitude) async {
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
    setState(() {
      lat = prefs.getString('lat') ?? '';
      lon = prefs.getString('lon') ?? '';
      latlonSet = prefs.getBool("latlonSet") ?? false;
    });
    if (latlonSet) {
      await getAddressFromLatLon(lat, lon);
    }
  }

  Future<void> removeLatLon() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('lat', "");
    prefs.setString('lon', "");
    prefs.setBool("latlonSet", false);
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
          addressSet = true;
        });
      }
    } catch (e) {
      setState(() {
        addressSet = false;
        address = "TURN ON THE INTERNET";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final translations = languageProvider.translations;

    return Scaffold(
      body: FutureBuilder(
        future: _futureSetLatLon,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }
          if (latlonSet) {
            locationMessage =
                "${translations["lat"]!}: $lat\n${translations["lon"]!}: $lon";
          } else {
            locationMessage = "";
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.1),
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
                      color: theme.colorScheme.primary.withOpacity(0.8),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      translations["locationRequired"]!,
                      style: GoogleFonts.dmSans(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      translations["locationDescription"]!,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              setState(() {
                                isLoading = true;
                              });
                              try {
                                final position =
                                    await _getLocation(languageProvider);
                                await addLatLonToPrefs("${position.latitude}",
                                    "${position.longitude}");
                                await setLatLon();

                                if (latlonSet) {
                                  setState(() {
                                    locationMessage =
                                        "${translations["lat"]!}: $lat\n${translations["lon"]!}: $lon";
                                  });
                                } else {
                                  setState(() {
                                    locationMessage = "";
                                  });
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              } finally {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            },
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              translations["getLocation"]!,
                              style: const TextStyle(
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
                              color: theme.colorScheme.shadow.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              locationMessage,
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                  fontSize: 20),
                            ),
                            if (address.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                address,
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (latlonSet && !isLoading && addressSet)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
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
                        child: Text(
                          translations["procceedToApp"]!,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onPrimary,
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
