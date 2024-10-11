import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/local_date.dart';
import 'package:income_expense_budget_plan/model/name_localized_model.dart';
import 'package:income_expense_budget_plan/model/transaction.dart';
import 'package:income_expense_budget_plan/service/util.dart';

class TransactionCategory extends NameLocalizedModel<String> {
  IconData? icon;
  String? parentUid;
  TransactionCategory? parent;
  List<TransactionCategory> child = [];
  TransactionType transactionType;
  bool system = false;
  int positionIndex = 0;
  late DateTime lastUpdated;

  TransactionCategory(
      {required super.id,
      required this.icon,
      required super.name,
      this.parentUid,
      required this.transactionType,
      bool? system,
      Map<String, String>? localizeNames,
      DateTime? updatedDateTime,
      int? index}) {
    this.system = system == true;
    if (localizeNames != null) {
      this.localizeNames = localizeNames;
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
    return {
      idFieldName(): id,
      'name': name,
      'icon': icon != null ? Util().iconDataToJSONString(icon!) : "",
      'parent_uid': parentUid ?? '',
      'transaction_type': transactionType.name,
      'system': system ? 1 : 0,
      'localize_names': jsonEncode(localizeNames),
      'position_index': positionIndex,
      'last_updated': lastUpdated.millisecondsSinceEpoch
    };
  }

  @override
  String toString() {
    return '{"${idFieldName()}": "$id", "name": "$name", "icon": ${Util().iconDataToJSONString(icon)},"parentUid": "$parentUid"${child.isNotEmpty ? ', '
            '"child": $child' : ''}, "transactionType": "${transactionType.name}", "localizeNames": ${jsonEncode(localizeNames)},"system": $system,'
        '"positionIndex": $positionIndex, "lastUpdated": "${lastUpdated.toIso8601String()}"}';
  }

  factory TransactionCategory.fromMap(Map<String, dynamic> json) => TransactionCategory(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        parentUid: (json['parent_uid'] as String).isNotEmpty ? json['parent_uid'] : null,
        transactionType: TransactionType.values.firstWhere((txnType) => txnType.toString().split('.').last == json['transaction_type']),
        system: json['system'] == 1,
        localizeNames: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_names'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMillisecondsSinceEpoch(json['last_updated']),
      );

  @override
  String displayText() => name;

  @override
  String idFieldName() => "uid";
}

enum TransactionType { income, expense, transfer, lend, borrowing, adjustment, shareBill, shareBillReturn }

class TransactionCategoriesListenable extends ChangeNotifier {
  final Map<TransactionType, List<TransactionCategory>> categoriesMap;
  Function()? customTriggerCallback;
  TransactionCategoriesListenable({required this.categoriesMap, this.customTriggerCallback});

  void addItem(TransactionCategory transactionCategory) {
    List<TransactionCategory>? categories = categoriesMap[transactionCategory.transactionType];
    if (categories == null) {
      categories = [];
      categoriesMap[transactionCategory.transactionType] = categories;
    }
    if (transactionCategory.parentUid == null) {
      if (!categories.contains(transactionCategory)) {
        categories.add(transactionCategory);
      }
    } else {
      addChildToParent(transactionCategory, categories);
    }
    triggerNotify();
  }

  void refreshItem(TransactionCategory transactionCategory, String? oldParentUid, String? newParentUid,
      Function(List<TransactionCategory> newCats)? callback) {
    TransactionDao().transactionCategoryByType(transactionCategory.transactionType).then((List<TransactionCategory> loadCats) {
      List<TransactionCategory>? categories = categoriesMap[transactionCategory.transactionType];
      if (categories == null) {
        categories = [];
        categoriesMap[transactionCategory.transactionType] = categories;
      } else {
        categories.removeRange(0, categories.length);
      }
      categories.addAll(loadCats);
      if (kDebugMode) {
        print("Final refreshed categories $categories");
      }
      if (callback != null) {
        callback(categories);
      }
      triggerNotify();
    });
  }

  bool addChildToParent(TransactionCategory transactionCategory, List<TransactionCategory> parentList) {
    for (TransactionCategory parent in parentList) {
      if (parent.id == transactionCategory.parentUid) {
        parent.child.add(transactionCategory);
        return true;
      } else {
        if (addChildToParent(transactionCategory, parent.child)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  String toString() {
    return '{"categoriesMap": $categoriesMap}';
  }

  void triggerNotify() {
    notifyListeners();
    if (customTriggerCallback != null) {
      customTriggerCallback!();
    }
  }
}
