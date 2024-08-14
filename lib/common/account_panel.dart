import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/util.dart';

class AccountPanel extends StatefulWidget {
  const AccountPanel({super.key});

  @override
  State<AccountPanel> createState() => _AccountPanelState();
}

class _AccountPanelState extends State<AccountPanel> {
  @override
  void initState() {
    super.initState();
    if (currentAppState.systemAssetCategories.isEmpty) Util().refreshSystemAssetCategory(null);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String accountTitle = AppLocalizations.of(context)!.titleAccount;
    return Scaffold(
      appBar: AppBar(title: Text(accountTitle)),
      body: Container(),
      floatingActionButton: FloatingActionButton(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        shape: const CircleBorder(),
        onPressed: () {
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
