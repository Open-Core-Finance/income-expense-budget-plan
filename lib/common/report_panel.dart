import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:income_expense_budget_plan/common/add_account_form.dart';
import 'package:income_expense_budget_plan/common/assets_categories_panel.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/report_chart_data.dart';
import 'package:income_expense_budget_plan/model/resource_statistic.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:income_expense_budget_plan/service/year_month_filter_data.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'no_data.dart';

final GlobalKey _widgetKey = GlobalKey();

class ReportPanel extends StatefulWidget {
  final YearMonthFilterData? yearMonthFilterData;
  ReportPanel({this.yearMonthFilterData}) : super(key: _widgetKey);

  @override
  State<ReportPanel> createState() => _ReportPanelState();
}

class _ReportPanelState extends State<ReportPanel> {
  YearMonthFilterData? yearMonthFilterData;
  int _chartTouchedIndex = 0;

  @override
  void initState() {
    super.initState();
    yearMonthFilterData = YearMonthFilterData(supportLoadTransactions: false);
  }

  YearMonthFilterData? _retrieveProvidedFilter() {
    YearMonthFilterData? providedYearMonthFilterData;
    try {
      providedYearMonthFilterData = widget.yearMonthFilterData;
      // if (kDebugMode) {
      //   print("Debug purpose only!. Provided filter: $providedYearMonthFilterData");
      // }
    } catch (e) {
      if (kDebugMode) {
        print("Debug purpose only!. There's no provided filter! $e");
      }
    }
    return providedYearMonthFilterData;
  }

  @override
  Widget build(BuildContext context) {
    var renderObj = _widgetKey.currentContext?.findRenderObject();
    Size? widgetSize;
    if (renderObj != null) {
      final RenderBox renderBox = renderObj as RenderBox;
      widgetSize = renderBox.size;
    }
    // final ThemeData theme = Theme.of(context);
    // final ColorScheme colorScheme = theme.colorScheme;
    var appLocalizations = AppLocalizations.of(context)!;

    YearMonthFilterData? providedYearMonthFilterData = _retrieveProvidedFilter();
    YearMonthFilterData filterData;
    if (providedYearMonthFilterData != null) {
      filterData = providedYearMonthFilterData;
    } else {
      filterData = yearMonthFilterData!;
    }
    List<ResourceStatisticMonthly> resourcesStatisticsMonthly = filterData.resourcesStatisticsMonthly;
    double totalIncome = 0;
    double totalExpense = 0;
    for (var statistic in resourcesStatisticsMonthly) {
      totalIncome += statistic.totalIncome;
      totalExpense += statistic.totalExpense;
    }
    // TODO list and bar data must base on currency
    List<ReportChartDataItem> list = _buildExpenseCategoryReportChartData(context, resourcesStatisticsMonthly, totalExpense);
    List<BarChartGroupData> barChartData = _buildExpenseIncomeBarChartData(context, totalIncome: totalIncome, totalExpense: totalExpense);

    Widget body;
    if (list.isEmpty) {
      body = const NoDataCard();
    } else {
      final percentageFormat = NumberFormat.percentPattern()
        ..minimumFractionDigits = 2
        ..maximumFractionDigits = 2;
      double defaultSize = 200;
      BoxConstraints constraints = BoxConstraints(maxWidth: defaultSize, maxHeight: defaultSize);
      double chartPadding = 10;
      if (widgetSize != null) {
        double minSize = max(defaultSize, min(widgetSize.width, widgetSize.height) / 2);
        defaultSize = minSize;
        constraints = BoxConstraints(maxWidth: minSize, maxHeight: minSize);
      }
      body = SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appLocalizations.reportSummarizeIncomeExpense, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: chartPadding),
            Row(
              children: [
                ConstrainedBox(
                    constraints: constraints,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _chartTouchedIndex = -1;
                                return;
                              }
                              _chartTouchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        sectionsSpace: 0,
                        centerSpaceRadius: 0,
                        sections: showingSections(list),
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 150),
                      swapAnimationCurve: Curves.linear,
                    )),
                ConstrainedBox(
                  constraints: constraints,
                  child: ListView(children: [
                    for (var item in list)
                      Row(
                        children: [
                          SizedBox(width: 20, height: 20, child: Container(color: item.color)),
                          const SizedBox(width: 10),
                          Icon(item.icon),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('${item.dataLabel} (${percentageFormat.format(item.percentage)})',
                                overflow: TextOverflow.ellipsis, maxLines: 1),
                          )
                        ],
                      )
                  ]),
                )
              ],
            ),
            const SizedBox(height: 10),
            const Divider(thickness: 1, indent: 0),
            SizedBox(height: chartPadding),
            Padding(
              padding: EdgeInsets.fromLTRB(chartPadding, 0, 0, 0),
              child: Row(
                children: [
                  ConstrainedBox(
                    constraints: constraints,
                    child: BarChart(
                      BarChartData(barGroups: barChartData, maxY: totalExpense * 1.1),
                      swapAnimationDuration: const Duration(milliseconds: 150),
                      swapAnimationCurve: Curves.linear,
                    ),
                  ),
                  SizedBox(width: chartPadding),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: defaultSize, maxWidth: defaultSize - (2 * chartPadding)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: chartPadding),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: 20, height: 20, child: Container(color: Colors.blue)),
                            const SizedBox(width: 10),
                            const Text("Thu:"),
                            const SizedBox(width: 10),
                            Text('$totalIncome', overflow: TextOverflow.ellipsis, maxLines: 1),
                            SizedBox(width: chartPadding)
                          ],
                        ),
                        SizedBox(height: chartPadding),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: 20, height: 20, child: Container(color: Colors.red)),
                            const SizedBox(width: 10),
                            const Text("Chi:"),
                            const SizedBox(width: 10),
                            Text('$totalExpense', overflow: TextOverflow.ellipsis, maxLines: 1),
                            SizedBox(width: chartPadding)
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: chartPadding),
          ],
        ),
      );
    }

    AppBar? appBar = providedYearMonthFilterData == null ? yearMonthFilterData!.generateFilterLabel(context, () => setState(() {})) : null;

    return Scaffold(appBar: appBar, body: body);
  }

  List<PieChartSectionData> showingSections(List<ReportChartDataItem> list) {
    if (_chartTouchedIndex >= list.length) {
      _chartTouchedIndex = 1;
    }
    // Create a NumberFormat instance for percentage formatting
    final percentageFormat = NumberFormat.percentPattern()
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;
    List<PieChartSectionData> result = [];
    for (var i = 0; i < list.length; i++) {
      ReportChartDataItem item = list[i];
      final isTouched = i == _chartTouchedIndex;
      final fontSize = isTouched
          ? 20.0
          : _chartTouchedIndex < 0
              ? 16.0
              : 10.0;
      final radius = isTouched ? 110.0 : 100.0;
      final widgetSize = isTouched ? 55.0 : 40.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      const iconBorderColor = Colors.black;
      final String title = (_chartTouchedIndex < 0 || isTouched)
          ? '${item.dataLabel} (${percentageFormat.format(item.percentage)})'
          : percentageFormat.format(item.percentage);
      result.add(PieChartSectionData(
        color: item.color,
        value: item.percentage,
        title: title,
        radius: radius,
        titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: const Color(0xffffffff), shadows: shadows),
        badgeWidget: _Badge(item, size: widgetSize, borderColor: iconBorderColor, isHovered: isTouched),
        badgePositionPercentageOffset: .98,
      ));
    }
    return result;
  }

  List<ReportChartDataItem> _buildExpenseCategoryReportChartData(
      BuildContext context, List<ResourceStatisticMonthly> statistics, double totalExpense) {
    var appLocalizations = AppLocalizations.of(context)!;
    List<ReportChartDataItem> result = [];
    List<Color> palette = currentAppState.systemSetting.reportColorPalette;
    int index = 0;
    statistics.sort((a, b) => (b.totalExpense - a.totalExpense).toInt());
    for (ResourceStatisticMonthly statistic in statistics) {
      if (statistic.resourceType == 'category' && statistic.resourceId != 'transfer') {
        ++index;
        TransactionCategory? category = currentAppState.retrieveCategory(statistic.resourceId);
        if (category != null) {
          result.add(
            ReportChartDataItem(
              icon: category.icon ?? defaultIconData,
              color: palette[index % palette.length],
              percentage: statistic.totalExpense / totalExpense,
              dataId: statistic.resourceId,
              dataLabel: category.getTitleText(currentAppState.systemSetting),
              value: statistic.totalExpense,
            ),
          );
        } else {
          result.add(
            ReportChartDataItem(
              icon: defaultIconData,
              color: palette[index % palette.length],
              percentage: statistic.totalExpense / totalExpense,
              dataId: statistic.resourceId,
              dataLabel: appLocalizations.reportUnknownCategoryName,
              value: statistic.totalExpense,
            ),
          );
        }
      }
    }
    double removedValue = 0;
    for (index = result.length - 1; index >= 0; index--) {
      var item = result[index];
      if (result.length > 5 && item.percentage < 0.03 && (removedValue / totalExpense) < 0.1) {
        result.removeAt(index);
        removedValue += item.value;
      }
    }
    if (removedValue > 0.0001) {
      int colorIndex = (result.length + 1) % currentAppState.systemSetting.reportColorPalette.length;
      result.add(ReportChartDataItem(
          icon: Icons.category,
          color: currentAppState.systemSetting.reportColorPalette[colorIndex],
          percentage: removedValue / totalExpense,
          dataId: "--",
          dataLabel: appLocalizations.reportOtherCategoryName,
          value: removedValue));
    }
    return result;
  }

  List<BarChartGroupData> _buildExpenseIncomeBarChartData(BuildContext context,
      {required double totalIncome, required double totalExpense}) {
    List<BarChartGroupData> result = [];
    double barWidth = 20;
    List<BarChartRodData> data = [
      BarChartRodData(toY: totalIncome, color: Colors.blue, width: barWidth, fromY: 0),
      BarChartRodData(toY: totalExpense, color: Colors.red, width: barWidth, fromY: 0)
    ];
    result.add(BarChartGroupData(x: 1, barRods: data, barsSpace: 10));
    return result;
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.item, {required this.size, required this.borderColor, required this.isHovered});
  final double size;
  final Color borderColor;
  final bool isHovered;
  final ReportChartDataItem item;

  @override
  Widget build(BuildContext context) {
    Widget widget = Icon(item.icon);
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withOpacity(.5), offset: const Offset(3, 3), blurRadius: 3),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(child: widget),
    );
  }
}
