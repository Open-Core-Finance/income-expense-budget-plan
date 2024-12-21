import 'dart:math';

import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:intl/intl.dart';

class BarChartItemData {
  final double value;
  final Color color;
  final String label;
  final bool startWithDivider;
  final bool excludeInChart;
  final bool showAsNegativeInLabel;

  BarChartItemData({
    required this.value,
    required this.color,
    required this.label,
    bool? startWithDivider,
    bool? excludeInChart,
    bool? showAsNegativeInLabel,
  })  : startWithDivider = startWithDivider ?? false,
        excludeInChart = excludeInChart ?? false,
        showAsNegativeInLabel = showAsNegativeInLabel ?? false;
}

abstract class BarChartListData {
  List<BarChartItemData> getItems(BuildContext context);

  List<BarChartGroupData> buildBarChartData(BuildContext context) {
    return buildBarChartDataByItems(context, getItems(context));
  }

  double getMaxY();

  List<BarChartGroupData> buildBarChartDataByItems(BuildContext context, List<BarChartItemData> items) {
    List<BarChartGroupData> result = [];
    double barWidth = currentAppState.systemSetting.reportBarWidth;

    List<BarChartRodData> data = getItems(context).where((item) => !item.excludeInChart).map((item) {
      return BarChartRodData(toY: item.value, color: item.color, width: barWidth, fromY: 0);
    }).toList(growable: true);
    result.add(BarChartGroupData(x: 1, barRods: data, barsSpace: currentAppState.systemSetting.reportBarSpace));
    return result;
  }
}

class GenericBarChartListData extends BarChartListData {
  List<BarChartItemData> items;
  GenericBarChartListData({required this.items});

  @override
  List<BarChartItemData> getItems(BuildContext context) => items;

  @override
  double getMaxY() {
    double maxVal = 0;
    for (var item in items) {
      var tmp = max(maxVal, item.value);
      if (tmp >= maxVal) {
        maxVal = tmp;
      }
    }
    return maxVal;
  }
}

class BarChartReportPanel extends StatefulWidget {
  final Currency currency;
  final CurrencyTextInputFormatter currencyFormatter;
  final NumberFormat percentageFormat;
  final double chartPadding;
  final BarChartListData barChartListData;
  final BoxConstraints panelConstraints;
  final BoxConstraints reportChartBoxConstraints;
  final double reportChartDefaultSize;

  const BarChartReportPanel({
    super.key,
    required this.currency,
    required this.currencyFormatter,
    required this.percentageFormat,
    required this.chartPadding,
    required this.barChartListData,
    required this.panelConstraints,
    required this.reportChartBoxConstraints,
    required this.reportChartDefaultSize,
  });

  @override
  State<BarChartReportPanel> createState() => BarChartReportState();
}

class BarChartReportState extends State<BarChartReportPanel> {
  late BarChartListData barChartListData;

  @override
  void initState() {
    super.initState();
    barChartListData = widget.barChartListData;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    var itemsData = barChartListData.getItems(context);
    List<BarChartGroupData> barchartDataGroup = barChartListData.buildBarChartData(context);
    var chartPadding = widget.chartPadding;
    var currencyFormatter = widget.currencyFormatter;

    BarChart chart = BarChart(
      BarChartData(
        barGroups: barchartDataGroup,
        maxY: (barChartListData.getMaxY() * 1.2).roundToDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(currencyFormatter.formatDouble(rod.toY), TextStyle(color: rod.color));
            },
            getTooltipColor: (group) => (theme.brightness == Brightness.light) ? Colors.black : Colors.white,
          ),
        ),
      ),
      duration: const Duration(milliseconds: 150),
      curve: Curves.linear,
    );
    Widget summarizeDisplay = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        for (var itemData in itemsData) ...[
          if (itemData.startWithDivider) const Divider(thickness: 1, indent: 0),
          SizedBox(height: chartPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (itemData.label.trim().isNotEmpty) SizedBox(width: 20, height: 20, child: Container(color: itemData.color)),
              const SizedBox(width: 10),
              if (itemData.label.trim().isNotEmpty) Text("${itemData.label}:"),
              Expanded(
                child: Text(_valueLabelShow(itemData),
                    overflow: TextOverflow.fade, style: TextStyle(color: itemData.color), textAlign: TextAlign.right),
              )
            ],
          ),
        ],
      ],
    );
    var panelBoxConstraints = widget.panelConstraints;
    var reportChartBoxConstraints = widget.reportChartBoxConstraints;
    var reportChartDefaultSize = widget.reportChartDefaultSize;

    if (panelBoxConstraints.maxWidth < currentAppState.platformConst.reportVerticalSplitViewMinWidth) {
      var maxSize = min(panelBoxConstraints.maxWidth, reportChartBoxConstraints.maxHeight);
      var constraints = BoxConstraints(maxWidth: panelBoxConstraints.maxWidth - 20, maxHeight: maxSize);
      return Column(mainAxisSize: MainAxisSize.min, children: [
        ConstrainedBox(constraints: constraints, child: chart),
        ConstrainedBox(
          constraints: constraints,
          child: Padding(padding: EdgeInsets.fromLTRB(chartPadding, 0, chartPadding, 0), child: summarizeDisplay),
        ),
      ]);
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: EdgeInsets.fromLTRB(chartPadding / 2, 0, chartPadding / 2, 0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            ConstrainedBox(constraints: reportChartBoxConstraints, child: chart),
            SizedBox(width: chartPadding),
            ConstrainedBox(
                constraints: BoxConstraints(maxHeight: reportChartDefaultSize, maxWidth: reportChartDefaultSize - chartPadding),
                child: summarizeDisplay),
          ],
        ),
      ),
    ]);
  }

  String _valueLabelShow(BarChartItemData item) {
    var currencyFormatter = widget.currencyFormatter;
    if (item.showAsNegativeInLabel) {
      return currencyFormatter.formatDouble(item.value * -1);
    }
    return currencyFormatter.formatDouble(item.value);
  }
}
