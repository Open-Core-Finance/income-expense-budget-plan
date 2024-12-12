import 'dart:math';

import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/dao/assets_dao.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/currency_assests_summarize.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccountSummarizePanel extends StatefulWidget {
  final Currency currency;
  final CurrencyTextInputFormatter currencyFormatter;
  final NumberFormat percentageFormat;
  final double chartPadding;
  final Future<List<Asset>> assetLoader;
  final BoxConstraints panelConstraints;
  final BoxConstraints reportChartBoxConstraints;
  final double reportChartDefaultSize;

  const AccountSummarizePanel({
    super.key,
    required this.currency,
    required this.currencyFormatter,
    required this.percentageFormat,
    required this.chartPadding,
    required this.assetLoader,
    required this.panelConstraints,
    required this.reportChartBoxConstraints,
    required this.reportChartDefaultSize,
  });

  @override
  State<StatefulWidget> createState() => _AccountSummarizePanel();
}

class _AccountSummarizePanel extends State<AccountSummarizePanel> {
  List<Asset> assets = [];

  @override
  void initState() {
    super.initState();
    widget.assetLoader.then((loadAssets) => setState(() {
          assets = loadAssets;
        }));
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    var appLocalizations = AppLocalizations.of(context)!;
    CurrencyAssetsSummarize summarize = CurrencyAssetsSummarize(currency: widget.currency, assets: assets);
    var chartPadding = widget.chartPadding;
    var currencyFormatter = widget.currencyFormatter;

    BarChart chart = BarChart(
      BarChartData(
        barGroups: _buildBarChartData(context, summarize),
        maxY: max(summarize.totalAvailable, summarize.totalAvailable) * 1.2,
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
    );
    Widget summarizeDisplay = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: chartPadding),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 20, height: 20, child: Container(color: Colors.blue)),
            const SizedBox(width: 10),
            Text("${appLocalizations.reportTotalAvailableAmount}:"),
            Expanded(
              child: Text(currencyFormatter.formatDouble(summarize.totalAvailable),
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
            Text("${appLocalizations.reportTotalOutstandingBalance}:"),
            Expanded(
                child: Text('-${currencyFormatter.formatDouble(summarize.totalOutstanding)}',
                    overflow: TextOverflow.fade, style: const TextStyle(color: Colors.red), textAlign: TextAlign.right))
          ],
        ),
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

  List<BarChartGroupData> _buildBarChartData(BuildContext context, CurrencyAssetsSummarize summarize) {
    List<BarChartGroupData> result = [];
    double barWidth = currentAppState.systemSetting.reportBarWidth;

    List<BarChartRodData> data = [
      BarChartRodData(toY: summarize.totalAvailable, color: Colors.blue, width: barWidth, fromY: 0),
      BarChartRodData(toY: summarize.totalOutstanding, color: Colors.red, width: barWidth, fromY: 0)
    ];
    result.add(BarChartGroupData(x: 1, barRods: data, barsSpace: currentAppState.systemSetting.reportBarSpace));
    return result;
  }
}
