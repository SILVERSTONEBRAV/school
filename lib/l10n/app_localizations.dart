import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('sw'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String _t(Map<String, String> values) =>
      values[locale.languageCode] ?? values['en']!;

  String get appName => _t({'en': 'School Management', 'sw': 'Usimamizi wa Shule'});
  String get signIn => _t({'en': 'Sign In', 'sw': 'Ingia'});
  String get signOut => _t({'en': 'Sign out', 'sw': 'Toka'});
  String get dashboard => _t({'en': 'Dashboard', 'sw': 'Dashibodi'});
  String get settings => _t({'en': 'Settings', 'sw': 'Mipangilio'});
  String get theme => _t({'en': 'Theme', 'sw': 'Mandhari'});
  String get language => _t({'en': 'Language', 'sw': 'Lugha'});
  String get systemTheme => _t({'en': 'System', 'sw': 'Mfumo'});
  String get lightTheme => _t({'en': 'Light', 'sw': 'Mwanga'});
  String get darkTheme => _t({'en': 'Dark', 'sw': 'Giza'});
  String get announcements => _t({'en': 'Announcements', 'sw': 'Matangazo'});
  String get noAnnouncements => _t({'en': 'No announcements', 'sw': 'Hakuna matangazo'});
  String get offlineMode => _t({'en': 'Showing cached data', 'sw': 'Inaonyesha data iliyohifadhiwa'});
  String get english => _t({'en': 'English', 'sw': 'Kiingereza'});
  String get swahili => _t({'en': 'Swahili', 'sw': 'Kiswahili'});
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales
          .any((supported) => supported.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
