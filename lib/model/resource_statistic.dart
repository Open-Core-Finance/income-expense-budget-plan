import 'package:income_expense_budget_plan/model/statistic.dart';
import 'package:income_expense_budget_plan/service/statistic.dart';
import 'package:income_expense_budget_plan/service/util.dart';

class ResourceStatisticMonthly extends CurrencyStatistic {
  int year;
  int month;
  String resourceType;
  String resourceId;

  ResourceStatisticMonthly({
    required this.month,
    required this.year,
    required this.resourceType,
    required this.resourceId,
    required super.currency,
    super.totalIncome,
    super.totalExpense,
    super.totalTransferOut,
    super.totalTransferIn,
    super.totalTransfer,
    super.totalFeePaid,
    super.totalSharedBillPaid,
    super.totalSharedBillReturn,
    super.totalLend,
    super.totalBorrow,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResourceStatisticMonthly &&
        other.resourceType == resourceType &&
        other.resourceId == resourceId &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode => resourceType.hashCode + resourceId.hashCode + (year * 12) + month;

  factory ResourceStatisticMonthly.fromMap(Map<String, dynamic> json) => ResourceStatisticMonthly(
        resourceType: json['resource_type'],
        resourceId: json['resource_uid'],
        year: json['stat_year'],
        month: json['stat_month'],
        totalIncome: json['total_income'],
        totalExpense: json['total_expense'],
        totalTransferOut: json['total_transfer_out'],
        totalTransferIn: json['total_transfer_in'],
        totalTransfer: json['total_transfer'],
        totalFeePaid: json['total_fee_paid'],
        totalLend: json['total_lend'],
        totalBorrow: json['total_borrow'],
        currency: Util().findCurrency(json['currency_uid'] as String),
      );

  @override
  String toAttrString() =>
      '"year": $year, "month": $month, "resourceType": "$resourceType", "resourceId": "$resourceId", ${super.toAttrString()}';
}

class ResourceStatisticDaily extends ResourceStatisticMonthly {
  int day;
  late DateTime lastUpdated;
  ResourceStatisticDaily({
    required this.day,
    required super.month,
    required super.year,
    required super.resourceType,
    required super.resourceId,
    required super.currency,
    super.totalIncome,
    super.totalExpense,
    super.totalTransferOut,
    super.totalTransferIn,
    super.totalTransfer,
    super.totalFeePaid,
    super.totalSharedBillPaid,
    super.totalSharedBillReturn,
    super.totalLend,
    super.totalBorrow,
    DateTime? updatedDateTime,
  }) {
    if (updatedDateTime == null) {
      lastUpdated = DateTime.now();
    } else {
      lastUpdated = updatedDateTime;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResourceStatisticDaily &&
        other.resourceType == resourceType &&
        other.resourceId == resourceId &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => resourceType.hashCode + resourceId.hashCode + (year * 365) + (month * 30) + day;

  factory ResourceStatisticDaily.fromMap(Map<String, dynamic> json) => ResourceStatisticDaily(
        resourceType: json['resource_type'],
        resourceId: json['resource_uid'],
        year: json['stat_year'],
        month: json['stat_month'],
        day: json['stat_day'],
        totalIncome: json['total_income'],
        totalExpense: json['total_expense'],
        totalTransferOut: json['total_transfer_out'],
        totalTransferIn: json['total_transfer_in'],
        totalTransfer: json['total_transfer'],
        updatedDateTime: DateTime.fromMillisecondsSinceEpoch(json['last_updated']),
        totalFeePaid: json['total_fee_paid'],
        totalLend: json['total_lend'],
        totalBorrow: json['total_borrow'],
        currency: Util().findCurrency(json['currency_uid'] as String),
      );

  @override
  String toAttrString() => '"day": $day, ${super.toAttrString()}';

  ResourceStatisticMonthly toMonthly() => ResourceStatisticMonthly(
        resourceType: resourceType,
        resourceId: resourceId,
        year: year,
        month: month,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        totalTransferOut: totalTransferOut,
        totalTransferIn: totalTransferIn,
        totalTransfer: totalTransfer,
        totalFeePaid: totalPaidFee,
        totalLend: totalLend,
        totalBorrow: totalBorrow,
        currency: currency,
      );
}
