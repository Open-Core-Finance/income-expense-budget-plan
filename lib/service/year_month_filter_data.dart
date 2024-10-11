import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/daily_transaction_entry.dart';
import 'package:income_expense_budget_plan/model/local_date.dart';
import 'package:income_expense_budget_plan/model/transaction.dart';
import 'package:income_expense_budget_plan/service/account_statistic.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/transaction_service.dart';

class YearMonthFilterData extends ChangeNotifier {
  late int year;
  late int month;
  List<Transactions> _transactions = [];
  List<DailyTransactionEntry> transactionsMap = [];
  Map<Asset, AccountStatistic> accountStatistics = {};
  Map<Currency, CurrencyStatistic> statisticMap = {};

  YearMonthFilterData({int? year, int? month}) {
    var currentDate = DateTime.now();
    if (year != null) {
      this.year = year;
    } else {
      this.year = currentDate.year;
    }
    if (month != null) {
      this.month = month;
    } else {
      this.month = currentDate.month;
    }
    _refreshFilterTransactions((transactions) => notifyListeners());
  }

  String getMonthAsNumberString() {
    if (month >= 10) {
      return "$month";
    } else {
      return "0$month";
    }
  }

  void previousMonth() {
    if (month > 1) {
      month = month - 1;
    } else {
      month = 12;
      year = year - 1;
    }
    _refreshFilterTransactions((transactions) {
      try {
        notifyListeners();
      } catch (e) {
        print("$e");
      }
    });
  }

  void nextMonth() {
    if (month < 12) {
      month = month + 1;
    } else {
      month = 1;
      year = year + 1;
    }
    _refreshFilterTransactions((transactions) {
      try {
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print("$e");
        }
      }
    });
  }

  @override
  String toString() {
    return '{"month": $month, "year": $year}';
  }

  List<Transactions> get transactions => _transactions;
  set transactions(List<Transactions> transactions) {
    _transactions = transactions;
    _buildTransactionByDateMap();
    if (kDebugMode) {
      print("Account Statistics: $accountStatistics");
    }
  }

  void _refreshFilterTransactions(void Function(List<Transactions>) callback) {
    TransactionDao().transactionsByYearAndMonth(year, month).then((txns) {
      transactions = txns;
      callback(txns);
    });
  }

  AppBar? generateFilterLabel(BuildContext context, Function? callback) {
    return FormUtil().buildYearMonthFilteredAppBar(context, this, callback);
  }

  void _buildTransactionByDateMap() {
    transactionsMap = [];
    accountStatistics = {};
    statisticMap = {};
    for (Transactions transactions in _transactions) {
      LocalDate localDate = LocalDate.fromDate(transactions.transactionDate);
      DailyTransactionEntry? transactionEntry = _findEntry(localDate);
      if (transactionEntry == null) {
        transactionEntry = DailyTransactionEntry(localDate: localDate);
        transactionsMap.add(transactionEntry);
      }
      transactionEntry.addTransaction(transactions);
      _addStatistic(transactions);
    }
    if (kDebugMode) {
      print("Statistic: $statisticMap");
    }
  }

  DailyTransactionEntry? _findEntry(LocalDate date) {
    for (DailyTransactionEntry entry in transactionsMap) {
      if (entry.localDate == date) {
        return entry;
      }
    }
    return null;
  }

  void _addStatistic(Transactions transactions) {
    Asset asset = transactions.account;
    AccountStatistic? accountStatistic = accountStatistics[asset];
    if (accountStatistic == null) {
      accountStatistic = AccountStatistic(account: asset);
      accountStatistics[asset] = accountStatistic;
    }
    TransactionService transactionService = TransactionService();
    transactionService.addTransactionStatisticToCurrency(statisticMap, transactions);
    transactionService.addTransactionStatistic([accountStatistic], transactions);
    if (transactions is TransferTransaction) {
      accountStatistic.totalTransferOut += transactions.amount;
      Asset toAccount = transactions.toAccount;
      AccountStatistic? accountStatisticTo = accountStatistics[toAccount];
      if (accountStatisticTo == null) {
        accountStatisticTo = AccountStatistic(account: toAccount);
        accountStatistics[toAccount] = accountStatisticTo;
      }
      accountStatisticTo.totalTransferIn += transactions.amount;
    }
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
