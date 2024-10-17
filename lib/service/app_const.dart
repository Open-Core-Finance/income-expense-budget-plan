import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';

// Const
const String tableNameCurrency = "currency";
const String tableNameSetting = "setting";
const String tableNameAsset = "asset";
const String databaseNameMain = "main_database.db";
const int databaseVersion = 1;
const String tableNameAssetCategory = "asset_category";
const String tableNameTransactionCategory = "transaction_category";
const String tableNameTransaction = "transactions";
const String tableNameResourceStatisticMonthly = "resource_statistic_monthly";
const String tableNameResourceStatisticDaily = "resource_statistic_daily";
const Map<String, String> localeMap = {'en': 'English', 'vi': 'Tiếng Việt'};
const String defaultLocale = 'en';
const IconData defaultIconData = Icons.collections;

const int appMinWidthMobile = 375;
const int appMinHeight = 375;
const int appMinPortraitHeight = 667;
const int appMinWidthDesktop = 900;

const tabSelectedColor = Color.fromARGB(255, 237, 202, 113);

// Share data
final platformBrightness = PlatformDispatcher.instance.platformBrightness;

AppState currentAppState = AppState();

const IconData dataAlert = IconData(0xf7f6, fontFamily: 'MaterialSymbolsIcons');
const incomeIconData = IconData(0xe147, fontFamily: 'MaterialSymbolsIcons');
const expenseIconData = IconData(0xe644, fontFamily: 'MaterialSymbolsIcons');
const lendIconData = IconData(0xf52c, fontFamily: 'MaterialSymbolsIcons');
const genericCategoryIconData = IconData(0xe65b, fontFamily: 'MaterialSymbolsIcons');
