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
    List<Map<String, dynamic>> result =
        await db.query(tableNameResourceStatisticMonthly, where: 'stat_year = ? ANd stat_month = ?', whereArgs: [year, month]);
    List<ResourceStatisticMonthly> resultObjectList = [
      for (Map<String, Object?> record in result) ResourceStatisticMonthly.fromMap(record)
    ];
    return resultObjectList;
  }
}
