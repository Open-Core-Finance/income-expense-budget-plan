import 'dart:core';

import 'package:income_expense_budget_plan/model/generic_model.dart';

class DebugLog extends GenericModel<int> {
  static int funcTypeSqlTrigger = 0;
  static int funcTypeCoding = 1;
  static int logLevelDebug = 0;
  static int logLevelInfo = 1;
  static int logLevelError = 2;

  String funcName;
  DebugLogFuncType funcType;
  DebugLogLevel logLevel;
  String message;
  late DateTime createdAt;

  DebugLog(
      {required super.id,
      required this.funcName,
      required this.funcType,
      required this.logLevel,
      required this.message,
      required this.createdAt});

  @override
  String displayText() => message;

  @override
  String idFieldName() => "id";

  @override
  Map<String, Object?> toMap() {
    Map<String, Object?> result = {
      'func_name': funcName,
      'func_type': funcTypeToInt(),
      'log_level': logLevelToInt(),
      'message': message,
      'created_at': createdAt.millisecondsSinceEpoch
    };
    if (id != null) {
      result[idFieldName()] = id;
    }
    return result;
  }

  int logLevelToInt() {
    if (logLevel == DebugLogLevel.debug) {
      return logLevelDebug;
    } else if (logLevel == DebugLogLevel.info) {
      return logLevelInfo;
    } else {
      return logLevelError;
    }
  }

  static DebugLogLevel intToLogLevel(int val) {
    if (val == logLevelDebug) {
      return DebugLogLevel.debug;
    } else if (val == logLevelError) {
      return DebugLogLevel.error;
    } else {
      return DebugLogLevel.info;
    }
  }

  int funcTypeToInt() {
    if (funcType == DebugLogFuncType.coding) {
      return funcTypeCoding;
    } else {
      return funcTypeSqlTrigger;
    }
  }

  static DebugLogFuncType intToFuncType(int val) {
    if (val == funcTypeSqlTrigger) {
      return DebugLogFuncType.sqlTrigger;
    } else {
      return DebugLogFuncType.coding;
    }
  }

  // Implement toString to make it easier to see information about
  // each Asset when using the print statement.
  @override
  String toString() {
    return '{"${idFieldName()}": "$id", "funcName": "$funcName", "funcType": $funcType,"logLevel": ${logLevel.name}, "message": "$message", '
        '"createdAt": "${createdAt.toIso8601String()}"}';
  }

  factory DebugLog.fromMap(Map<String, dynamic> json) => DebugLog(
        id: json['id'],
        funcName: json['func_name'],
        funcType: intToFuncType(json['funcType']),
        logLevel: intToLogLevel(json['logLevel']),
        message: json['message'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DebugLog && other.id == id;
  }

  @override
  int get hashCode => id ?? 0;
}

enum DebugLogLevel { debug, info, error }

enum DebugLogFuncType { sqlTrigger, coding }
