import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/service/account_service.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:income_expense_budget_plan/ui-common/add_account_form.dart';
import 'package:income_expense_budget_plan/ui-common/assets_categories_panel.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

abstract class AccountPanel extends StatefulWidget {
  final Function(Asset item)? accountTap;
  final FloatingActionButton? floatingButton;
  final bool showDeleted;
  const AccountPanel({super.key, this.accountTap, this.floatingButton, required this.showDeleted});
}

abstract class AccountPanelState<T extends AccountPanel> extends State<T> {
  final Util util = Util();
  final AccountService accountService = AccountService();

  @override
  void initState() {
    super.initState();
    var appState = currentAppState;
    if (appState.assetCategories.isEmpty) {
      accountService.refreshAssetCategories((cats) => accountService.refreshAssets());
    } else {
      accountService.refreshAssets();
    }
  }

  AssetCategory _categoryMapping(AssetCategory c, List<Asset> assets) {
    c.assets.clear();
    util.findCategoryChild(assets, c);
    return c;
  }

  int _categorySort(AssetCategory a, AssetCategory b) {
    int assets1Size = a.assets.length;
    int assets2Size = b.assets.length;
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
  }

  Widget buildUi(BuildContext context, AppLocalizations appLocalizations, List<Asset> accounts, List<AssetCategory> categories,
      List<AssetCategory> deletedCategories, bool showTab);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    var appState = Provider.of<AppState>(context, listen: true);
    List<Asset> assets = appState.assets.map((a) => a).toList(growable: true);

    List<AssetCategory> categories = appState.assetCategories
        .where((category) => category.deleted != true)
        .map((c) => _categoryMapping(c, assets))
        .toList(growable: true);
    final List<AssetCategory> deletedCategories = appState.assetCategories
        .where((category) => category.deleted == true)
        .map((c) => _categoryMapping(c, assets))
        .toList(growable: true);
    bool showTab = widget.showDeleted && deletedCategories.isNotEmpty;
    categories.sort(_categorySort);
    if (kDebugMode) {
      print("\nShow deleted category tab: $showTab\n");
    }
    Widget floatingButton;
    if (widget.floatingButton != null) {
      floatingButton = widget.floatingButton!;
    } else {
      floatingButton = FloatingActionButton(
        foregroundColor: theme.primaryColor,
        backgroundColor: theme.iconTheme.color,
        shape: const CircleBorder(),
        onPressed: () => util.navigateTo(context, AddAccountForm(editCallback: assetRefreshed)),
        heroTag: "Add-Account-Button",
        child: const Icon(Icons.add),
      );
    }
    var scaffold = Scaffold(
      appBar:
          AppBar(title: Text(appLocalizations.titleAccount), bottom: topTabBar(theme, appState, categories, deletedCategories, showTab)),
      body: buildUi(context, appLocalizations, assets, categories, deletedCategories, showTab),
      floatingActionButton: floatingButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
    if (!showTab) {
      return scaffold;
    } else {
      return DefaultTabController(length: 2, child: scaffold);
    }
  }

  PreferredSizeWidget? topTabBar(
      ThemeData theme, AppState appState, List<AssetCategory> categories, List<AssetCategory> deletedCategories, bool showTab) {
    if (!showTab) return null;
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return TabBar(
      tabs: <Widget>[
        Tab(icon: Icon(Icons.category, color: Colors.blue), text: appLocalizations.accountCategoryActivatedList),
        Tab(icon: Icon(Icons.delete, color: Colors.red), text: appLocalizations.accountCategoryDeletedList)
      ],
    );
  }

  void switchAssetCat(Asset originAsset, AssetCategory originCat, AssetCategory targetCategory, Function? callback) {
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

  void assetRefreshed(List<Asset> assets, bool isNew) => accountService.refreshAssets();

  void assetCategoriesRefreshed(List<AssetCategory> cats, bool isNew) => accountService.refreshAssets();

  List<Widget> categoryTrailingButtons(AssetCategory category, ThemeData theme) {
    var manageIcon = IconButton(
        icon: const Icon(Icons.tune), onPressed: () => util.navigateTo(context, AssetCategoriesPanel(showDeleted: widget.showDeleted)));
    IconButton actionIcon;
    if (category.deleted) {
      actionIcon = IconButton(
          icon: Icon(Icons.restore, color: Colors.green),
          onPressed: () => accountService.showRestoreCategoryDialog(context, category,
              onSuccess: () => accountService.refreshAssetCategories((cats) => accountService.refreshAssets())));
    } else {
      actionIcon = IconButton(
          icon: Icon(Icons.delete, color: theme.colorScheme.error),
          onPressed: () => accountService.showRemoveCategoryDialog(context, category,
              onSuccess: () => accountService.refreshAssetCategories((cats) => accountService.refreshAssets())));
    }
    return [actionIcon, manageIcon];
  }

  Widget assetTrailingButton(Asset asset, ThemeData theme) {
    IconButton actionIcon;
    if (asset.deleted) {
      actionIcon = IconButton(
        icon: Icon(Icons.restore, color: Colors.green),
        onPressed: () => AccountService().showRestoreDialog(context, asset,
            onSuccess: () => accountService.refreshAssetCategories((cats) => accountService.refreshAssets())),
      );
    } else {
      actionIcon = IconButton(
        icon: Icon(Icons.delete, color: theme.colorScheme.error),
        onPressed: () => AccountService().showRemoveDialog(context, asset,
            onSuccess: () => accountService.refreshAssetCategories((cats) => accountService.refreshAssets())),
      );
    }
    return actionIcon;
  }
}
