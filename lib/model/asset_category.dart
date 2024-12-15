import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:income_expense_budget_plan/model/name_localized_model.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'assets.dart';

abstract class AssetTreeNode extends NameLocalizedModel<String> {
  IconData? icon;
  int positionIndex = 0;
  bool deleted = false;
  AssetTreeNode({required super.id, required super.name, super.localizeNames, required this.icon, required this.deleted});

  @override
  Map<String, Object?> toMap() {
    Map<String, Object?> result = super.toMap();
    result.addAll(
        {'icon': icon != null ? Util().iconDataToJSONString(icon!) : "", 'position_index': positionIndex, 'soft_deleted': deleted ? 1 : 0});
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()}, "icon": ${Util().iconDataToJSONString(icon)}, "positionIndex": $positionIndex,"deleted": "${deleted ? 1 : 0}"}"';
  }
}

class AssetCategory extends AssetTreeNode {
  bool system = false;
  late DateTime lastUpdated;
  List<Asset> assets = [];

  AssetCategory({
    required super.id,
    required super.icon,
    required super.name,
    bool? system,
    super.localizeNames,
    DateTime? updatedDateTime,
    int? index,
    required super.deleted,
  }) {
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

  @override
  Map<String, Object?> toMap() {
    Map<String, Object?> result = super.toMap();
    result.addAll({'system': system ? 1 : 0, 'last_updated': lastUpdated.millisecondsSinceEpoch});
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()}, "system": $system, "lastUpdated": "${lastUpdated.toIso8601String()}"';
  }

  factory AssetCategory.fromMap(Map<String, dynamic> json) => AssetCategory(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        system: json['system'] == 1,
        localizeNames: Util().fromLocalizeDbField(Util().customJsonDecode(json['localize_names'])),
        index: json['position_index'],
        updatedDateTime: DateTime.fromMillisecondsSinceEpoch(json['last_updated']),
        deleted: json['soft_deleted'] == 1,
      );

  @override
  String displayText() => name;

  @override
  String idFieldName() => "uid";
}
