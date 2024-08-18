import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:income_expense_budget_plan/common/transaction_categories_panel.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TransactionCategoryTree extends StatefulWidget {
  final Function(TransactionCategory item)? itemTap;
  final List<TransactionCategory> categories;
  final String addPanelTitle;
  final TransactionType transactionType;

  const TransactionCategoryTree(
      {super.key, this.itemTap, required this.categories, required this.transactionType, required this.addPanelTitle});

  @override
  State<TransactionCategoryTree> createState() => _TransactionCategoryTreeState();
}

class _TransactionCategoryTreeState extends State<TransactionCategoryTree> {
  // This controller is responsible for both providing your hierarchical data to tree views and also manipulate the states of your tree nodes.
  TreeController<TransactionCategory>? treeController;
  late List<TransactionCategory> _categories;

  @override
  void initState() {
    super.initState();
    _categories = widget.categories;
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
      create: (context) => TransactionCategoriesListenable(transactionType: widget.transactionType, categories: widget.categories),
      builder: (BuildContext context, Widget? child) {
        treeController = TreeController<TransactionCategory>(
          // Provide the root nodes that will be used as a starting point when traversing your hierarchical data.
          roots: widget.categories,
          // Provide a callback for the controller to get the children of a given node when traversing your hierarchical data.
          // Avoid doing heavy computations in this method, it should behave like a getter.
          childrenProvider: (TransactionCategory category) => category.child,
          defaultExpansionState: true,
          parentProvider: (TransactionCategory node) => node.parent,
        );
        // This package provides some different tree views to customize how your hierarchical data is incorporated into your app.
        // In this example, a TreeView is used which has no custom behaviors, if you wanted your tree nodes to animate in and out when the parent node is expanded
        // and collapsed, the AnimatedTreeView could be used instead.
        //
        // The tree view widgets also have a Sliver variant to make it easy to incorporate your hierarchical data in sophisticated scrolling
        // experiences.
        return Consumer<TransactionCategoriesListenable>(
          builder: (context, transactionCategories, child) => Scaffold(
            body: AnimatedTreeView<TransactionCategory>(
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
                        allCategories: transactionCategories.categories,
                        origin: origin,
                        target: target,
                        callback: () {
                          // Make sure to rebuild your tree view to show the reordered nodes
                          // in their new vicinity.
                          treeController?.rebuild();
                        },
                      );
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
                  builder: (BuildContext context, TreeDragAndDropDetails? details) => TransactionCategoryTile(
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
                    addPanelTitle: widget.addPanelTitle,
                    removeCall: _showRemoveDialog,
                    transactionCategories: transactionCategories,
                    details: details,
                    editCallBack: _categoriesRefreshed,
                  ),
                  toggleExpansionOnHover: true,
                  canToggleExpansion: true,
                );
              },
            ),
            floatingActionButton: FloatingActionButton(
              foregroundColor: colorScheme.primary,
              backgroundColor: theme.iconTheme.color,
              shape: const CircleBorder(),
              onPressed: () => Util().navigateTo(
                context,
                ChangeNotifierProvider(
                  create: (context) => TransactionCategoriesListenable(
                    transactionType: transactionCategories.transactionType,
                    categories: transactionCategories.categories,
                    customTriggerCallback: () => transactionCategories.triggerNotify(),
                  ),
                  builder: (context, child) => child!,
                  child: AddTransactionCategoryPanel(
                    addPanelTitle: widget.addPanelTitle,
                    editCallback: (cats) => setState(() {}),
                  ),
                ),
              ),
              child: const Icon(Icons.add),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: SizedBox(
              height: 30,
              child: Container(color: theme.hoverColor),
            ),
          ),
        );
      },
    );
  }

  void _categoriesRefreshed(List<TransactionCategory> cats) {
    if (kDebugMode) {
      print("\nUpdating tree categories...\n$cats\n");
    }
    setState(() {});
  }

  void _showRemoveDialog(BuildContext context, TransactionCategory category) {
    Util().showRemoveDialogByField(context, category,
        tableName: tableNameTransactionCategory,
        titleLocalize: AppLocalizations.of(context)!.transactionCategoryDeleteDialogTitle,
        confirmLocalize: AppLocalizations.of(context)!.transactionCategoryDeleteConfirm,
        successLocalize: AppLocalizations.of(context)!.transactionCategoryDeleteSuccess,
        errorLocalize: AppLocalizations.of(context)!.transactionCategoryDeleteError,
        onSuccess: () => setState(() => Util().removeInTree(_categories, category)),
        onError: (e, over) {
          if (kDebugMode) {
            print("Error $e and $over");
          }
        });
  }
}

// Create a widget to display the data held by your tree nodes.
class TransactionCategoryTile extends StatelessWidget {
  final TreeEntry<TransactionCategory> entry;
  final VoidCallback onTap;
  final String addPanelTitle;
  final Function(BuildContext context, TransactionCategory category) removeCall;
  final TransactionCategoriesListenable transactionCategories;
  final TreeDragAndDropDetails? details;
  final Function(List<TransactionCategory> cats)? editCallBack;

  const TransactionCategoryTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.addPanelTitle,
    required this.removeCall,
    required this.transactionCategories,
    required this.details,
    this.editCallBack,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    var textLocalizeLanguage = entry.node.localizeNames[currentAppState.systemSettings.locale?.languageCode];
    var category = entry.node;
    String tileText;
    if (textLocalizeLanguage?.isNotEmpty == true) {
      tileText = textLocalizeLanguage!;
    } else {
      tileText = category.name;
    }
    if (entry.node.child.isNotEmpty) {
      tileText += '(${entry.node.child.length})';
    }
    Widget treeNodeTile = ListTile(
      leading: Icon(category.icon, color: theme.iconTheme.color), // Icon on the left
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
                  transactionType: transactionCategories.transactionType,
                  categories: transactionCategories.categories,
                  customTriggerCallback: () => transactionCategories.triggerNotify(),
                ),
                builder: (context, child) => child!,
                child: AddTransactionCategoryPanel(editingCategory: category, addPanelTitle: addPanelTitle, editCallback: editCallBack),
              ),
            ),
          ),
          if (!category.system)
            IconButton(icon: Icon(Icons.delete, color: theme.colorScheme.error), onPressed: () => removeCall(context, category)),
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
      feedback: IntrinsicWidth(
        child: Material(elevation: 4, child: treeNodeTile),
      ),

      child: InkWell(
        onTap: onTap,
        child: TreeIndentation(
          entry: entry,
          // Provide an indent guide if desired. Indent guides can be used to add decorations to the indentation of tree nodes.
          // This could also be provided through a DefaultTreeIndentGuide inherited widget placed above the tree view.
          guide: const IndentGuide.connectingLines(indent: 48, padding: EdgeInsets.fromLTRB(0, 0, 0, 0)),
          // The widget to render next to the indentation. TreeIndentation respects the text direction of `Directionality.maybeOf(context)`
          // and defaults to left-to-right.
          child: treeNodeTile,
        ),
      ),
    );
  }
}
