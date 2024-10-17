import 'package:flutter/foundation.dart';
import 'package:income_expense_budget_plan/model/setting.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class SettingDao {
  final DatabaseService databaseService = DatabaseService();
  // Singleton pattern
  static final SettingDao _dao = SettingDao._internal();
  factory SettingDao() => _dao;
  SettingDao._internal();

  Future<SettingModel> loadSettings() async {
    var listSettings = await databaseService.loadListModel(tableNameSetting, SettingModel.fromMap);
    if (kDebugMode) {
      print("Loaded setting $listSettings");
    }
    SettingModel result;
    if (listSettings.isEmpty) {
      var systemLocaleStr = Intl.systemLocale;
      var indexOfUnderScore = systemLocaleStr.indexOf("_");
      if (indexOfUnderScore > 0) {
        systemLocaleStr = systemLocaleStr.substring(0, indexOfUnderScore);
      }
      if (!localeMap.containsKey(systemLocaleStr)) {
        systemLocaleStr = defaultLocale;
      }
      result = SettingModel(localeKey: systemLocaleStr);
      databaseService.database.then((database) {
        database.insert(tableNameSetting, result.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      });
    } else {
      result = listSettings.first;
    }
    return result;
  }
}
