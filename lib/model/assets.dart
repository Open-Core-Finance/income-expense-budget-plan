import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/data_export_import.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/util.dart';

import 'asset_category.dart';

abstract class Asset extends AssetTreeNode {
  String description;
  String currencyUid;
  Map<String, String> localizeDescriptions = {};
  late DateTime lastUpdated;
  String categoryUid;
  AssetCategory? category;
  double availableAmount = 0;

  Asset(
      {required super.id,
      required super.icon,
      required super.name,
      required this.description,
      super.localizeNames,
      Map<String, String>? localizeDescriptions,
      DateTime? updatedDateTime,
      int? index,
      required this.currencyUid,
      required this.categoryUid,
      required this.availableAmount}) {
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

  // Convert a Asset into a Map. The keys must correspond to the names of the columns in the database.
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
      'category_uid': categoryUid,
      'available_amount': availableAmount,
      'asset_type': getAssetType()
    };
  }

  // Implement toString to make it easier to see information about
  // each Asset when using the print statement.
  @override
  String toString() {
    return '{${attributeString()}}';
  }

  String attributeString() {
    return '"${idFieldName()}": "$id", "name": "$name", "icon": ${Util().iconDataToJSONString(icon)},"description": "$description", '
        '"positionIndex": $positionIndex, "lastUpdated": "${lastUpdated.toIso8601String()}", "currencyUid": "$currencyUid", '
        '"categoryUid": "$categoryUid","localizeNames": ${jsonEncode(localizeNames)}, "localizeDescriptions": ${jsonEncode(localizeDescriptions)},"availableAmount": "$availableAmount",'
        '"assetType": "${getAssetType()}"';
  }

  @override
  String displayText() => name;

  @override
  String idFieldName() => "uid";

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Asset && other.id == id && id != null;
  }

  @override
  int get hashCode => id?.hashCode ?? 0;

  Widget getAmountDisplayText() {
    var formatter = FormUtil().buildFormatter(currentAppState.currencies
        .firstWhere((element) => element.id == currencyUid, orElse: () => currentAppState.systemSetting.defaultCurrency!));
    return Text(formatter.formatDouble(availableAmount));
  }

  String getAssetType();

  String asExportDataLine() {
    return '$id|$name|${Util().iconDataToJSONString(icon)}|$description|$positionIndex|${lastUpdated.millisecondsSinceEpoch}|'
        '$currencyUid|$categoryUid|${jsonEncode(localizeNames)}|${jsonEncode(localizeDescriptions)}|$availableAmount|${getAssetType()}';
  }
}

enum AssetType { genericAccount, bankCasa, loan, eWallet, creditCard, payLaterAccount }

class GenericAccount extends Asset {
  GenericAccount({
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
    required super.availableAmount,
  });

  factory GenericAccount.fromMap(Map<String, dynamic> json) => GenericAccount(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        description: json['description'],
        currencyUid: json['currency_uid'],
        localizeNames: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_names'])),
        localizeDescriptions: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_descriptions'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMillisecondsSinceEpoch(json['last_updated']),
        availableAmount: json['available_amount'],
        categoryUid: json['category_uid'],
      );

  @override
  String getAssetType() => AssetType.genericAccount.name;
}

class BankCasaAccount extends Asset {
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
    required super.availableAmount,
  });

  factory BankCasaAccount.fromMap(Map<String, dynamic> json) => BankCasaAccount(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        description: json['description'],
        currencyUid: json['currency_uid'],
        localizeNames: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_names'])),
        localizeDescriptions: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_descriptions'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMillisecondsSinceEpoch(json['last_updated']),
        availableAmount: json['available_amount'],
        categoryUid: json['category_uid'],
      );

  @override
  String getAssetType() => AssetType.bankCasa.name;
}

class LoanAccount extends Asset {
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
  }) : super(availableAmount: 0);

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({'loan_amount': loanAmount});
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
        localizeNames: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_names'])),
        localizeDescriptions: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_descriptions'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMillisecondsSinceEpoch(json['last_updated']),
        loanAmount: json['loan_amount'],
        categoryUid: json['category_uid'],
      );

  @override
  Widget getAmountDisplayText() {
    var formatter = FormUtil().buildFormatter(currentAppState.currencies
        .firstWhere((element) => element.id == currencyUid, orElse: () => currentAppState.systemSetting.defaultCurrency!));
    return Text(formatter.formatDouble(loanAmount));
  }

  @override
  String getAssetType() => AssetType.loan.name;

  @override
  String asExportDataLine() {
    return '${super.asExportDataLine()}|$loanAmount';
  }
}

class EWallet extends Asset {
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
    required super.availableAmount,
  });

  factory EWallet.fromMap(Map<String, dynamic> json) => EWallet(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        description: json['description'],
        currencyUid: json['currency_uid'],
        localizeNames: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_names'])),
        localizeDescriptions: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_descriptions'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMillisecondsSinceEpoch(json['last_updated']),
        availableAmount: json['available_amount'],
        categoryUid: json['category_uid'],
      );

  @override
  String getAssetType() => AssetType.eWallet.name;
}

class CreditCard extends Asset {
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
      required super.availableAmount,
      required this.creditLimit});

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({'credit_limit': creditLimit});
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()}, "creditLimit": "$creditLimit"';
  }

  factory CreditCard.fromMap(Map<String, dynamic> json) => CreditCard(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        description: json['description'],
        currencyUid: json['currency_uid'],
        localizeNames: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_names'])),
        localizeDescriptions: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_descriptions'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMillisecondsSinceEpoch(json['last_updated']),
        availableAmount: json['available_amount'],
        creditLimit: json['credit_limit'],
        categoryUid: json['category_uid'],
      );

  @override
  Widget getAmountDisplayText() {
    var formatter = FormUtil().buildFormatter(currentAppState.currencies
        .firstWhere((element) => element.id == currencyUid, orElse: () => currentAppState.systemSetting.defaultCurrency!));
    return Text('${formatter.formatDouble(creditLimit - availableAmount)}/${formatter.formatDouble(creditLimit)}');
  }

  @override
  String getAssetType() => AssetType.creditCard.name;

  @override
  String asExportDataLine() {
    return '${super.asExportDataLine()}|$creditLimit';
  }
}

class PayLaterAccount extends Asset {
  double paymentLimit = 0;
  PayLaterAccount(
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
      required super.availableAmount,
      required this.paymentLimit});

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({'payment_limit': paymentLimit});
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()}, "paymentLimit": "$paymentLimit"';
  }

  factory PayLaterAccount.fromMap(Map<String, dynamic> json) => PayLaterAccount(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        description: json['description'],
        currencyUid: json['currency_uid'],
        localizeNames: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_names'])),
        localizeDescriptions: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_descriptions'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMillisecondsSinceEpoch(json['last_updated']),
        availableAmount: json['available_amount'],
        paymentLimit: json['payment_limit'],
        categoryUid: json['category_uid'],
      );

  @override
  String getAssetType() => AssetType.payLaterAccount.name;

  @override
  String asExportDataLine() {
    return '${super.asExportDataLine()}|$paymentLimit';
  }
}
