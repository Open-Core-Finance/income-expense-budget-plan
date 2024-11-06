import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:income_expense_budget_plan/ui-common/account_panel.dart';
import 'package:income_expense_budget_plan/ui-common/add_account_form.dart';
import 'package:income_expense_budget_plan/ui-common/assets_categories_panel.dart';
import 'package:provider/provider.dart';

class AccountPanelLandscape extends AccountPanel {
  const AccountPanelLandscape({super.key, super.accountTap, super.floatingButton});

  @override
  State<AccountPanelLandscape> createState() => _AccountPanelLandscapeState();
}

class _AccountPanelLandscapeState extends AccountPanelState<AccountPanelLandscape> {
  TreeController<AssetTreeNode>? treeController;

  @override
  void dispose() {
    // Remember to dispose your tree controller to release resources.
    treeController?.dispose();
    super.dispose();
  }

  @override
  Widget buildUi(BuildContext context, AppLocalizations appLocalizations, List<Asset> accounts, List<AssetTreeNode> categories) {
    treeController?.dispose();
    treeController = TreeController<AssetTreeNode>(
      // Provide the root nodes that will be used as a starting point when traversing your hierarchical data.
      roots: categories,
      // Provide a callback for the controller to get the children of a given node when traversing your hierarchical data.
      // Avoid doing heavy computations in this method, it should behave like a getter.
      childrenProvider: (AssetTreeNode category) => (category is AssetCategory) ? category.assets : [],
      defaultExpansionState: true,
      parentProvider: (AssetTreeNode node) => (node is Asset) ? node.category : null,
    );
    return AnimatedTreeView<AssetTreeNode>(
      duration: const Duration(seconds: 1),
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
                switchAssetCat(originAsset, originCat!, target, () => setState(() {}));
              }
            } else {
              var originAsset = (origin as Asset);
              var targetAsset = (target as Asset);
              var originCat = originAsset.category;
              var targetCat = targetAsset.category;
              if (originCat?.id != targetCat?.id) {
                switchAssetCat(originAsset, originCat!, targetCat!, () {
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
            removeCall: showRemoveDialog,
            details: details,
            editCallBack: assetRefreshed,
            editCategoryCallBack: assetCategoriesRefreshed,
          ),
          toggleExpansionOnHover: true,
          canToggleExpansion: true,
        );
      },
    );
  }
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
    Util util = Util();
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
        guide: const IndentGuide.connectingLines(indent: 36, padding: EdgeInsets.fromLTRB(0, 0, 0, 0)),
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
