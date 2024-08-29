import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:sqflite/sqflite.dart';

import 'currency.dart';

class SettingModel extends ChangeNotifier {
  Locale? _locale;

  /// 0: light mode.
  /// 1: dart mode.
  /// -1: follow system.
  int _darkMode = 0;

  String? defaultCurrencyUid;
  Currency? defaultCurrency;

  SettingModel({required String localeKey, int? darkMode, this.defaultCurrencyUid}) {
    _locale = Locale(localeKey);
    if (darkMode != null) {
      _darkMode = darkMode;
    }
  }

  Locale? get locale => _locale;

  int get darkMode => _darkMode;

  set locale(Locale? locale) {
    _locale = locale;
    DatabaseService().database.then((Database db) {
      db.insert(tableNameSetting, toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    });
    notifyListeners();
  }

  set darkMode(int darkMode) {
    _darkMode = darkMode;
    DatabaseService().database.then((Database db) {
      db.insert(tableNameSetting, toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    });
    notifyListeners();
  }

  String get currentLanguageText => localeMap[_locale?.languageCode] ?? 'English';

  Map<String, Object?> toMap() {
    return {'id': 1, 'locale': _locale?.languageCode ?? 'en', 'dark_mode': darkMode, 'default_currency_uid': defaultCurrencyUid};
  }

  @override
  String toString() {
    return '{"locale": "$_locale", "darkMode": "$darkMode", "defaultCurrencyUid": "$defaultCurrencyUid"}';
  }

  factory SettingModel.fromMap(Map<String, dynamic> json) => SettingModel(
        localeKey: json['locale'],
        darkMode: json['dark_mode'],
        defaultCurrencyUid: json['default_currency_uid'],
      );

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

  bool isDarkNow() {
    switch (darkMode) {
      case 0:
        return false;
      case 1:
        return true;
      default:
        return platformBrightness == Brightness.dark;
    }
  }
}
