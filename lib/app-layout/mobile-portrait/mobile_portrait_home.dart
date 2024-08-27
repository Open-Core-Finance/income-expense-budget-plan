import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/extensions/string_extensions.dart';
import 'package:income_expense_budget_plan/common/account_panel.dart';
import 'package:income_expense_budget_plan/common/more_panel.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/setting.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sqflite/sqflite.dart';

class HomePageMobilePortrait extends StatefulWidget {
  const HomePageMobilePortrait({super.key});

  @override
  State<HomePageMobilePortrait> createState() => _HomePageMobilePortraitState();
}

class _HomePageMobilePortraitState extends State<HomePageMobilePortrait> {
  _HomePageMobilePortraitState() {}

  refresh() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // Show the dialog when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDefaultCurrencyCheck();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print("Current screensize ${MediaQuery.of(context).size}");
    }
    final ThemeData theme = Theme.of(context);
    return Consumer<AppState>(
      builder: (context, appState, child) => Consumer<SettingModel>(
        builder: (context, setting, child) => Scaffold(
          body: <Widget>[
            /// Home page
            Card(
              shadowColor: Colors.transparent,
              margin: const EdgeInsets.all(8.0),
              child: SizedBox.expand(
                child: Center(
                  child: Text(
                    'Home page',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ),
            ),
            const AccountPanel(),
            Card(
              shadowColor: Colors.transparent,
              margin: const EdgeInsets.all(8.0),
              child: SizedBox.expand(
                child: Center(
                  child: Text(
                    'AAAA page',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ),
            ),
            const MorePanel()
          ][appState.currentHomePageIndex],
          // bottomNavigationBar: BottomAppBar(
          //   shape: const CircularNotchedRectangle(),
          //   child: Container(height: 50.0)
          // ),
          bottomNavigationBar: NavigationBar(
            onDestinationSelected: (int index) {
              setState(() {
                currentAppState.currentHomePageIndex = index;
              });
            },
            indicatorColor: Colors.amber,
            selectedIndex: currentAppState.currentHomePageIndex,
            destinations: <Widget>[
              NavigationDestination(
                icon: const Icon(Icons.history),
                label: AppLocalizations.of(context)!.navHistory,
              ),
              NavigationDestination(
                selectedIcon: const Icon(Icons.home),
                icon: const Icon(Icons.account_box),
                label: AppLocalizations.of(context)!.navAccount,
              ),
              NavigationDestination(
                icon: const Icon(Icons.analytics),
                label: AppLocalizations.of(context)!.navReport,
              ),
              NavigationDestination(
                icon: const Icon(Icons.more),
                label: AppLocalizations.of(context)!.navMore,
              ),
            ],
          ),
          // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
      ),
    );
  }

  Future<void> _startDefaultCurrencyCheck() async {
    String? currencyId = currentAppState.systemSetting.defaultCurrencyUid;
    if (currencyId == null || currencyId.isBlank) {
      if (kDebugMode) {
        print("Default currency [$currencyId] and isBlank [${currencyId?.isBlank}]");
      }
      showDialog(context: context, builder: (BuildContext context) => const DefaultCurrencySelectionDialog());
    }
  }
}

class DefaultCurrencySelectionDialog extends StatefulWidget {
  const DefaultCurrencySelectionDialog({super.key});

  @override
  State<DefaultCurrencySelectionDialog> createState() => _DefaultCurrencySelectionDialog();
}

class _DefaultCurrencySelectionDialog extends State<DefaultCurrencySelectionDialog> {
  Currency? _selectedCurrency;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.currencyDialogTitleSelectDefault),
      content: SingleChildScrollView(
        child: ListBody(children: <Widget>[
          for (var currency in currentAppState.currencies)
            RadioListTile(
              title: Text("${currency.name} (${currency.symbol})"),
              value: currency,
              groupValue: _selectedCurrency,
              onChanged: (Currency? value) => setState(() => _selectedCurrency = value),
            ),
        ]),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(AppLocalizations.of(context)!.actionConfirm),
          onPressed: () {
            if (_selectedCurrency != null) {
              currentAppState.systemSetting.defaultCurrencyUid = _selectedCurrency?.id;
              currentAppState.systemSetting.defaultCurrency = _selectedCurrency;
              DatabaseService().database.then((db) {
                db.update(tableNameSetting, currentAppState.systemSetting.toMap(),
                    where: "id = ?", whereArgs: ["1"], conflictAlgorithm: ConflictAlgorithm.replace);
              });
              Navigator.of(context).pop();
            } else {
              Util().showErrorDialog(context, AppLocalizations.of(context)!.currencyDialogEmptySelectionError, null);
            }
          },
        ),
      ],
    );
  }
}
