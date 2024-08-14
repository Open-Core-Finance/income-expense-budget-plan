import 'package:flutter/foundation.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/setting.dart';

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
    notifyListeners();
  }

  List<AssetCategory> get systemAssetCategories => _systemAssetCategories;

  set systemAssetCategories(List<AssetCategory> systemAssetCategories) {
    _systemAssetCategories = systemAssetCategories;
    notifyListeners();
  }

  @override
  String toString() {
    return "{currentHomePageIndex: $currentHomePageIndex, systemSettings: $systemSettings}";
  }

  void triggerNotify() {
    notifyListeners();
  }
}
