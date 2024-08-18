import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:sqflite/sqflite.dart';

class SettingModel extends ChangeNotifier {
  Locale? _locale;

  /// 0: light mode.
  /// 1: dart mode.
  /// -1: follow system.
  int _darkMode = -1;

  SettingModel({required String localeKey, required int darkMode}) {
    _locale = Locale(localeKey);
    _darkMode = darkMode;
  }

  Locale? get locale => _locale;

  int get darkMode => _darkMode;

  set locale(Locale? locale) {
    _locale = locale;
    DatabaseService().database.then((Database db) {
      db.insert(tableNameSettings, toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    });
    notifyListeners();
  }

  set darkMode(int darkMode) {
    _darkMode = darkMode;
    DatabaseService().database.then((Database db) {
      db.insert(tableNameSettings, toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    });
    notifyListeners();
  }

  String get currentLanguageText => localeMap[_locale?.languageCode] ?? 'English';

  // Convert a Assets into a Map. The keys must correspond to the names of the columns in the database.
  Map<String, Object?> toMap() {
    return {'id': 1, 'locale': _locale?.languageCode ?? 'en', 'dark_mode': darkMode};
  }

  // Implement toString to make it easier to see information about
  // each Assets when using the print statement.
  @override
  String toString() {
    return '{_locale: $_locale, darkMode: $darkMode}';
  }

  factory SettingModel.fromMap(Map<String, dynamic> json) => SettingModel(localeKey: json['locale'], darkMode: json['dark_mode']);

  String getDarkModeText(BuildContext context) {
    return SettingModel.parseDarkModeText(context, darkMode);
  }

  static String parseDarkModeText(BuildContext context, int mode) {
    var appLocalizations = AppLocalizations.of(context)!;
    switch (mode) {
      case 0:
        return appLocalizations.settingsDarkModeLight;
      case 1:
        return appLocalizations.settingsDarkModeDark;
      default:
        return appLocalizations.settingsDarkModeAuto;
    }
  }

  Brightness get brightness {
    switch (darkMode) {
      case 0:
        return Brightness.light;
      case 1:
        return Brightness.dark;
      default:
        return platformBrightness;
    }
  }
}
