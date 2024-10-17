import 'package:flutter/foundation.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/transaction.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';

import '../service/util.dart';

class TransactionDao {
  final DatabaseService databaseService = DatabaseService();
  TransactionDao();

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

  Future<List<Map<String, dynamic>>> loadCategoryByTransactionTypeAndNameAndIgnoreSpecificCategory(
      TransactionType transactionType, String name, String? uuidToIgnore) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> result = await db.query(tableNameTransactionCategory,
        where: 'transaction_type = ? and name = ?${uuidToIgnore != null ? ' and uid != ?' : ''}',
        whereArgs: uuidToIgnore != null ? [transactionType.name, name, uuidToIgnore] : [transactionType.name, name]);
    return result;
  }

  Future<List<Transactions>> transactionsByYearAndMonth(int year, int month) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> records =
        await db.query(tableNameTransaction, where: 'year_month = ?', whereArgs: [year * 12 + month], orderBy: 'transaction_date DESC');
    return [for (Map<String, Object?> record in records) await _transactionFromDb(record)];
  }

  Future<Transactions> _transactionFromDb(Map<String, Object?> record) async {
    String txnType = record['transaction_type']! as String;
    if (kDebugMode) {
      print("Transaction: $record => ${DateTime.fromMillisecondsSinceEpoch(record['transaction_date'] as int)}");
    }
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
}
