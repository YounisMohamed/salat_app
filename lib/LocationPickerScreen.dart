import 'package:awqatalsalah/younisText.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
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
  String locationMessage = "";
  late Future<void> _futureSetLatLon;

  @override
  void initState() {
    super.initState();
    _futureSetLatLon = setLatLon();
  }

  Future<Position> _getLocation() async {
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
        const SnackBar(content: Text("Location permission is permanently denied.")),
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
    getAddressFromLatLon(latitude, longitude); // Fetch address
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
      await getAddressFromLatLon(lat, lon); // Fetch address
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
          address = "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        });
      }
    } catch (e) {
      setState(() {
        address = "Failed to fetch address: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick a Location")),
      body: FutureBuilder(
        future: _futureSetLatLon,
        builder: (context, snapshot) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: ElevatedButton(
                    child: const YounisText("Get Location",color: Colors.purple,),
                    onPressed: () async {
                      try {
                        _getLocation().then((value) {
                          addLatLonToPrefs("${value.latitude}", "${value.longitude}");
                          setState(() {
                            setLatLon();
                          });
                        });
                      } catch (e) {
                        setState(() {
                          locationMessage = e.toString();
                        });
                      }
                    }
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              YounisText(locationMessage, color: Colors.black38,),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(48.0),
                child: Text(address, style: GoogleFonts.dmSans(
                    fontSize: 24,
                    color: Colors.black87
                ),),
              ),

            ],
          );
        },
      ),
    );
  }
}