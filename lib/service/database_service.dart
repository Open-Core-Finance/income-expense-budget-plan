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
  static final String execMapSuccessKey = "success";
  static final String execMapErrDetailsKey = "errDetails";
  // Singleton pattern
  static final DatabaseService _databaseService = DatabaseService._internal();
  factory DatabaseService() => _databaseService;
  DatabaseService._internal();

  static Completer<void>? _onCreateCompleter;
  Future<void>? get onCreateComplete => _onCreateCompleter?.future;

  late String databasePath;
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
    String databasePrefix = (await getApplicationSupportDirectory()).absolute.path;

    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    databasePath = join(databasePrefix, databaseNameMain);

    // Initialize FFI
    sqfliteFfiInit();

    if (kDebugMode) {
      print("Opening database $databasePath...");
    }

    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    return openDatabase(
      databasePath,
      onCreate: _onCreate,
      version: databaseVersion,
      singleInstance: true,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onOpen: _onOpen,
      onUpgrade: _onUpgrade,
    );
  }

  // Internal file execution call
  Future<Map<String, dynamic>> _executeSqlFileBundle(Database db, String sqlFilePath) async {
    if (kDebugMode) {
      print('Executed SQL file "$sqlFilePath"!!');
    }
    return _executeSqlContent(db, await rootBundle.loadString(sqlFilePath));
  }

  Future<Map<String, dynamic>> _executeTriggersSqlFileBundle(Database db, String sqlFilePath) async {
    if (kDebugMode) {
      print('Executed SQL Trigger file "$sqlFilePath"!!');
    }
    return _executeTriggersSqlContent(db, await rootBundle.loadString(sqlFilePath));
  }

  // Internal execution call
  Future<Map<String, dynamic>> _executeSqlContent(Database db, String sqlContent) async =>
      _executeStatements(db, sqlContent.split(';'), ";");
  Future<Map<String, dynamic>> _executeTriggersSqlContent(Database db, String sqlContent) async =>
      _executeStatements(db, sqlContent.split('END;'), "\nEND;");

  // External execution call
  Future<Map<String, dynamic>> executeSqlContent(String sqlContent) async => _executeSqlContent(await database, sqlContent);
  Future<Map<String, dynamic>> executeTriggersSqlFile(String sqlContent) async => _executeTriggersSqlContent(await database, sqlContent);

  // Common full content execution logic
  Future<Map<String, dynamic>> _executeStatements(Database db, List<String> statements, String statementSuffix) async {
    Map<String, dynamic> resultMap = {};
    // Execute each statement
    for (String statement in statements) {
      var statementResult = await _executeSingleStatement(db, statement, statementSuffix);
      if (statementResult != null) {
        return statementResult;
      }
    }
    resultMap[execMapSuccessKey] = true;
    return resultMap;
  }

  // Single statement execution logic
  Future<Map<String, dynamic>?> _executeSingleStatement(Database db, String statement, String statementSuffix) async {
    var statementTrim = statement.trim();
    if (statementTrim.isNotEmpty) {
      try {
        var execution = db.execute("$statementTrim$statementSuffix");
        await execution;
        if (kDebugMode) {
          if (statementSuffix == ";") {
            print("Executed SQL [$statementTrim]!");
          } else {
            print("Executed SQL Trigger!");
          }
        }
      } catch (e) {
        if (kDebugMode) {
          if (statementSuffix == ";") {
            print("SQL [$statementTrim] trigger fail! $e");
          } else {
            print("Executed SQL Trigger fail!!");
          }
        }
        return {execMapSuccessKey: false, execMapErrDetailsKey: e};
      }
    }
    return null;
  }

  // When the database is first created
  Future<void> _onCreate(Database db, int version) async {
    if (kDebugMode) {
      print("Creating database with version $version...");
    }

    // Initialize the completer
    _onCreateCompleter = Completer<void>();

    await _executeSqlFileBundle(db, 'assets/db_init.sql');
    // Complete the completer once the onCreate is done
    _onCreateCompleter?.complete();

    await _executeSqlFileBundle(db, 'assets/db_clean_triggers.sql');
    _executeTriggersSqlFileBundle(db, 'assets/db_create_triggers.sql');
  }

  Future<void> _onOpen(Database db) async {
    await _executeSqlFileBundle(db, 'assets/db_clean_triggers.sql');
    await _executeTriggersSqlFileBundle(db, 'assets/db_create_triggers.sql');
    await _executeSqlFileBundle(db, 'assets/db_validate_and_correct.sql');
    if (kDebugMode) {
      print("Opening database successful. Current version $databaseVersion");
    }
  }

  // When the database version increased
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print("Upgrading database version from $oldVersion to $newVersion...");
    }
    await _executeSqlFileBundle(db, 'assets/db_clean_triggers.sql');
    await _executeTriggersSqlFileBundle(db, 'assets/db_create_triggers.sql');
    await _executeSqlFileBundle(db, 'assets/db_upgrade_all.sql');
    if (oldVersion < 2) {
      await _executeSqlFileBundle(db, 'assets/db_upgrade_2.sql');
    }
    // if (oldVersion < 3) {
    //   _executeSqlFileBundle(db, 'assets/db_upgrade_3.sql');
    // }
    // add more version specific sql
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
        if (retrieveItemDisplay != null && context.mounted) {
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
        if (retrieveItemDisplay != null && context.mounted) {
          Util().showErrorDialog(context, errorLocalize(retrieveItemDisplay()), closeErrorCallback);
        }
        if (onError != null) onError(e, f);
      });
    });
  }
}
