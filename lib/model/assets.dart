import 'dart:convert';

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
        '"categoryUid": "$categoryUid","localizeNames": ${jsonEncode(localizeNames)}, "localizeDescriptions": ${jsonEncode(localizeDescriptions)},"availableAmount": "$availableAmount"';
  }

  @override
  String displayText() => name;

  @override
  String idFieldName() => "uid";
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

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({'asset_type': AssetType.genericAccount.name});
    return result;
  }

  factory GenericAccount.fromMap(Map<String, dynamic> json) => GenericAccount(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        description: json['description'],
        currencyUid: json['currency_uid'],
        localizeNames: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_names'])),
        localizeDescriptions: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_descriptions'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMicrosecondsSinceEpoch(json['last_updated']),
        availableAmount: json['available_amount'],
        categoryUid: json['category_uid'],
      );
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

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({'asset_type': AssetType.bankCasa.name});
    return result;
  }

  factory BankCasaAccount.fromMap(Map<String, dynamic> json) => BankCasaAccount(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        description: json['description'],
        currencyUid: json['currency_uid'],
        localizeNames: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_names'])),
        localizeDescriptions: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_descriptions'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMicrosecondsSinceEpoch(json['last_updated']),
        availableAmount: json['available_amount'],
        categoryUid: json['category_uid'],
      );
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
        localizeNames: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_names'])),
        localizeDescriptions: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_descriptions'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMicrosecondsSinceEpoch(json['last_updated']),
        loanAmount: json['loan_amount'],
        categoryUid: json['category_uid'],
      );
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

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({'asset_type': AssetType.eWallet.name});
    return result;
  }

  factory EWallet.fromMap(Map<String, dynamic> json) => EWallet(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        description: json['description'],
        currencyUid: json['currency_uid'],
        localizeNames: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_names'])),
        localizeDescriptions: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_descriptions'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMicrosecondsSinceEpoch(json['last_updated']),
        availableAmount: json['available_amount'],
        categoryUid: json['category_uid'],
      );
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
    result.addAll({'credit_limit': creditLimit, 'asset_type': AssetType.creditCard.name});
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
        updatedDateTime: DateTime.fromMicrosecondsSinceEpoch(json['last_updated']),
        availableAmount: json['available_amount'],
        creditLimit: json['credit_limit'],
        categoryUid: json['category_uid'],
      );
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
    result.addAll({'payment_limit': paymentLimit, 'asset_type': AssetType.creditCard.name});
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
        updatedDateTime: DateTime.fromMicrosecondsSinceEpoch(json['last_updated']),
        availableAmount: json['available_amount'],
        paymentLimit: json['payment_limit'],
        categoryUid: json['category_uid'],
      );
}
