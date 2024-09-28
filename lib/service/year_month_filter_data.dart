import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/transaction.dart';

class YearMonthFilterData extends ChangeNotifier {
  late int year;
  late int month;
  List<Transactions> transactions = [];

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
    _refreshFilterTransactions((transactions) => notifyListeners());
  }

  void nextMonth() {
    if (month < 12) {
      month = month + 1;
    } else {
      month = 1;
      year = year + 1;
    }
    _refreshFilterTransactions((transactions) => notifyListeners());
  }

  @override
  String toString() {
    return '{"month": $month, "year": $year}';
  }

  void _refreshFilterTransactions(void Function(List<Transactions>) callback) {
    TransactionDao().transactionsByYearAndMonth(year, month).then((txns) {
      transactions = txns;
      callback(txns);
    });
  }
}
