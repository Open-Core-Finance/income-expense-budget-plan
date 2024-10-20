import 'package:income_expense_budget_plan/model/resource_statistic.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';

class ResourceStatisticDao {
  final DatabaseService databaseService = DatabaseService();
  // Singleton pattern
  static final ResourceStatisticDao _dao = ResourceStatisticDao._internal();
  factory ResourceStatisticDao() => _dao;
  ResourceStatisticDao._internal();

  Future<List<ResourceStatisticMonthly>> loadMonthlyStatistics(int year, int month) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> result = await db.rawQuery(
        'select resource_type, resource_uid, stat_year, stat_month, currency_uid, sum(total_income) as total_income, sum(total_expense) as total_expense,'
        'sum(total_transfer_out) as total_transfer_out, sum(total_transfer_in) as total_transfer_in, sum(total_transfer) as total_transfer,'
        'sum(total_fee_paid) as total_fee_paid, sum(total_lend) as total_lend, sum(total_borrow) as total_borrow from $tableNameResourceStatisticDaily '
        'where stat_year = ? ANd stat_month = ? '
        'GROUP BY resource_type, resource_uid, stat_year, stat_month, currency_uid',
        [year, month]);
    List<ResourceStatisticMonthly> resultObjectList = [
      for (Map<String, Object?> record in result) ResourceStatisticMonthly.fromMap(record)
    ];
    return resultObjectList;
  }

  Future<List<ResourceStatisticDaily>> loadDailyStatistics(int year, int month) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> result =
        await db.query(tableNameResourceStatisticDaily, where: 'stat_year = ? ANd stat_month = ?', whereArgs: [year, month]);
    List<ResourceStatisticDaily> resultObjectList = [for (Map<String, Object?> record in result) ResourceStatisticDaily.fromMap(record)];
    return resultObjectList;
  }
}
