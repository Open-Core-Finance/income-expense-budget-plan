import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/model/setting.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/ui-app-layout/home.dart';
import 'package:income_expense_budget_plan/ui-app-layout/mobile-portrait/portrait_more_panel.dart';
import 'package:income_expense_budget_plan/ui-common/report_panel.dart';
import 'package:income_expense_budget_plan/ui-common/transaction_panel.dart';
import 'package:income_expense_budget_plan/ui-platform-based/portrait/account_panel.dart';

class HomePageMobilePortrait extends HomePage {
  const HomePageMobilePortrait({super.key}) : super(layoutStyle: layoutStyleMobilePortrait);

  @override
  State<HomePageMobilePortrait> createState() => _HomePageMobilePortraitState();
}

class _HomePageMobilePortraitState extends HomePageState<HomePageMobilePortrait> {
  @override
  Widget homePageBuild(
      {required BuildContext context,
      required AppState appState,
      required SettingModel setting,
      required AppLocalizations appLocalizations,
      required Widget body}) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) => setState(() => appState.currentHomePageIndex = index),
        indicatorColor: tabSelectedColor,
        selectedIndex: appState.currentHomePageIndex,
        destinations: <Widget>[
          NavigationDestination(icon: Icon(Icons.history, color: theme.primaryColor), label: appLocalizations.navHistory),
          NavigationDestination(icon: Icon(Icons.analytics, color: theme.primaryColor), label: appLocalizations.navReport),
          NavigationDestination(
            selectedIcon: Icon(Icons.home, color: theme.primaryColor),
            icon: Icon(Icons.account_box, color: theme.primaryColor),
            label: appLocalizations.navAccount,
          ),
          NavigationDestination(icon: Icon(Icons.more, color: theme.primaryColor), label: appLocalizations.navMore),
        ],
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  @override
  List<Widget> allIndexesWidgets(BuildContext context, AppLocalizations appLocalizations) =>
      [const TransactionPanel(), ReportPanel(), const AccountPanelPortrait(), const MobilePortraitMorePanel()];
}
