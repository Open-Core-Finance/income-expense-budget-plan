import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/transaction.dart';
import 'package:income_expense_budget_plan/service/account_statistic.dart';
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
          statistic.totalFeePaid -= transactions.feeAmount;
        } else {
          statistic.totalFeePaid += transactions.feeAmount;
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
      return const IconData(0xf3ee, fontFamily: 'MaterialSymbolsIcons');
    } else if (tran is TransferTransaction) {
      return Icons.published_with_changes_sharp;
    } else if (tran is AdjustmentTransaction) {
      bool isNegative = tran.adjustedAmount < 0;
      if (isNegative) {
        return Icons.paid_sharp;
      } else {
        // Money bag
        return const IconData(0xf3ee, fontFamily: 'MaterialSymbolsIcons');
      }
    }
    return defaultIconData;
  }
}
