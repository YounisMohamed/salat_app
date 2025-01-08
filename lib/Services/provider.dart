import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReciterProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  int _selectedReciter = 1; // Default value

  final Map<int, String> reciters = {
    1: "Nasser El Qattamy",
    2: "Islam Sobhi",
    3: "Rashed El Affasy",
    4: "Yasser El Dosry",
    5: "Adhan Mecca",
    6: "Naqshabandi",
    7: "El Menshawy",
    8: "Abd Elbaset",
    9: "El Amody",
    10: "Ahmed Mala",
  };

  ReciterProvider() {
    _loadReciterFromPrefs();
  }

  int get selectedReciter => _selectedReciter;
  String get selectedReciterName => reciters[_selectedReciter] ?? "Unknown";

  Future<void> _loadReciterFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _selectedReciter = _prefs.getInt("reciter") ?? 1;
    notifyListeners();
  }

  Future<void> setReciter(int reciterNumber) async {
    _selectedReciter = reciterNumber;
    await _prefs.setInt("reciter", reciterNumber);
    notifyListeners();
  }
}

class LanguageProvider with ChangeNotifier {
  int _selectedLanguage = 1; // Default to English (1)

  int get selectedLanguage => _selectedLanguage;

  void setLanguage(int language) {
    _selectedLanguage = language;
    notifyListeners();
  }
}
