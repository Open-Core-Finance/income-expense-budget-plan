import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/service/util.dart';

import 'asset_category.dart';

abstract class Assets extends AssetTreeNode {
  String description;
  String currencyUid;
  Map<String, String> localizeDescriptions = {};
  int positionIndex = 0;
  late DateTime lastUpdated;
  String categoryUid;
  Currency? currency;
  AssetCategory? category;

  Assets(
      {required super.id,
      required super.icon,
      required super.name,
      required this.description,
      super.localizeNames,
      Map<String, String>? localizeDescriptions,
      DateTime? updatedDateTime,
      int? index,
      required this.currencyUid,
      required this.categoryUid}) {
    if (localizeDescriptions != null) {
      this.localizeDescriptions = localizeDescriptions;
    }
    if (updatedDateTime == null) {
      lastUpdated = DateTime.now();
    } else {
      lastUpdated = updatedDateTime;
    }
    if (index != null) {
      positionIndex = index;
    }
  }

  // Convert a Assets into a Map. The keys must correspond to the names of the columns in the database.
  @override
  Map<String, Object?> toMap() {
    return {
      idFieldName(): id,
      'name': name,
      'description': description,
      'icon': icon != null ? Util().iconDataToJSONString(icon!) : "",
      'currency_uid': currencyUid,
      'localize_names': jsonEncode(localizeNames),
      'localize_descriptions': jsonEncode(localizeDescriptions),
      'position_index': positionIndex,
      'last_updated': lastUpdated.millisecondsSinceEpoch,
      'category_uid': categoryUid
    };
  }

  // Implement toString to make it easier to see information about
  // each Assets when using the print statement.
  @override
  String toString() {
    return '{${attributeString()}}';
  }

  String attributeString() {
    return '"${idFieldName()}": "$id", "name": "$name", "icon": ${Util().iconDataToJSONString(icon)},"description": "$description", '
        '"positionIndex": $positionIndex, "lastUpdated": "${lastUpdated.toIso8601String()}", "currencyUid": "$currencyUid", '
        '"categoryUid": "$categoryUid","localizeNames": ${jsonEncode(localizeNames)}, "localizeDescriptions": ${jsonEncode(localizeDescriptions)}';
  }

  @override
  String displayText() => name;

  @override
  String idFieldName() => "uid";
}

enum AssetType { cash, bankCasa, loan, termDeposit, eWallet, creditCard }

class CashAccount extends Assets {
  double availableAmount = 0;
  CashAccount({
    required super.id,
    required super.icon,
    required super.name,
    required super.description,
    super.localizeNames,
    super.localizeDescriptions,
    super.updatedDateTime,
    super.index,
    required super.currencyUid,
    required super.categoryUid,
    required this.availableAmount,
  });

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({'available_amount': availableAmount, 'asset_type': AssetType.cash.name});
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()},"availableAmount": "$availableAmount"';
  }

  factory CashAccount.fromMap(Map<String, dynamic> json) => CashAccount(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        description: json['description'],
        currencyUid: json['currency_uid'],
        localizeNames: Util().fromLocalizeDbField(jsonDecode(json['localize_names'])),
        localizeDescriptions: Util().fromLocalizeDbField(jsonDecode(json['localize_descriptions'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMicrosecondsSinceEpoch(json['last_updated']),
        availableAmount: json['available_amount'],
        categoryUid: json['category_uid'],
      );
}

class BankCasaAccount extends Assets {
  double availableAmount = 0;
  BankCasaAccount({
    required super.id,
    required super.icon,
    required super.name,
    required super.description,
    super.localizeNames,
    super.localizeDescriptions,
    super.updatedDateTime,
    super.index,
    required super.currencyUid,
    required super.categoryUid,
    required this.availableAmount,
  });

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({'available_amount': availableAmount, 'asset_type': AssetType.bankCasa.name});
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()},"availableAmount": "$availableAmount"';
  }

  factory BankCasaAccount.fromMap(Map<String, dynamic> json) => BankCasaAccount(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        description: json['description'],
        currencyUid: json['currency_uid'],
        localizeNames: Util().fromLocalizeDbField(jsonDecode(json['localize_names'])),
        localizeDescriptions: Util().fromLocalizeDbField(jsonDecode(json['localize_descriptions'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMicrosecondsSinceEpoch(json['last_updated']),
        availableAmount: json['available_amount'],
        categoryUid: json['category_uid'],
      );
}

class LoanAccount extends Assets {
  double loanAmount = 0;
  LoanAccount({
    required super.id,
    required super.icon,
    required super.name,
    required super.description,
    super.localizeNames,
    super.localizeDescriptions,
    super.updatedDateTime,
    super.index,
    required super.currencyUid,
    required super.categoryUid,
    required this.loanAmount,
  });

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({'loan_amount': loanAmount, 'asset_type': AssetType.loan.name});
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()},"loanAmount": "$loanAmount"';
  }

  factory LoanAccount.fromMap(Map<String, dynamic> json) => LoanAccount(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        description: json['description'],
        currencyUid: json['currency_uid'],
        localizeNames: Util().fromLocalizeDbField(jsonDecode(json['localize_names'])),
        localizeDescriptions: Util().fromLocalizeDbField(jsonDecode(json['localize_descriptions'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMicrosecondsSinceEpoch(json['last_updated']),
        loanAmount: json['loan_amount'],
        categoryUid: json['category_uid'],
      );
}

class TermDepositAccount extends Assets {
  double depositAmount = 0;
  TermDepositAccount({
    required super.id,
    required super.icon,
    required super.name,
    required super.description,
    super.localizeNames,
    super.localizeDescriptions,
    super.updatedDateTime,
    super.index,
    required super.currencyUid,
    required super.categoryUid,
    required this.depositAmount,
  });

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({'deposit_amount': depositAmount, 'asset_type': AssetType.termDeposit.name});
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()},"depositAmount": "$depositAmount"';
  }

  factory TermDepositAccount.fromMap(Map<String, dynamic> json) => TermDepositAccount(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        description: json['description'],
        currencyUid: json['currency_uid'],
        localizeNames: Util().fromLocalizeDbField(jsonDecode(json['localize_names'])),
        localizeDescriptions: Util().fromLocalizeDbField(jsonDecode(json['localize_descriptions'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMicrosecondsSinceEpoch(json['last_updated']),
        depositAmount: json['deposit_amount'],
        categoryUid: json['category_uid'],
      );
}

class EWallet extends Assets {
  double availableAmount = 0;
  EWallet({
    required super.id,
    required super.icon,
    required super.name,
    required super.description,
    super.localizeNames,
    super.localizeDescriptions,
    super.updatedDateTime,
    super.index,
    required super.currencyUid,
    required super.categoryUid,
    required this.availableAmount,
  });

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({'available_amount': availableAmount, 'asset_type': AssetType.eWallet.name});
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()},"availableAmount": "$availableAmount"';
  }

  factory EWallet.fromMap(Map<String, dynamic> json) => EWallet(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        description: json['description'],
        currencyUid: json['currency_uid'],
        localizeNames: Util().fromLocalizeDbField(jsonDecode(json['localize_names'])),
        localizeDescriptions: Util().fromLocalizeDbField(jsonDecode(json['localize_descriptions'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMicrosecondsSinceEpoch(json['last_updated']),
        availableAmount: json['available_amount'],
        categoryUid: json['category_uid'],
      );
}

class CreditCard extends Assets {
  double availableAmount = 0;
  double creditLimit = 0;
  CreditCard(
      {required super.id,
      required super.icon,
      required super.name,
      required super.description,
      super.localizeNames,
      super.localizeDescriptions,
      super.updatedDateTime,
      super.index,
      required super.currencyUid,
      required super.categoryUid,
      required this.availableAmount,
      required this.creditLimit});

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({'available_amount': availableAmount, 'credit_limit': creditLimit, 'asset_type': AssetType.creditCard.name});
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()},"availableAmount": "$availableAmount", "creditLimit": "$creditLimit"';
  }

  factory CreditCard.fromMap(Map<String, dynamic> json) => CreditCard(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        description: json['description'],
        currencyUid: json['currency_uid'],
        localizeNames: Util().fromLocalizeDbField(jsonDecode(json['localize_names'])),
        localizeDescriptions: Util().fromLocalizeDbField(jsonDecode(json['localize_descriptions'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMicrosecondsSinceEpoch(json['last_updated']),
        availableAmount: json['available_amount'],
        creditLimit: json['credit_limit'],
        categoryUid: json['category_uid'],
      );
}
