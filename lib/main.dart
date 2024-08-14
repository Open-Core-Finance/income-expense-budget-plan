import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/dao/setting_dao.dart';
import 'package:income_expense_budget_plan/large-screen/home.dart';
import 'package:income_expense_budget_plan/model/setting.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:provider/provider.dart';

void main() {
  // Avoid errors caused by flutter upgrade.
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();

  SettingDao().loadSettings().then((SettingModel settings) {
    currentAppState.systemSettings = settings;
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => currentAppState,
      child: MaterialApp(
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
            brightness: currentAppState.systemSettings.brightness,
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
        locale: currentAppState.systemSettings.locale,
      ),
    );
  }
}
