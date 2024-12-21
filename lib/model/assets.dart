import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
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
  double paidFee;

  Asset({
    required super.id,
    required super.icon,
    required super.name,
    required this.description,
    super.localizeNames,
    Map<String, String>? localizeDescriptions,
    DateTime? updatedDateTime,
    int? index,
    required this.currencyUid,
    required this.categoryUid,
    required this.availableAmount,
    required super.deleted,
    required this.paidFee,
  }) {
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

  @override
  Map<String, Object?> toMap() {
    Map<String, Object?> result = super.toMap();
    result.addAll({
      'description': description,
      'currency_uid': currencyUid,
      'localize_descriptions': jsonEncode(localizeDescriptions),
      'last_updated': lastUpdated.millisecondsSinceEpoch,
      'category_uid': categoryUid,
      'available_amount': availableAmount,
      'asset_type': getAssetType()
    });
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()},"description": "$description", "currencyUid": "$currencyUid", '
        '"categoryUid": "$categoryUid", "localizeDescriptions": ${jsonEncode(localizeDescriptions)},"availableAmount": "$availableAmount",'
        '"assetType": "${getAssetType()}", "lastUpdated": "${lastUpdated.toIso8601String()}"';
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
    required super.deleted,
    required super.paidFee,
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
        deleted: json['soft_deleted'] == 1,
        paidFee: json['paid_fee'],
      );

  @override
  String getAssetType() => AssetType.genericAccount.name;

  @override
  String asExportDataLine() {
    return '${super.asExportDataLine()}|$deleted';
  }
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
    required super.deleted,
    required super.paidFee,
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
        deleted: json['soft_deleted'] == 1,
        paidFee: json['paid_fee'],
      );

  @override
  String getAssetType() => AssetType.bankCasa.name;

  @override
  String asExportDataLine() {
    return '${super.asExportDataLine()}|$deleted';
  }
}

class LoanAccount extends Asset {
  double loanAmount;
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
    required super.deleted,
    required super.paidFee,
  }) : super(availableAmount: 0);

  @override
  Map<String, Object?> toMap() {
    Map<String, Object?> result = super.toMap();
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
        deleted: json['soft_deleted'] == 1,
        paidFee: json['paid_fee'],
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
    return '${super.asExportDataLine()}|$loanAmount|$deleted';
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
    required super.deleted,
    required super.paidFee,
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
        deleted: json['soft_deleted'] == 1,
        paidFee: json['paid_fee'],
      );

  @override
  String getAssetType() => AssetType.eWallet.name;

  @override
  String asExportDataLine() {
    return '${super.asExportDataLine()}|$deleted';
  }
}

class CreditCard extends Asset {
  double creditLimit = 0;
  CreditCard({
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
    required this.creditLimit,
    required super.deleted,
    required super.paidFee,
  });

  @override
  Map<String, Object?> toMap() {
    Map<String, Object?> result = super.toMap();
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
        deleted: json['soft_deleted'] == 1,
        paidFee: json['paid_fee'],
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
    return '${super.asExportDataLine()}|$creditLimit|$deleted';
  }
}

class PayLaterAccount extends Asset {
  double paymentLimit = 0;
  PayLaterAccount({
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
    required this.paymentLimit,
    required super.deleted,
    required super.paidFee,
  });

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
        deleted: json['soft_deleted'] == 1,
        paidFee: json['paid_fee'],
      );

  @override
  String getAssetType() => AssetType.payLaterAccount.name;

  @override
  String asExportDataLine() {
    return '${super.asExportDataLine()}|$paymentLimit|$deleted';
  }
}
