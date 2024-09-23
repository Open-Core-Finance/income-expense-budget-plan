import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/common/add_account_form.dart';
import 'package:income_expense_budget_plan/common/add_transaction_form.dart';
import 'package:income_expense_budget_plan/common/assets_categories_panel.dart';
import 'package:income_expense_budget_plan/common/no_data.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../model/transaction.dart';

class TransactionPanel extends StatefulWidget {
  const TransactionPanel({super.key});

  @override
  State<TransactionPanel> createState() => _TransactionPanelState();
}

class _TransactionPanelState extends State<TransactionPanel> {
  late TextEditingController _searchController;
  List<Transactions> transactions = [];
  List<Transactions> filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        foregroundColor: theme.primaryColor,
        backgroundColor: theme.iconTheme.color,
        shape: const CircleBorder(),
        onPressed: () => Util().navigateTo(context, const AddTransactionForm()),
        heroTag: "Add-transaction-Button",
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: const NoDataCard(),
    );
  }
}
