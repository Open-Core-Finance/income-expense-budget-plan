import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'generic_model.dart';

class AssetCategory extends GenericModel<String> {
  IconData? icon;
  String name;
  bool system = false;
  Map<String, String> localizeNames = {};

  AssetCategory({required super.id, required this.icon, required this.name, bool? system, Map<String, String>? localizeNames}) {
    this.system = system == true;
    if (localizeNames != null) {
      this.localizeNames = localizeNames;
    }
  }

  // Convert a Assets into a Map. The keys must correspond to the names of the columns in the database.
  @override
  Map<String, Object?> toMap() {
    return {
      idFieldName(): id,
      'name': name,
      'icon': icon != null ? Util().iconDataToJSONString(icon!) : "",
      'system': system ? 1 : 0,
      'localize_names': jsonEncode(localizeNames)
    };
  }

  // Implement toString to make it easier to see information about
  // each Assets when using the print statement.
  @override
  String toString() {
    return '{"${idFieldName()}": "$id", "name": "$name", "icon": ${Util().iconDataToJSONString(icon)},"system": $system, "localizeNames": ${jsonEncode(localizeNames)}}';
  }

  factory AssetCategory.fromMap(Map<String, dynamic> json) => AssetCategory(
        id: json['uid'],
        icon: Util().iconDataFromJSONString(json['icon'] as String),
        name: json['name'],
        system: json['system'] == 1,
        localizeNames: Util().fromLocalizeDbField(jsonDecode(json['localize_names'])),
      );

  @override
  String displayText() => name;

  @override
  String idFieldName() => "uid";
}
