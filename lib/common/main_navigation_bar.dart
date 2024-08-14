import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';

class MainNavigationBar extends StatefulWidget {
  const MainNavigationBar({super.key});

  @override
  State<MainNavigationBar> createState() => _MainNavigationBarState();
}

class _MainNavigationBarState extends State<MainNavigationBar> {
  _MainNavigationBarState();

  @override
  Widget build(BuildContext context) {
    final String reportLabel = AppLocalizations.of(context)!.navReport;
    final String accountLabel = AppLocalizations.of(context)!.navAccount;
    final String historyLabel = AppLocalizations.of(context)!.navHistory;
    final String moreLabel = AppLocalizations.of(context)!.navMore;
    return NavigationBar(
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
          label: historyLabel,
        ),
        NavigationDestination(
          selectedIcon: const Icon(Icons.home),
          icon: const Icon(Icons.account_box),
          label: accountLabel,
        ),
        NavigationDestination(
          icon: const Icon(Icons.analytics),
          label: reportLabel,
        ),
        NavigationDestination(
          icon: const Icon(Icons.more),
          label: moreLabel,
        ),
      ],
    );
  }
}
