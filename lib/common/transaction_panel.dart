import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/common/add_transaction_form.dart';
import 'package:income_expense_budget_plan/common/no_data.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:income_expense_budget_plan/service/year_month_filter_data.dart';
import 'package:provider/provider.dart';

import '../model/transaction.dart';

class TransactionPanel extends StatefulWidget {
  const TransactionPanel({super.key});

  @override
  State<TransactionPanel> createState() => _TransactionPanelState();
}

class _TransactionPanelState extends State<TransactionPanel> {
  late TextEditingController _searchController;
  List<Transactions> filteredTransactions = [];
  YearMonthFilterData? yearMonthFilterData;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    YearMonthFilterData? providedYearMonthFilterData = _retrieveProvidedFilter();
    if (providedYearMonthFilterData == null) {
      yearMonthFilterData = YearMonthFilterData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    YearMonthFilterData? providedYearMonthFilterData = _retrieveProvidedFilter();
    List<Transactions> transactions = [];
    if (providedYearMonthFilterData != null) {
      transactions = providedYearMonthFilterData.transactions;
    } else {
      transactions = yearMonthFilterData!.transactions;
    }

    Widget body;
    if (transactions.isEmpty) {
      body = const NoDataCard();
    } else {
      body = Container();
    }

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
      appBar: FormUtil().buildYearMonthFilteredAppBar(context, providedYearMonthFilterData, yearMonthFilterData, () => setState(() {})),
      body: body,
    );
  }

  YearMonthFilterData _getCurrentFilter() {
    YearMonthFilterData? providedYearMonthFilterData = _retrieveProvidedFilter();
    if (providedYearMonthFilterData != null) {
      return providedYearMonthFilterData;
    }
    return yearMonthFilterData!;
  }

  YearMonthFilterData? _retrieveProvidedFilter() {
    YearMonthFilterData? providedYearMonthFilterData;
    try {
      providedYearMonthFilterData = Provider.of<YearMonthFilterData>(context);
      if (kDebugMode) {
        print("Debug purpose only!. Provided filter: $providedYearMonthFilterData");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Debug purpose only!. There's no provided filter!");
      }
    }
    return providedYearMonthFilterData;
  }
}
