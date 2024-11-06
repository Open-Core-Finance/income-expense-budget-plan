import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/ui-common/add_transaction_form.dart';
import 'package:income_expense_budget_plan/ui-common/no_data.dart';
import 'package:income_expense_budget_plan/ui-common/transaction_item_display.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/daily_transaction_entry.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/account_statistic.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:income_expense_budget_plan/service/year_month_filter_data.dart';

import '../model/transaction.dart';

class TransactionPanel extends StatefulWidget {
  final YearMonthFilterData? yearMonthFilterData;
  const TransactionPanel({super.key, this.yearMonthFilterData});

  @override
  State<TransactionPanel> createState() => _TransactionPanelState();
}

class _TransactionPanelState extends State<TransactionPanel> {
  late TextEditingController _searchController;
  List<Transactions> filteredTransactions = [];
  YearMonthFilterData? yearMonthFilterData;
  FormUtil formUtil = FormUtil();

  final double _monthlyStatisticDataSize = 18;
  final TextStyle _monthlyStatisticTitleStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  late final TextStyle _monthlyStatisticDataIncomeStyle;
  late final TextStyle _monthlyStatisticDataExpenseStyle;

  final double _dailyPanelStatisticSize = 18;
  late final TextStyle _dailyPanelStatisticIncomeStyle;
  late final TextStyle _dailyPanelStatisticExpenseStyle;
  final TextStyle _dailyPanelDateStyle = const TextStyle(fontSize: 48, fontWeight: FontWeight.bold);
  final TextStyle _dailyPanelWeekdayStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.normal);
  final TextStyle _dailyPanelYearMonthStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.normal);

  _TransactionPanelState() {
    _monthlyStatisticDataIncomeStyle = TextStyle(fontSize: _monthlyStatisticDataSize, fontWeight: FontWeight.bold, color: Colors.blue);
    _monthlyStatisticDataExpenseStyle = TextStyle(fontSize: _monthlyStatisticDataSize, fontWeight: FontWeight.bold, color: Colors.red);

    _dailyPanelStatisticIncomeStyle = TextStyle(fontSize: _dailyPanelStatisticSize, fontWeight: FontWeight.bold, color: Colors.blue);
    _dailyPanelStatisticExpenseStyle = TextStyle(fontSize: _dailyPanelStatisticSize, fontWeight: FontWeight.bold, color: Colors.red);
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    YearMonthFilterData? providedYearMonthFilterData = _retrieveProvidedFilter();
    if (providedYearMonthFilterData == null) {
      yearMonthFilterData = YearMonthFilterData(
        supportLoadStatisticMonthly: false,
        refreshFunction: () => setState(() {}),
        refreshStatisticFunction: () => setState(() {}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    var appLocalizations = AppLocalizations.of(context)!;

    YearMonthFilterData? providedYearMonthFilterData = _retrieveProvidedFilter();
    YearMonthFilterData filterData;
    if (providedYearMonthFilterData != null) {
      filterData = providedYearMonthFilterData;
    } else {
      filterData = yearMonthFilterData!;
    }
    List<Transactions> transactions = filterData.transactions;

    Widget body;
    if (transactions.isEmpty) {
      body = const NoDataCard();
    } else {
      List<DailyTransactionEntry> list = filterData.transactionsMap;
      body = Column(children: [
        Flexible(
          child: ListView.separated(
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(children: [
                  const Divider(color: Colors.grey, thickness: 24, indent: 0, endIndent: 0),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 0, maxHeight: 80),
                    child: SingleChildScrollView(
                      child: Column(children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Center(child: Text(appLocalizations.transactionTotalIncome, style: _monthlyStatisticTitleStyle)),
                                  ...[
                                    for (var statisticItem in filterData.statisticMap.entries)
                                      Text(formUtil.buildFormatter(statisticItem.key).formatDouble(statisticItem.value.totalIncome),
                                          style: _monthlyStatisticDataIncomeStyle)
                                  ]
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Center(child: Text(appLocalizations.transactionTotalExpense, style: _monthlyStatisticTitleStyle)),
                                  ...[
                                    for (var statisticItem in filterData.statisticMap.entries)
                                      Center(
                                          child: Text(
                                              formUtil.buildFormatter(statisticItem.key).formatDouble(statisticItem.value.totalExpense),
                                              style: _monthlyStatisticDataExpenseStyle))
                                  ]
                                ],
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                ]);
              } else {
                var entry = list[index - 1];
                var txns = entry.transactions;
                var txnDate = entry.localDate;
                List<Widget> statisticWidgets = _buildDailyStatisticTitle(entry);
                Widget? trailingWidget;
                if (statisticWidgets.isNotEmpty) {
                  trailingWidget = Column(children: statisticWidgets);
                }
                Widget widget = ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: 0, maxHeight: txns.length * (TransactionItemConfigKey.eachTransactionHeight + 4) + 120),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 88,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                            child: Row(
                              children: [
                                Text("${txnDate.day}", style: _dailyPanelDateStyle),
                                Expanded(
                                  child: Column(
                                    children: [
                                      ListTile(
                                        title: Text(txnDate.getWeekDay(context), style: _dailyPanelWeekdayStyle),
                                        subtitle: Text("${txnDate.getMonthString()}/${txnDate.year}", style: _dailyPanelYearMonthStyle),
                                      )
                                    ],
                                  ),
                                ),
                                if (trailingWidget != null) trailingWidget
                              ],
                            ),
                          ),
                        ),
                      ),
                      Divider(color: theme.dividerColor, thickness: 1),
                      for (var txn in entry.transactions) ...[
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: 0,
                            maxHeight: txns.length * (TransactionItemConfigKey.eachTransactionHeight + 4) + 120,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                            child: _transactionWidget(txn),
                          ),
                        ),
                      ]
                    ],
                  ),
                );

                return widget;
              }
            },
            separatorBuilder: (BuildContext context, int index) => const Divider(color: Colors.grey, thickness: 16),
            itemCount: list.length + 1,
          ),
        ),
      ]);
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        foregroundColor: theme.primaryColor,
        backgroundColor: theme.iconTheme.color,
        shape: const CircleBorder(),
        onPressed: () => Util().navigateTo(context, AddTransactionForm(editCallback: transactionUpdated)),
        heroTag: "Add-transaction-Button",
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      appBar: providedYearMonthFilterData == null ? yearMonthFilterData!.generateFilterLabel(context, () => setState(() {})) : null,
      body: body,
    );
  }

  YearMonthFilterData? _retrieveProvidedFilter() {
    YearMonthFilterData? providedYearMonthFilterData;
    try {
      // providedYearMonthFilterData = Provider.of<YearMonthFilterData>(context);
      providedYearMonthFilterData = widget.yearMonthFilterData;
      if (kDebugMode) {
        print("Debug purpose only!. Provided filter: $providedYearMonthFilterData");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Debug purpose only!. There's no provided filter! $e");
      }
    }
    return providedYearMonthFilterData;
  }

  List<Widget> _buildCurrencyStatisticWidget(CurrencyStatistic statistic) {
    List<Widget> result = [];
    var formatter = formUtil.buildFormatter(statistic.currency);
    bool isZeroExpense = (statistic.totalExpense <= 0.0001 && statistic.totalExpense >= -0.0001);
    bool isZeroIncome = (statistic.totalIncome <= 0.0001 && statistic.totalIncome >= -0.0001);
    if (isZeroExpense) {
      if (!isZeroIncome) {
        result.add(Text(formatter.formatDouble(statistic.totalIncome), style: _dailyPanelStatisticIncomeStyle));
      }
    } else if (isZeroIncome) {
      result.add(Text(formatter.formatDouble(statistic.totalExpense), style: _dailyPanelStatisticExpenseStyle));
    } else {
      result.addAll([
        Text(formatter.formatDouble(statistic.totalIncome), style: _dailyPanelStatisticIncomeStyle),
        Text(formatter.formatDouble(statistic.totalExpense), style: _dailyPanelStatisticExpenseStyle),
      ]);
    }
    return result;
  }

  List<Widget> _buildDailyStatisticTitle(DailyTransactionEntry entry) {
    List<Widget> result = [];
    for (MapEntry<Currency, CurrencyStatistic> entry in entry.statisticMap.entries) {
      result.addAll(_buildCurrencyStatisticWidget(entry.value));
    }
    return result;
  }

  Widget _transactionWidget(Transactions tran) {
    onTap(Transactions tr) {
      Util().navigateTo(context, AddTransactionForm(editingTransaction: tran, editCallback: transactionUpdated));
    }

    if (tran is ExpenseTransaction) {
      return ExpenseTransactionTile(transaction: tran, onTap: onTap);
    } else if (tran is IncomeTransaction) {
      return IncomeTransactionTile(transaction: tran, onTap: onTap);
    } else if (tran is TransferTransaction) {
      return TransferTransactionTile(transaction: tran, onTap: onTap);
    } else if (tran is ShareBillTransaction) {
      return SharedBillTransactionTile(transaction: tran, onTap: onTap);
    } else if (tran is ShareBillReturnTransaction) {
      return SharedBillReturnTransactionTile(transaction: tran, onTap: onTap);
    } else if (tran is AdjustmentTransaction) {
      return AdjustmentTransactionTile(transaction: tran, onTap: onTap);
    }
    TransactionCategory? category = tran.transactionCategory;
    return Row(children: [
      const VerticalDivider(width: 10, thickness: 10, color: Colors.red),
      Icon(category?.icon ?? defaultIconData),
      Text(tran.getType().name)
    ]);
  }

  void transactionUpdated(Transactions transaction, Transactions? deletedTran) =>
      setState(() => _retrieveProvidedFilter()?.refreshFilterTransactions());
}
