import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:income_expense_budget_plan/ui-common/add_transaction_category_form.dart';
import 'package:income_expense_budget_plan/ui-common/transaction_categories_panel.dart';
import 'package:provider/provider.dart';

class TransactionCategoryTree extends StatefulWidget {
  final Function(TransactionCategory item)? itemTap;
  final List<TransactionCategory> categories;
  final TransactionType transactionType;
  final FloatingActionButton? floatingActionButton;

  const TransactionCategoryTree(
      {required super.key, this.itemTap, required this.categories, required this.transactionType, this.floatingActionButton});

  @override
  State<TransactionCategoryTree> createState() => _TransactionCategoryTreeState();
}

class _TransactionCategoryTreeState extends State<TransactionCategoryTree> {
  // This controller is responsible for both providing your hierarchical data to tree views and also manipulate the states of your tree nodes.
  TreeController<TransactionCategory>? treeController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Remember to dispose your tree controller to release resources.
    treeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    treeController?.dispose();
    return ChangeNotifierProvider(
      create: (context) => TransactionCategoriesListenable(categoriesMap: {widget.transactionType: widget.categories}),
      builder: (BuildContext context, Widget? child) {
        TransactionCategoryHandler handler =
            TransactionCategoryHandler(categories: widget.categories, refreshState: setState, transactionType: widget.transactionType);
        treeController = TreeController<TransactionCategory>(
          // Provide the root nodes that will be used as a starting point when traversing your hierarchical data.
          roots: widget.categories,
          // Provide a callback for the controller to get the children of a given node when traversing your hierarchical data.
          // Avoid doing heavy computations in this method, it should behave like a getter.
          childrenProvider: (TransactionCategory category) => category.child,
          defaultExpansionState: true,
          parentProvider: (TransactionCategory node) => node.parent,
        );

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
                    categoriesMap: {widget.transactionType: transactionCategories.categoriesMap[widget.transactionType] ?? []},
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
            body: AnimatedTreeView<TransactionCategory>(
              duration: const Duration(seconds: 1),
              // This controller is used by tree views to build a flat representation of a tree structure so it can be lazy rendered by a SliverList.
              // It is also used to store and manipulate the different states of the tree nodes.
              treeController: treeController!,
              // Provide a widget builder callback to map your tree nodes into widgets.
              nodeBuilder: (BuildContext context, TreeEntry<TransactionCategory> entry) {
                var nodeObj = entry.node;
                // Provide a widget to display your tree nodes in the tree view.
                //
                // Can be any widget, just make sure to include a [TreeIndentation]
                // within its widget subtree to properly indent your tree nodes.
                return TreeDragTarget<TransactionCategory>(
                  node: entry.node,
                  onNodeAccepted: (TreeDragAndDropDetails<TransactionCategory> details) {
                    if (kDebugMode) {
                      print("Accepted $details");
                    }
                    var origin = details.draggedNode;
                    var target = details.targetNode;
                    if (details.draggedNode.parentUid != details.targetNode.parentUid) {
                      Util().showErrorDialog(context, AppLocalizations.of(context)!.transactionCategoryDragToInvalidTarget, () {});
                    } else {
                      Util().swapChildCategories(
                          allCategories: transactionCategories.categoriesMap[widget.transactionType] ?? [],
                          origin: origin,
                          target: target,
                          callback: () => treeController?.rebuild());
                    }
                  },
                  onWillAcceptWithDetails: (DragTargetDetails<TransactionCategory> details) {
                    if (kDebugMode) {
                      print("Details data [${details.data}] offset [${details.offset}]");
                    }
                    // Optionally make sure the target node is expanded so the dragging
                    // node is visible in its new vicinity when the tree gets rebuilt.
                    treeController!.setExpansionState(details.data, true);

                    return true;
                  },
                  onLeave: (TransactionCategory? data) {
                    if (data != null) {
                      treeController!.setExpansionState(data, false);
                    }
                  },
                  builder: (BuildContext context, TreeDragAndDropDetails? details) => TransactionCategoryTreeTile(
                    // Add a key to your tiles to avoid syncing descendant animations.
                    key: ValueKey(nodeObj),
                    // Your tree nodes are wrapped in TreeEntry instances when traversing the tree, these objects hold important details about its node
                    // relative to the tree, like: expansion state, level, parent, etc.
                    //
                    // TreeEntries are short lived, each time TreeController.rebuild is called, a new TreeEntry is created for each node so its properties
                    // are always up to date.
                    entry: entry,
                    // Add a callback to toggle the expansion state of this node.
                    onTap: () {
                      if (widget.itemTap != null) {
                        widget.itemTap!(nodeObj);
                      }
                      treeController!.toggleExpansion(nodeObj);
                    },
                    addPanelTitle: handler.retrieveAddPanelTitle(context),
                    removeCall: handler.showRemoveDialog,
                    transactionCategories: transactionCategories,
                    details: details,
                    editCallBack: _categoriesRefreshed,
                    transactionType: widget.transactionType,
                  ),
                  toggleExpansionOnHover: true,
                  canToggleExpansion: true,
                );
              },
            ),
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: SizedBox(height: 30, child: Container(color: theme.hoverColor)),
          );
        });
      },
    );
  }

  void _categoriesRefreshed(List<TransactionCategory> cats) {
    if (kDebugMode) {
      print("\nUpdating tree categories...\n${cats.length}\n");
    }
    setState(() {});
  }
}

// Create a widget to display the data held by your tree nodes.
class TransactionCategoryTreeTile extends StatelessWidget {
  final TreeEntry<TransactionCategory> entry;
  final VoidCallback onTap;
  final String addPanelTitle;
  final Function(BuildContext context, TransactionCategory category) removeCall;
  final TransactionCategoriesListenable transactionCategories;
  final TreeDragAndDropDetails? details;
  final Function(List<TransactionCategory> cats)? editCallBack;
  final TransactionType transactionType;

  const TransactionCategoryTreeTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.addPanelTitle,
    required this.removeCall,
    required this.transactionCategories,
    required this.details,
    this.editCallBack,
    required this.transactionType,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    var textLocalizeLanguage = entry.node.localizeNames[currentAppState.systemSetting.locale?.languageCode];
    var category = entry.node;
    String tileText;
    if (textLocalizeLanguage?.isNotEmpty == true) {
      tileText = textLocalizeLanguage!;
    } else {
      tileText = category.name;
    }
    if (category.child.isNotEmpty) {
      tileText += '(${category.child.length})';
    }
    Widget treeNodeTile = ListTile(
      leading: Icon(category.icon, color: theme.iconTheme.color),
      title: Text(tileText), // Title of the item
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: theme.primaryColor),
            onPressed: () => Util().navigateTo(
              context,
              ChangeNotifierProvider(
                create: (context) => TransactionCategoriesListenable(
                  categoriesMap: {transactionType: transactionCategories.categoriesMap[transactionType] ?? []},
                  customTriggerCallback: () => transactionCategories.triggerNotify(),
                ),
                builder: (context, child) => child!,
                child: AddTransactionCategoryPanel(
                    editingCategory: category, addPanelTitle: addPanelTitle, editCallback: editCallBack, transactionType: transactionType),
              ),
            ),
          ),
          if (!category.system)
            IconButton(icon: Icon(Icons.delete, color: theme.colorScheme.error), onPressed: () => removeCall(context, category)),
          const Icon(Icons.drag_handle),
        ],
      ),
    );

    // // If details is not null, a dragging tree node is hovering this
    // // drag target. Add some decoration to give feedback to the user.
    if (details != null) {
      treeNodeTile = ColoredBox(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        child: treeNodeTile,
      );
    }

    return TreeDraggable<TransactionCategory>(
      node: entry.node,

      // Show some feedback to the user under the dragging pointer,
      // this can be any widget.
      feedback: Material(
        // elevation: 4.0,
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 20,
          child: ListTile(
            leading: Icon(category.icon, color: theme.iconTheme.color), // Icon on the left
            title: Text(tileText),
          ),
        ),
      ),

      collapseOnDragStart: false,
      expandOnDragEnd: true,

      child: InkWell(
        onTap: onTap,
        child: TreeIndentation(
          entry: entry,
          // Provide an indent guide if desired. Indent guides can be used to add decorations to the indentation of tree nodes.
          // This could also be provided through a DefaultTreeIndentGuide inherited widget placed above the tree view.
          guide: const IndentGuide.connectingLines(indent: 46, padding: EdgeInsets.fromLTRB(0, 0, 0, 0)),
          // The widget to render next to the indentation. TreeIndentation respects the text direction of `Directionality.maybeOf(context)`
          // and defaults to left-to-right.
          child: treeNodeTile,
        ),
      ),
    );
  }
}
