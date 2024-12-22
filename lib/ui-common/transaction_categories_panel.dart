import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:provider/provider.dart';
import 'package:income_expense_budget_plan/service/custom_font.dart';

abstract class TransactionCategoriesPanel extends StatefulWidget {
  final bool disableBack;
  final Function(TransactionCategory item)? itemTap;
  final String listPanelTitle;
  final FloatingActionButton? floatingActionButton;
  const TransactionCategoriesPanel({super.key, required this.listPanelTitle, bool? disableBack, this.itemTap, this.floatingActionButton})
      : disableBack = disableBack ?? false;
}

abstract class TransactionCategoriesPanelState<T extends TransactionCategoriesPanel> extends State<T> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    String listPanelTitle = widget.listPanelTitle;
    TransactionCategoriesListenable transactionCategories = Provider.of<TransactionCategoriesListenable>(context);

    Widget? appBarLeading;
    if (widget.disableBack != true) {
      appBarLeading = IconButton(icon: Icon(Icons.arrow_back, color: colorScheme.secondary), onPressed: () => Navigator.of(context).pop());
    }

    AppLocalizations apLocalizations = AppLocalizations.of(context)!;
    PreferredSizeWidget? appBarBottom;
    Widget body = buildUiBody(context, apLocalizations, transactionCategories);

    if (transactionCategories.categoriesMap.length >= 2) {
      String expenseTitle = apLocalizations.menuExpenseCategory;
      String incomeTitle = apLocalizations.menuIncomeCategory;
      appBarBottom = TabBar(
        tabs: [
          Tab(icon: const Icon(MaterialSymbolsOutlinedFont.iconDataAddCircle), text: incomeTitle),
          Tab(icon: const Icon(Icons.remove_circle), text: expenseTitle)
        ],
      );

      // if (kDebugMode) {
      //   print("Body $body with categories ${transactionCategories.categoriesMap}\n");
      // }

      return DefaultTabController(
        length: transactionCategories.categoriesMap.length,
        child: Scaffold(appBar: AppBar(leading: appBarLeading, title: Text(listPanelTitle), bottom: appBarBottom), body: body),
      );
    } else {
      // if (kDebugMode) {
      //   print("Body $body with categories ${transactionCategories.categoriesMap}\n");
      // }

      return Scaffold(appBar: AppBar(leading: appBarLeading, title: Text(listPanelTitle)), body: body);
    }
  }

  Widget buildUiBody(BuildContext context, AppLocalizations apLocalizations, TransactionCategoriesListenable transactionCategories);
}

class TransactionCategoryHandler {
  List<TransactionCategory> categories;
  void Function(VoidCallback fn) refreshState;
  TransactionType transactionType;

  TransactionCategoryHandler({required this.categories, required this.refreshState, required this.transactionType});

  Future<void> showRemoveDialog(BuildContext context, TransactionCategory category) async {
    AppLocalizations apLocalizations = AppLocalizations.of(context)!;
    return Util().showRemoveDialogByField(
      context,
      category,
      tableName: tableNameTransactionCategory,
      titleLocalize: apLocalizations.transactionCategoryDeleteDialogTitle,
      confirmLocalize: apLocalizations.transactionCategoryDeleteConfirm,
      successLocalize: apLocalizations.transactionCategoryDeleteSuccess,
      errorLocalize: apLocalizations.transactionCategoryDeleteError,
      onSuccess: () => refreshState(() => Util().removeInTree(categories, category)),
      onError: (e, over) {
        if (kDebugMode) {
          print("Error $e and $over");
        }
      },
    );
  }

  String retrieveAddPanelTitle(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    switch (transactionType) {
      case TransactionType.income:
        return appLocalizations.titleAddIncomeCategory;
      case TransactionType.expense:
        return appLocalizations.titleAddExpenseCategory;
      default:
        return appLocalizations.titleAddTransactionCategory;
    }
  }
}
