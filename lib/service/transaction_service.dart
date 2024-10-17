import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/transaction.dart';
import 'package:income_expense_budget_plan/service/account_statistic.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/model/statistic.dart';

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
        statistic.totalSharedBillPaid = statistic.totalSharedBillPaid + transactions.amount;
      } else if (transactions is ShareBillReturnTransaction) {
        statistic.totalSharedBillReturn += transactions.amount;
      } else {
        // Do nothing for adjustment for now.
      }
    }
  }

  void addTransactionStatisticToCurrency(Map<Currency, CurrencyStatistic> statisticMap, Transactions transactions) {
    Currency currency = _findTransactionCurrency(transactions);
    CurrencyStatistic? statisticTmp = statisticMap[currency];
    if (statisticTmp == null) {
      statisticTmp = CurrencyStatistic(currency: currency);
      statisticMap[currency] = statisticTmp;
    }
    addTransactionStatistic([statisticTmp], transactions);
  }

  Currency _findTransactionCurrency(Transactions transactions) {
    var currencies = currentAppState.currencies;
    for (var currency in currencies) {
      if (currency.id == transactions.currencyUid) {
        return currency;
      }
    }
    return currentAppState.systemSetting.defaultCurrency!;
  }
}
