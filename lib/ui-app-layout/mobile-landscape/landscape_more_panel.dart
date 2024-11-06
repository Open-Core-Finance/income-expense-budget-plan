import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:income_expense_budget_plan/ui-app-layout/home.dart';
import 'package:income_expense_budget_plan/ui-common/file_export.dart';
import 'package:income_expense_budget_plan/ui-common/file_import.dart';
import 'package:income_expense_budget_plan/ui-platform-based/landscape/transaction_categories_panel.dart';
import 'package:provider/provider.dart';

class LandscapeMorePanel extends StatefulWidget {
  const LandscapeMorePanel({super.key});

  @override
  State<LandscapeMorePanel> createState() => _LandscapeMorePanelState();
}

class _LandscapeMorePanelState extends State<LandscapeMorePanel> {
  late DeveloperTapCountTriggerSupport developerTriggerSupport;

  @override
  void initState() {
    super.initState();
    developerTriggerSupport = DeveloperTapCountTriggerSupport(updateUiState: setState);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return ListView(
      children: <Widget>[
        ListTile(
          title: Text(appLocalizations.settingsDarkMode),
          subtitle: Text(currentAppState.systemSetting.getDarkModeText(context)),
          onTap: () => Util().chooseBrightnessMode(context),
        ),
        ListTile(
          title: Text(appLocalizations.menuExpenseCategory),
          onTap: () {
            var txnType = TransactionType.expense;
            int startTime = DateTime.now().millisecondsSinceEpoch;
            TransactionDao().transactionCategoryByType(txnType).then((List<TransactionCategory> loadCats) {
              int loadEndTime = DateTime.now().millisecondsSinceEpoch;
              var categories = loadCats;
              int parseEndTime = DateTime.now().millisecondsSinceEpoch;
              if (kDebugMode) {
                print("\nLoad time: ${loadEndTime - startTime}, parse time: ${parseEndTime - loadEndTime}");
              }
              var model = TransactionCategoriesListenable(categoriesMap: {txnType: categories});
              if (context.mounted) {
                Util().navigateTo(
                  context,
                  ChangeNotifierProvider(
                      create: (context) => model,
                      builder: (context, child) => child!,
                      child: TransactionCategoriesPanelLandscape(listPanelTitle: appLocalizations.menuExpenseCategory)),
                );
              }
            });
          },
          iconColor: colorScheme.primary,
        ),
        ListTile(
          title: Text(appLocalizations.menuIncomeCategory),
          onTap: () {
            var txnType = TransactionType.income;
            TransactionDao().transactionCategoryByType(txnType).then((List<TransactionCategory> loadCats) {
              var categories = loadCats;
              if (kDebugMode) {
                print("Final list income categories $categories");
              }
              var model = TransactionCategoriesListenable(categoriesMap: {txnType: categories});
              if (context.mounted) {
                Util().navigateTo(
                  context,
                  ChangeNotifierProvider(
                    create: (context) => model,
                    builder: (context, child) => child!,
                    child: TransactionCategoriesPanelLandscape(listPanelTitle: appLocalizations.menuIncomeCategory),
                  ),
                );
              }
            });
          },
          iconColor: colorScheme.primary,
        ),
        ListTile(
          title: Text(appLocalizations.dataExportFileMenu),
          onTap: () => Util().navigateTo(context, const DataFileExport(showBackArrow: true)),
          iconColor: colorScheme.primary,
        ),
        ListTile(
          title: Text(appLocalizations.dataImportFileMenu),
          onTap: () => Util().navigateTo(context, const DataFileImport(showBackArrow: true)),
          iconColor: colorScheme.primary,
        ),
        if (developerTriggerSupport.canShowDeveloperMenu())
          ListTile(
            title: Text(appLocalizations.sqlImportMenu),
            onTap: () {
              Util().navigateTo(context, const SqlImport(showBackArrow: true));
              developerTriggerSupport.resetTapCount();
            },
            iconColor: colorScheme.primary,
          ),
        MouseRegion(
          cursor: SystemMouseCursors.click, // Changes the cursor to a pointer
          child: GestureDetector(
            onTap: developerTriggerSupport.increaseTap,
            child: SizedBox(height: 100, child: Text("")),
          ),
        ),
      ],
    );
  }
}
