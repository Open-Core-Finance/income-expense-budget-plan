import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';

// Const
const String tableNameCurrency = "currency";
const String tableNameSettings = "settings";
const String tableNameAssets = "assets";
const String databaseNameMain = "main_database.db";
const int databaseVersion = 1;
const String tableNameAssetsCategory = "assets_category";
const String tableNameTransactionCategory = "transaction_category";
const Map<String, String> localeMap = {'en': 'English', 'vi': 'Tiếng Việt'};
const String defaultLocale = 'en';
const IconData defaultIconData = Icons.collections;

// Share data
final platformBrightness = PlatformDispatcher.instance.platformBrightness;

AppState currentAppState = AppState();
