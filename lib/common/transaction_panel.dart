import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/common/add_transaction_form.dart';
import 'package:income_expense_budget_plan/common/no_data.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/daily_transaction_entry.dart';
import 'package:income_expense_budget_plan/model/local_date.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/service/account_statistic.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
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
  FormUtil formUtil = FormUtil();

  final double _monthlyStatisticDataSize = 24;
  final TextStyle _monthlyStatisticTitleStyle = const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  late final TextStyle _monthlyStatisticDataIncomeStyle;
  late final TextStyle _monthlyStatisticDataExpenseStyle;

  final double _dailyPanelStatisticSie = 20;
  late final TextStyle _dailyPanelStatisticIncomeStyle;
  late final TextStyle _dailyPanelStatisticExpenseStyle;
  final TextStyle _dailyPanelDateStyle = const TextStyle(fontSize: 50, fontWeight: FontWeight.bold);
  final TextStyle _dailyPanelWeekdayStyle = const TextStyle(fontSize: 24, fontWeight: FontWeight.normal);
  final TextStyle _dailyPanelYearMonthStyle = const TextStyle(fontSize: 24, fontWeight: FontWeight.normal);

  _TransactionPanelState() {
    _monthlyStatisticDataIncomeStyle = TextStyle(fontSize: _monthlyStatisticDataSize, fontWeight: FontWeight.bold, color: Colors.blue);
    _monthlyStatisticDataExpenseStyle = TextStyle(fontSize: _monthlyStatisticDataSize, fontWeight: FontWeight.bold, color: Colors.red);

    _dailyPanelStatisticIncomeStyle = TextStyle(fontSize: _dailyPanelStatisticSie, fontWeight: FontWeight.bold, color: Colors.blue);
    _dailyPanelStatisticExpenseStyle = TextStyle(fontSize: _dailyPanelStatisticSie, fontWeight: FontWeight.bold, color: Colors.red);
  }

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
                  const Divider(
                    color: Colors.grey, // Separator color
                    thickness: 24, // Separator thickness
                    indent: 0, // Padding before the separator
                    endIndent: 0, // Padding after the separator
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 0, maxHeight: 80),
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 0.0, right: 0.0), // Add left margin
                        child: Row(
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
                      ),
                    ]),
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
                if (kDebugMode) {
                  print("Statistic $statisticWidgets; Entry: $entry");
                }
                Widget widget = ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: 0, maxHeight: txns.length * (TransactionItemConfigKey.eachTransactionHeight + 4) + 120),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 88,
                        child: SingleChildScrollView(
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
                      Divider(color: theme.dividerColor, thickness: 1, height: 1),
                      for (var txn in entry.transactions) ...[_transactionWidget(txn)]
                    ],
                  ),
                );

                return widget;
              }
            },
            separatorBuilder: (BuildContext context, int index) => const Divider(color: Colors.grey, thickness: 16, height: 16),
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
        onPressed: () => Util().navigateTo(context, const AddTransactionForm()),
        heroTag: "Add-transaction-Button",
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      appBar: providedYearMonthFilterData == null ? yearMonthFilterData!.generateFilterLabel(context, () => setState(() {})) : null,
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
    if (tran is ExpenseTransaction) {
      return ExpenseTransactionTile(transaction: tran);
    } else if (tran is IncomeTransaction) {
      return IncomeTransactionTile(transaction: tran);
    } else if (tran is TransferTransaction) {
      return TransferTransactionTile(transaction: tran);
    } else if (tran is ShareBillTransaction) {
      return SharedBillTransactionTile(transaction: tran);
    } else if (tran is ShareBillReturnTransaction) {
      return SharedBillReturnTransactionTile(transaction: tran);
    }
    TransactionCategory? category = tran.transactionCategory;
    return Row(children: [
      const VerticalDivider(width: 10, thickness: 10, color: Colors.red),
      Icon(category?.icon ?? defaultIconData),
      Text(tran.getType())
    ]);
    // TODO display by transaction type.
    //print("tran $tran");
    return Container();
  }
}

class TransactionItemConfigKey {
  static const double markDisplaySize = 24;
  static const double iconDisplaySize = 24 * 3 / 2;
  static const double categoryNameSize = 20;
  static const double transactionDescriptionSize = 14;
  static const double amountSize = 24;
  static const double accountNameSize = 18;

  static const double eachTransactionHeight = 80;
}

abstract class GenericTransactionTile<T extends Transactions> extends StatelessWidget {
  final T transaction;
  final FormUtil formUtil = FormUtil();
  GenericTransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // final ColorScheme colorScheme = theme.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 0, maxHeight: TransactionItemConfigKey.eachTransactionHeight),
      child: Row(
        children: [
          SizedBox(
            height: TransactionItemConfigKey.eachTransactionHeight,
            child: VerticalDivider(thickness: 2, width: 20, color: theme.dividerColor, endIndent: 0, indent: 0),
          ),
          const Text("---", style: TextStyle(fontSize: TransactionItemConfigKey.markDisplaySize), textAlign: TextAlign.left),
          iconDisplay(context),
          const SizedBox(width: 10),
          nameDisplay(context),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              amountDisplay(context),
              Text(transaction.account.name,
                  style: const TextStyle(fontSize: TransactionItemConfigKey.accountNameSize), textAlign: TextAlign.right)
            ],
          )
        ],
      ),
    );
  }

  Widget amountDisplay(BuildContext context) {
    var formatter = FormUtil().buildFormatter(currentAppState.currencies
        .firstWhere((element) => element.id == transaction.currencyUid, orElse: () => currentAppState.systemSetting.defaultCurrency!));
    return Text(formatter.formatDouble(transaction.amount), style: amountTextStyle(context));
  }

  Widget nameDisplay(BuildContext context) {
    var textStyle = const TextStyle(fontSize: TransactionItemConfigKey.categoryNameSize);
    if (transaction.description.isNotEmpty) {
      var descriptionTextStyle = const TextStyle(fontSize: TransactionItemConfigKey.transactionDescriptionSize);
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transaction.transactionCategory?.name ?? "", textAlign: TextAlign.left, style: textStyle),
            Text(transaction.description, textAlign: TextAlign.left, style: descriptionTextStyle)
          ],
        ),
      );
    } else {
      return Expanded(child: Text(transaction.transactionCategory?.name ?? "", style: textStyle, textAlign: TextAlign.left));
    }
  }

  TextStyle amountTextStyle(BuildContext context);

  Widget iconDisplay(BuildContext context) {
    return Icon(transaction.transactionCategory?.icon ?? defaultIcon(context), size: TransactionItemConfigKey.iconDisplaySize);
  }

  IconData defaultIcon(BuildContext context) {
    return defaultIconData;
  }
}

class ExpenseTransactionTile extends GenericTransactionTile<ExpenseTransaction> {
  ExpenseTransactionTile({super.key, required super.transaction});

  @override
  TextStyle amountTextStyle(BuildContext context) {
    return const TextStyle(fontSize: TransactionItemConfigKey.amountSize, color: Colors.red);
  }

  @override
  IconData defaultIcon(BuildContext context) {
    return Icons.paid_sharp;
  }
}

class IncomeTransactionTile extends GenericTransactionTile<IncomeTransaction> {
  IncomeTransactionTile({super.key, required super.transaction});

  @override
  TextStyle amountTextStyle(BuildContext context) {
    return const TextStyle(fontSize: TransactionItemConfigKey.amountSize, color: Colors.blue);
  }

  @override
  IconData defaultIcon(BuildContext context) {
    // Money bag
    return const IconData(0xf3ee, fontFamily: 'MaterialSymbolsIcons');
  }
}

class TransferTransactionTile extends GenericTransactionTile<TransferTransaction> {
  TransferTransactionTile({super.key, required super.transaction});

  @override
  TextStyle amountTextStyle(BuildContext context) {
    return const TextStyle(fontSize: TransactionItemConfigKey.amountSize);
  }

  @override
  Widget nameDisplay(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    String text = appLocalizations.transactionTransferTitle(transaction.toAccount.getTitleText(currentAppState.systemSetting));
    if (transaction.description.isNotEmpty) {
      var descriptionTextStyle = const TextStyle(fontSize: TransactionItemConfigKey.transactionDescriptionSize);
      return Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, textAlign: TextAlign.left, style: const TextStyle(fontSize: TransactionItemConfigKey.categoryNameSize)),
          Text(transaction.description, textAlign: TextAlign.left, style: descriptionTextStyle)
        ]),
      );
    } else {
      return Expanded(
        child: Text(text, style: const TextStyle(fontSize: TransactionItemConfigKey.categoryNameSize), textAlign: TextAlign.left),
      );
    }
  }

  @override
  IconData defaultIcon(BuildContext context) {
    return Icons.published_with_changes_sharp;
  }
}

class SharedBillTransactionTile extends GenericTransactionTile<ShareBillTransaction> {
  SharedBillTransactionTile({super.key, required super.transaction});

  @override
  TextStyle amountTextStyle(BuildContext context) {
    return const TextStyle(fontSize: TransactionItemConfigKey.amountSize, color: Colors.red);
  }

  @override
  IconData defaultIcon(BuildContext context) {
    return Icons.paid_sharp;
  }

  @override
  Widget nameDisplay(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    var formatter = FormUtil().buildFormatter(currentAppState.currencies
        .firstWhere((element) => element.id == transaction.currencyUid, orElse: () => currentAppState.systemSetting.defaultCurrency!));
    String text = appLocalizations.transactionSharedBillTitle(
        formatter.formatDouble(transaction.amount), transaction.transactionCategory?.name ?? "");
    if (transaction.description.isNotEmpty) {
      var descriptionTextStyle = const TextStyle(fontSize: TransactionItemConfigKey.transactionDescriptionSize);
      return Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, textAlign: TextAlign.left, style: const TextStyle(fontSize: TransactionItemConfigKey.categoryNameSize)),
          Text(transaction.description, textAlign: TextAlign.left, style: descriptionTextStyle)
        ]),
      );
    } else {
      return Expanded(
        child: Text(text, style: const TextStyle(fontSize: TransactionItemConfigKey.categoryNameSize), textAlign: TextAlign.left),
      );
    }
  }

  @override
  Widget amountDisplay(BuildContext context) {
    var formatter = FormUtil().buildFormatter(currentAppState.currencies
        .firstWhere((element) => element.id == transaction.currencyUid, orElse: () => currentAppState.systemSetting.defaultCurrency!));
    return Text(formatter.formatDouble(transaction.mySplit), style: amountTextStyle(context));
  }
}

class SharedBillReturnTransactionTile extends GenericTransactionTile<ShareBillReturnTransaction> {
  SharedBillReturnTransactionTile({super.key, required super.transaction});

  @override
  TextStyle amountTextStyle(BuildContext context) {
    return const TextStyle(fontSize: TransactionItemConfigKey.amountSize, color: Colors.blue);
  }

  @override
  IconData defaultIcon(BuildContext context) {
    // Money bag
    return const IconData(0xf3ee, fontFamily: 'MaterialSymbolsIcons');
  }

  @override
  Widget nameDisplay(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    String text = appLocalizations.transactionSharedBillReturnedTitle(transaction.transactionCategory?.name ?? "");
    if (transaction.description.isNotEmpty) {
      var descriptionTextStyle = const TextStyle(fontSize: TransactionItemConfigKey.transactionDescriptionSize);
      return Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, textAlign: TextAlign.left, style: const TextStyle(fontSize: TransactionItemConfigKey.categoryNameSize)),
          Text(transaction.description, textAlign: TextAlign.left, style: descriptionTextStyle)
        ]),
      );
    } else {
      return Expanded(
        child: Text(text, style: const TextStyle(fontSize: TransactionItemConfigKey.categoryNameSize), textAlign: TextAlign.left),
      );
    }
  }
}
