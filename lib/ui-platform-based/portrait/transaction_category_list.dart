import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:income_expense_budget_plan/ui-common/add_transaction_category_form.dart';
import 'package:income_expense_budget_plan/ui-common/transaction_categories_panel.dart';
import 'package:provider/provider.dart';

class TransactionCategoriesList extends StatefulWidget {
  final Function(TransactionCategory item)? itemTap;
  final List<TransactionCategory> categories;
  final TransactionType transactionType;
  final FloatingActionButton? floatingActionButton;

  const TransactionCategoriesList(
      {required super.key, this.itemTap, required this.categories, required this.transactionType, this.floatingActionButton});

  @override
  State<TransactionCategoriesList> createState() => _TransactionCategoriesListState();
}

class _TransactionCategoriesListState extends State<TransactionCategoriesList> {
  final Util util = Util();

  void _categoriesRefreshed(List<TransactionCategory> cats, bool addNew) {
    if (kDebugMode) {
      print("\nUpdating tree categories...\n${cats.length}\n");
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);
    var colorScheme = theme.colorScheme;
    List<TransactionCategory> categories = widget.categories;
    TransactionCategoryHandler handler =
        TransactionCategoryHandler(categories: widget.categories, refreshState: setState, transactionType: widget.transactionType);
    List<Widget> widgets = [];
    for (var category in categories) {
      widgets.add(_categoryDisplay(context, theme, appLocalizations, appState, category, _categoriesRefreshed, false, handler));
      List<TransactionCategory> child = category.child;
      for (var c in child) {
        widgets.add(_categoryDisplay(context, theme, appLocalizations, appState, c, _categoriesRefreshed, true, handler));
      }
    }
    widgets.add(SizedBox(height: 30));

    return Consumer<TransactionCategoriesListenable>(builder: (context, transactionCategories, child) {
      FloatingActionButton floatingActionButton;
      if (widget.floatingActionButton != null) {
        floatingActionButton = widget.floatingActionButton!;
      } else {
        floatingActionButton = FloatingActionButton(
          foregroundColor: colorScheme.primary,
          backgroundColor: theme.iconTheme.color,
          shape: const CircleBorder(),
          heroTag: "${widget.key.toString()}-Add-transaction-categories-Button",
          onPressed: () => Util().navigateTo(
            context,
            ChangeNotifierProvider(
              create: (context) => TransactionCategoriesListenable(
                categoriesMap: {widget.transactionType: widget.categories},
                customTriggerCallback: () => transactionCategories.triggerNotify(),
              ),
              builder: (context, child) => child!,
              child: AddTransactionCategoryPanel(
                  addPanelTitle: handler.retrieveAddPanelTitle(context),
                  editCallback: (cats) => setState(() {}),
                  transactionType: widget.transactionType),
            ),
          ),
          child: const Icon(Icons.add),
        );
      }
      return Scaffold(
        body: ListView(children: widgets),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: SizedBox(height: 30, child: Container(color: theme.hoverColor)),
      );
    });
  }

  Widget _categoryDisplay(
    BuildContext context,
    ThemeData theme,
    AppLocalizations appLocalizations,
    AppState appState,
    TransactionCategory category,
    Function(List<TransactionCategory> cats, bool isAddNew)? editCategoryCallBack,
    bool isChild,
    TransactionCategoryHandler handler,
  ) {
    return Consumer<TransactionCategoriesListenable>(
      builder: (context, transactionCategories, child) {
        return TransactionCategoryListTile(
          category: category,
          onTap: widget.itemTap,
          addPanelTitle: handler.retrieveAddPanelTitle(context),
          removeCall: handler.showRemoveDialog,
          transactionCategories: transactionCategories,
          transactionType: widget.transactionType,
          isChild: isChild,
          disableEdit: false,
        );
      },
    );
  }
}

// Create a widget to display the data held by your tree nodes.
class TransactionCategoryListTile extends StatelessWidget {
  final TransactionCategory category;
  final Function(TransactionCategory category)? onTap;
  final String addPanelTitle;
  final Function(BuildContext context, TransactionCategory category) removeCall;
  final TransactionCategoriesListenable transactionCategories;
  final Function(List<TransactionCategory> cats)? editCallBack;
  final TransactionType transactionType;
  final bool isChild;
  final bool disableEdit;

  const TransactionCategoryListTile({
    super.key,
    required this.category,
    this.onTap,
    required this.addPanelTitle,
    required this.removeCall,
    required this.transactionCategories,
    this.editCallBack,
    required this.transactionType,
    String? subTitle,
    required this.isChild,
    required this.disableEdit,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    Util util = Util();
    String tileText = category.getTitleText(currentAppState.systemSetting);
    if (category.child.isNotEmpty) {
      tileText += '(${category.child.length})';
    }
    Widget? leading;
    if (!isChild) {
      leading = Icon(category.icon, color: theme.iconTheme.color);
    } else {
      leading = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 58),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: 20, child: VerticalDivider(thickness: 2, color: theme.dividerColor, endIndent: 0, indent: 0)),
            const Text("---", style: TextStyle(fontSize: 10), textAlign: TextAlign.left),
            Icon(category.icon, color: theme.iconTheme.color),
            SizedBox(width: 2),
          ],
        ),
      );
    }
    Widget title = Text(tileText);
    Widget? trailing;
    if (!category.system && disableEdit != true) {
      trailing = IconButton(icon: Icon(Icons.delete, color: theme.colorScheme.error), onPressed: () => removeCall(context, category));
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
          onTap: () {
            if (onTap != null) {
              onTap!(category);
            } else if (disableEdit != true) {
              util.navigateTo(
                context,
                ChangeNotifierProvider(
                  create: (context) => TransactionCategoriesListenable(
                    categoriesMap: {transactionType: transactionCategories.categoriesMap[transactionType] ?? []},
                    customTriggerCallback: () => transactionCategories.triggerNotify(),
                  ),
                  builder: (context, child) => child!,
                  child: AddTransactionCategoryPanel(
                      editingCategory: category,
                      addPanelTitle: addPanelTitle,
                      editCallback: editCallBack,
                      transactionType: transactionType),
                ),
              );
            }
          },
          child: ListTile(leading: leading, title: title, trailing: trailing)),
    );
  }
}
