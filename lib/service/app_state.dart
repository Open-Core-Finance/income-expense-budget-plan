import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
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
  late SettingModel systemSetting;
  List<AssetCategory> _assetCategories = [];
  List<Asset> _assets = [];
  List<Currency> _currencies = [];
  int get currentHomePageIndex => _currentHomePageIndex;
  bool isMobile = true;
  bool isLandscape = false;

  set currentHomePageIndex(int currentHomePageIndex) {
    _currentHomePageIndex = currentHomePageIndex;
    triggerNotify();
  }

  List<AssetCategory> get assetCategories => _assetCategories;

  set assetCategories(List<AssetCategory> systemAssetCategories) {
    _assetCategories = systemAssetCategories;
    triggerNotify();
  }

  List<Asset> get assets => _assets;

  set assets(List<Asset> assets) {
    _assets = assets;
    triggerNotify();
  }

  List<Currency> get currencies => _currencies;
  set currencies(List<Currency> currencies) {
    _currencies = currencies;
    triggerNotify();
  }

  void reOrderAssetCategory(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex != newIndex) {
      DatabaseService().database.then((db) {
        final item = assetCategories.removeAt(oldIndex);
        assetCategories.insert(newIndex, item);
        for (int i = min(oldIndex, newIndex); i <= max(oldIndex, newIndex); i++) {
          var cat = assetCategories[i];
          cat.positionIndex = i + 1;
          db.update(tableNameAssetCategory, {'position_index': cat.positionIndex},
              where: "uid = ?", whereArgs: [cat.id], conflictAlgorithm: ConflictAlgorithm.replace);
        }
        triggerNotify();
      });
    }
  }

  @override
  String toString() {
    return "{currentHomePageIndex: $currentHomePageIndex, systemSetting: $systemSetting}";
  }

  void triggerNotify() {
    notifyListeners();
  }
}
