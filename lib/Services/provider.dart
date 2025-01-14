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

class MethodProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  int _selectedMethod = 5;

  final Map<int, String> methods = {
    5: "Egyptian General Authority of Survey",
    4: "Umm Al-Qura, Makkah",
    3: "Muslim World League",
    2: "Islamic Society of North America",
    12: "Union Organization islamic de France",
    22: "Comunidade Islamica de Lisboa",
  };

  late List<MapEntry<int, String>> _orderedMethods;

  MethodProvider() {
    _orderedMethods = methods.entries.toList();
    _loadMethodsFromPrefs();
  }

  int get selectedMethod => _selectedMethod;
  String get selectedMethodName => methods[_selectedMethod] ?? "Unknown";

  int getDisplayIndex(int methodId) {
    return _orderedMethods.indexWhere((entry) => entry.key == methodId) +
        1; // one based
  }

  int getMethodId(int displayIndex) {
    return _orderedMethods[displayIndex - 1].key; // one based
  }

  int get methodCount => methods.length;

  List<MapEntry<int, String>> get orderedMethods => _orderedMethods;

  Future<void> _loadMethodsFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _selectedMethod = _prefs.getInt("method") ?? 5;
    notifyListeners();
  }

  Future<void> setMethod(int method) async {
    _selectedMethod = method;
    await _prefs.setInt("method", method);
    notifyListeners();
  }
}

class LanguageProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  int _selectedLanguage = 1; // Default value

  final Map<int, String> languages = {1: "English", 2: "Arabic", 3: "español"};

  Map<String, String> toArabic = {
    "title": "مواقيت الصلاة",
    "Fajr": "الفجر",
    "Shuruq": "الشروق",
    "Dhuhr": "الظهر",
    "Asr": "العصر",
    "Maghrib": "المغرب",
    "Isha": "العشاء",
    "nextPrayer": "الصلاة القادمة",
    "prayerTimesRefreshed": "تم تحديث مواقيت الصلوات",
    "timeUntil": "الوقت المتبقي",
    "Nasser El Qattamy": "ناصر القطامي",
    "Islam Sobhi": "إسلام صبحي",
    "Rashed El Affasy": "راشد العفاسي",
    "Yasser El Dosry": "ياسر الدوسري",
    "Adhan Mecca": "اذان مكة",
    "Naqshabandi": "النقشبندي",
    "El Menshawy": "المنشاوي",
    "Abd Elbaset": "عبد الباسط",
    "El Amody": "العمودي",
    "Ahmed Mala": "أحمد الملا",
    "selectAReciter": "اختر المؤذن",
    "cancel": "الغاء",
    "settingsPage": "صفحة الاعدادات",
    "methodOfCalculatingPrayer": "طريقة حساب الصلوات",
    "selectAMethodOfCalculatingPrayerTimes": "اختر طريقة حساب الصلوات",
    "Umm Al-Qura, Makkah": "أم القرى, مكة المكرمة",
    "Egyptian General Authority of Survey": "الهيئة المصرية العامة للمساحة",
    "Muslim World League": "رابطة العالم الاسلامي",
    "Islamic Society of North America": "المجتمع الاسلامي لشمال امريكا",
    "Union Organization islamic de France": "الاتحاد الاسلامي الفرنسي",
    "Comunidade Islamica de Lisboa": "المجتمع الاسباني الاسلامي",
    "selectAppLanguage": "اختر اللغة",
    "English": "الانجليزية",
    "Arabic": "العربية",
    "español": "الاسبانية",
    "selectPreferredLanguage": "اختر لغة البرنامج",
    "goToLocationScreen": "الذهاب لصفحة تحديد الموقع",
    "pickYourLocation": "اختر موقعك",
    "locationRequired": "يرجى تحديد موقعك",
    "locationDescription":
        "نحتاج الى تحديد موقعك بشكل دقيق لحسبة صحيحة للصلوات",
    "getLocation": "حدد موقعي",
    "locationLocated": "تم تحديد موقعك",
    "lat": "خط العرض",
    "lon": "خط الطول",
    "procceedToApp": "الذهاب للصفحة الرئيسية",
    "pleaseEnableLocationServices": "الرجاء تشغيل اللوكيشن في جهازك",
    "locationPermissionIsDenied": "تم رفض الاذن لتحديد الموقع",
    "locationPermissionIsPermanentlyDenied":
        "تم رفض الاذن لتحديد الموقع للابد, برجاء تشغيله فالاعدادات",
    "settingsWarning":
        "بعد تغيير أي إعدادات، يرجى العودة إلى الصفحة الرئيسية والضغط على زر التحديث لتطبيق التغييرات",
  };
  final Map<String, String> toEnglish = {
    "title": "Prayer Times",
    "Fajr": "Fajr",
    "Shuruq": "Sunrise",
    "Dhuhr": "Dhuhr",
    "Asr": "Asr",
    "Maghrib": "Maghrib",
    "Isha": "Isha",
    "nextPrayer": "Next Prayer",
    "prayerTimesRefreshed": "Prayer Times Refreshed!",
    "timeUntil": "Time Remaining",
    "Nasser El Qattamy": "Nasser El Qattamy",
    "Islam Sobhi": "Islam Sobhi",
    "Rashed El Affasy": "Rashed El Affasy",
    "Yasser El Dosry": "Yasser El Dosry",
    "Adhan Mecca": "Adhan Mecca",
    "Naqshabandi": "Naqshabandi",
    "El Menshawy": "El Menshawy",
    "Abd Elbaset": "Abd Elbaset",
    "El Amody": "El Amody",
    "Ahmed Mala": "Ahmed Mala",
    "selectAReciter": "Select a Reciter",
    "cancel": "Cancel",
    "settingsPage": "Settings Page",
    "methodOfCalculatingPrayer": "Method of Calculating Prayer",
    "selectAMethodOfCalculatingPrayerTimes":
        "Select a Method of Calculating Prayer Times",
    "Umm Al-Qura, Makkah": "Umm Al-Qura, Makkah",
    "Egyptian General Authority of Survey":
        "Egyptian General Authority of Survey",
    "Muslim World League": "Muslim World League",
    "Islamic Society of North America": "Islamic Society of North America",
    "Union Organization islamic de France":
        "Union Organization islamic de France",
    "Comunidade Islamica de Lisboa": "Comunidade Islamica de Lisboa",
    "selectAppLanguage": "Select Language",
    "English": "English",
    "Arabic": "Arabic",
    "español": "Spanish",
    "selectPreferredLanguage": "Select Preferred Language",
    "goToLocationScreen": "Go to Location Screen",
    "pickYourLocation": "Pick Your Location",
    "locationRequired": "Location is Required",
    "locationDescription":
        "We need your precise location for accurate prayer times",
    "getLocation": "Get My Location",
    "locationLocated": "Location Identified",
    "lat": "Latitude",
    "lon": "Longitude",
    "procceedToApp": "Proceed to Main Page",
    "pleaseEnableLocationServices":
        "Please enable location services on your device",
    "locationPermissionIsDenied": "Location permission is denied",
    "locationPermissionIsPermanentlyDenied":
        "Location permission is permanently denied, please enable it in settings",
    "settingsWarning":
        "After changing any settings, please return to the home page and click the refresh button to apply your changes.",
  };

  final Map<String, String> toSpanish = {
    "title": "Horarios de Oración",
    "Fajr": "Fajr",
    "Shuruq": "Amanecer",
    "Dhuhr": "Dhuhr",
    "Asr": "Asr",
    "Maghrib": "Maghrib",
    "Isha": "Isha",
    "nextPrayer": "Próxima Oración",
    "prayerTimesRefreshed": "Los Horarios de Oración se han renovado",
    "timeUntil": "Tiempo Restante",
    "Nasser El Qattamy": "Nasser El Qattamy",
    "Islam Sobhi": "Islam Sobhi",
    "Rashed El Affasy": "Rashed El Affasy",
    "Yasser El Dosry": "Yasser El Dosry",
    "Adhan Mecca": "Adhan La Meca",
    "Naqshabandi": "Naqshabandi",
    "El Menshawy": "El Menshawy",
    "Abd Elbaset": "Abd Elbaset",
    "El Amody": "El Amody",
    "Ahmed Mala": "Ahmed Mala",
    "selectAReciter": "Selecciona un Recitador",
    "cancel": "Cancelar",
    "settingsPage": "Página de Configuración",
    "methodOfCalculatingPrayer": "Método de Cálculo de la Oración",
    "selectAMethodOfCalculatingPrayerTimes":
        "Selecciona un Método de Cálculo de Horarios de Oración",
    "Umm Al-Qura, Makkah": "Umm Al-Qura, La Meca",
    "Egyptian General Authority of Survey": "Autoridad General de Egipto",
    "Muslim World League": "Liga Mundial Musulmana",
    "Islamic Society of North America":
        "Sociedad Islámica de América del Norte",
    "Union Organization islamic de France": "Organización Islámica de Francia",
    "Comunidade Islamica de Lisboa": "Comunidad Islámica de Lisboa",
    "selectAppLanguage": "Selecciona el Idioma",
    "English": "Inglés",
    "Arabic": "Árabe",
    "español": "Español",
    "selectPreferredLanguage": "Selecciona el Idioma Preferido",
    "goToLocationScreen": "Ir a la Pantalla de Ubicación",
    "pickYourLocation": "Selecciona tu Ubicación",
    "locationRequired": "Se Requiere Ubicación",
    "locationDescription":
        "Necesitamos tu ubicación precisa para horarios de oración precisos",
    "getLocation": "Obtener Mi Ubicación",
    "locationLocated": "Ubicación Identificada",
    "lat": "Latitud",
    "lon": "Longitud",
    "procceedToApp": "Ir a la Página Principal",
    "pleaseEnableLocationServices":
        "Por favor, activa los servicios de ubicación en tu dispositivo",
    "locationPermissionIsDenied": "Permiso de ubicación denegado",
    "locationPermissionIsPermanentlyDenied":
        "Permiso de ubicación denegado permanentemente, actívalo en configuraciones",
    "settingsWarning":
        "Después de cambiar cualquier configuración, regrese a la página de inicio y haga clic en el botón Actualizar para aplicar los cambios",
  };

  LanguageProvider() {
    _loadLanguagesFromPrefs();
  }

  Map<String, String> get translations {
    switch (_selectedLanguage) {
      case 2:
        return toArabic;
      case 3:
        return toSpanish;
      case 1:
      default:
        return toEnglish;
    }
  }

  int get selectedLanguage => _selectedLanguage;
  String get selectedLanguageName => languages[_selectedLanguage] ?? "Unknown";

  Future<void> _loadLanguagesFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _selectedLanguage = _prefs.getInt("language") ?? 1;
    notifyListeners();
  }

  Future<void> setLanguage(int languageNumber) async {
    _selectedLanguage = languageNumber;
    await _prefs.setInt("language", languageNumber);
    notifyListeners();
  }
}

class ThemeProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  String _selectedColor = "Default";

  final Map<String, Color> colorThemes = {
    "Default": Colors.grey,
    "Purple": Colors.deepPurpleAccent,
    "Brown": Colors.deepOrange,
    "Blue": Colors.blue,
    "Gold": Colors.amberAccent,
    "Green": Colors.greenAccent,
    "Indigo": Colors.indigoAccent,
  };

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  String get selectedColor => _selectedColor;
  Color get selectedTheme => colorThemes[_selectedColor] ?? Colors.red;

  Future<void> _loadThemeFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _selectedColor = _prefs.getString("color") ?? "Default";
    notifyListeners();
  }

  Future<void> setTheme(String colorName) async {
    _selectedColor = colorName;
    await _prefs.setString("color", colorName);
    notifyListeners();
  }
}
