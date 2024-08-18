import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

late Database database;

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _databaseService = DatabaseService._internal();
  factory DatabaseService() => _databaseService;
  DatabaseService._internal();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Initialize the DB first time it is accessed
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI
    sqfliteFfiInit();

    databaseFactory = databaseFactoryFfi;

    final databasePath = await getDatabasesPath();

    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    final path = join(databasePath, databaseNameMain);
    if (kDebugMode) {
      print("Opening database $path...");
    }
    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    return openDatabase(path,
        onCreate: _onCreate,
        version: databaseVersion,
        singleInstance: true,
        onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
        onOpen: _onOpen,
        onUpgrade: _onUpgrade);
  }

  Future<void> _executeSqlFile(Database db, String sqlFilePath) async {
    var sqlContent = await rootBundle.loadString(sqlFilePath);
    List<String> sqlStatements = sqlContent.split(';');
    // Execute each statement
    for (String statement in sqlStatements) {
      if (statement.trim().isNotEmpty) {
        var execution = db.execute(statement);
        if (kDebugMode) {
          print("SQL $statement...");
        }
        await execution;
      }
    }
  }

  // When the database is first created
  Future<void> _onCreate(Database db, int version) async {
    _executeSqlFile(db, 'assets/db_init.sql');
  }

  Future<void> _onOpen(Database db) async {
    if (kDebugMode) {
      print("Opening database successful.");
    }
    _executeSqlFile(db, 'assets/db_validate_and_correct.sql');
  }

  // When the database version increased
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _executeSqlFile(db, 'assets/db_upgrade.sql');
  }

  Future<List<T>> loadListModel<T>(String tableName, T Function(Map<String, dynamic> data) convert) async {
    var db = await database;
    // Query the table for all the dogs.
    final List<Map<String, Object?>> dataMap = await db.query(tableName);

    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [for (Map<String, Object?> record in dataMap) convert(record)];
  }

  void deleteItemByField(BuildContext context, String tableName, String fieldName, dynamic fieldValue, Function(String) successLocalize,
      Function(String) errorLocalize,
      {String Function()? retrieveItemDisplay,
      Function? onComplete,
      Function? onSuccess,
      Function? onError,
      bool? navigateBackWhenSuccess,
      bool? navigateBackWhenError}) {
    Function? closeSuccessCallback;
    if (navigateBackWhenSuccess == true) {
      closeSuccessCallback = () => Navigator.of(context).pop();
    }
    Function? closeErrorCallback;
    if (navigateBackWhenError == true) {
      closeErrorCallback = () => Navigator.of(context).pop();
    }
    database.then((db) {
      db.delete(tableName, where: '$fieldName = ?', whereArgs: [fieldValue]).then((deletedCount) {
        if (onComplete != null) onComplete();
        if (kDebugMode) {
          print("Deleted $deletedCount records in table $tableName");
        }
        if (retrieveItemDisplay != null) {
          if (deletedCount <= 0) {
            Util().showErrorDialog(context, errorLocalize(retrieveItemDisplay()), closeSuccessCallback);
          } else {
            Util().showSuccessDialog(context, successLocalize(retrieveItemDisplay()), closeErrorCallback);
          }
        }
        if (onSuccess != null) onSuccess();
      }, onError: (e, f) {
        throw e;
      }).catchError((e, f) {
        if (onComplete != null) onComplete();
        if (retrieveItemDisplay != null) {
          Util().showErrorDialog(context, errorLocalize(retrieveItemDisplay()), closeErrorCallback);
        }
        if (onError != null) onError(e, f);
      });
    });
  }
}
