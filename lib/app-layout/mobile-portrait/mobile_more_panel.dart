import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/common/assets_categories_panel.dart';
import 'package:income_expense_budget_plan/common/sql_import.dart';
import 'package:income_expense_budget_plan/common/transaction_categories_panel.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class MobilePortraitMorePanel extends StatefulWidget {
  const MobilePortraitMorePanel({super.key});

  @override
  State<MobilePortraitMorePanel> createState() => _MobilePortraitMorePanelState();
}

class _MobilePortraitMorePanelState extends State<MobilePortraitMorePanel> {
  int _tapCount = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return ListView(
      children: <Widget>[
        if (!currentAppState.isLandscape) ...[
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingsDarkMode),
            subtitle: Text(currentAppState.systemSetting.getDarkModeText(context)),
            onTap: () => Util().chooseBrightnessMode(context),
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(currentAppState.systemSetting.currentLanguageText),
            onTap: () => Util().chooseLanguage(context),
            iconColor: colorScheme.primary,
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.menuAccountCategory),
            onTap: () => Util().navigateTo(context, const AssetCategoriesPanel()),
            iconColor: colorScheme.primary,
          )
        ],
        ListTile(
          title: Text(AppLocalizations.of(context)!.menuExpenseCategory),
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
                    child: TransactionCategoriesPanel(listPanelTitle: AppLocalizations.of(context)!.menuExpenseCategory),
                  ),
                );
              }
            });
          },
          iconColor: colorScheme.primary,
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.menuIncomeCategory),
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
                    child: TransactionCategoriesPanel(listPanelTitle: AppLocalizations.of(context)!.menuIncomeCategory),
                  ),
                );
              }
            });
          },
          iconColor: colorScheme.primary,
        ),
        if (_tapCount >= showHiddenCount)
          ListTile(
            title: Text(AppLocalizations.of(context)!.sqlImportMenu),
            onTap: () {
              Util().navigateTo(context, const SqlImport(showBackArrow: true));
              setState(() => _tapCount = 0);
            },
            iconColor: colorScheme.primary,
          ),
        MouseRegion(
          cursor: SystemMouseCursors.click, // Changes the cursor to a pointer
          child: GestureDetector(
            onTap: () {
              if (_tapCount != showHiddenCount - 1) {
                _tapCount++;
              } else {
                setState(() => _tapCount++);
              }
            },
            child: SizedBox(height: 100, child: Text("")),
          ),
        ),
      ],
    );
  }
}
