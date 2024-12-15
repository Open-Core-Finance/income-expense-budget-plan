import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:income_expense_budget_plan/model/debug_log.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

late Database database;

class DatabaseService {
  static final int statementPrintMaxLength = 10;
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
    String databasePrefix = (await resolvePossibleDatabaseFolder()).absolute.path;

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
    return _callOpenDatabase().catchError((_) {
      databasePath = databaseNameMain;
      return _callOpenDatabase();
    });
  }

  Future<Database> _callOpenDatabase() => openDatabase(databasePath,
      onCreate: _onCreate,
      version: databaseVersion,
      singleInstance: true,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onOpen: _onOpen,
      onUpgrade: _onUpgrade,
      onDowngrade: _onDowngrade);

  Future<Directory> resolvePossibleDatabaseFolder() {
    if (Platform.isIOS || Platform.isMacOS) {
      return getLibraryDirectory().catchError((e) => _resolveGenericDatabasePath());
    }
    return _resolveGenericDatabasePath();
  }

  Future<Directory> _resolveGenericDatabasePath() {
    return getApplicationSupportDirectory().catchError(
        (e) => getApplicationDocumentsDirectory().catchError((e2) => getApplicationCacheDirectory().catchError((e2) => Directory.current)));
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
            print("Executed SQL [${_substringForPrint(statementTrim, statementPrintMaxLength)}]!");
          } else {
            print("Executed SQL Trigger!");
          }
        }
      } catch (e) {
        if (kDebugMode) {
          if (statementSuffix == ";") {
            print("Executed SQL [${_substringForPrint(statementTrim, statementPrintMaxLength)}] fail! $e");
          } else {
            print("Executed SQL Trigger fail! [${_substringForPrint(statementTrim, statementPrintMaxLength)}]! $e");
          }
        }
        return {execMapSuccessKey: false, execMapErrDetailsKey: e};
      }
    }
    return null;
  }

  String _substringForPrint(String statement, int maxLength) {
    if (statement.length <= maxLength || maxLength <= 1) {
      return statement;
    }
    return "${statement.substring(0, maxLength)}...";
  }

  // When the database is first created
  Future<void> _onCreate(Database db, int version) async {
    if (kDebugMode) {
      print("Creating database with version $version...");
    }

    // Initialize the completer
    _onCreateCompleter = Completer<void>();

    await _executeSqlFileBundle(db, 'assets/db_init.sql').catchError((e) => {execMapSuccessKey: false, execMapErrDetailsKey: e});

    // Complete the completer once the onCreate is done
    _onCreateCompleter?.complete();

    await _executeSqlFileBundle(db, 'assets/db_clean_triggers.sql');
    _executeTriggersSqlFileBundle(db, 'assets/db_create_triggers.sql');
  }

  Future<void> _onOpen(Database db) async {
    await _executeSqlFileBundle(db, 'assets/db_clean_triggers.sql');
    await _executeSqlFileBundle(db, 'assets/db_validate_and_correct.sql');
    await _executeTriggersSqlFileBundle(db, 'assets/db_create_triggers.sql');
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
    await _executeSqlFileBundle(db, 'assets/db_upgrade_all.sql');
    if (oldVersion < 2) {
      await _executeSqlFileBundle(db, 'assets/db_upgrade_2.sql');
    }
    if (oldVersion < 3) {
      await _executeSqlFileBundle(db, 'assets/db_upgrade_3.sql');
    }
    if (oldVersion < 4) {
      await _executeSqlFileBundle(db, 'assets/db_upgrade_4.sql');
    }
    // add more version specific sql like 5, 6, 7...
    await _executeTriggersSqlFileBundle(db, 'assets/db_create_triggers.sql');
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
      bool? navigateBackWhenError,
      Future<int> Function(Database db, String tableName, String fieldName, dynamic fieldValue)? customDeleteAction}) async {
    Function? closeSuccessCallback;
    if (navigateBackWhenSuccess == true) {
      closeSuccessCallback = () => Navigator.of(context).pop();
    }
    Function? closeErrorCallback;
    if (navigateBackWhenError == true) {
      closeErrorCallback = () => Navigator.of(context).pop();
    }
    var db = await database;

    Future<int> deleteFuture;
    if (customDeleteAction != null) {
      deleteFuture = customDeleteAction(db, tableName, fieldName, fieldValue);
    } else {
      deleteFuture = db.delete(tableName, where: '$fieldName = ?', whereArgs: [fieldValue]);
    }
    deleteFuture.then((deletedCount) async {
      if (onComplete != null) onComplete();
      if (kDebugMode) {
        print("Deleted $deletedCount records in table $tableName");
      }
      if (retrieveItemDisplay != null && context.mounted) {
        if (deletedCount <= 0) {
          await Util().showErrorDialog(context, errorLocalize(retrieveItemDisplay()), closeSuccessCallback);
        } else {
          await Util().showSuccessDialog(context, successLocalize(retrieveItemDisplay()), closeErrorCallback);
        }
      }
      if (onSuccess != null) onSuccess();
    }).catchError((e, f) {
      if (onComplete != null) onComplete();
      if (retrieveItemDisplay != null && context.mounted) {
        Util().showErrorDialog(context, errorLocalize(retrieveItemDisplay()), closeErrorCallback).then((_) {
          if (onError != null) onError(e, f);
        });
      }
    });
  }

  FutureOr<int> recordCodingError(dynamic e, String functionName, Function(Exception e)? callback) async {
    if (kDebugMode) {
      print("Saving error $e");
    }
    DebugLog debugLog = DebugLog(
      id: null,
      funcName: functionName,
      funcType: DebugLogFuncType.coding,
      logLevel: DebugLogLevel.error,
      message: '$e',
      createdAt: DateTime.now(),
    );
    database.then((db) => db.insert(tableNameDebugLog, debugLog.toMap(), conflictAlgorithm: ConflictAlgorithm.replace));
    if (callback != null) callback(e);
    return 0;
  }

  // When the database version increased
  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print("Downgrading database version from $oldVersion to $newVersion...");
    }
    await _executeSqlFileBundle(db, 'assets/db_clean_triggers.sql');

    // add more version specific sql like 7, 6, 5...
    if (oldVersion >= 4) {
      await _executeSqlFileBundle(db, 'assets/db_downgrade_4.sql');
    }
    if (oldVersion >= 3) {
      await _executeSqlFileBundle(db, 'assets/db_downgrade_3.sql');
    }
    await _executeSqlFileBundle(db, 'assets/db_downgrade_all.sql');
    await _executeTriggersSqlFileBundle(db, 'assets/db_create_triggers.sql');
  }
}
