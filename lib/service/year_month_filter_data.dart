import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/dao/resource_statistic_dao.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/daily_transaction_entry.dart';
import 'package:income_expense_budget_plan/model/local_date.dart';
import 'package:income_expense_budget_plan/model/resource_statistic.dart';
import 'package:income_expense_budget_plan/model/transaction.dart';
import 'package:income_expense_budget_plan/service/account_statistic.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/transaction_service.dart';

class YearMonthFilterData extends ChangeNotifier {
  late int year;
  late int month;
  late bool supportLoadTransactions;
  late bool supportLoadStatisticMonthly;
  List<Transactions> _transactions = [];
  List<DailyTransactionEntry> transactionsMap = [];
  Map<Asset, AccountStatistic> accountStatistics = {};
  Map<Currency, CurrencyStatistic> statisticMap = {};
  List<ResourceStatisticMonthly> _resourcesStatisticsMonthlyList = [];
  Map<Currency, List<ResourceStatisticMonthly>> resourcesStatisticsMonthlyMap = {};
  Function? refreshFunction;
  Function? refreshStatisticFunction;

  YearMonthFilterData(
      {int? year,
      int? month,
      this.refreshFunction,
      this.refreshStatisticFunction,
      bool? supportLoadTransactions,
      bool? supportLoadStatisticMonthly}) {
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
    this.supportLoadTransactions = supportLoadTransactions == false ? false : true;
    this.supportLoadStatisticMonthly = supportLoadStatisticMonthly == false ? false : true;
    refreshFilterTransactions();
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
    refreshFilterTransactions();
  }

  void nextMonth() {
    if (month < 12) {
      month = month + 1;
    } else {
      month = 1;
      year = year + 1;
    }
    refreshFilterTransactions();
  }

  @override
  String toString() {
    return '{"month": $month, "year": $year}';
  }

  List<Transactions> get transactions => _transactions;
  set transactions(List<Transactions> transactions) {
    _transactions = transactions;
    _buildTransactionByDateMap();
  }

  List<ResourceStatisticMonthly> get resourcesStatisticsMonthly => _resourcesStatisticsMonthlyList;
  set resourcesStatisticsMonthly(List<ResourceStatisticMonthly> statistic) {
    _resourcesStatisticsMonthlyList = statistic;
    if (kDebugMode) {
      print("Loaded resources statistics");
    }
    resourcesStatisticsMonthlyMap = {};
    for (var statistic in _resourcesStatisticsMonthlyList) {
      var currency = statistic.currency;
      List<ResourceStatisticMonthly>? tmp = resourcesStatisticsMonthlyMap[currency];
      if (tmp == null) {
        tmp = [];
        resourcesStatisticsMonthlyMap[currency] = tmp;
      }
      tmp.add(statistic);
    }
  }

  void refreshFilterTransactions() {
    _refreshFilterTransactions((transactions) {
      notifyListeners();
      if (refreshFunction != null) refreshFunction!();
    }, (statistics) {
      notifyListeners();
      if (refreshStatisticFunction != null) refreshStatisticFunction!();
    });
  }

  void _refreshFilterTransactions(
      void Function(List<Transactions>) callback, void Function(List<ResourceStatisticMonthly>) statisticMonthlyCallback) {
    if (supportLoadTransactions) {
      TransactionDao().transactionsByYearAndMonth(year, month).then((txns) {
        transactions = txns;
        callback(txns);
      });
    }
    if (supportLoadStatisticMonthly) {
      ResourceStatisticDao().loadMonthlyStatistics(year, month).then((statistic) {
        // ResourceStatisticDao().loadDailyStatistics(year, month).then((statistic) {
        //   List<ResourceStatisticMonthly> monthlyList = [];
        //   for (var daily in statistic) {
        //     var tmp = daily.toMonthly();
        //     ResourceStatisticMonthly? originMonthly;
        //     for (var monthly in monthlyList) {
        //       if (monthly == tmp) {
        //         originMonthly = monthly;
        //         break;
        //       }
        //     }
        //     if (originMonthly == null) {
        //       originMonthly = tmp;
        //       monthlyList.add(originMonthly);
        //     } else {
        //       originMonthly.combineWith(tmp);
        //     }
        //   }
        resourcesStatisticsMonthly = statistic;
        statisticMonthlyCallback(statistic);
      });
    }
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
}
