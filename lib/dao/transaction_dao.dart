import 'package:income_expense_budget_plan/model/asset_category.dart';
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
}
