import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/common/assets_categories_panel.dart';
import 'package:income_expense_budget_plan/common/transaction_categories_panel.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/setting.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class MorePanel extends StatefulWidget {
  const MorePanel({super.key});

  @override
  State<MorePanel> createState() => _MorePanelState();
}

class _MorePanelState extends State<MorePanel> {
  @override
  Widget build(BuildContext context) {
    final String accountCategoryLabel = AppLocalizations.of(context)!.menuAccountCategory;
    final String incomeCategoryLabel = AppLocalizations.of(context)!.menuIncomeCategory;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return ListView(
      children: <Widget>[
        ListTile(
          title: const Text('Dark Mode'),
          subtitle: Text(currentAppState.systemSettings.getDarkModeText(context)),
          onTap: _chooseDarkMode,
        ),
        ListTile(
          title: const Text('Language'),
          subtitle: Text(currentAppState.systemSettings.currentLanguageText),
          onTap: _chooseLanguage,
          iconColor: colorScheme.primary,
        ),
        ListTile(
          title: Text(accountCategoryLabel),
          onTap: () {
            Util().navigateTo(context, const AssetsCategoriesPanel());
          },
          iconColor: colorScheme.primary,
        ),
        ListTile(
          title: Text(incomeCategoryLabel),
          onTap: () {
            var txnType = TransactionType.income;
            TransactionDao().transactionCategoryByType(txnType).then((List<TransactionCategory> loadCats) {
              var categories = Util().buildTransactionCategoryTree(loadCats);
              var listPanelTitle = AppLocalizations.of(context)!.menuIncomeCategory;
              var addPanelTitle = AppLocalizations.of(context)!.titleAddIncomeCategory;
              var model = TransactionCategoriesListenable(transactionType: txnType, categories: categories);
              Util().navigateTo(
                context,
                ChangeNotifierProvider(
                  create: (context) => model,
                  child: TransactionCategoriesPanel(
                    listPanelTitle: listPanelTitle,
                    addPanelTitle: addPanelTitle,
                  ),
                ),
              );
            });
          },
          iconColor: colorScheme.primary,
        )
      ],
    );
  }

  void _chooseLanguage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                for (MapEntry<String, String> localeConfig in localeMap.entries)
                  ListTile(
                    title: Text(localeMap[localeConfig.key]!),
                    onTap: () {
                      currentAppState.systemSettings.locale = Locale(localeConfig.key);
                      // currentAppState.notifyListeners();
                      Navigator.of(context).pop();
                    },
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  void _chooseDarkMode() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select dark mode'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                for (int mode in [-1, 0, 1])
                  ListTile(
                    title: Text(SettingModel.parseDarkModeText(context, mode)),
                    onTap: () {
                      currentAppState.systemSettings.darkMode = mode;
                      Navigator.of(context).pop();
                    },
                  )
              ],
            ),
          ),
        );
      },
    );
  }
}
