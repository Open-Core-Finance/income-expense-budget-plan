import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:income_expense_budget_plan/service/util.dart';

class TransactionCategory {
  String uid;
  IconData? icon;
  String name;
  String? parentUid;
  List<TransactionCategory> child = [];
  TransactionType transactionType;
  bool system = false;
  Map<String, String> localizeNames = {};

  TransactionCategory(
      {required this.uid,
      required this.icon,
      required this.name,
      this.parentUid,
      required this.transactionType,
      bool? system,
      Map<String, String>? localizeNames}) {
    this.system = system == true;
    if (localizeNames != null) {
      this.localizeNames = localizeNames;
    }
  }

  // Convert a Assets into a Map. The keys must correspond to the names of the columns in the database.
  Map<String, Object?> toMap() {
    return {
      'uid': uid,
      'name': name,
      'icon': icon != null ? Util().iconDataToJSONString(icon!) : "",
      'parent_uid': parentUid ?? '',
      'transaction_type': transactionType.name,
      'system': system ? 1 : 0,
      'localize_names': jsonEncode(localizeNames)
    };
  }

  // Implement toString to make it easier to see information about
  // each Assets when using the print statement.
  @override
  String toString() {
    return '{"uid": "$uid", "name": "$name", "icon": ${Util().iconDataToJSONString(icon)},"parentUid": "$parentUid"${child.isNotEmpty ? ', '
        '"child": $child' : ''}, transactionType: $transactionType,"system": $system, "localizeNames": ${jsonEncode(localizeNames)}';
  }

  factory TransactionCategory.fromMap(Map<String, dynamic> json) => TransactionCategory(
        uid: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        parentUid: (json['parent_uid'] as String).isNotEmpty ? json['parent_uid'] : null,
        transactionType: TransactionType.values.firstWhere((txnType) => txnType.toString().split('.').last == json['transaction_type']),
        system: json['system'] == 1,
        localizeNames: jsonDecode(json['localize_names']) as Map<String, String>,
      );
}

enum TransactionType { income, expense, transfer, lend, borrowing, adjustment, groupPrePaid, groupPaidMemberReturn }

class TransactionCategoriesListenable extends ChangeNotifier {
  final TransactionType transactionType;
  final List<TransactionCategory> categories;
  TransactionCategoriesListenable({required this.transactionType, required this.categories});

  void addItem(TransactionCategory transactionCategory) {
    if (transactionCategory.parentUid == null) {
      if (!categories.contains(transactionCategory)) {
        categories.add(transactionCategory);
      }
    } else {
      addChildToParent(transactionCategory, categories);
    }
    notifyListeners();
  }

  bool addChildToParent(TransactionCategory transactionCategory, List<TransactionCategory> parentList) {
    for (TransactionCategory parent in parentList) {
      if (parent.uid == transactionCategory.parentUid) {
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
    return '{"transactionType": "$transactionType", "categories": $categories}';
  }
}
