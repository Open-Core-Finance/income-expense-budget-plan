import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:income_expense_budget_plan/model/name_localized_model.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'assets.dart';

abstract class AssetTreeNode extends NameLocalizedModel<String> {
  IconData? icon;
  int positionIndex = 0;
  AssetTreeNode({required super.id, required super.name, super.localizeNames, required this.icon});
}

class AssetCategory extends AssetTreeNode {
  bool system = false;
  late DateTime lastUpdated;
  List<Asset> assets = [];

  AssetCategory(
      {required super.id,
      required super.icon,
      required super.name,
      bool? system,
      super.localizeNames,
      DateTime? updatedDateTime,
      int? index}) {
    this.system = system == true;
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
      'icon': icon != null ? Util().iconDataToJSONString(icon!) : "",
      'system': system ? 1 : 0,
      'localize_names': jsonEncode(localizeNames),
      'position_index': positionIndex,
      'last_updated': lastUpdated.millisecondsSinceEpoch
    };
  }

  // Implement toString to make it easier to see information about
  // each Asset when using the print statement.
  @override
  String toString() {
    return '{"${idFieldName()}": "$id", "name": "$name", "icon": ${Util().iconDataToJSONString(icon)},"system": $system, "localizeNames": ${jsonEncode(localizeNames)},'
        '"positionIndex": $positionIndex, "lastUpdated": "${lastUpdated.toIso8601String()}"}';
  }

  factory AssetCategory.fromMap(Map<String, dynamic> json) => AssetCategory(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        system: json['system'] == 1,
        localizeNames: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_names'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMicrosecondsSinceEpoch(json['last_updated']),
      );

  @override
  String displayText() => name;

  @override
  String idFieldName() => "uid";
}
