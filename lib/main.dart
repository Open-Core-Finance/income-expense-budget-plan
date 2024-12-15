import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/service/account_service.dart';
import 'package:income_expense_budget_plan/ui-platform-based/landscape/desktop/desktop_home.dart';
import 'package:income_expense_budget_plan/ui-platform-based/landscape/mobile-landscape/mobile_landscape_home.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:income_expense_budget_plan/ui-platform-based/portrait/mobile_portrait_home.dart';
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
  await DatabaseService().database.then((db) {
    // Await the onCreate completion if needed
    var createCompletion = DatabaseService().onCreateComplete;
    if (createCompletion != null) {
      createCompletion.then((_) => initialMainApp());
    } else {
      initialMainApp();
    }
  }).catchError((e) {
    runApp(MyAppStartError(error: e));
  });
}

void initialMainApp() {
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

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
      AccountService().refreshAssets().then((List<Asset> assets) => runApp(const MyApp()));
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

class MyAppStartError extends StatelessWidget {
  final Error? error;
  const MyAppStartError({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Income Expense Budget Plan',
      home: Scaffold(
        body: Card(
          //shadowColor: Colors.transparent,
          child: SizedBox.expand(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 60),
                  const SizedBox(height: 2.0),
                  Text(
                    "So sorry to say that the app startup error!!! "
                    "Please help send the following error message to the app developer doanbaotrung@gmail.com for further "
                    "troubleshoot! $error",
                    style: TextStyle(fontSize: 24),
                  ),
                ],
              ),
            ),
          ),
        ),
        appBar: AppBar(leading: IconButton(onPressed: () => exit(0), icon: Icon(Icons.close, color: Colors.red, size: 40))),
      ),
    );
  }
}
