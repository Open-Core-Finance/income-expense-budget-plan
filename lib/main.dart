import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/ui-app-layout/desktop/desktop_home.dart';
import 'package:income_expense_budget_plan/ui-app-layout/mobile-landscape/mobile_landscape_home.dart';
import 'package:income_expense_budget_plan/ui-app-layout/mobile-portrait/mobile_portrait_home.dart';
import 'package:income_expense_budget_plan/dao/setting_dao.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/setting.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:provider/provider.dart';

import 'model/currency.dart';

void main() async {
  // Avoid errors caused by flutter upgrade.
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();

  // Get the database instance to trigger initialization
  await DatabaseService().database;

  // Await the onCreate completion if needed
  var createCompletion = DatabaseService().onCreateComplete;
  if (createCompletion != null) {
    await createCompletion;
  }

  currentAppState.reloadTransactionCategories();
  SettingDao().loadSettings().then((SettingModel settings) {
    currentAppState.systemSetting = settings;
    DatabaseService().loadListModel(tableNameCurrency, Currency.fromMap).then((currencies) {
      currentAppState.currencies = currencies;
      for (var i = 0; i < currencies.length; i++) {
        var currency = currencies[i];
        if (currency.id == settings.defaultCurrencyUid) {
          currentAppState.systemSetting.defaultCurrency = currency;
        }
      }
      TransactionDao().transactionCategories();
      Util().refreshAssets((List<Asset> assets) => runApp(const MyApp()));
    });
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context);
    var screenSize = media.size;
    currentAppState.isMobile = screenSize.width < currentAppState.platformConst.appMinWidthDesktop;
    currentAppState.isLandscape = currentAppState.isMobile && screenSize.width > screenSize.height;
    Widget homePage;
    if (currentAppState.isMobile) {
      if (currentAppState.isLandscape) {
        homePage = const HomePageMobileLandscape();
      } else {
        homePage = const HomePageMobilePortrait();
      }
    } else {
      homePage = const HomePageDesktop();
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => currentAppState),
        ChangeNotifierProvider(create: (context) => currentAppState.systemSetting)
      ],
      builder: (context, child) => Consumer<SettingModel>(
        builder: (context, setting, child) => MaterialApp(
          title: 'Income Expense Budget Plan',
          theme: ThemeData(
              // This is the theme of your application.
              //
              // Try running your application with "flutter run". You'll see the
              // application has a blue toolbar. Then, without quitting the app, try
              // changing the primarySwatch below to Colors.green and then invoke
              // "hot reload" (press "r" in the console where you ran "flutter run",
              // or simply save your changes to "hot reload" in a Flutter IDE).
              // Notice that the counter didn't reset back to zero; the application
              // is not restarted.
              primarySwatch: Colors.blue,
              useMaterial3: true,
              brightness: setting.brightness,
              iconTheme: const IconThemeData(color: Colors.blue)),
          home: homePage,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: [for (MapEntry<String, String> localeConfig in localeMap.entries) Locale(localeConfig.key)],
          localeResolutionCallback: (locale, supportedLocales) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale?.languageCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
          locale: setting.locale,
        ),
      ),
    );
  }
}
