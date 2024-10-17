import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/common/add_account_form.dart';
import 'package:income_expense_budget_plan/common/assets_categories_panel.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/resource_statistic.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:income_expense_budget_plan/service/year_month_filter_data.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import 'no_data.dart';

class ReportPanel extends StatefulWidget {
  final YearMonthFilterData? yearMonthFilterData;
  const ReportPanel({super.key, this.yearMonthFilterData});

  @override
  State<ReportPanel> createState() => _ReportPanelState();
}

class _ReportPanelState extends State<ReportPanel> {
  YearMonthFilterData? yearMonthFilterData;

  @override
  void initState() {
    super.initState();
    yearMonthFilterData = YearMonthFilterData();
  }

  YearMonthFilterData? _retrieveProvidedFilter() {
    YearMonthFilterData? providedYearMonthFilterData;
    try {
      providedYearMonthFilterData = widget.yearMonthFilterData;
      if (kDebugMode) {
        print("Debug purpose only!. Provided filter: $providedYearMonthFilterData");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Debug purpose only!. There's no provided filter! $e");
      }
    }
    return providedYearMonthFilterData;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // final ColorScheme colorScheme = theme.colorScheme;
    // var appLocalizations = AppLocalizations.of(context)!;

    YearMonthFilterData? providedYearMonthFilterData = _retrieveProvidedFilter();
    YearMonthFilterData filterData;
    if (providedYearMonthFilterData != null) {
      filterData = providedYearMonthFilterData;
    } else {
      filterData = yearMonthFilterData!;
    }
    List<ResourceStatisticMonthly> resourcesStatisticsMonthly = filterData.resourcesStatisticsMonthly;

    Widget body;
    if (resourcesStatisticsMonthly.isEmpty) {
      body = const NoDataCard();
    } else {
      body = const Text("Report will be generated here!");
    }

    return Scaffold(
      appBar: providedYearMonthFilterData == null ? yearMonthFilterData!.generateFilterLabel(context, () => setState(() {})) : null,
      body: body,
    );
  }
}
