import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/service/statistic.dart';
import 'package:income_expense_budget_plan/ui-common/feature_in_development.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/resource_statistic.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/service/year_month_filter_data.dart';

class ReportViewMore extends StatefulWidget {
  final Currency currency;
  final List<ResourceStatisticMonthly> resourcesStatisticsMonthly;
  final YearMonthFilterData filterData;
  final CurrencyStatistic statistic;
  const ReportViewMore({
    super.key,
    required this.currency,
    required this.resourcesStatisticsMonthly,
    required this.statistic,
    required this.filterData,
  });

  @override
  State<ReportViewMore> createState() => _ReportViewMoreState();
}

class _ReportViewMoreState extends State<ReportViewMore> {
  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final filterData = widget.filterData;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.error),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(appLocalizations.reportViewMoreStatisticFor("${filterData.getMonthAsNumberString()}/${filterData.year}")),
      ),
      body: const FeatureInDevelopment(),
    );
  }
}
