import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/transaction.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/statistic.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/model/statistic.dart';
import 'package:income_expense_budget_plan/service/util.dart';

class TransactionService {
  // Singleton pattern
  static final TransactionService _service = TransactionService._internal();
  factory TransactionService() => _service;
  TransactionService._internal();

  void addTransactionStatistic(List<Statistic> statistics, Transactions transactions) {
    for (Statistic statistic in statistics) {
      if (transactions.withFee) {
        if (transactions is ShareBillReturnTransaction) {
          statistic.totalPaidFee -= transactions.feeAmount;
        } else {
          statistic.totalPaidFee += transactions.feeAmount;
        }
      }
      if (transactions is IncomeTransaction) {
        statistic.totalIncome += transactions.amount;
      } else if (transactions is ExpenseTransaction) {
        statistic.totalExpense += transactions.amount;
      } else if (transactions is TransferTransaction) {
        statistic.totalTransfer += transactions.amount;
      } else if (transactions is LendTransaction) {
        statistic.totalLend += transactions.amount;
      } else if (transactions is BorrowingTransaction) {
        statistic.totalBorrow += transactions.amount;
      } else if (transactions is ShareBillTransaction) {
        statistic.totalExpense += transactions.mySplit;
        statistic.totalSharedBillPaid = statistic.totalSharedBillPaid + transactions.amount;
      } else if (transactions is ShareBillReturnTransaction) {
        statistic.totalSharedBillReturn += transactions.amount;
      } else {
        // Do nothing for adjustment for now.
      }
    }
  }

  void addTransactionStatisticToCurrency(Map<Currency, CurrencyStatistic> statisticMap, Transactions transactions) {
    Currency currency = Util().findCurrency(transactions.currencyUid);
    CurrencyStatistic? statisticTmp = statisticMap[currency];
    if (statisticTmp == null) {
      statisticTmp = CurrencyStatistic(currency: currency);
      statisticMap[currency] = statisticTmp;
    }
    addTransactionStatistic([statisticTmp], transactions);
  }

  IconData getDefaultIconData(Transactions tran) {
    if ((tran is IncomeTransaction) || (tran is ShareBillTransaction)) {
      return Icons.paid_sharp;
    } else if (tran is ExpenseTransaction) {
      return Icons.shopping_bag_outlined;
    } else if (tran is TransferTransaction) {
      return Icons.published_with_changes_sharp;
    } else if (tran is AdjustmentTransaction) {
      bool isNegative = tran.adjustedAmount < 0;
      if (isNegative) {
        return Icons.paid_sharp;
      } else {
        return Icons.shopping_bag_outlined;
      }
    }
    return defaultIconData;
  }

  DropdownMenuItem<TransactionCategory> buildTransactionCategoryDropdownItem(BuildContext context, TransactionCategory cat, bool isChild) {
    final ThemeData theme = Theme.of(context);
    List<Widget> widgets = [];
    if (isChild) {
      widgets.addAll([
        SizedBox(width: 10),
        SizedBox(height: 20, width: 8, child: VerticalDivider(thickness: 2, color: theme.dividerColor, endIndent: 0, indent: 0)),
        const Text("---", style: TextStyle(fontSize: 10), textAlign: TextAlign.left)
      ]);
    }
    widgets.addAll([SizedBox(width: 5), Icon(cat.icon, color: theme.iconTheme.color), SizedBox(width: 5)]);
    String tileText = cat.getTitleText(currentAppState.systemSetting);
    if (cat.child.isNotEmpty) {
      tileText += '(${cat.child.length})';
    }
    widgets.add(Text(tileText));
    return DropdownMenuItem<TransactionCategory>(value: cat, child: Row(children: widgets));
  }
}
