import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/local_date.dart';
import 'package:income_expense_budget_plan/model/transaction.dart';
import 'package:income_expense_budget_plan/service/account_statistic.dart';
import 'package:income_expense_budget_plan/service/transaction_service.dart';

class DailyTransactionEntry {
  LocalDate localDate;
  List<Transactions> transactions = [];
  Map<Currency, CurrencyStatistic> statisticMap = {};

  DailyTransactionEntry({required this.localDate, List<Transactions>? txn}) {
    if (txn != null) {
      transactions = txn;
      for (Transactions tran in transactions) {
        _addTransactionStatistic(tran);
      }
    }
  }

  @override
  String toString() {
    return '{"localDate": "$localDate", "transactions": $transactions, "statisticMap": $statisticMap}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyTransactionEntry && other.localDate == localDate;
  }

  @override
  int get hashCode => localDate.hashCode;

  void addTransaction(Transactions transaction) {
    transactions.add(transaction);
    _addTransactionStatistic(transaction);
  }

  void _addTransactionStatistic(Transactions tran) {
    TransactionService().addTransactionStatisticToCurrency(statisticMap, tran);
  }
}
