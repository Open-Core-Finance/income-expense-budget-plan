import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/service/statistic.dart';

class AccountStatistic extends Statistic {
  Asset account;
  AccountStatistic({required this.account});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountStatistic && other.account == account;
  }

  @override
  int get hashCode => account.hashCode;

  @override
  String toAttrString() => '${super.toAttrString()}, "account": "${account.name}"';
}

class CurrencyStatistic extends Statistic {
  Currency currency;
  CurrencyStatistic({required this.currency});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurrencyStatistic && other.currency == currency;
  }

  @override
  int get hashCode => currency.hashCode;

  @override
  String toAttrString() => '${super.toAttrString()}, "currency": "${currency.name}"';
}
