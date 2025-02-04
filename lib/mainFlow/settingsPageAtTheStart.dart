import 'package:awqatalsalah/Services/provider.dart';
import 'package:awqatalsalah/mainFlow/PermissionPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SettingsPageAtTheStart extends StatefulWidget {
  const SettingsPageAtTheStart({super.key});

  @override
  State<SettingsPageAtTheStart> createState() => _SettingsPageAtTheStartState();
}

class _SettingsPageAtTheStartState extends State<SettingsPageAtTheStart> {
  @override
  Widget build(BuildContext context) {
    final methodProvider = Provider.of<MethodProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final translations = languageProvider.translations;
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          translations["initConfigurations"]!,
          style: GoogleFonts.dmSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildSettingCard(
                    context: context,
                    icon: Icons.calculate,
                    title: translations["methodOfCalculatingPrayer"]!,
                    value: translations[methodProvider.selectedMethodName]!,
                    onTap: () async {
                      await _showMethodDialog(
                          context, methodProvider, languageProvider);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSettingCard(
                    context: context,
                    icon: Icons.language,
                    title: translations["selectAppLanguage"]!,
                    value: translations[languageProvider.selectedLanguageName]!,
                    onTap: () async {
                      await _showLanguageMethod(context, languageProvider);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSettingCard(
                    context: context,
                    icon: Icons.color_lens,
                    title: translations["changeTheme"]!,
                    value: translations["clickHereToChangeThemeOfApp"]!,
                    onTap: () {
                      _showThemeDialog(
                          context, themeProvider, languageProvider);
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildSettingCard(
                    context: context,
                    icon: Icons.check,
                    title: translations["continue"]!,
                    value: translations["clickHereToProceed"]!,
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const PermissionPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Card(
      elevation: 4,
      shadowColor: primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withOpacity(0.3), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showLanguageMethod(
    BuildContext context, LanguageProvider languageProvider) async {
  final theme = Theme.of(context);
  final translations = languageProvider.translations;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Column(
          children: [
            Icon(
              Icons.access_time_outlined,
              size: 40,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
            const SizedBox(height: 12),
            Text(
              translations["selectPreferredLanguage"]!,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              width: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.3),
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
            itemCount: languageProvider.languages.length,
            itemBuilder: (context, index) {
              final entry = languageProvider.languages.entries.elementAt(index);
              final isSelected = entry.key == languageProvider.selectedLanguage;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : theme.colorScheme.surface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      "${entry.key}",
                      style: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    translations[entry.value]!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  onTap: () async {
                    await languageProvider.setLanguage(entry.key);
                    Navigator.of(context).pop();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle,
                          color: theme.colorScheme.primary)
                      : null,
                  hoverColor: theme.colorScheme.primary.withOpacity(0.05),
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
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Future<void> _showMethodDialog(BuildContext context,
    MethodProvider methodProvider, LanguageProvider languageProvider) async {
  final theme = Theme.of(context);
  final translations = languageProvider.translations;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Column(
          children: [
            Icon(
              Icons.access_time_outlined,
              size: 40,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
            const SizedBox(height: 12),
            Text(
              translations["selectAMethodOfCalculatingPrayerTimes"]!,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              width: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.3),
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
            itemCount: methodProvider.methodCount,
            itemBuilder: (context, index) {
              final entry = methodProvider.orderedMethods[index];
              final isSelected = entry.key == methodProvider.selectedMethod;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : theme.colorScheme.surface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      "${index + 1}", // Display sequential number
                      style: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    translations[entry.value]!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  onTap: () async {
                    await methodProvider.setMethod(entry.key);
                    Navigator.of(context).pop();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle,
                          color: theme.colorScheme.primary)
                      : null,
                  hoverColor: theme.colorScheme.primary.withOpacity(0.05),
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
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Future<void> _showThemeDialog(BuildContext context, ThemeProvider themeProvider,
    LanguageProvider languageProvider) async {
  final theme = Theme.of(context);
  final translations = languageProvider.translations;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Column(
          children: [
            Icon(
              Icons.palette, // Changed to palette icon
              size: 40,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
            const SizedBox(height: 12),
            Text(
              translations["chooseYourTheme"]!,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              width: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.3),
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
            itemCount: themeProvider.colorThemes.length,
            itemBuilder: (context, index) {
              final entry = themeProvider.colorThemes.entries.elementAt(index);
              final isSelected = entry.key == themeProvider.selectedColor;
              final themeColor = entry.value; // This is the Color from your map

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  // Use the theme color with opacity for the background
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: themeColor, width: 2)
                      : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8, // Increased padding
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: themeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    translations[entry.key]!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: themeColor, // Use theme color for text
                    ),
                  ),
                  onTap: () async {
                    await themeProvider.setTheme(entry.key);
                    Navigator.of(context).pop();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: themeColor,
                          size: 28,
                        )
                      : null,
                  hoverColor: themeColor.withOpacity(0.15),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              translations["cancel"]!,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      );
    },
  );
}
