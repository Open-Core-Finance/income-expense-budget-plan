import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/common/add_account_form.dart';
import 'package:income_expense_budget_plan/common/assets_categories_panel.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

class AccountPanel extends StatefulWidget {
  final Function(Asset item)? accountTap;
  const AccountPanel({super.key, this.accountTap});

  @override
  State<AccountPanel> createState() => _AccountPanelState();
}

class _AccountPanelState extends State<AccountPanel> {
  TreeController<AssetTreeNode>? treeController;
  final Util util = Util();

  @override
  void initState() {
    super.initState();
    var appState = currentAppState;
    if (appState.assetCategories.isEmpty) {
      util.refreshAssetCategories((cats) {
        _reloadAssets();
      });
    } else {
      _reloadAssets();
    }
  }

  void _reloadAssets() {
    if (kDebugMode) {
      print("Reload assets");
    }

    util.refreshAssets((List<Asset> assets) {
      if (kDebugMode) {
        print("Assets loaded: $assets");
      }
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
    var util = Util();
    final ThemeData theme = Theme.of(context);
    final String accountTitle = AppLocalizations.of(context)!.titleAccount;
    var appState = Provider.of<AppState>(context, listen: true);
    List<Asset> assets = appState.assets.map((a) => a).toList(growable: true);
    List<AssetTreeNode> categories = appState.assetCategories.map((c) {
      c.assets.clear();
      util.findCategoryChild(assets, c);
      return (c as AssetTreeNode);
    }).toList(growable: true);
    categories.sort((a, b) {
      int assets1Size = (a is AssetCategory) ? a.assets.length : 0;
      int assets2Size = (b is AssetCategory) ? b.assets.length : 0;
      int result;
      if (assets1Size > 0) {
        result = assets2Size > 0 ? 0 : -1;
      } else {
        result = assets2Size > 0 ? 1 : 0;
      }
      if (result != 0) {
        return result;
      } else {
        return a.positionIndex - b.positionIndex;
      }
    });
    if (kDebugMode) {
      if (categories.isNotEmpty) {
        print("\nCategories: $categories\n Child: ${(categories[0] as AssetCategory).assets}\n");
      } else {
        print("\nCategories: $categories\n");
      }
    }
    treeController?.dispose();
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
        if (node is Asset) {
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
                var originAsset = (origin as Asset);
                var originCat = originAsset.category;
                if (originCat?.id != target.id) {
                  _switchAssetCat(originAsset, originCat!, target, () => setState(() {}));
                }
              } else {
                var originAsset = (origin as Asset);
                var targetAsset = (target as Asset);
                var originCat = originAsset.category;
                var targetCat = targetAsset.category;
                if (originCat?.id != targetCat?.id) {
                  _switchAssetCat(originAsset, originCat!, targetCat!, () {
                    util.swapAssetNode(parentCat: targetCat, origin: originAsset, target: targetAsset, callback: () => setState(() {}));
                  });
                } else {
                  util.swapAssetNode(parentCat: targetCat!, origin: originAsset, target: targetAsset, callback: () => setState(() {}));
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
                if (widget.accountTap != null && nodeObj is Asset) {
                  widget.accountTap!(nodeObj);
                }
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
        foregroundColor: theme.primaryColor,
        backgroundColor: theme.iconTheme.color,
        shape: const CircleBorder(),
        onPressed: () => util.navigateTo(
            context,
            AddAccountForm(
              editCallback: _assetRefreshed,
            )),
        heroTag: "Add-Account-Button",
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _switchAssetCat(Asset originAsset, AssetCategory originCat, AssetCategory targetCategory, Function? callback) {
    originCat.assets.remove(originAsset);
    originAsset.category = targetCategory;
    originAsset.categoryUid = targetCategory.id!;
    originAsset.positionIndex = targetCategory.assets.length;
    targetCategory.assets.add(originAsset);
    DatabaseService().database.then((db) {
      var f = db.update(tableNameAsset, originAsset.toMap(),
          where: "uid = ?", whereArgs: [originAsset.id], conflictAlgorithm: ConflictAlgorithm.replace);
      f.then((_) {
        if (callback != null) callback();
      });
    });
  }

  void _showRemoveDialog(BuildContext context, Asset account) {
    util.showRemoveDialogByField(context, account,
        tableName: tableNameAsset,
        titleLocalize: AppLocalizations.of(context)!.accountDeleteDialogTitle,
        confirmLocalize: AppLocalizations.of(context)!.accountDeleteConfirm,
        successLocalize: AppLocalizations.of(context)!.accountDeleteSuccess,
        errorLocalize: AppLocalizations.of(context)!.accountDeleteError,
        onSuccess: _reloadAssets, onError: (e, over) {
      if (kDebugMode) {
        print("Error $e and $over");
      }
    });
  }

  void _assetRefreshed(List<Asset> assets, bool isNew) => _reloadAssets();

  void _assetCategoriesRefreshed(List<AssetCategory> cats, bool isNew) => _reloadAssets();
}

// Create a widget to display the data held by your tree nodes.
class AssetTreeNodeTile extends StatelessWidget {
  final TreeEntry<AssetTreeNode> entry;
  final VoidCallback onTap;
  final Function(BuildContext context, Asset category) removeCall;
  final TreeDragAndDropDetails? details;
  final Function(List<Asset> cats, bool isAddNew)? editCallBack;
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
    final appState = Provider.of<AppState>(context);
    final Util util = Util();
    var category = entry.node;
    String tileText = category.getTitleText(appState.systemSetting);
    Widget? subTitle;
    if (category is AssetCategory) {
      if (category.assets.isEmpty) {
        subTitle = Text(AppLocalizations.of(context)!.accountCategoryEmpty);
      }
    } else if (category is Asset) {
      subTitle = category.getAmountDisplayText();
    }
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
                  if (category is Asset) {
                    util.navigateTo(context, AddAccountForm(editingAsset: category, editCallback: editCallBack));
                  } else {
                    util.navigateTo(
                        context, AddAssetCategoryForm(editingCategory: category as AssetCategory, editCallback: editCategoryCallBack));
                  }
                },
              ),
              if (category is Asset) ...[
                IconButton(icon: Icon(Icons.delete, color: theme.colorScheme.error), onPressed: () => removeCall(context, category)),
                const Icon(Icons.drag_handle)
              ],
              if (category is AssetCategory)
                IconButton(icon: const Icon(Icons.tune), onPressed: () => util.navigateTo(context, const AssetCategoriesPanel()))
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

    if (entry.node is Asset) {
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
