import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/generic_model.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/util.dart';

abstract class Transactions extends GenericModel {
  late DateTime lastUpdated;
  DateTime transactionDate;
  TimeOfDay transactionTime;
  TransactionCategory? transactionCategory;
  String description;
  bool withFee;
  double feeAmount;
  double amount;
  Asset account;
  String currencyUid;
  late bool notIncludeToReport;
  Transactions(
      {required super.id,
      required this.transactionDate,
      required this.transactionTime,
      required this.transactionCategory,
      required this.description,
      required this.withFee,
      required this.feeAmount,
      required this.amount,
      DateTime? updatedDateTime,
      required this.account,
      required this.currencyUid,
      bool? skipReport}) {
    if (updatedDateTime == null) {
      lastUpdated = DateTime.now();
    } else {
      lastUpdated = updatedDateTime;
    }
    if (skipReport != null) {
      notIncludeToReport = skipReport;
    } else {
      notIncludeToReport = false;
    }
  }

  @override
  Map<String, Object?> toMap() {
    return {
      idFieldName(): id,
      'description': description,
      'transaction_date': transactionDate.millisecondsSinceEpoch,
      'transaction_time': Util().timeOfDayToMinutes(transactionTime),
      'transaction_category_uid': transactionCategory?.id,
      'with_fee': withFee ? 1 : 0,
      'fee_amount': feeAmount,
      'amount': amount,
      'last_updated': lastUpdated.millisecondsSinceEpoch,
      'account_uid': account.id,
      'currency_uid': currencyUid,
      "transaction_type": getType().name,
      "not_include_to_report": notIncludeToReport == true ? 1 : 0
    };
  }

  // Implement toString to make it easier to see information about
  // each Asset when using the print statement.
  @override
  String toString() {
    return '{${attributeString()}}';
  }

  String attributeString() {
    return '"${idFieldName()}": "$id", "transactionDate": "$transactionDate", "transactionTime": "$transactionTime", "transactionCategory": $transactionCategory,"description": "$description", '
        '"withFee": $withFee, "feeAmount": "$feeAmount", "amount": "$amount", "currencyUid": "$currencyUid", "accountId": "${account.id}",'
        '"lastUpdated": "$lastUpdated", "transactionType": "${getType()}", "notIncludeToReport": $notIncludeToReport';
  }

  @override
  String displayText() => id;

  @override
  String idFieldName() => "id";

  factory Transactions.fromMap(Map<String, dynamic> json) => throw UnimplementedError('fromMap must be implemented in subclasses');

  TransactionType getType();

  String asExportDataLine() {
    return '${getType().name}|$id|${transactionDate.millisecondsSinceEpoch}|${Util().timeOfDayToMinutes(transactionTime)}|${transactionCategory?.id}|$description|'
        '$withFee|$feeAmount|$amount|${lastUpdated.millisecondsSinceEpoch}|$currencyUid|$notIncludeToReport|${account.id}';
  }
}

class IncomeTransaction extends Transactions {
  IncomeTransaction(
      {required super.id,
      required super.transactionDate,
      required super.transactionTime,
      required super.transactionCategory,
      required super.description,
      required super.withFee,
      required super.feeAmount,
      required super.amount,
      super.updatedDateTime,
      required super.account,
      required super.currencyUid,
      super.skipReport});

  factory IncomeTransaction.fromMap(Map<String, dynamic> json) => IncomeTransaction(
      id: json['id'],
      description: json['description'] as String,
      transactionDate: DateTime.fromMillisecondsSinceEpoch(json['transaction_date']),
      transactionTime: Util().minutesToTimeOfDay(json['transaction_time']),
      transactionCategory: currentAppState.retrieveCategory(json['transaction_category_uid'] as String?),
      currencyUid: json['currency_uid'],
      withFee: json['with_fee'] == 1,
      feeAmount: json['fee_amount'],
      amount: json['amount'],
      updatedDateTime: DateTime.fromMillisecondsSinceEpoch(json['last_updated']),
      account: currentAppState.retrieveAccount(json['account_uid'] as String) ?? currentAppState.assets[0],
      skipReport: json['not_include_to_report'] == 1);

  @override
  TransactionType getType() => TransactionType.income;
}

class ExpenseTransaction extends Transactions {
  ExpenseTransaction(
      {required super.id,
      required super.transactionDate,
      required super.transactionTime,
      required super.transactionCategory,
      required super.description,
      required super.withFee,
      required super.feeAmount,
      required super.amount,
      super.updatedDateTime,
      required super.account,
      required super.currencyUid,
      super.skipReport});

  @override
  TransactionType getType() => TransactionType.expense;

  factory ExpenseTransaction.fromMap(Map<String, dynamic> json) => ExpenseTransaction(
      id: json['id'],
      description: json['description'] as String,
      transactionDate: DateTime.fromMillisecondsSinceEpoch(json['transaction_date']),
      transactionTime: Util().minutesToTimeOfDay(json['transaction_time']),
      transactionCategory: currentAppState.retrieveCategory(json['transaction_category_uid'] as String?),
      currencyUid: json['currency_uid'],
      withFee: json['with_fee'] == 1,
      feeAmount: json['fee_amount'],
      amount: json['amount'],
      updatedDateTime: DateTime.fromMillisecondsSinceEpoch(json['last_updated']),
      account: currentAppState.retrieveAccount(json['account_uid'] as String) ?? currentAppState.assets[0],
      skipReport: json['not_include_to_report'] == 1);
}

class TransferTransaction extends Transactions {
  Asset toAccount;
  bool feeApplyToFromAccount = false;
  TransferTransaction(
      {required super.id,
      required super.transactionDate,
      required super.transactionTime,
      required super.transactionCategory,
      required super.description,
      required super.withFee,
      required super.feeAmount,
      required super.amount,
      super.updatedDateTime,
      required super.account,
      required super.currencyUid,
      required this.toAccount,
      bool? feeApplyTo,
      super.skipReport}) {
    if (feeApplyTo == true) {
      feeApplyToFromAccount = true;
    } else {
      feeApplyToFromAccount = false;
    }
  }

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({'to_account_uid': toAccount.id, "fee_apply_to_from_account": feeApplyToFromAccount == true ? 1 : 0});
    return result;
  }

  @override
  TransactionType getType() => TransactionType.transfer;

  @override
  String attributeString() {
    return '${super.attributeString()}, "toAccount":"$toAccount", "feeApplyToFromAccount": ${feeApplyToFromAccount == true}';
  }

  factory TransferTransaction.fromMap(Map<String, dynamic> json) => TransferTransaction(
      id: json['id'],
      description: json['description'] as String,
      transactionDate: DateTime.fromMillisecondsSinceEpoch(json['transaction_date']),
      transactionTime: Util().minutesToTimeOfDay(json['transaction_time']),
      transactionCategory: currentAppState.retrieveCategory(json['transaction_category_uid'] as String?),
      currencyUid: json['currency_uid'],
      withFee: json['with_fee'] == 1,
      feeAmount: json['fee_amount'],
      amount: json['amount'],
      updatedDateTime: DateTime.fromMillisecondsSinceEpoch(json['last_updated']),
      account: currentAppState.retrieveAccount(json['account_uid'] as String) ?? currentAppState.assets[0],
      toAccount: currentAppState.retrieveAccount(json['to_account_uid'] as String) ?? currentAppState.assets[0],
      feeApplyTo: json['fee_apply_to_from_account'] == 1,
      skipReport: json['not_include_to_report'] == 1);

  @override
  String asExportDataLine() {
    return '${super.asExportDataLine()}|${toAccount.id}|$feeApplyToFromAccount';
  }
}

class LendTransaction extends Transactions {
  LendTransaction(
      {required super.id,
      required super.transactionDate,
      required super.transactionTime,
      required super.transactionCategory,
      required super.description,
      required super.withFee,
      required super.feeAmount,
      required super.amount,
      super.updatedDateTime,
      required super.account,
      required super.currencyUid,
      super.skipReport});

  @override
  TransactionType getType() => TransactionType.lend;

  factory LendTransaction.fromMap(Map<String, dynamic> json) => LendTransaction(
      id: json['id'],
      description: json['description'] as String,
      transactionDate: DateTime.fromMillisecondsSinceEpoch(json['transaction_date']),
      transactionTime: Util().minutesToTimeOfDay(json['transaction_time']),
      transactionCategory: currentAppState.retrieveCategory(json['transaction_category_uid'] as String?),
      currencyUid: json['currency_uid'],
      withFee: json['with_fee'] == 1,
      feeAmount: json['fee_amount'],
      amount: json['amount'],
      updatedDateTime: DateTime.fromMillisecondsSinceEpoch(json['last_updated']),
      account: currentAppState.retrieveAccount(json['account_uid'] as String) ?? currentAppState.assets[0],
      skipReport: json['not_include_to_report'] == 1);
}

class BorrowingTransaction extends Transactions {
  BorrowingTransaction(
      {required super.id,
      required super.transactionDate,
      required super.transactionTime,
      required super.transactionCategory,
      required super.description,
      required super.withFee,
      required super.feeAmount,
      required super.amount,
      super.updatedDateTime,
      required super.account,
      required super.currencyUid,
      super.skipReport});

  @override
  TransactionType getType() => TransactionType.borrowing;

  factory BorrowingTransaction.fromMap(Map<String, dynamic> json) => BorrowingTransaction(
      id: json['id'],
      description: json['description'] as String,
      transactionDate: DateTime.fromMillisecondsSinceEpoch(json['transaction_date']),
      transactionTime: Util().minutesToTimeOfDay(json['transaction_time']),
      transactionCategory: currentAppState.retrieveCategory(json['transaction_category_uid'] as String?),
      currencyUid: json['currency_uid'],
      withFee: json['with_fee'] == 1,
      feeAmount: json['fee_amount'],
      amount: json['amount'],
      updatedDateTime: DateTime.fromMillisecondsSinceEpoch(json['last_updated']),
      account: currentAppState.retrieveAccount(json['account_uid'] as String) ?? currentAppState.assets[0],
      skipReport: json['not_include_to_report'] == 1);
}

class AdjustmentTransaction extends Transactions {
  double adjustedAmount = 0;
  AdjustmentTransaction(
      {required super.id,
      required super.transactionDate,
      required super.transactionTime,
      required super.transactionCategory,
      required super.description,
      required super.withFee,
      required super.feeAmount,
      required super.amount,
      super.updatedDateTime,
      required super.account,
      required super.currencyUid,
      double? adjustedAmount,
      super.skipReport}) {
    if (adjustedAmount != null) {
      this.adjustedAmount = adjustedAmount;
    }
  }

  @override
  TransactionType getType() => TransactionType.adjustment;

  factory AdjustmentTransaction.fromMap(Map<String, dynamic> json) => AdjustmentTransaction(
      id: json['id'],
      description: json['description'] as String,
      transactionDate: DateTime.fromMillisecondsSinceEpoch(json['transaction_date']),
      transactionTime: Util().minutesToTimeOfDay(json['transaction_time']),
      transactionCategory: currentAppState.retrieveCategory(json['transaction_category_uid'] as String?),
      currencyUid: json['currency_uid'],
      withFee: json['with_fee'] == 1,
      feeAmount: json['fee_amount'],
      amount: json['amount'],
      updatedDateTime: DateTime.fromMillisecondsSinceEpoch(json['last_updated']),
      account: currentAppState.retrieveAccount(json['account_uid'] as String) ?? currentAppState.assets[0],
      adjustedAmount: json['adjusted_amount'],
      skipReport: json['not_include_to_report'] == 1);

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({'adjusted_amount': adjustedAmount});
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()}, "adjustedAmount":"$adjustedAmount"}';
  }

  @override
  String asExportDataLine() {
    return '${super.asExportDataLine()}|$adjustedAmount';
  }
}

class ShareBillTransaction extends Transactions {
  double mySplit;
  late double remainingAmount;
  ShareBillTransaction(
      {required super.id,
      required super.transactionDate,
      required super.transactionTime,
      required super.transactionCategory,
      required super.description,
      required super.withFee,
      required super.feeAmount,
      required super.amount,
      super.updatedDateTime,
      required super.account,
      required super.currencyUid,
      required this.mySplit,
      double? remaining,
      super.skipReport}) {
    if (remaining != null) {
      remainingAmount = remaining;
    } else {
      remainingAmount = ((withFee ? feeAmount : 0) + amount) - mySplit;
    }
  }

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({'my_split': mySplit, 'remaining_amount': remainingAmount});
    return result;
  }

  @override
  TransactionType getType() => TransactionType.shareBill;

  @override
  String attributeString() {
    return '${super.attributeString()}, "mySplit": "$mySplit", "remainingAmount": $remainingAmount';
  }

  factory ShareBillTransaction.fromMap(Map<String, dynamic> json) => ShareBillTransaction(
      id: json['id'],
      description: json['description'] as String,
      transactionDate: DateTime.fromMillisecondsSinceEpoch(json['transaction_date']),
      transactionTime: Util().minutesToTimeOfDay(json['transaction_time']),
      transactionCategory: currentAppState.retrieveCategory(json['transaction_category_uid'] as String?),
      currencyUid: json['currency_uid'],
      withFee: json['with_fee'] == 1,
      feeAmount: json['fee_amount'],
      amount: json['amount'],
      updatedDateTime: DateTime.fromMillisecondsSinceEpoch(json['last_updated']),
      account: currentAppState.retrieveAccount(json['account_uid'] as String) ?? currentAppState.assets[0],
      mySplit: json['my_split'],
      remaining: json['remaining_amount'],
      skipReport: json['not_include_to_report'] == 1);

  @override
  String asExportDataLine() {
    return '${super.asExportDataLine()}|$mySplit|$remainingAmount';
  }
}

class ShareBillReturnTransaction extends Transactions {
  ShareBillTransaction? sharedBill;
  ShareBillReturnTransaction(
      {required super.id,
      required super.transactionDate,
      required super.transactionTime,
      required super.transactionCategory,
      required super.description,
      required super.withFee,
      required super.feeAmount,
      required super.amount,
      super.updatedDateTime,
      required super.account,
      required super.currencyUid,
      this.sharedBill,
      super.skipReport});

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({'shared_bill_id': sharedBill?.id});
    return result;
  }

  @override
  TransactionType getType() => TransactionType.shareBillReturn;

  @override
  String attributeString() {
    return '${super.attributeString()}, "sharedBillId": "$sharedBill"';
  }

  factory ShareBillReturnTransaction.fromMap(Map<String, dynamic> json, ShareBillTransaction? shareBill) => ShareBillReturnTransaction(
      id: json['id'],
      description: json['description'] as String,
      transactionDate: DateTime.fromMillisecondsSinceEpoch(json['transaction_date']),
      transactionTime: Util().minutesToTimeOfDay(json['transaction_time']),
      transactionCategory: currentAppState.retrieveCategory(json['transaction_category_uid'] as String?),
      currencyUid: json['currency_uid'],
      withFee: json['with_fee'] == 1,
      feeAmount: json['fee_amount'],
      amount: json['amount'],
      updatedDateTime: DateTime.fromMillisecondsSinceEpoch(json['last_updated']),
      account: currentAppState.retrieveAccount(json['account_uid'] as String) ?? currentAppState.assets[0],
      // sharedBillId: json['shared_bill_id'],
      sharedBill: shareBill,
      skipReport: json['not_include_to_report'] == 1);

  @override
  String asExportDataLine() {
    return '${super.asExportDataLine()}|${sharedBill?.id}';
  }
}
