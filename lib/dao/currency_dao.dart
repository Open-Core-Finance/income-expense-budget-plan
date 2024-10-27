import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';

class CurrencyDao {
  final DatabaseService databaseService = DatabaseService();

  Future<bool> existById(String assetId) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> records = await db.query(tableNameCurrency, where: 'uid = ?', whereArgs: [assetId]);
    return (records.isNotEmpty);
  }
}
