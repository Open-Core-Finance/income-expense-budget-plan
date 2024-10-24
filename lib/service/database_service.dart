import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

late Database database;

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _databaseService = DatabaseService._internal();
  factory DatabaseService() => _databaseService;
  DatabaseService._internal();

  static Completer<void>? _onCreateCompleter;
  Future<void>? get onCreateComplete => _onCreateCompleter?.future;

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Initialize the DB first time it is accessed
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    databaseFactory = databaseFactoryFfi;
    // final databasePath = await getDatabasesPath();
    final String databasePath = (await getApplicationSupportDirectory()).absolute.path;

    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    final path = join(databasePath, databaseNameMain);

    // Initialize FFI
    sqfliteFfiInit();

    if (kDebugMode) {
      print("Opening database $path...");
    }

    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    return openDatabase(
      path,
      onCreate: _onCreate,
      version: databaseVersion,
      singleInstance: true,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onOpen: _onOpen,
      onUpgrade: _onUpgrade,
    );
  }

  Future<bool> _executeSqlFileBundle(Database db, String sqlFilePath) async {
    var sqlContent = await rootBundle.loadString(sqlFilePath);
    return _executeSqlContent(db, sqlContent);
  }

  Future<bool> _executeSqlContent(Database db, String sqlContent) async {
    List<String> sqlStatements = sqlContent.split(';');
    // Execute each statement
    for (String statement in sqlStatements) {
      if (statement.trim().isNotEmpty) {
        try {
          var execution = db.execute(statement);
          if (kDebugMode) {
            print("SQL $statement...");
          }
          await execution;
        } catch (e) {
          if (kDebugMode) {
            print("SQL $statement executed fail! $e");
          }
          return false;
        }
      }
    }
    return true;
  }

  Future<bool> _executeTriggersSqlFileBundle(Database db, String sqlFilePath) async {
    var sqlContent = await rootBundle.loadString(sqlFilePath);
    return _executeTriggersSqlContent(db, sqlContent);
  }

  Future<bool> _executeTriggersSqlContent(Database db, String sqlContent) async {
    List<String> triggerStatements = sqlContent.split('END;');
    // Execute each statement
    for (String statement in triggerStatements) {
      if (statement.trim().isNotEmpty) {
        try {
          var execution = db.execute("$statement\nEND;");
          if (kDebugMode) {
            print("SQL $statement...");
          }
          await execution;
        } catch (e) {
          if (kDebugMode) {
            print("SQL $statement trigger fail! $e");
          }
          return false;
        }
      }
    }
    return true;
  }

  Future<bool> executeSqlContent(String sqlContent) async {
    return _executeSqlContent(await database, sqlContent);
  }

  Future<bool> executeTriggersSqlFile(String sqlContent) async {
    return _executeTriggersSqlContent(await database, sqlContent);
  }

  // When the database is first created
  Future<void> _onCreate(Database db, int version) async {
    // Initialize the completer
    _onCreateCompleter = Completer<void>();

    await _executeSqlFileBundle(db, 'assets/db_init.sql');
    // Complete the completer once the onCreate is done
    _onCreateCompleter?.complete();

    _executeTriggersSqlFileBundle(db, 'assets/db_create_triggers.sql');
  }

  Future<void> _onOpen(Database db) async {
    if (kDebugMode) {
      print("Opening database successful.");
    }
    _executeSqlFileBundle(db, 'assets/db_validate_and_correct.sql');
  }

  // When the database version increased
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _executeSqlFileBundle(db, 'assets/db_upgrade.sql');
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
