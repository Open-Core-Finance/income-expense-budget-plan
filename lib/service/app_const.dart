import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/custom_font.dart';

// Const
const String databaseNameMain = "main_database.db";
const int databaseVersion = 5;

const String tableNameCurrency = "currency";
const String tableNameSetting = "setting";
const String tableNameAsset = "asset";
const String tableNameAssetCategory = "asset_category";
const String tableNameTransactionCategory = "transaction_category";
const String tableNameTransaction = "transactions";
const String tableNameResourceStatisticDaily = "resource_statistic_daily";
const String tableNameDebugLog = "debug_log";
const Map<String, String> localeMap = {'en': 'English', 'vi': 'Tiếng Việt'};
const String defaultLocale = 'en';
const IconData defaultIconData = Icons.collections;

const int showHiddenCount = 6;
const int layoutStyleMobilePortrait = 1;
const int layoutStyleMobileLandscape = 2;
const int layoutStyleDesktop = 3;

const tabSelectedColor = Color.fromARGB(255, 237, 202, 113);

// Share data
final platformBrightness = PlatformDispatcher.instance.platformBrightness;
const double deltaCompareValue = 0.00000000001;
const SinglePickerConfiguration iconPickerConfig = SinglePickerConfiguration(iconPackModes: [
  IconPack.allMaterial,
  IconPack.cupertino,
  IconPack.fontAwesomeIcons,
  IconPack.lineAwesomeIcons,
  IconPack.custom
], customIconPack: {
  "Data Alert": IconPickerIcon(data: MaterialSymbolsOutlinedFont.iconDataDataAlert, name: 'data_alert', pack: IconPack.custom),
  "Price Change": IconPickerIcon(data: MaterialSymbolsOutlinedFont.priceChangeIconData, name: 'price_change', pack: IconPack.custom)
});

AppState currentAppState = AppState();

class PlatformConst {
  late int appMinWidthMobile;
  late int appMinHeight;
  late int appMinPortraitHeight;
  late int appMinWidthDesktop;
  late int reportVerticalSplitViewMinWidth;

  PlatformConst() {
    reportVerticalSplitViewMinWidth = 600;
    if (Platform.isIOS || Platform.isAndroid) {
      appMinWidthMobile = 480;
      appMinHeight = 480;
      appMinPortraitHeight = 854;
      appMinWidthDesktop = 1500;
    } else {
      appMinWidthMobile = 375;
      appMinHeight = 375;
      appMinPortraitHeight = 667;
      appMinWidthDesktop = 900;
    }
  }
}
