import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/dao/assets_dao.dart';
import 'package:income_expense_budget_plan/model/generic_model.dart';
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
      Map<String, dynamic> map = jsonDecode(jsonString);
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
    return findChild(categories, null);
  }

  List<TransactionCategory> findChild(List<TransactionCategory> categories, TransactionCategory? parent) {
    if (kDebugMode) {
      print("********************");
      print("Categories received $categories for parent $parent");
    }
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
    if (kDebugMode) {
      print("Categories after remove $categories for parent $parent. Extracted child $child");
    }
    if (parent != null) {
      parent.child.addAll(child);
    }
    if (child.isNotEmpty && categories.isNotEmpty) {
      for (var c in child) {
        if (kDebugMode) {
          print("Continue find child for parent $c");
        }
        findChild(categories, c);
      }
    }
    if (kDebugMode) {
      print("********************");
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

  void refreshSystemAssetCategory(Function()? callback) {
    AssetsDao().assetsCategories().then((categories) {
      if (kDebugMode) {
        print("Loaded categories $categories");
      }
      categories.sort((a, b) => a.positionIndex - b.positionIndex);
      currentAppState.systemAssetCategories = categories;
      if (callback != null) {
        callback();
      }
    });
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
}
