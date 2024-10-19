import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';
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
  String? _lastTransactionAccountUid;
  List<Color> reportColorPalette;
  double reportChartSizeDefault = 200;
  double reportChartPadding = 10;
  double reportBarWidth = 20;
  double reportBarSpace = 10;
  int reportPieChartPreferCount = 8;
  double reportPieChartOtherLimitPercentage = 0.1;
  double reportPieChartPreferItemMinPercentage = 0.05;

  SettingModel({
    required String localeKey,
    int? darkMode,
    this.defaultCurrencyUid,
    String? lastTransactionAccountUid,
    required this.reportColorPalette,
    double? reportChartSizeDefault,
    double? reportChartPadding,
    double? reportBarWidth,
    double? reportBarSpace,
    int? reportPieChartPreferCount,
    double? reportPieChartOtherLimitPercentage,
    double? reportPieChartPreferItemMinPercentage,
  }) {
    _locale = Locale(localeKey);
    if (darkMode != null) {
      _darkMode = darkMode;
    }
    _lastTransactionAccountUid = lastTransactionAccountUid;
    if (reportColorPalette.isEmpty) {
      reportColorPalette = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.black,
        Colors.amber,
        Colors.cyan,
        Colors.lime,
        Colors.pink,
        Colors.teal,
        Colors.yellow
      ];
    }
    if (reportChartSizeDefault != null) {
      this.reportChartSizeDefault = reportChartSizeDefault;
    }
    if (reportChartPadding != null) {
      this.reportChartPadding = reportChartPadding;
    }
    if (reportBarWidth != null) {
      this.reportBarWidth = reportBarWidth;
    }
    if (reportBarSpace != null) {
      this.reportBarSpace = reportBarSpace;
    }
    if (reportPieChartPreferCount != null) {
      this.reportPieChartPreferCount = reportPieChartPreferCount;
    }
    if (reportPieChartOtherLimitPercentage != null) {
      this.reportPieChartOtherLimitPercentage = reportPieChartOtherLimitPercentage;
    }
    if (reportPieChartPreferItemMinPercentage != null) {
      this.reportPieChartOtherLimitPercentage = reportPieChartPreferItemMinPercentage;
    }
  }

  Locale? get locale => _locale;

  int get darkMode => _darkMode;

  void saveUpdatedSetting({Function? callback}) {
    DatabaseService().database.then((Database db) {
      db.insert(tableNameSetting, toMap(), conflictAlgorithm: ConflictAlgorithm.replace).then((_) {
        if (callback != null) callback();
      });
    });
  }

  set locale(Locale? locale) {
    _locale = locale;
    saveUpdatedSetting(callback: notifyListeners);
  }

  set darkMode(int darkMode) {
    _darkMode = darkMode;
    saveUpdatedSetting(callback: notifyListeners);
  }

  String get currentLanguageText => localeMap[_locale?.languageCode] ?? 'English';

  Map<String, Object?> toMap() {
    return {
      'id': 1,
      'locale': _locale?.languageCode ?? 'en',
      'dark_mode': darkMode,
      'default_currency_uid': defaultCurrencyUid,
      'last_transaction_account_uid': _lastTransactionAccountUid,
      'report_color_palette': reportColorPalette.map((color) => color.value.toRadixString(16)).join(','),
      'report_chart_size_default': reportChartSizeDefault,
      'report_chart_padding': reportChartPadding,
      'report_bar_width': reportBarWidth,
      'report_bar_space': reportBarSpace,
      'report_pie_chart_prefer_count': reportPieChartPreferCount,
      'report_pie_chart_other_limit_percentage': reportPieChartOtherLimitPercentage,
      'report_pie_chart_prefer_item_min_percentage': reportPieChartPreferItemMinPercentage,
    };
  }

  @override
  String toString() {
    return '{"locale": "$_locale", "darkMode": "$darkMode", "defaultCurrencyUid": "$defaultCurrencyUid", '
        '"lastTransactionAccountUid":"$_lastTransactionAccountUid", "reportColorPalette": $reportColorPalette,'
        '"reportChartSizeDefault": $reportChartSizeDefault, "reportChartPadding": $reportChartPadding,'
        '"reportBarWidth": $reportBarWidth, "reportBarSpace": $reportBarSpace, "reportPieChartPreferCount": $reportPieChartPreferCount,'
        '"reportPieChartOtherLimitPercentage": $reportPieChartOtherLimitPercentage,'
        '"reportPieChartPreferItemMinPercentage": $reportPieChartPreferItemMinPercentage}';
  }

  factory SettingModel.fromMap(Map<String, dynamic> json) => SettingModel(
        localeKey: json['locale'],
        darkMode: json['dark_mode'],
        defaultCurrencyUid: json['default_currency_uid'],
        lastTransactionAccountUid: json['last_transaction_account_uid'],
        reportColorPalette: Util().parseListColor(json['report_color_palette']),
        reportChartSizeDefault: json['report_chart_size_default'],
        reportChartPadding: json['report_chart_padding'],
        reportBarWidth: json['report_bar_width'],
        reportBarSpace: json['report_bar_space'],
        reportPieChartPreferCount: json['report_pie_chart_prefer_count'],
        reportPieChartOtherLimitPercentage: json['report_pie_chart_other_limit_percentage'],
        reportPieChartPreferItemMinPercentage: json['report_pie_chart_prefer_item_min_percentage'],
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

  String? get lastTransactionAccountUid => _lastTransactionAccountUid;

  set lastTransactionAccountUid(String? lastTransactionAccountUid) {
    _lastTransactionAccountUid = lastTransactionAccountUid;
    saveUpdatedSetting(callback: notifyListeners);
  }
}
