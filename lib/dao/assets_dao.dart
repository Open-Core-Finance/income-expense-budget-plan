import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';

class AssetsDao {
  final DatabaseService databaseService = DatabaseService();
  AssetsDao();

  Future<List<AssetCategory>> assetCategories() async {
    return databaseService.loadListModel(tableNameAssetCategory, AssetCategory.fromMap);
  }

  Future<List<Map<String, dynamic>>> loadCategoryByNameAndIgnoreSpecificCategory(String name, String? uuidToIgnore) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> result = await db.query(
      tableNameAssetCategory,
      where: 'name = ?${uuidToIgnore != null ? ' and uid != ?' : ''}',
      whereArgs: uuidToIgnore != null ? [name, uuidToIgnore] : [name],
    );
    return result;
  }

  Future<List<Asset>> assets() async {
    return databaseService.loadListModel(tableNameAsset, (Map<String, Object?> record) {
      String assetType = record['asset_type']! as String;
      switch (assetType) {
        case "cash":
          return CashAccount.fromMap(record);
        case "bankCasa":
          return BankCasaAccount.fromMap(record);
        case "loan":
          return LoanAccount.fromMap(record);
        case "termDeposit":
          return TermDepositAccount.fromMap(record);
        case "eWallet":
          return EWallet.fromMap(record);
        default:
          return CreditCard.fromMap(record);
      }
    });
  }

  Future<List<Map<String, dynamic>>> loadAssetsByNameAndIgnoreSpecificCategory(String name, String? uuidToIgnore) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> result = await db.query(
      tableNameAsset,
      where: 'name = ?${uuidToIgnore != null ? ' and uid != ?' : ''}',
      whereArgs: uuidToIgnore != null ? [name, uuidToIgnore] : [name],
    );
    return result;
  }
}
