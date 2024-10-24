import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/extensions/string_extensions.dart';
import 'package:income_expense_budget_plan/app-layout/desktop/desktop_home.dart';
import 'package:income_expense_budget_plan/common/account_panel.dart';
import 'package:income_expense_budget_plan/common/default_currency_selection.dart';
import 'package:income_expense_budget_plan/app-layout/mobile-portrait/mobile_more_panel.dart';
import 'package:income_expense_budget_plan/common/report_panel.dart';
import 'package:income_expense_budget_plan/common/transaction_panel.dart';
import 'package:income_expense_budget_plan/model/setting.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePageMobilePortrait extends StatefulWidget {
  const HomePageMobilePortrait({super.key});

  @override
  State<HomePageMobilePortrait> createState() => _HomePageMobilePortraitState();
}

class _HomePageMobilePortraitState extends State<HomePageMobilePortrait> {
  _HomePageMobilePortraitState();

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
      print("Current screen size ${MediaQuery.of(context).size}");
    }
    final ThemeData theme = Theme.of(context);
    return Consumer<AppState>(
      builder: (context, appState, child) => Consumer<SettingModel>(
        builder: (context, setting, child) => Scaffold(
          body: <Widget>[
            const TransactionPanel(),
            const AccountPanel(),
            ReportPanel(),
            const MobilePortraitMorePanel()
          ][appState.currentHomePageIndex % 4],
          bottomNavigationBar: NavigationBar(
            onDestinationSelected: (int index) {
              setState(() {
                currentAppState.currentHomePageIndex = index;
              });
            },
            indicatorColor: tabSelectedColor,
            selectedIndex: currentAppState.currentHomePageIndex,
            destinations: <Widget>[
              NavigationDestination(
                icon: Icon(Icons.history, color: theme.primaryColor),
                label: AppLocalizations.of(context)!.navHistory,
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.home, color: theme.primaryColor),
                icon: Icon(Icons.account_box, color: theme.primaryColor),
                label: AppLocalizations.of(context)!.navAccount,
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics, color: theme.primaryColor),
                label: AppLocalizations.of(context)!.navReport,
              ),
              NavigationDestination(
                icon: Icon(Icons.more, color: theme.primaryColor),
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
