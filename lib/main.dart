import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_iconpicker/extensions/string_extensions.dart';
import 'package:income_expense_budget_plan/dao/setting_dao.dart';
import 'package:income_expense_budget_plan/large-screen/home.dart';
import 'package:income_expense_budget_plan/model/setting.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
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

  SettingDao().loadSettings().then((SettingModel settings) {
    currentAppState.systemSettings = settings;
    DatabaseService().loadListModel(tableNameCurrency, Currency.fromMap).then((currencies) {
      currentAppState.currencies = currencies;
      for (var i = 0; i < currencies.length; i++) {
        var currency = currencies[i];
        if (currency.id == settings.defaultCurrencyUid) {
          currentAppState.systemSettings.defaultCurrency = currency;
        }
      }
      if (kDebugMode) {
        print("Currencies: $currencies");
      }
      runApp(const MyApp());
    });
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => currentAppState),
        ChangeNotifierProvider(create: (context) => currentAppState.systemSettings)
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
          home: const HomePage(),
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
