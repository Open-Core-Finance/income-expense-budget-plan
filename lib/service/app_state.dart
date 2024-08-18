import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/setting.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:sqflite/sqflite.dart';

class AppState extends ChangeNotifier {
  // Singleton pattern
  static final AppState _appState = AppState._internal();
  factory AppState() => _appState;
  AppState._internal();

  int _currentHomePageIndex = 0;
  late SettingModel systemSettings;
  List<AssetCategory> _systemAssetCategories = [];

  int get currentHomePageIndex => _currentHomePageIndex;

  set currentHomePageIndex(int currentHomePageIndex) {
    _currentHomePageIndex = currentHomePageIndex;
    triggerNotify();
  }

  List<AssetCategory> get systemAssetCategories => _systemAssetCategories;

  set systemAssetCategories(List<AssetCategory> systemAssetCategories) {
    _systemAssetCategories = systemAssetCategories;
    triggerNotify();
  }

  void reOrderAssetCategory(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex != newIndex) {
      DatabaseService().database.then((db) {
        final item = systemAssetCategories.removeAt(oldIndex);
        systemAssetCategories.insert(newIndex, item);
        for (int i = min(oldIndex, newIndex); i <= max(oldIndex, newIndex); i++) {
          var cat = systemAssetCategories[i];
          cat.positionIndex = i + 1;
          db.update(tableNameAssetsCategory, {'position_index': cat.positionIndex},
              where: "uid = ?", whereArgs: [cat.id], conflictAlgorithm: ConflictAlgorithm.replace);
        }
        triggerNotify();
      });
    }
  }

  @override
  String toString() {
    return "{currentHomePageIndex: $currentHomePageIndex, systemSettings: $systemSettings}";
  }

  void triggerNotify() {
    notifyListeners();
  }
}
