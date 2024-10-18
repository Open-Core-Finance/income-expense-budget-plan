import 'package:flutter/cupertino.dart';

class ReportChartDataItem {
  IconData icon;
  Color color;
  double percentage;
  String dataId;
  String dataLabel;
  double value;
  ReportChartDataItem({
    required this.icon,
    required this.color,
    required this.percentage,
    required this.dataId,
    required this.dataLabel,
    required this.value,
  });

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReportChartDataItem && other.dataId == dataId;
  }

  @override
  int get hashCode => dataId.hashCode;
}
