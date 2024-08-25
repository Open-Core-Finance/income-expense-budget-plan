import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:income_expense_budget_plan/common/add_account_form.dart';
import 'package:income_expense_budget_plan/common/assets_categories_panel.dart';
import 'package:income_expense_budget_plan/dao/assets_dao.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/v8.dart';

class AccountPanel extends StatefulWidget {
  const AccountPanel({super.key});

  @override
  State<AccountPanel> createState() => _AccountPanelState();
}

class _AccountPanelState extends State<AccountPanel> {
  TreeController<AssetTreeNode>? treeController;
  List<AssetTreeNode> categories = [];

  @override
  void initState() {
    super.initState();
    if (currentAppState.assetCategories.isEmpty) {
      Util().refreshAssetCategories(_reloadAssets);
    } else {
      _reloadAssets(currentAppState.assetCategories);
    }
  }

  void _reloadAssets(List<AssetCategory> categories) {
    for (var category in categories) {
      category.assets.removeRange(0, category.assets.length);
    }
    Util().refreshAssets((List<Assets> assets) {
      Util().mappingAssetsAndCategories(assets, categories);
      this.categories = [];
      this.categories.addAll(categories);
      setState(() => this.categories.sort((a, b) {
            var assets1 = (a as AssetCategory).assets;
            var assets2 = (b as AssetCategory).assets;
            var result = assets2.length - assets1.length;
            if (result == 0) {
              return a.positionIndex - b.positionIndex;
            } else {
              return result;
            }
          }));
    });
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
    final String accountTitle = AppLocalizations.of(context)!.titleAccount;
    if (kDebugMode) {
      if (categories.isNotEmpty) {
        print("\nCategories: $categories\n Child: ${(categories[0] as AssetCategory).assets}\n");
      } else {
        print("\nCategories: $categories\n");
      }
    }
    treeController?.dispose();
    return Consumer<AppState>(
      builder: (context, appState, child) {
        treeController = TreeController<AssetTreeNode>(
          // Provide the root nodes that will be used as a starting point when traversing your hierarchical data.
          roots: categories,
          // Provide a callback for the controller to get the children of a given node when traversing your hierarchical data.
          // Avoid doing heavy computations in this method, it should behave like a getter.
          childrenProvider: (AssetTreeNode category) {
            if (category is AssetCategory) {
              return category.assets;
            } else {
              return [];
            }
          },
          defaultExpansionState: true,
          parentProvider: (AssetTreeNode node) {
            if (node is Assets) {
              return node.category;
            } else {
              return null;
            }
          },
        );
        return Scaffold(
          appBar: AppBar(title: Text(accountTitle)),
          body: AnimatedTreeView<AssetTreeNode>(
            treeController: treeController!,
            nodeBuilder: (BuildContext context, TreeEntry<AssetTreeNode> entry) {
              var nodeObj = entry.node;
              // Provide a widget to display your tree nodes in the tree view.
              //
              // Can be any widget, just make sure to include a [TreeIndentation]
              // within its widget subtree to properly indent your tree nodes.
              return TreeDragTarget<AssetTreeNode>(
                node: entry.node,
                onNodeAccepted: (TreeDragAndDropDetails<AssetTreeNode> details) {
                  if (kDebugMode) {
                    print("Accepted $details");
                  }
                  var origin = details.draggedNode;
                  treeController!.setExpansionState(origin, true);
                  var target = details.targetNode;
                  treeController!.setExpansionState(target, true);
                  if (target is AssetCategory) {
                    var originAsset = (origin as Assets);
                    var originCat = originAsset.category;
                    if (originCat?.id != target.id) {
                      _switchAssetCat(originAsset, originCat!, target, () => setState(() {}));
                    }
                  } else {
                    var originAsset = (origin as Assets);
                    var targetAsset = (target as Assets);
                    var originCat = originAsset.category;
                    var targetCat = targetAsset.category;
                    if (originCat?.id != targetCat?.id) {
                      _switchAssetCat(originAsset, originCat!, targetCat!, () {
                        Util()
                            .swapAssetNode(parentCat: targetCat, origin: originAsset, target: targetAsset, callback: () => setState(() {}));
                      });
                    } else {
                      Util()
                          .swapAssetNode(parentCat: targetCat!, origin: originAsset, target: targetAsset, callback: () => setState(() {}));
                    }
                  }
                },
                onWillAcceptWithDetails: (DragTargetDetails<AssetTreeNode> details) {
                  if (kDebugMode) {
                    print("Details data [${details.data}] offset [${details.offset}]");
                  }
                  // Optionally make sure the target node is expanded so the dragging
                  // node is visible in its new vicinity when the tree gets rebuilt.
                  treeController!.setExpansionState(details.data, true);

                  return true;
                },
                onLeave: (AssetTreeNode? data) {
                  if (data != null) {
                    treeController!.setExpansionState(data, true);
                  }
                },
                builder: (BuildContext context, TreeDragAndDropDetails? details) => AssetTreeNodeTile(
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
                    treeController!.toggleExpansion(nodeObj);
                  },
                  removeCall: _showRemoveDialog,
                  details: details,
                  editCallBack: _assetRefreshed,
                  editCategoryCallBack: _assetCategoriesRefreshed,
                ),
                toggleExpansionOnHover: true,
                canToggleExpansion: true,
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            foregroundColor: colorScheme.primary,
            backgroundColor: colorScheme.surface,
            shape: const CircleBorder(),
            onPressed: () => Util().navigateTo(context, const AddAccountForm()),
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  void _switchAssetCat(Assets originAsset, AssetCategory originCat, AssetCategory targetCategory, Function? callback) {
    originCat.assets.remove(originAsset);
    originAsset.category = targetCategory;
    originAsset.categoryUid = targetCategory.id!;
    originAsset.positionIndex = targetCategory.assets.length;
    targetCategory.assets.add(originAsset);
    DatabaseService().database.then((db) {
      var f = db.update(tableNameAssets, originAsset.toMap(),
          where: "uid = ?", whereArgs: [originAsset.id], conflictAlgorithm: ConflictAlgorithm.replace);
      f.then((_) {
        if (callback != null) callback();
      });
    });
  }

  void _showRemoveDialog(BuildContext context, Assets category) {
    Util().showRemoveDialogByField(context, category,
        tableName: tableNameTransactionCategory,
        titleLocalize: AppLocalizations.of(context)!.accountDeleteDialogTitle,
        confirmLocalize: AppLocalizations.of(context)!.accountDeleteConfirm,
        successLocalize: AppLocalizations.of(context)!.accountDeleteSuccess,
        errorLocalize: AppLocalizations.of(context)!.accountDeleteError,
        onSuccess: () => setState(() => Util().removeInAccountTree(currentAppState.assetCategories, category)),
        onError: (e, over) {
          if (kDebugMode) {
            print("Error $e and $over");
          }
        });
  }

  void _assetRefreshed(List<Assets> assets, bool isNew) {
    _reloadAssets(currentAppState.assetCategories);
  }

  void _assetCategoriesRefreshed(List<AssetCategory> cats, bool isNew) {
    _reloadAssets(cats);
  }
}

// Create a widget to display the data held by your tree nodes.
class AssetTreeNodeTile extends StatelessWidget {
  final TreeEntry<AssetTreeNode> entry;
  final VoidCallback onTap;
  final Function(BuildContext context, Assets category) removeCall;
  final TreeDragAndDropDetails? details;
  final Function(List<Assets> cats, bool isAddNew)? editCallBack;
  final Function(List<AssetCategory> cats, bool isAddNew)? editCategoryCallBack;

  const AssetTreeNodeTile(
      {super.key,
      required this.entry,
      required this.onTap,
      required this.removeCall,
      required this.details,
      this.editCallBack,
      this.editCategoryCallBack});

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
    Widget? subTitle;
    if (category is AssetCategory && category.assets.isEmpty) subTitle = Text(AppLocalizations.of(context)!.accountCategoryEmpty);
    Widget treeNodeTile = InkWell(
      onTap: onTap,
      child: TreeIndentation(
        entry: entry,
        // Provide an indent guide if desired. Indent guides can be used to add decorations to the indentation of tree nodes.
        // This could also be provided through a DefaultTreeIndentGuide inherited widget placed above the tree view.
        guide: const IndentGuide.connectingLines(indent: 48, padding: EdgeInsets.fromLTRB(0, 0, 0, 0)),
        // The widget to render next to the indentation. TreeIndentation respects the text direction of `Directionality.maybeOf(context)`
        // and defaults to left-to-right.
        child: ListTile(
          leading: Icon(category.icon, color: theme.iconTheme.color), // Icon on the left
          title: Text(tileText),
          subtitle: subTitle,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: theme.primaryColor),
                onPressed: () {
                  if (category is Assets) {
                    Util().navigateTo(context, AddAccountForm(editingAssets: category, editCallback: editCallBack));
                  } else {
                    Util().navigateTo(
                      context,
                      AddAssetsCategoryPanel(editingCategory: category as AssetCategory, editCallback: editCategoryCallBack),
                    );
                  }
                },
              ),
              if (category is Assets) ...[
                IconButton(icon: Icon(Icons.delete, color: theme.colorScheme.error), onPressed: () => removeCall(context, category)),
                const Icon(Icons.drag_handle)
              ],
              if (category is AssetCategory)
                IconButton(icon: const Icon(Icons.tune), onPressed: () => Util().navigateTo(context, const AssetsCategoriesPanel()))
            ],
          ),
        ),
      ),
    );

    // If details is not null, a dragging tree node is hovering this
    // drag target. Add some decoration to give feedback to the user.
    if (details != null) {
      treeNodeTile = ColoredBox(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        child: treeNodeTile,
      );
    }

    if (entry.node is Assets) {
      return TreeDraggable<AssetTreeNode>(
        node: entry.node,

        // Show some feedback to the user under the dragging pointer,
        // this can be any widget.
        feedback: Material(
          elevation: 4.0,
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 20,
            child: ListTile(
                leading: Icon(category.icon, color: theme.iconTheme.color), // Icon on the left
                title: Text(tileText)),
          ),
        ),

        collapseOnDragStart: false,
        expandOnDragEnd: true,

        child: treeNodeTile,
      );
    } else {
      return treeNodeTile;
    }
  }
}
