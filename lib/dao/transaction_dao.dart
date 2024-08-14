import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';

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
    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [for (Map<String, Object?> record in result) TransactionCategory.fromMap(record)];
  }

  Future<List<Map<String, dynamic>>> loadCategoryByTransactionTypeAndName(TransactionType transactionType, String name) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> result = await db.query(
      tableNameTransactionCategory,
      where: 'transaction_type = ? and name = ?',
      whereArgs: [transactionType.name, name],
    );
    return result;
  }
}
