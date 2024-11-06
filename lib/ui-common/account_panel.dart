import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:income_expense_budget_plan/ui-common/add_account_form.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

abstract class AccountPanel extends StatefulWidget {
  final Function(Asset item)? accountTap;
  final FloatingActionButton? floatingButton;
  const AccountPanel({super.key, this.accountTap, this.floatingButton});
}

abstract class AccountPanelState<T extends AccountPanel> extends State<T> {
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

  Widget buildUi(BuildContext context, AppLocalizations appLocalizations, List<Asset> accounts, List<AssetCategory> categories);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    var appState = Provider.of<AppState>(context, listen: true);
    List<Asset> assets = appState.assets.map((a) => a).toList(growable: true);
    List<AssetCategory> categories = appState.assetCategories.map((c) {
      c.assets.clear();
      util.findCategoryChild(assets, c);
      return c;
    }).toList(growable: true);
    categories.sort((a, b) {
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
    });
    if (kDebugMode) {
      if (categories.isNotEmpty) {
        print("\nCategories: $categories\n Child: ${categories[0].assets}\n");
      } else {
        print("\nCategories: $categories\n");
      }
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
    return Scaffold(
      appBar: AppBar(title: Text(appLocalizations.titleAccount)),
      body: buildUi(context, appLocalizations, assets, categories),
      floatingActionButton: floatingButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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

  void showRemoveDialog(BuildContext context, Asset account) {
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

  void assetRefreshed(List<Asset> assets, bool isNew) => _reloadAssets();

  void assetCategoriesRefreshed(List<AssetCategory> cats, bool isNew) => _reloadAssets();
}
