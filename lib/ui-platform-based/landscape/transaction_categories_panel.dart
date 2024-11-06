import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/ui-common/transaction_categories_panel.dart';
import 'package:income_expense_budget_plan/ui-platform-based/landscape/transaction_category_tree.dart';

class TransactionCategoriesPanelLandscape extends TransactionCategoriesPanel {
  const TransactionCategoriesPanelLandscape(
      {super.key, required super.listPanelTitle, super.disableBack, super.itemTap, super.floatingActionButton});

  @override
  State<TransactionCategoriesPanelLandscape> createState() => _TransactionCategoriesPanelStateLandscape();
}

class _TransactionCategoriesPanelStateLandscape extends TransactionCategoriesPanelState<TransactionCategoriesPanelLandscape> {
  @override
  Widget buildUiBody(BuildContext context, AppLocalizations apLocalizations, TransactionCategoriesListenable transactionCategories) {
    if (transactionCategories.categoriesMap.length >= 2) {
      return TabBarView(
        children: [
          TransactionCategoryTree(
            key: Key("Categories-panel-${widget.key.toString()}-income"),
            categories: transactionCategories.categoriesMap[TransactionType.income] ?? [],
            transactionType: TransactionType.income,
            itemTap: widget.itemTap,
          ),
          TransactionCategoryTree(
            key: Key("Categories-panel-${widget.key.toString()}-expense"),
            categories: transactionCategories.categoriesMap[TransactionType.expense] ?? [],
            transactionType: TransactionType.expense,
            itemTap: widget.itemTap,
          ),
        ],
      );
    } else {
      var categoriesEntry = transactionCategories.categoriesMap.entries.first;
      return TransactionCategoryTree(
          key: Key("Categories-panel-${widget.key.toString()}"),
          categories: categoriesEntry.value,
          transactionType: categoriesEntry.key,
          itemTap: widget.itemTap);
    }
  }
}
