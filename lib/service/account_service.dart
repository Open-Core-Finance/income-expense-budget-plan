import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/dao/assets_dao.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/transaction.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/statistic.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:sqflite/sqflite.dart';

class AccountService {
  // Singleton pattern
  static final AccountService _service = AccountService._internal();
  factory AccountService() => _service;
  AccountService._internal();

  Util util = Util();

  void showRemoveDialog(BuildContext context, Asset account, {Function? onSuccess, Function? onError}) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    util.showRemoveDialogByField(
      context,
      account,
      tableName: tableNameAsset,
      titleLocalize: appLocalizations.accountDeleteDialogTitle,
      confirmLocalize: appLocalizations.accountDeleteConfirm,
      successLocalize: appLocalizations.accountDeleteSuccess,
      errorLocalize: appLocalizations.accountDeleteError,
      onSuccess: onSuccess,
      customDeleteAction: (db, tableName, fieldName, fieldValue) async {
        return db.update(tableName, {'soft_deleted': 1},
            where: "$fieldName = ?", whereArgs: [fieldValue], conflictAlgorithm: ConflictAlgorithm.replace);
      },
      onError: (e, over) {
        if (kDebugMode) {
          print("Error $e and $over");
        }
        if (onError != null) onError(e, over);
      },
    );
  }

  void showRestoreDialog(BuildContext context, Asset account, {Function? onSuccess, Function? onError}) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    util.showRemoveDialogByField(
      context,
      account,
      tableName: tableNameAsset,
      titleLocalize: appLocalizations.accountRestoreDialogTitle,
      confirmLocalize: appLocalizations.accountRestoreConfirm,
      successLocalize: appLocalizations.accountRestoreSuccess,
      errorLocalize: appLocalizations.accountRestoreError,
      onSuccess: onSuccess,
      customDeleteAction: (db, tableName, fieldName, fieldValue) async {
        return db.update(tableName, {'soft_deleted': 0},
            where: "$fieldName = ?", whereArgs: [fieldValue], conflictAlgorithm: ConflictAlgorithm.replace);
      },
      onError: (e, over) {
        if (kDebugMode) {
          print("Error $e and $over");
        }
        if (onError != null) onError(e, over);
      },
    );
  }

  Future<void> showRestoreCategoryDialog(BuildContext context, AssetCategory category, {required Function onSuccess}) async {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return util.showRemoveDialogByField(
      context,
      category,
      tableName: tableNameAssetCategory,
      titleLocalize: appLocalizations.accountCategoryRestoreDialogTitle,
      confirmLocalize: appLocalizations.accountCategoryRestoreConfirm,
      successLocalize: appLocalizations.accountCategoryRestoreSuccess,
      errorLocalize: appLocalizations.accountCategoryRestoreError,
      onSuccess: onSuccess,
      customDeleteAction: (db, tableName, fieldName, fieldValue) async {
        return db.update(tableName, {'soft_deleted': 0},
            where: "$fieldName = ?", whereArgs: [fieldValue], conflictAlgorithm: ConflictAlgorithm.replace);
      },
    );
  }

  Future<void> showRemoveCategoryDialog(BuildContext context, AssetCategory category, {required Function onSuccess}) async {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return util.showRemoveDialogByField(context, category,
        tableName: tableNameAssetCategory,
        titleLocalize: appLocalizations.accountCategoryDeleteDialogTitle,
        confirmLocalize: appLocalizations.accountCategoryDeleteConfirm,
        successLocalize: appLocalizations.accountCategoryDeleteSuccess,
        errorLocalize: appLocalizations.accountCategoryDeleteError,
        onSuccess: onSuccess, customDeleteAction: (db, tableName, fieldName, fieldValue) async {
      return db.update(tableName, {'soft_deleted': 1},
          where: "$fieldName = ?", whereArgs: [fieldValue], conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  void refreshAssetCategories(Function(List<AssetCategory> c)? callback) {
    AssetsDao().assetCategories().then((categories) {
      categories.sort((a, b) {
        if (a.deleted) {
          return (a.positionIndex - b.positionIndex) * 100;
        } else if (b.deleted) {
          return (a.positionIndex - b.positionIndex) * (-100);
        }
        return a.positionIndex - b.positionIndex;
      });
      currentAppState.assetCategories = categories;
      if (callback != null) {
        callback(categories);
      }
    });
  }

  Future<List<Asset>> refreshAssets() async {
    if (kDebugMode) {
      print("Reload assets");
    }
    var assets = await AssetsDao().assets();

    assets.sort((a, b) => a.positionIndex - b.positionIndex);
    currentAppState.assets = assets;

    if (kDebugMode) {
      // print("Assets loaded: $assets");
      print("All Assets loaded!");
    }

    return assets;
  }

  Widget elementIconDisplay(AssetTreeNode node, ThemeData theme) {
    if (node.deleted) {
      return Icon(node.icon, color: Colors.grey);
    }
    return Icon(node.icon, color: theme.iconTheme.color);
  }

  Widget elementTextDisplay(AssetTreeNode node, ThemeData theme) {
    String text = node.getTitleText(currentAppState.systemSetting);
    if (node.deleted) {
      return Text(text, style: TextStyle(decoration: TextDecoration.lineThrough));
    }
    return Text(text);
  }

  IconData resolveAccountTypeIcon(AssetType type) {
    if (type == AssetType.genericAccount) {
      return Icons.request_quote;
    } else if (type == AssetType.eWallet) {
      return Icons.wallet;
    } else if (type == AssetType.bankCasa) {
      return Icons.account_balance;
    } else if (type == AssetType.payLaterAccount) {
      return Icons.payments;
    } else if (type == AssetType.creditCard) {
      return Icons.credit_card;
    } else {
      return Icons.real_estate_agent_outlined;
    }
  }
}
