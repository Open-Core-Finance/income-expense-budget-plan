import 'dart:math';

import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/common/report_view_more.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/report_chart_data.dart';
import 'package:income_expense_budget_plan/model/resource_statistic.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:income_expense_budget_plan/service/year_month_filter_data.dart';
import 'package:intl/intl.dart';
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
    yearMonthFilterData = YearMonthFilterData(
      supportLoadTransactions: false,
      refreshFunction: () => setState(() {}),
      refreshStatisticFunction: () => setState(() {}),
    );
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

    YearMonthFilterData? providedYearMonthFilterData = _retrieveProvidedFilter();
    YearMonthFilterData filterData;
    if (providedYearMonthFilterData != null) {
      filterData = providedYearMonthFilterData;
    } else {
      filterData = yearMonthFilterData!;
    }

    Map<Currency, List<ResourceStatisticMonthly>> resourcesStatisticsMonthlyMap = filterData.resourcesStatisticsMonthlyMap;
    Widget body;
    if (resourcesStatisticsMonthlyMap.isEmpty) {
      body = const NoDataCard();
    } else {
      final percentageFormat = NumberFormat.percentPattern()
        ..minimumFractionDigits = 2
        ..maximumFractionDigits = 2;
      double reportChartDefaultSize = currentAppState.systemSetting.reportChartSizeDefault;
      BoxConstraints constraints = BoxConstraints(maxWidth: reportChartDefaultSize, maxHeight: reportChartDefaultSize);
      double chartPadding = currentAppState.systemSetting.reportChartPadding;
      if (widgetSize != null) {
        double minSize = max(reportChartDefaultSize, min(widgetSize.width, widgetSize.height) / 2);
        reportChartDefaultSize = minSize;
        constraints = BoxConstraints(maxWidth: minSize, maxHeight: minSize);
      }
      List<Widget> children = [];
      for (var entry in resourcesStatisticsMonthlyMap.entries) {
        var currency = entry.key;
        List<ResourceStatisticMonthly> resourcesStatisticsMonthly =
            entry.value.where((statistic) => statistic.resourceType == 'category').toList(growable: false);
        double totalIncome = 0;
        double totalExpense = 0;
        for (var statistic in resourcesStatisticsMonthly) {
          totalIncome += statistic.totalIncome;
          totalExpense += statistic.totalExpense;
        }
        List<ReportChartDataItem> chartDataItems = _buildExpenseCategoryReportChartData(context, resourcesStatisticsMonthly, totalExpense);
        List<BarChartGroupData> barChartData =
            _buildExpenseIncomeBarChartData(context, totalIncome: totalIncome, totalExpense: totalExpense);
        CurrencyTextInputFormatter currencyFormatter = FormUtil().buildFormatter(currency);
        children.addAll(_buildChartForCurrency(context,
            currency: currency,
            chartPadding: chartPadding,
            reportChartBoxConstraints: constraints,
            percentageFormat: percentageFormat,
            chartDataItems: chartDataItems,
            totalExpense: totalExpense,
            totalIncome: totalIncome,
            barChartData: barChartData,
            reportChartDefaultSize: reportChartDefaultSize,
            currencyFormatter: currencyFormatter,
            viewMoreFnc: () => _viewMore(currency, resourcesStatisticsMonthly, totalIncome, totalExpense, filterData)));
      }

      body = SingleChildScrollView(
        child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: children),
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
    var systemSettings = currentAppState.systemSetting;
    List<Color> palette = systemSettings.reportColorPalette;
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
              dataLabel: category.getTitleText(systemSettings),
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
      if (result.length > systemSettings.reportPieChartPreferCount &&
          item.percentage < systemSettings.reportPieChartPreferItemMinPercentage &&
          (removedValue / totalExpense) < systemSettings.reportPieChartOtherLimitPercentage) {
        result.removeAt(index);
        removedValue += item.value;
      }
    }
    if (removedValue > 0.0001) {
      int colorIndex = (result.length + 1) % systemSettings.reportColorPalette.length;
      result.add(ReportChartDataItem(
          icon: Icons.category,
          color: systemSettings.reportColorPalette[colorIndex],
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
    double barWidth = currentAppState.systemSetting.reportBarWidth;
    List<BarChartRodData> data = [
      BarChartRodData(toY: totalIncome, color: Colors.blue, width: barWidth, fromY: 0),
      BarChartRodData(toY: totalExpense, color: Colors.red, width: barWidth, fromY: 0)
    ];
    result.add(BarChartGroupData(x: 1, barRods: data, barsSpace: currentAppState.systemSetting.reportBarSpace));
    return result;
  }

  List<Widget> _buildChartForCurrency(BuildContext context,
      {required Currency currency,
      required double chartPadding,
      required BoxConstraints reportChartBoxConstraints,
      required NumberFormat percentageFormat,
      required List<ReportChartDataItem> chartDataItems,
      required List<BarChartGroupData> barChartData,
      required double totalExpense,
      required double totalIncome,
      required double reportChartDefaultSize,
      required CurrencyTextInputFormatter currencyFormatter,
      required void Function() viewMoreFnc}) {
    ThemeData theme = Theme.of(context);
    var appLocalizations = AppLocalizations.of(context)!;
    double totalDifferences = totalIncome - totalExpense;
    var viewMoreRow = ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [ElevatedButton(onPressed: viewMoreFnc, child: Text("${appLocalizations.reportViewMoreButton} >>"))],
        ),
      ),
    );
    List<Widget> result = [
      const Divider(thickness: 1, indent: 0),
      Text('${appLocalizations.reportSummarizeIncomeExpense} (${currency.name})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      SizedBox(height: chartPadding),
      Row(
        children: [
          ConstrainedBox(
            constraints: reportChartBoxConstraints,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                        _chartTouchedIndex = -1;
                        return;
                      }
                      _chartTouchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 0,
                centerSpaceRadius: 0,
                sections: showingSections(chartDataItems),
              ),
              swapAnimationDuration: const Duration(milliseconds: 150),
              swapAnimationCurve: Curves.linear,
            ),
          ),
          ConstrainedBox(
            constraints: reportChartBoxConstraints,
            child: ListView(children: [
              for (var item in chartDataItems)
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
          ),
        ],
      ),
      viewMoreRow,
      const SizedBox(height: 10),
      const Divider(thickness: 1, indent: 0),
      SizedBox(height: chartPadding),
      Padding(
        padding: EdgeInsets.fromLTRB(chartPadding, 0, 0, 0),
        child: Row(
          children: [
            ConstrainedBox(
              constraints: reportChartBoxConstraints,
              child: BarChart(
                BarChartData(
                  barGroups: barChartData,
                  maxY: max(totalExpense, totalIncome) * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(currencyFormatter.formatDouble(rod.toY), TextStyle(color: rod.color));
                      },
                      getTooltipColor: (group) => (theme.brightness == Brightness.light) ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                swapAnimationDuration: const Duration(milliseconds: 150),
                swapAnimationCurve: Curves.linear,
              ),
            ),
            SizedBox(width: chartPadding),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: reportChartDefaultSize, maxWidth: reportChartDefaultSize - chartPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: chartPadding),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 20, height: 20, child: Container(color: Colors.blue)),
                      const SizedBox(width: 10),
                      Text("${appLocalizations.reportTotalIncome}:"),
                      Expanded(
                        child: Text(currencyFormatter.formatDouble(totalIncome),
                            overflow: TextOverflow.fade, style: const TextStyle(color: Colors.blue), textAlign: TextAlign.right),
                      )
                    ],
                  ),
                  SizedBox(height: chartPadding),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 20, height: 20, child: Container(color: Colors.red)),
                      const SizedBox(width: 10),
                      Text("${appLocalizations.reportTotalExpense}:"),
                      Expanded(
                          child: Text('-${currencyFormatter.formatDouble(totalExpense)}',
                              overflow: TextOverflow.fade, style: const TextStyle(color: Colors.red), textAlign: TextAlign.right))
                    ],
                  ),
                  const Divider(thickness: 1, indent: 0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 20, height: 20, child: Container()),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          currencyFormatter.formatDouble(totalDifferences),
                          overflow: TextOverflow.fade,
                          style: TextStyle(color: totalDifferences < 0 ? Colors.red : Colors.blue),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      viewMoreRow,
      SizedBox(height: chartPadding),
    ];
    return result;
  }

  void _viewMore(Currency currency, List<ResourceStatisticMonthly> resourcesStatisticsMonthly, double totalIncome, double totalExpense,
      YearMonthFilterData filterData) {
    Util().navigateTo(
      context,
      ReportViewMore(
        currency: currency,
        resourcesStatisticsMonthly: resourcesStatisticsMonthly,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        filterData: filterData,
      ),
    );
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
