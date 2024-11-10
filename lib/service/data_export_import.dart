import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/dao/assets_dao.dart';
import 'package:income_expense_budget_plan/dao/currency_dao.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/transaction.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:sqflite/sqflite.dart';

abstract class DataSink {
  void write(Uint8List data);

  void writeString(String data) {
    // Convert string to Uint8List and add to the stream
    write(Uint8List.fromList(utf8.encode(data)));
  }

  void writeStringLine(String data) => writeString("$data\n");

  Future<void> flush();
}

class StreamDataSink extends DataSink {
  final StreamController<Uint8List> _controller;

  StreamDataSink(this._controller);

  @override
  void write(Uint8List data) {
    _controller.add(data);
  }

  @override
  Future<void> flush() async {
    await _controller.close();
  }
}

class IOSinkDataSink extends DataSink {
  final IOSink _sink;

  IOSinkDataSink(this._sink);

  @override
  void write(Uint8List data) {
    _sink.add(data);
  }

  @override
  Future<void> flush() async {
    await _sink.flush();
  }
}

abstract class DataExport {
  static String autoAppendMissingExtension = 'iebp';
  static List<String> allowedExtensions = [autoAppendMissingExtension, 'txt', 'csv', 'json', 'dat'];
  static String dataVersionKey = "data-version";
  static String currenciesHeaderLine = "=== Currencies ===";
  static String accountCategoriesHeaderLine = "=== Account Categories ===";
  static String accountsHeaderLine = "=== Accounts ===";
  static String transactionCategoriesHeaderLine = "=== Transaction Categories ===";
  static String transactionsHeaderLine = "=== Transactions ===";
  static String endFileFooter = "=== END ===";

  String dataSeparator;
  int version;

  DataExport({required this.version, required this.dataSeparator});

  void initialFileHeader(DataSink file) => file.writeStringLine('$dataVersionKey-$version');
  void initialFileFooter(DataSink file) => file.writeString(endFileFooter);

  void initialCurrencyHeader(DataSink file) => file.writeStringLine(currenciesHeaderLine);
  void initialAccountCategoryHeader(DataSink file) => file.writeStringLine(accountCategoriesHeaderLine);
  void initialAccountHeader(DataSink file) => file.writeStringLine(accountsHeaderLine);
  void initialTransactionHeader(DataSink file) => file.writeStringLine(transactionsHeaderLine);
  void initialTransactionCategoryHeader(DataSink file) => file.writeStringLine(transactionCategoriesHeaderLine);

  String currencyToLineData(Currency currency);

  String accountCategoryToLineData(AssetCategory category);
  String accountToLineData(Asset account);
  String transactionCategoryToLineData(TransactionCategory category);
  String transactionToLineData(Transactions transaction);

  Future<void> writingDataDesktop({
    required File file,
    required List<Currency> currencies,
    required List<AssetCategory> categories,
    required List<Asset> assets,
    required List<TransactionCategory> transactionCategories,
    required List<Transactions> transactions,
    required Function() lineWroteListener,
    required bool Function() isTerminated,
  }) async {
    IOSink outputFileSink = file.openWrite();

    DataSink dataSink = IOSinkDataSink(outputFileSink);
    await writingData(
        dataSink: dataSink,
        currencies: currencies,
        categories: categories,
        assets: assets,
        transactionCategories: transactionCategories,
        transactions: transactions,
        lineWroteListener: lineWroteListener,
        isTerminated: isTerminated);
  }

  Future<Uint8List> writingDataMobile({
    required List<Currency> currencies,
    required List<AssetCategory> categories,
    required List<Asset> assets,
    required List<TransactionCategory> transactionCategories,
    required List<Transactions> transactions,
    required Function() lineWroteListener,
    required bool Function() isTerminated,
  }) async {
    // Create a StreamController for Uint8List
    final StreamController<Uint8List> streamController = StreamController<Uint8List>();

    // Create a Uint8List to hold the data
    final List<int> byteList = [];

    // Listen to the stream
    streamController.stream.listen((data) {
      // Append the incoming data to byteList
      byteList.addAll(data);
    });

    DataSink dataSink = StreamDataSink(streamController);
    await writingData(
        dataSink: dataSink,
        currencies: currencies,
        categories: categories,
        assets: assets,
        transactionCategories: transactionCategories,
        transactions: transactions,
        lineWroteListener: lineWroteListener,
        isTerminated: isTerminated);

    return Uint8List.fromList(byteList);
  }

  Future<void> writingData({
    required DataSink dataSink,
    required List<Currency> currencies,
    required List<AssetCategory> categories,
    required List<Asset> assets,
    required List<TransactionCategory> transactionCategories,
    required List<Transactions> transactions,
    required Function() lineWroteListener,
    required bool Function() isTerminated,
  }) async {
    initialFileHeader(dataSink);

    initialCurrencyHeader(dataSink);
    for (var currency in currencies) {
      dataSink.writeStringLine(currencyToLineData(currency));
      lineWroteListener();
    }

    initialAccountCategoryHeader(dataSink);
    for (var category in categories) {
      dataSink.writeStringLine(accountCategoryToLineData(category));
      lineWroteListener();
    }

    initialAccountHeader(dataSink);
    for (var account in assets) {
      dataSink.writeStringLine(accountToLineData(account));
      lineWroteListener();
    }

    initialTransactionCategoryHeader(dataSink);
    for (var category in transactionCategories) {
      dataSink.writeStringLine(transactionCategoryToLineData(category));
      lineWroteListener();
    }

    initialTransactionHeader(dataSink);
    for (var txn in transactions) {
      dataSink.writeStringLine(transactionToLineData(txn));
      lineWroteListener();
    }

    initialFileFooter(dataSink);

    await dataSink.flush();
  }
}

abstract class DataImport {
  static int dataTypeCurrency = 0;
  static int dataTypeAccountCategory = 1;
  static int dataTypeAccount = 2;
  static int dataTypeTransactionCategory = 3;
  static int dataTypeTransaction = 4;
  String dataSeparator = "|";
  int version;

  DataImport({required this.version, required this.dataSeparator});

  bool checkVersion(String readVersion) {
    if (kDebugMode) {
      print("Read version $readVersion, Service version: ${DataExport.dataVersionKey}-$version");
    }
    return '${DataExport.dataVersionKey}-$version' == readVersion;
  }

  Currency lineToCurrency(String line);
  AssetCategory lineToAccountCategory(String line);
  Asset lineToAccount(String line);
  TransactionCategory lineToTransactionCategory(String line);
  Transactions lineToTransaction(String line);

  Future<void> readFileData(File file) async {
    List<String> lines = file.readAsLinesSync(encoding: utf8);
    if (!checkVersion(lines.first)) {
      throw Exception("Incorrect version");
    }
    int dataRowIndex = 1;
    int currentDataType = -1;
    for (; dataRowIndex < lines.length; dataRowIndex++) {
      var line = lines[dataRowIndex];
      if (line == DataExport.currenciesHeaderLine) {
        currentDataType = DataImport.dataTypeCurrency;
        continue;
      }
      if (line == DataExport.accountCategoriesHeaderLine) {
        currentDataType = DataImport.dataTypeAccountCategory;
        continue;
      }
      if (line == DataExport.accountsHeaderLine) {
        currentDataType = DataImport.dataTypeAccount;
        continue;
      }
      if (line == DataExport.transactionCategoriesHeaderLine) {
        currentDataType = DataImport.dataTypeTransactionCategory;
        continue;
      }
      if (line == DataExport.transactionsHeaderLine) {
        currentDataType = DataImport.dataTypeTransaction;
        continue;
      }
      if (line == DataExport.endFileFooter) {
        break;
      }
      if (currentDataType == DataImport.dataTypeCurrency) {
        Currency currency = lineToCurrency(line);
        CurrencyDao().existById(currency.id!).then((existed) {
          if (!existed) {
            DatabaseService().database.then((db) {
              db.insert(tableNameAsset, currency.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore).then((_) {
                currentAppState.currencies.add(currency);
              });
            });
          }
        });
      } else if (currentDataType == DataImport.dataTypeAccountCategory) {
        AssetCategory category = lineToAccountCategory(line);
        AssetsDao().categoryExistById(category.id!).then((bool existed) {
          if (!existed) {
            DatabaseService().database.then((db) {
              db.insert(tableNameAssetCategory, category.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore).then((_) {
                currentAppState.assetCategories.add(category);
              });
            });
          }
        });
      } else if (currentDataType == DataImport.dataTypeAccount) {
        Asset account = lineToAccount(line);
        AssetsDao().existById(account.id!).then((bool existed) {
          if (!existed) {
            DatabaseService().database.then((db) {
              db.insert(tableNameAsset, account.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore).then((_) {
                currentAppState.assets.add(account);
              });
            });
          }
        });
      } else if (currentDataType == DataImport.dataTypeTransactionCategory) {
        TransactionCategory category = lineToTransactionCategory(line);
        TransactionDao().transactionCategoryById(category.id!).then((TransactionCategory? cat) {
          if (cat == null) {
            DatabaseService().database.then((db) {
              db.insert(tableNameTransactionCategory, category.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
            });
          }
        });
      } else if (currentDataType == DataImport.dataTypeTransaction) {
        Transactions transaction = lineToTransaction(line);
        TransactionDao().transactionById(transaction.id!).then((Transactions? txn) {
          if (txn != null) {
            DatabaseService().database.then((db) {
              db.insert(tableNameTransaction, txn.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
            });
          }
        });
      }
    }
  }
}

class DataExportV1 extends DataExport {
  DataExportV1() : super(version: 1, dataSeparator: "|");

  @override
  String accountCategoryToLineData(AssetCategory category) {
    return '${category.id}$dataSeparator${category.name}$dataSeparator${Util().iconDataToJSONString(category.icon)}$dataSeparator${category.system}$dataSeparator${jsonEncode(category.localizeNames)}'
        '$dataSeparator${category.positionIndex}$dataSeparator${category.lastUpdated.millisecondsSinceEpoch}';
  }

  @override
  String accountToLineData(Asset account) {
    return account.asExportDataLine();
  }

  @override
  String transactionToLineData(Transactions transaction) {
    return transaction.asExportDataLine();
  }

  @override
  String currencyToLineData(Currency currency) {
    return '${currency.id}$dataSeparator${currency.name}$dataSeparator${currency.iso}'
        '$dataSeparator${currency.deleted}$dataSeparator${currency.symbol}$dataSeparator${currency.symbolPosition}$dataSeparator'
        '${currency.mainCurrency}$dataSeparator${currency.show}$dataSeparator${currency.decimalPoint}$dataSeparator${currency.language}';
  }

  @override
  String transactionCategoryToLineData(TransactionCategory category) {
    return '${category.id}$dataSeparator${category.name}$dataSeparator${Util().iconDataToJSONString(category.icon)}$dataSeparator${category.parentUid}$dataSeparator'
        '${category.transactionType.name}$dataSeparator${jsonEncode(category.localizeNames)}$dataSeparator${category.system}$dataSeparator'
        '${category.positionIndex}$dataSeparator${category.lastUpdated.millisecondsSinceEpoch}';
  }
}

class DataImportV1 extends DataImport {
  DataImportV1() : super(version: 1, dataSeparator: "|");

  @override
  Asset lineToAccount(String line) {
    var data = line.split("|");
    var id = data[0];
    var name = data[1];
    IconData icon = Util().iconDataFromJSONString(data[2]);
    String description = data[3];
    int positionIndex = int.tryParse(data[4]) ?? 0;
    DateTime lastUpdated = DateTime.fromMillisecondsSinceEpoch(int.tryParse(data[5]) ?? 0);
    String currencyUid = data[6];
    String categoryUid = data[7];
    Map<String, String> localizeNames = Util().fromLocalizeDbField(Util().customJsonDecode(data[8]));
    Map<String, String> localizeDescriptions = Util().fromLocalizeDbField(Util().customJsonDecode(data[9]));
    double availableAmount = double.tryParse(data[10]) ?? 0.0;
    String assetType = data[11];
    switch (assetType) {
      case "genericAccount":
        return GenericAccount(
            id: id,
            icon: icon,
            name: name,
            index: positionIndex,
            updatedDateTime: lastUpdated,
            localizeNames: localizeNames,
            localizeDescriptions: localizeDescriptions,
            description: description,
            currencyUid: currencyUid,
            categoryUid: categoryUid,
            availableAmount: availableAmount);
      case "bankCasa":
        return BankCasaAccount(
            id: id,
            icon: icon,
            name: name,
            index: positionIndex,
            updatedDateTime: lastUpdated,
            localizeNames: localizeNames,
            localizeDescriptions: localizeDescriptions,
            description: description,
            currencyUid: currencyUid,
            categoryUid: categoryUid,
            availableAmount: availableAmount);
      case "loan":
        double loanAmount = double.tryParse(data[12]) ?? 0;
        return LoanAccount(
            id: id,
            icon: icon,
            name: name,
            index: positionIndex,
            updatedDateTime: lastUpdated,
            localizeNames: localizeNames,
            localizeDescriptions: localizeDescriptions,
            description: description,
            currencyUid: currencyUid,
            categoryUid: categoryUid,
            loanAmount: loanAmount);
      case "eWallet":
        return EWallet(
            id: id,
            icon: icon,
            name: name,
            index: positionIndex,
            updatedDateTime: lastUpdated,
            localizeNames: localizeNames,
            localizeDescriptions: localizeDescriptions,
            description: description,
            currencyUid: currencyUid,
            categoryUid: categoryUid,
            availableAmount: availableAmount);
      case "payLaterAccount":
        double paymentLimit = double.tryParse(data[12]) ?? 0;
        return PayLaterAccount(
            id: id,
            icon: icon,
            name: name,
            index: positionIndex,
            updatedDateTime: lastUpdated,
            localizeNames: localizeNames,
            localizeDescriptions: localizeDescriptions,
            description: description,
            currencyUid: currencyUid,
            categoryUid: categoryUid,
            availableAmount: availableAmount,
            paymentLimit: paymentLimit);
      default:
        double creditLimit = double.tryParse(data[12]) ?? 0;
        return CreditCard(
            id: id,
            icon: icon,
            name: name,
            index: positionIndex,
            updatedDateTime: lastUpdated,
            localizeNames: localizeNames,
            localizeDescriptions: localizeDescriptions,
            description: description,
            currencyUid: currencyUid,
            categoryUid: categoryUid,
            availableAmount: availableAmount,
            creditLimit: creditLimit);
    }
  }

  @override
  AssetCategory lineToAccountCategory(String line) {
    var data = line.split("|");
    String id = data[0];
    String name = data[1];
    IconData icon = Util().iconDataFromJSONString(data[2]);
    bool system = bool.tryParse(data[3]) ?? false;
    Map<String, String> localizeNames = Util().fromLocalizeDbField(Util().customJsonDecode(data[4]));
    int positionIndex = int.tryParse(data[5]) ?? 0;
    DateTime lastUpdated = DateTime.fromMillisecondsSinceEpoch(int.tryParse(data[6]) ?? 0);
    return AssetCategory(
        id: id, icon: icon, name: name, system: system, localizeNames: localizeNames, index: positionIndex, updatedDateTime: lastUpdated);
  }

  @override
  Currency lineToCurrency(String line) {
    var data = line.split("|");
    String id = data[0];
    String name = data[1];
    String iso = data[2];
    bool deleted = bool.tryParse(data[3]) ?? false;
    String symbol = data[4].trim();
    SymbolPosition symbolPosition = SymbolPosition.values.firstWhere((symbol) => symbol.toString() == data[5]);
    return Currency(
        id: id,
        name: name,
        iso: iso,
        deleted: deleted,
        symbol: symbol,
        symbolPosition: symbolPosition,
        mainCurrency: bool.tryParse(data[6]),
        show: bool.tryParse(data[7]),
        decimalPoint: int.tryParse(data[8]),
        language: data[9]);
  }

  @override
  Transactions lineToTransaction(String line) {
    var data = line.split("|");
    String txnType = data[0];
    var id = data[1];
    DateTime transactionDate = DateTime.fromMillisecondsSinceEpoch(int.tryParse(data[2]) ?? 0);
    TimeOfDay transactionTime = Util().minutesToTimeOfDay(int.tryParse(data[3]) ?? 0);
    String? transactionCategoryId = data[4] == 'null' ? null : data[4];
    String description = data[5];
    bool withFee = bool.tryParse(data[6]) ?? false;
    double feeAmount = double.tryParse(data[7]) ?? 0;
    double amount = double.tryParse(data[8]) ?? 0;
    DateTime lastUpdated = DateTime.fromMillisecondsSinceEpoch(int.tryParse(data[9]) ?? 0);
    String currencyUid = data[10];
    bool notIncludeToReport = bool.tryParse(data[11]) ?? false;
    Asset account = currentAppState.retrieveAccount(data[12]) ?? currentAppState.assets[0];
    Transactions txn;
    switch (txnType) {
      case "income":
        txn = IncomeTransaction(
            id: id,
            description: description,
            transactionDate: transactionDate,
            transactionTime: transactionTime,
            transactionCategory: null,
            currencyUid: currencyUid,
            withFee: withFee,
            feeAmount: feeAmount,
            amount: amount,
            updatedDateTime: lastUpdated,
            account: account,
            skipReport: notIncludeToReport);
        break;
      case "expense":
        txn = ExpenseTransaction(
            id: id,
            description: description,
            transactionDate: transactionDate,
            transactionTime: transactionTime,
            transactionCategory: null,
            currencyUid: currencyUid,
            withFee: withFee,
            feeAmount: feeAmount,
            amount: amount,
            updatedDateTime: lastUpdated,
            account: account,
            skipReport: notIncludeToReport);
        break;
      case "transfer":
        Asset toAccount = currentAppState.retrieveAccount(data[13]) ?? currentAppState.assets[0];
        bool feeApplyToFromAccount = bool.tryParse(data[14]) ?? false;
        txn = TransferTransaction(
            id: id,
            description: description,
            transactionDate: transactionDate,
            transactionTime: transactionTime,
            transactionCategory: null,
            currencyUid: currencyUid,
            withFee: withFee,
            feeAmount: feeAmount,
            amount: amount,
            updatedDateTime: lastUpdated,
            account: account,
            skipReport: notIncludeToReport,
            toAccount: toAccount,
            feeApplyTo: feeApplyToFromAccount);
        break;
      case "lend":
        txn = LendTransaction(
            id: id,
            description: description,
            transactionDate: transactionDate,
            transactionTime: transactionTime,
            transactionCategory: null,
            currencyUid: currencyUid,
            withFee: withFee,
            feeAmount: feeAmount,
            amount: amount,
            updatedDateTime: lastUpdated,
            account: account,
            skipReport: notIncludeToReport);
        break;
      case "borrowing":
        txn = BorrowingTransaction(
            id: id,
            description: description,
            transactionDate: transactionDate,
            transactionTime: transactionTime,
            transactionCategory: null,
            currencyUid: currencyUid,
            withFee: withFee,
            feeAmount: feeAmount,
            amount: amount,
            updatedDateTime: lastUpdated,
            account: account,
            skipReport: notIncludeToReport);
        break;
      case "adjustment":
        double adjustedAmount = double.tryParse(data[13]) ?? 0;
        txn = AdjustmentTransaction(
            id: id,
            description: description,
            transactionDate: transactionDate,
            transactionTime: transactionTime,
            transactionCategory: null,
            currencyUid: currencyUid,
            withFee: withFee,
            feeAmount: feeAmount,
            amount: amount,
            updatedDateTime: lastUpdated,
            account: account,
            skipReport: notIncludeToReport,
            adjustedAmount: adjustedAmount);
        break;
      case "shareBill":
        double mySplit = double.tryParse(data[13]) ?? 0;
        double remainingAmount = double.tryParse(data[14]) ?? 0;
        txn = ShareBillTransaction(
            id: id,
            description: description,
            transactionDate: transactionDate,
            transactionTime: transactionTime,
            transactionCategory: null,
            currencyUid: currencyUid,
            withFee: withFee,
            feeAmount: feeAmount,
            amount: amount,
            updatedDateTime: lastUpdated,
            account: account,
            skipReport: notIncludeToReport,
            mySplit: mySplit,
            remaining: remainingAmount);
        break;
      default:
        String? sharedBillId = data[13] == 'null' ? null : data[13];
        ShareBillReturnTransaction tmp = ShareBillReturnTransaction(
          id: id,
          description: description,
          transactionDate: transactionDate,
          transactionTime: transactionTime,
          transactionCategory: null,
          currencyUid: currencyUid,
          withFee: withFee,
          feeAmount: feeAmount,
          amount: amount,
          updatedDateTime: lastUpdated,
          account: account,
          skipReport: notIncludeToReport,
        );
        txn = tmp;
        if (sharedBillId != null) {
          TransactionDao().transactionById(sharedBillId).then((txn) {
            if (txn != null) {
              if (txn is ShareBillTransaction) {
                tmp.sharedBill = txn;
              } else {
                if (kDebugMode) {
                  print('Transaction with ID [$sharedBillId] is not a share bill.');
                }
              }
            } else {
              if (kDebugMode) {
                print("Cannot find share bill for ID [$sharedBillId]");
              }
            }
          });
        }
        break;
    }
    if (transactionCategoryId != null) {
      TransactionDao().transactionCategoryById(transactionCategoryId).then((category) => txn.transactionCategory = category);
    }
    return txn;
  }

  @override
  TransactionCategory lineToTransactionCategory(String line) {
    var data = line.split("|");
    String id = data[0];
    String name = data[1];
    IconData icon = Util().iconDataFromJSONString(data[2]);
    String? parentUid = data[3] == 'null' ? null : data[3];
    TransactionType transactionType = TransactionType.values.firstWhere((txnType) => txnType.toString().split('.').last == data[4]);
    Map<String, String> localizeNames = Util().fromLocalizeDbField(Util().customJsonDecode(data[5]));
    bool system = bool.tryParse(data[6]) ?? false;
    int positionIndex = int.tryParse(data[7]) ?? 0;
    DateTime lastUpdated = DateTime.fromMillisecondsSinceEpoch(int.tryParse(data[8]) ?? 0);
    return TransactionCategory(
      id: id,
      icon: icon,
      name: name,
      parentUid: parentUid,
      transactionType: transactionType,
      system: system,
      localizeNames: localizeNames,
      index: positionIndex,
      updatedDateTime: lastUpdated,
    );
  }
}
