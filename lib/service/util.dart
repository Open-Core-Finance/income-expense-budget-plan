import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/dao/assets_dao.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/generic_model.dart';
import 'package:income_expense_budget_plan/model/setting.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:sqflite/sqflite.dart';

class Util {
  // Singleton pattern
  static final Util _util = Util._internal();
  factory Util() => _util;
  Util._internal();

  void navigateTo(BuildContext context, Widget widget) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  String iconDataToJSONString(IconData? data) {
    if (data == null) return "null";
    Map<String, dynamic> map = <String, dynamic>{};
    map['codePoint'] = data.codePoint;
    map['fontFamily'] = data.fontFamily;
    map['fontPackage'] = data.fontPackage;
    map['matchTextDirection'] = data.matchTextDirection;
    return jsonEncode(map);
  }

  IconData iconDataFromJSONString(String jsonString) {
    if (jsonString.isNotEmpty) {
      Map<String, dynamic> map = customJsonDecode(jsonString);
      return IconData(
        map['codePoint'],
        fontFamily: map['fontFamily'],
        fontPackage: map['fontPackage'],
        matchTextDirection: map['matchTextDirection'],
      );
    }
    return defaultIconData;
  }

  List<TransactionCategory> buildTransactionCategoryTree(List<TransactionCategory> categories) {
    if (kDebugMode) {
      print("********************");
      print("Categories received $categories");
    }
    var result = findChild(categories, null);
    if (kDebugMode) {
      print("Categories after parsed $result");
      print("********************");
    }
    return result;
  }

  List<TransactionCategory> findChild(List<TransactionCategory> categories, TransactionCategory? parent) {
    List<TransactionCategory> child = [];
    for (int i = 0; i < categories.length; i++) {
      TransactionCategory category = categories[i];
      if (category.parentUid == parent?.id) {
        child.add(category);
        category.parent = parent;
        categories.removeAt(i--);
      }
    }
    child.sort((a, b) => a.positionIndex - b.positionIndex);
    if (parent != null) {
      parent.child.addAll(child);
    }
    if (child.isNotEmpty && categories.isNotEmpty) {
      for (var c in child) {
        findChild(categories, c);
      }
    }
    return child;
  }

  TransactionCategory? findTransactionCategory(List<TransactionCategory> categories, TransactionType transactionType, String? categoryId) {
    if (categoryId != null) {
      for (TransactionCategory category in categories) {
        if (kDebugMode) {
          print("Input category ID [$categoryId] and input transaction type [$transactionType]. "
              "Category ID [${category.id}] and Category transaction type [${category.transactionType}]");
        }
        if (category.id == categoryId && category.transactionType == transactionType) {
          return category;
        }
        var result = findTransactionCategory(category.child, transactionType, categoryId);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }

  List<TransactionCategory>? findSiblingCategories(
      List<TransactionCategory> categories, TransactionType transactionType, String? parenUid) {
    for (TransactionCategory cat in categories) {
      if (kDebugMode) {
        print("[findSiblingCategories] Input parenUid [$parenUid] and input transaction type [$transactionType]. "
            "Category ID [${cat.id}] and Category transaction type [${cat.transactionType}]");
      }
      if (cat.parentUid == parenUid && cat.transactionType == transactionType) {
        return categories;
      }
      var child = findSiblingCategories(cat.child, transactionType, parenUid);
      if (child != null) {
        return child;
      }
    }
    return null;
  }

  void refreshAssetCategories(Function(List<AssetCategory> c)? callback) {
    AssetsDao().assetCategories().then((categories) {
      if (kDebugMode) {
        print("Loaded categories $categories");
      }
      categories.sort((a, b) => a.positionIndex - b.positionIndex);
      currentAppState.assetCategories = categories;
      if (callback != null) {
        callback(categories);
      }
    });
  }

  void refreshAssets(Function(List<Asset> a)? callback) {
    AssetsDao().assets().then((assets) {
      if (kDebugMode) {
        print("Loaded assets $assets");
      }
      assets.sort((a, b) => a.positionIndex - b.positionIndex);
      currentAppState.assets = assets;
      if (callback != null) {
        callback(assets);
      }
    });
  }

  void mappingAssetsAndCategories(List<Asset> assets, List<AssetCategory> assetCategories) {
    int startTime = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) {
      print("\n****\nStarted mapping assets with categories at [$startTime].\n****\n");
    }
    List<Asset> tmp = [];
    tmp.addAll(assets);
    for (var category in assetCategories) {
      findCategoryChild(tmp, category);
    }
    int endTime = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) {
      print("\n****\nFinished mapping assets with categories at [$endTime].\n****\nTotal processed ${endTime - startTime}ms.");
    }
  }

  void findCategoryChild(List<Asset> assets, AssetCategory category) {
    for (var i = 0; i < assets.length; i++) {
      var asset = assets[i];
      if (asset.categoryUid == category.id) {
        category.assets.add(asset);
        asset.category = category;
        assets.removeAt(i--);
        if (kDebugMode) {
          print("Asset ${asset.name} with category ${category.name}");
        }
      }
    }
    if (kDebugMode) {
      print("\nCategories ${category.name} have ${category.assets.length} child!\n${category.assets}");
    }
  }

  void showErrorDialog(BuildContext context, String errorMessage, Function? callback) {
    final ThemeData theme = Theme.of(context);
    showMessageDialog(context, AppLocalizations.of(context)!.titleError, errorMessage, AppLocalizations.of(context)!.actionClose,
        theme.colorScheme.error, callback);
  }

  void showSuccessDialog(BuildContext context, String successMessage, Function? callback) {
    final ThemeData theme = Theme.of(context);
    showMessageDialog(context, AppLocalizations.of(context)!.titleSuccess, successMessage, AppLocalizations.of(context)!.actionConfirm,
        theme.iconTheme.color, callback);
  }

  void showMessageDialog(BuildContext context, String title, String message, String buttonText, Color? buttonColor, Function? callback) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (callback != null) {
                  callback(); // Close the dialog
                }
              },
              style: ButtonStyle(foregroundColor: WidgetStateProperty.all(buttonColor)),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  void showRemoveDialogByField(BuildContext context, GenericModel model,
      {required String tableName,
      required Function(String) titleLocalize,
      required Function(String) confirmLocalize,
      required Function(String) successLocalize,
      required Function(String) errorLocalize,
      Function? onComplete,
      Function? onSuccess,
      Function? onError}) {
    bool deleting = false;
    final dialogTitle = titleLocalize(model.displayText());
    final confirmMessage = confirmLocalize(model.displayText());
    final ThemeData theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(dialogTitle),
            scrollable: true,
            content: Text(confirmMessage),
            actions: [
              if (deleting)
                const CircularProgressIndicator()
              else
                TextButton(
                  onPressed: () async {
                    setState(() {
                      deleting = true;
                    });
                    DatabaseService().deleteItemByField(context, tableName, model.idFieldName(), model.id, successLocalize, errorLocalize,
                        retrieveItemDisplay: () => model.displayText(),
                        onComplete: () => setState(() {
                              deleting = false;
                              Navigator.of(context).pop();
                              if (onComplete != null) onComplete();
                            }),
                        onSuccess: onSuccess,
                        onError: onError);
                  },
                  style: ButtonStyle(foregroundColor: WidgetStateProperty.all(theme.colorScheme.primary)),
                  child: Text(AppLocalizations.of(context)!.actionConfirm),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ButtonStyle(foregroundColor: WidgetStateProperty.all(theme.colorScheme.error)),
                child: Text(AppLocalizations.of(context)!.actionClose),
              )
            ],
          ),
        );
      },
    );
  }

  Map<String, String> fromLocalizeDbField(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, value as String));
  }

  bool removeInTree(List<TransactionCategory> categories, TransactionCategory toRemove) {
    for (int i = 0; i < categories.length; i++) {
      TransactionCategory category = categories[i];
      if (category.id == toRemove.id) {
        categories.removeAt(i--);
        return true;
      }
      if (removeInTree(category.child, toRemove)) {
        return true;
      }
    }
    if (kDebugMode) {
      print("Categories after removal $categories");
    }
    return false;
  }

  bool removeInAccountTree(List<AssetCategory> categories, Asset toRemove) {
    for (int i = 0; i < categories.length; i++) {
      AssetCategory category = categories[i];
      var assets = category.assets;
      for (int j = 0; j < assets.length; j++) {
        var asset = assets[j];
        if (asset.id == toRemove.id) {
          assets.remove(j);
          return true;
        }
      }
    }
    return false;
  }

  void swapChildCategories(
      {required List<TransactionCategory> allCategories,
      required TransactionCategory origin,
      required TransactionCategory target,
      Function? callback}) {
    List<TransactionCategory> categories = findSiblingCategories(allCategories, origin.transactionType, origin.parentUid) ?? [];
    int oldIndex = categories.indexOf(origin);
    int newIndex = categories.indexOf(target);
    if (kDebugMode) {
      print("Drag/Drop within $categories from oldIndex [$oldIndex] to newIndex [$newIndex]");
    }
    if (oldIndex != newIndex) {
      DatabaseService().database.then((db) {
        final item = categories.removeAt(oldIndex);
        categories.insert(newIndex, item);
        for (int i = min(oldIndex, newIndex); i <= max(oldIndex, newIndex); i++) {
          var cat = categories[i];
          cat.positionIndex = i + 1;
          db.update(tableNameTransactionCategory, {'position_index': cat.positionIndex},
              where: "uid = ?", whereArgs: [cat.id], conflictAlgorithm: ConflictAlgorithm.replace);
        }
        if (callback != null) callback();
      });
    }
  }

  void swapAssetNode({required AssetCategory parentCat, required Asset origin, required Asset target, Function? callback}) {
    List<Asset> assets = parentCat.assets;
    int oldIndex = assets.indexOf(origin);
    int newIndex = assets.indexOf(target);
    if (oldIndex != newIndex) {
      DatabaseService().database.then((db) {
        final item = assets.removeAt(oldIndex);
        assets.insert(newIndex, item);
        for (int i = min(oldIndex, newIndex); i <= max(oldIndex, newIndex); i++) {
          var a = assets[i];
          a.positionIndex = i + 1;
          db.update(tableNameAsset, {'position_index': a.positionIndex},
              where: "uid = ?", whereArgs: [a.id], conflictAlgorithm: ConflictAlgorithm.replace);
        }
        if (callback != null) callback();
      });
    }
  }

  void chooseBrightnessMode(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select dark mode'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                for (int mode in [-1, 0, 1])
                  ListTile(
                    title: Text(SettingModel.parseDarkModeText(context, mode)),
                    onTap: () {
                      currentAppState.systemSetting.darkMode = mode;
                      Navigator.of(context).pop();
                    },
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  void chooseLanguage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                for (MapEntry<String, String> localeConfig in localeMap.entries)
                  ListTile(
                    title: Text(localeMap[localeConfig.key]!),
                    onTap: () {
                      currentAppState.systemSetting.locale = Locale(localeConfig.key);
                      currentAppState.triggerNotify();
                      Navigator.of(context).pop();
                    },
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  int timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  TimeOfDay minutesToTimeOfDay(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Map<String, dynamic> customJsonDecode(String? json) {
    if (json != null) {
      if (json.isNotEmpty) {
        return jsonDecode(json);
      } else {
        return {};
      }
    }
    return {};
  }

  Asset changeAssetType(Asset original, String selectedAccountType) {
    if (selectedAccountType == original.getAssetType()) {
      return original;
    }
    switch (selectedAccountType) {
      case "genericAccount":
        return GenericAccount(
            id: original.id,
            icon: original.icon,
            name: original.name,
            localizeNames: original.localizeNames,
            index: original.positionIndex,
            localizeDescriptions: original.localizeDescriptions,
            description: original.description,
            currencyUid: original.currencyUid,
            categoryUid: original.categoryUid,
            availableAmount: original.availableAmount);
      case "bankCasa":
        return BankCasaAccount(
            id: original.id,
            icon: original.icon,
            name: original.name,
            localizeNames: original.localizeNames,
            index: original.positionIndex,
            localizeDescriptions: original.localizeDescriptions,
            description: original.description,
            currencyUid: original.currencyUid,
            categoryUid: original.categoryUid,
            availableAmount: original.availableAmount);
      case "loan":
        return LoanAccount(
            id: original.id,
            icon: original.icon,
            name: original.name,
            localizeNames: original.localizeNames,
            index: original.positionIndex,
            localizeDescriptions: original.localizeDescriptions,
            description: original.description,
            currencyUid: original.currencyUid,
            categoryUid: original.categoryUid,
            loanAmount: 0);
      case "eWallet":
        return EWallet(
            id: original.id,
            icon: original.icon,
            name: original.name,
            localizeNames: original.localizeNames,
            index: original.positionIndex,
            localizeDescriptions: original.localizeDescriptions,
            description: original.description,
            currencyUid: original.currencyUid,
            categoryUid: original.categoryUid,
            availableAmount: original.availableAmount);
        break;
      case "payLaterAccount":
        PayLaterAccount assets = PayLaterAccount(
            id: original.id,
            icon: original.icon,
            name: original.name,
            localizeNames: original.localizeNames,
            index: original.positionIndex,
            localizeDescriptions: original.localizeDescriptions,
            description: original.description,
            currencyUid: original.currencyUid,
            categoryUid: original.categoryUid,
            availableAmount: original.availableAmount,
            paymentLimit: 0);
        if (original is CreditCard) {
          assets.paymentLimit = original.creditLimit;
        }
        return assets;
      default:
        CreditCard assets = CreditCard(
            id: original.id,
            icon: original.icon,
            name: original.name,
            localizeNames: original.localizeNames,
            index: original.positionIndex,
            localizeDescriptions: original.localizeDescriptions,
            description: original.description,
            currencyUid: original.currencyUid,
            categoryUid: original.categoryUid,
            availableAmount: original.availableAmount,
            creditLimit: 0);
        if (original is PayLaterAccount) {
          assets.creditLimit = original.paymentLimit;
        }
        return assets;
    }
  }

  Currency findCurrency(String currencyUid) {
    var currencies = currentAppState.currencies;
    for (var currency in currencies) {
      if (currency.id == currencyUid) {
        return currency;
      }
    }
    return currentAppState.systemSetting.defaultCurrency!;
  }
}
