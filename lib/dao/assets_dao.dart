import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';

class AssetsDao {
  final DatabaseService databaseService = DatabaseService();

  // Singleton pattern
  static final AssetsDao _dao = AssetsDao._internal();
  factory AssetsDao() => _dao;
  AssetsDao._internal();

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
    return databaseService.loadListModel(tableNameAsset, (Map<String, Object?> record) => assetFromJson(record));
  }

  Asset assetFromJson(Map<String, Object?> record) {
    String assetType = record['asset_type']! as String;
    switch (assetType) {
      case "genericAccount":
        return GenericAccount.fromMap(record);
      case "bankCasa":
        return BankCasaAccount.fromMap(record);
      case "loan":
        return LoanAccount.fromMap(record);
      case "eWallet":
        return EWallet.fromMap(record);
      case "payLaterAccount":
        return PayLaterAccount.fromMap(record);
      default:
        return CreditCard.fromMap(record);
    }
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

  Future<bool> existById(String assetId) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> records =
        await db.query(tableNameAsset, where: 'uid = ?', whereArgs: [assetId], orderBy: 'last_updated DESC');
    return (records.isNotEmpty);
  }

  Future<Asset?> loadById(String assetId) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> records =
        await db.query(tableNameAsset, where: 'uid = ?', whereArgs: [assetId], orderBy: 'last_updated DESC');
    if (records.isNotEmpty) {
      return assetFromJson(records.first);
    } else {
      return null;
    }
  }

  Future<bool> categoryExistById(String assetCategoryId) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> records = await db.query(tableNameAssetCategory, where: 'uid = ?', whereArgs: [assetCategoryId]);
    return (records.isNotEmpty);
  }

  Future<AssetCategory?> categoryById(String assetCategoryId) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> records = await db.query(tableNameAssetCategory, where: 'uid = ?', whereArgs: [assetCategoryId]);
    if (records.isNotEmpty) {
      return AssetCategory.fromMap(records.first);
    } else {
      return null;
    }
  }
}
