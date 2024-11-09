import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/model/transaction.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:intl/intl.dart';

import '../service/util.dart';

class TransactionDao {
  final DatabaseService databaseService = DatabaseService();
  // Singleton pattern
  static final TransactionDao _dao = TransactionDao._internal();
  factory TransactionDao() => _dao;
  TransactionDao._internal();

  Future<List<TransactionCategory>> transactionCategoryByType(TransactionType transactionType) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> result = await db.query(
      tableNameTransactionCategory,
      where: 'transaction_type = ?',
      whereArgs: [transactionType.name],
    );
    List<TransactionCategory> resultObjectList = [for (Map<String, Object?> record in result) TransactionCategory.fromMap(record)];
    resultObjectList = Util().buildTransactionCategoryTree(resultObjectList);
    currentAppState.categoriesMap[transactionType] = resultObjectList;
    return resultObjectList;
  }

  Future<List<TransactionCategory>> transactionCategories() async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> result = await db.query(tableNameTransactionCategory);
    List<TransactionCategory> resultObjectList = [for (Map<String, Object?> record in result) TransactionCategory.fromMap(record)];
    resultObjectList = Util().buildTransactionCategoryTree(resultObjectList);
    for (var cat in resultObjectList) {
      List<TransactionCategory>? list = currentAppState.categoriesMap[cat.transactionType];
      if (list == null) {
        list = [cat];
        currentAppState.categoriesMap[cat.transactionType] = list;
      } else {
        list.add(cat);
      }
    }
    return resultObjectList;
  }

  Future<List<Map<String, dynamic>>> loadCategoryByTransactionTypeAndNameAndIgnoreSpecificCategory(
      TransactionType transactionType, String name, String? uuidToIgnore) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> result = await db.query(tableNameTransactionCategory,
        where: 'transaction_type = ? and name = ?${uuidToIgnore != null ? ' and uid != ?' : ''}',
        whereArgs: uuidToIgnore != null ? [transactionType.name, name, uuidToIgnore] : [transactionType.name, name]);
    return result;
  }

  Future<List<Transactions>> transactionsByYearAndMonth(int year, int month) async {
    if (kDebugMode) {
      print("Loading transaction by year and month...");
    }
    final db = await databaseService.database;
    List<Map<String, dynamic>> records =
        await db.query(tableNameTransaction, where: 'year_month = ?', whereArgs: [year * 12 + month], orderBy: 'transaction_date DESC');
    return [for (Map<String, Object?> record in records) await _transactionFromDb(record)];
  }

  Future<Transactions> _transactionFromDb(Map<String, Object?> record) async {
    String txnType = record['transaction_type']! as String;
    switch (txnType) {
      case "income":
        return IncomeTransaction.fromMap(record);
      case "expense":
        return ExpenseTransaction.fromMap(record);
      case "transfer":
        return TransferTransaction.fromMap(record);
      case "lend":
        return LendTransaction.fromMap(record);
      case "borrowing":
        return BorrowingTransaction.fromMap(record);
      case "adjustment":
        return AdjustmentTransaction.fromMap(record);
      case "shareBill":
        return ShareBillTransaction.fromMap(record);
      default:
        String? sharedBillId = record['shared_bill_id'] as String?;
        ShareBillTransaction? sharedBill;
        if (sharedBillId != null) {
          sharedBill = (await transactionById(sharedBillId)) as ShareBillTransaction?;
        }
        return ShareBillReturnTransaction.fromMap(record, sharedBill);
    }
  }

  Future<Transactions?> transactionById(String id) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> records =
        await db.query(tableNameTransaction, where: 'id = ?', whereArgs: [id], orderBy: 'transaction_date DESC');
    if (records.isNotEmpty) {
      return _transactionFromDb(records.first);
    }
    return null;
  }

  Future<List<ShareBillTransaction>> inCompleteSharedBills() async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> records = await db.query(tableNameTransaction,
        where: 'transaction_type = ? AND remaining_amount > 0', whereArgs: ['shareBill'], orderBy: 'transaction_date DESC');
    return [for (Map<String, Object?> record in records) ShareBillTransaction.fromMap(record)];
  }

  Future<List<Transactions>> transactionsFromDateRange(DateTimeRange range) async {
    if (kDebugMode) {
      print("Loading transaction by date range...");
    }
    var dateFormat = DateFormat("yyyy-MM-dd");
    final db = await databaseService.database;
    List<Map<String, dynamic>> records = await db.query(tableNameTransaction,
        where: "datetime(transaction_date / 1000, 'unixepoch') >= ? AND datetime(transaction_date / 1000, 'unixepoch') <= ?",
        whereArgs: ['${dateFormat.format(range.start)} 00:00:00', '${dateFormat.format(range.end)} 23:59:59'],
        orderBy: 'transaction_date ASC');
    return [for (Map<String, Object?> record in records) await _transactionFromDb(record)];
  }

  Future<TransactionCategory?> transactionCategoryById(String id) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> records =
        await db.query(tableNameTransactionCategory, where: 'uid = ?', whereArgs: [id], orderBy: 'last_updated DESC');
    if (records.isNotEmpty) {
      return TransactionCategory.fromMap(records.first);
    }
    return null;
  }
}
