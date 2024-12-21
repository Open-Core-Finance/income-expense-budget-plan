import 'dart:math';

import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/report_chart_data.dart';
import 'package:income_expense_budget_plan/model/resource_statistic.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/statistic.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:income_expense_budget_plan/service/year_month_filter_data.dart';
import 'package:income_expense_budget_plan/ui-common/bar_chart_report.dart';
import 'package:income_expense_budget_plan/ui-common/currency_assests_summarize.dart';
import 'package:income_expense_budget_plan/ui-common/report_view_more.dart';
import 'package:intl/intl.dart';

import 'no_data.dart';

class ReportPanel extends StatefulWidget {
  final YearMonthFilterData? yearMonthFilterData;
  const ReportPanel({super.key, this.yearMonthFilterData});

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
    } catch (e) {
      if (kDebugMode) {
        print("Debug purpose only!. There's no provided filter! $e");
      }
    }
    return providedYearMonthFilterData;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints panelConstraints) {
        YearMonthFilterData? providedYearMonthFilterData = _retrieveProvidedFilter();
        YearMonthFilterData filterData;
        if (providedYearMonthFilterData != null) {
          filterData = providedYearMonthFilterData;
        } else {
          filterData = yearMonthFilterData!;
        }

        Map<Currency, List<ResourceStatisticMonthly>> resourcesStatisticsMonthlyMap = filterData.resourcesStatisticsMonthlyMap;
        Set<Currency> noTranCurrencies = currentAppState.assets
            .where((asset) {
              bool contain = false;
              for (var k in resourcesStatisticsMonthlyMap.keys) {
                if (k.id == asset.currencyUid) {
                  contain = true;
                  break;
                }
              }
              return !contain && asset.availableAmount > deltaCompareValue;
            })
            .map((asset) => currentAppState.currencies.firstWhere((c) => c.id == asset.currencyUid))
            .toSet();
        Set<Currency> reportCurrencies = resourcesStatisticsMonthlyMap.keys.toSet();
        reportCurrencies.addAll(noTranCurrencies);
        if (kDebugMode) {
          if (noTranCurrencies.isNotEmpty) {
            print("No transactions currencies $noTranCurrencies");
          }
        }
        Widget body;
        if (reportCurrencies.isEmpty) {
          body = const NoDataCard();
        } else {
          final percentageFormat = NumberFormat.percentPattern()
            ..minimumFractionDigits = 2
            ..maximumFractionDigits = 2;
          double reportChartDefaultSize = currentAppState.systemSetting.reportChartSizeDefault;
          double chartPadding = currentAppState.systemSetting.reportChartPadding;
          double minSize = max(reportChartDefaultSize, (min(panelConstraints.maxWidth, panelConstraints.maxHeight) - 10) / 2);
          reportChartDefaultSize = minSize;
          BoxConstraints constraints = BoxConstraints(maxWidth: minSize, maxHeight: minSize + 15);

          if (reportCurrencies.length > 1) {
            var tapBar = TabBar(
              tabs: <Widget>[for (Currency currency in reportCurrencies) Tab(child: Text("${currency.iso} (${currency.symbol})"))],
            );
            var reportPanels = TabBarView(children: [
              for (Currency currency in reportCurrencies)
                _buildChartsForCurrency(
                  context,
                  currency: currency,
                  monthlyStatistics: resourcesStatisticsMonthlyMap[currency] ?? [],
                  chartPadding: chartPadding,
                  reportChartBoxConstraints: constraints,
                  panelBoxConstraints: panelConstraints,
                  percentageFormat: percentageFormat,
                  reportChartDefaultSize: reportChartDefaultSize,
                  currencyFormatter: FormUtil().buildFormatter(currency),
                  filterData: filterData,
                )
            ]);
            body = DefaultTabController(
              length: reportCurrencies.length,
              child: Scaffold(appBar: AppBar(title: tapBar), body: reportPanels),
            );
          } else {
            var currency = reportCurrencies.first;
            CurrencyTextInputFormatter currencyFormatter = FormUtil().buildFormatter(currency);
            List<ResourceStatisticMonthly> monthlyStatistics = resourcesStatisticsMonthlyMap[currency] ?? [];
            body = _buildChartsForCurrency(
              context,
              currency: currency,
              monthlyStatistics: monthlyStatistics,
              chartPadding: chartPadding,
              reportChartBoxConstraints: constraints,
              panelBoxConstraints: panelConstraints,
              percentageFormat: percentageFormat,
              reportChartDefaultSize: reportChartDefaultSize,
              currencyFormatter: currencyFormatter,
              filterData: filterData,
            );
          }
        }

        AppBar? appBar =
            providedYearMonthFilterData == null ? yearMonthFilterData!.generateFilterLabel(context, () => setState(() {})) : null;

        return Scaffold(appBar: appBar, body: body);
      },
    );
  }

  SingleChildScrollView _buildChartsForCurrency(
    BuildContext context, {
    required Currency currency,
    required List<ResourceStatisticMonthly> monthlyStatistics,
    required double chartPadding,
    required BoxConstraints reportChartBoxConstraints,
    required BoxConstraints panelBoxConstraints,
    required NumberFormat percentageFormat,
    required double reportChartDefaultSize,
    required CurrencyTextInputFormatter currencyFormatter,
    required YearMonthFilterData filterData,
  }) {
    var appLocalizations = AppLocalizations.of(context)!;
    List<Widget> children = [SizedBox(height: 20)];
    List<ResourceStatisticMonthly> resourcesStatisticsMonthly =
        monthlyStatistics.where((statistic) => statistic.resourceType == 'category').toList(growable: false);
    if (resourcesStatisticsMonthly.isNotEmpty) {
      CurrencyStatistic statistic = CurrencyStatistic(currency: currency);
      for (var st in resourcesStatisticsMonthly) {
        statistic.totalIncome += st.totalIncome;
        statistic.totalExpense += st.totalExpense;
        statistic.totalPaidFee += st.totalPaidFee;
      }
      List<ReportChartDataItem> chartDataItems =
          _buildExpenseCategoryReportChartData(context, resourcesStatisticsMonthly, statistic.totalExpense);
      CurrencyTextInputFormatter currencyFormatter = FormUtil().buildFormatter(currency);
      children.addAll(
        _buildExpenseChartForCurrency(
          context,
          currency: currency,
          chartPadding: chartPadding,
          reportChartBoxConstraints: reportChartBoxConstraints,
          percentageFormat: percentageFormat,
          chartDataItems: chartDataItems,
          statistic: statistic,
          reportChartDefaultSize: reportChartDefaultSize,
          currencyFormatter: currencyFormatter,
          viewMoreFnc: () => _viewMore(currency, resourcesStatisticsMonthly, statistic, filterData),
          panelBoxConstraints: panelBoxConstraints,
        ),
      );
      children.add(const Divider(thickness: 1, indent: 0));
    }
    children.addAll(
      [
        Text('${appLocalizations.reportSummarizeAccountsAvail} (${currency.name})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: chartPadding * 2),
        BarChartReportPanel(
          currency: currency,
          currencyFormatter: currencyFormatter,
          percentageFormat: percentageFormat,
          chartPadding: chartPadding,
          panelConstraints: panelBoxConstraints,
          reportChartBoxConstraints: reportChartBoxConstraints,
          reportChartDefaultSize: reportChartDefaultSize,
          barChartListData: CurrencyAssetsSummarize(currency: currency, assets: currentAppState.assets),
        ),
        SizedBox(height: chartPadding),
      ],
    );
    return SingleChildScrollView(
      child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
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

  BarChartListData _buildExpenseIncomeBarChartData(BuildContext context, {required CurrencyStatistic statistic}) {
    var appLocalizations = AppLocalizations.of(context)!;
    List<BarChartItemData> data = [
      BarChartItemData(value: statistic.totalIncome, color: Colors.blue, label: appLocalizations.reportTotalIncome),
      BarChartItemData(
          value: statistic.totalExpense, color: Colors.red, label: appLocalizations.reportTotalExpense, showAsNegativeInLabel: true)
    ];

    if (statistic.totalPaidFee > deltaCompareValue) {
      data.add(BarChartItemData(
        value: statistic.totalPaidFee,
        color: Colors.purpleAccent,
        label: appLocalizations.reportTotalPaidFee,
        showAsNegativeInLabel: true,
      ));
    }
    double totalDifferences = statistic.totalIncome - statistic.totalExpense - statistic.totalPaidFee;
    data.add(BarChartItemData(
        value: totalDifferences,
        color: totalDifferences < 0 ? Colors.red : Colors.blue,
        label: '',
        startWithDivider: true,
        excludeInChart: true));
    return GenericBarChartListData(items: data);
  }

  List<Widget> _buildExpenseChartForCurrency(BuildContext context,
      {required Currency currency,
      required double chartPadding,
      required BoxConstraints reportChartBoxConstraints,
      required BoxConstraints panelBoxConstraints,
      required NumberFormat percentageFormat,
      required List<ReportChartDataItem> chartDataItems,
      required CurrencyStatistic statistic,
      required double reportChartDefaultSize,
      required CurrencyTextInputFormatter currencyFormatter,
      required void Function() viewMoreFnc}) {
    var appLocalizations = AppLocalizations.of(context)!;
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
      Text('${appLocalizations.reportSummarizeExpense} (${currency.name})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      SizedBox(height: chartPadding),
      ..._buildPieChartRow(
        currency: currency,
        chartDataItems: chartDataItems,
        percentageFormat: percentageFormat,
        reportChartBoxConstraints: reportChartBoxConstraints,
        panelBoxConstraints: panelBoxConstraints,
      ),
      viewMoreRow,
      const SizedBox(height: 10),
      const Divider(thickness: 1, indent: 0),
      Text('${appLocalizations.reportSummarizeIncomeExpense} (${currency.name})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      SizedBox(height: chartPadding * 2),
      BarChartReportPanel(
        currency: currency,
        percentageFormat: percentageFormat,
        reportChartBoxConstraints: reportChartBoxConstraints,
        panelConstraints: panelBoxConstraints,
        chartPadding: chartPadding,
        barChartListData: _buildExpenseIncomeBarChartData(context, statistic: statistic),
        reportChartDefaultSize: reportChartDefaultSize,
        currencyFormatter: currencyFormatter,
      ),
      viewMoreRow,
      SizedBox(height: chartPadding),
    ];
    return result;
  }

  List<Widget> _buildPieChartRow({
    required Currency currency,
    required List<ReportChartDataItem> chartDataItems,
    required NumberFormat percentageFormat,
    required BoxConstraints reportChartBoxConstraints,
    required BoxConstraints panelBoxConstraints,
  }) {
    PieChart chart = PieChart(
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
        borderData: FlBorderData(show: true),
        sectionsSpace: 0,
        centerSpaceRadius: 0,
        sections: showingSections(chartDataItems),
      ),
      duration: const Duration(milliseconds: 150),
      curve: Curves.linear,
    );
    List<Widget> categoriesView = [
      for (var item in chartDataItems)
        Row(
          children: [
            SizedBox(width: 20, height: 20, child: Container(color: item.color)),
            const SizedBox(width: 10),
            Icon(item.icon),
            const SizedBox(width: 10),
            Expanded(
              child: Text('${item.dataLabel} (${percentageFormat.format(item.percentage)})', overflow: TextOverflow.ellipsis, maxLines: 1),
            )
          ],
        )
    ];
    if (panelBoxConstraints.maxWidth < currentAppState.platformConst.reportVerticalSplitViewMinWidth) {
      var maxSize = min(panelBoxConstraints.maxWidth, reportChartBoxConstraints.maxHeight);
      return [
        ConstrainedBox(constraints: BoxConstraints(maxWidth: panelBoxConstraints.maxWidth - 20, maxHeight: maxSize), child: chart),
        const SizedBox(height: 50),
        ...categoriesView
      ];
    }
    return [
      Row(children: [
        ConstrainedBox(constraints: reportChartBoxConstraints, child: chart),
        ConstrainedBox(constraints: reportChartBoxConstraints, child: ListView(children: categoriesView)),
      ])
    ];
  }

  void _viewMore(Currency currency, List<ResourceStatisticMonthly> resourcesStatisticsMonthly, CurrencyStatistic statistic,
      YearMonthFilterData filterData) {
    Util().navigateTo(
      context,
      ReportViewMore(
          currency: currency, resourcesStatisticsMonthly: resourcesStatisticsMonthly, statistic: statistic, filterData: filterData),
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
