import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';

class AssetsDao {
  final DatabaseService databaseService = DatabaseService();
  AssetsDao();

  Future<List<AssetCategory>> assetsCategories() async {
    return databaseService.loadListModel(tableNameAssetsCategory, AssetCategory.fromMap);
  }

  Future<List<Map<String, dynamic>>> loadCategoryByNameAndIgnoreSpecificCategory(String name, String? uuidToIgnore) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> result = await db.query(
      tableNameAssetsCategory,
      where: 'name = ?${uuidToIgnore != null ? ' and uid != ?' : ''}',
      whereArgs: uuidToIgnore != null ? [name, uuidToIgnore] : [name],
    );
    return result;
  }
}
