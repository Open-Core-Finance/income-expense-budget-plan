import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:income_expense_budget_plan/common/transaction_category_tree.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/v8.dart';

class TransactionCategoriesPanel extends StatefulWidget {
  final bool disableBack;
  final Function(TransactionCategory item)? itemTap;
  final String listPanelTitle;
  const TransactionCategoriesPanel({super.key, required this.listPanelTitle, bool? disableBack, this.itemTap})
      : disableBack = disableBack ?? false;

  @override
  State<TransactionCategoriesPanel> createState() => _TransactionCategoriesPanelState();
}

class _TransactionCategoriesPanelState extends State<TransactionCategoriesPanel> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    String listPanelTitle = widget.listPanelTitle;
    TransactionCategoriesListenable transactionCategories = Provider.of<TransactionCategoriesListenable>(context);

    Widget? appBarLeading;
    if (widget.disableBack != true) {
      appBarLeading = IconButton(icon: Icon(Icons.arrow_back, color: colorScheme.secondary), onPressed: () => Navigator.of(context).pop());
    }

    PreferredSizeWidget? appBarBottom;
    Widget body;
    if (transactionCategories.categoriesMap.length >= 2) {
      AppLocalizations apLocalizations = AppLocalizations.of(context)!;
      String expenseTitle = apLocalizations.menuExpenseCategory;
      String incomeTitle = apLocalizations.menuIncomeCategory;
      appBarBottom = TabBar(
        tabs: [
          Tab(icon: const Icon(incomeIconData), text: incomeTitle),
          Tab(icon: const Icon(expenseIconData), text: expenseTitle),
          //Tab(icon: const Icon(genericCategoryIconData), text: apLocalizations.transactionCategory),
        ],
      );
      body = TabBarView(
        children: [
          TransactionCategoryTree(
            key: Key("Categories-panel-${widget.key.toString()}-income"),
            categories: transactionCategories.categoriesMap[TransactionType.income] ?? [],
            transactionType: TransactionType.income,
            itemTap: widget.itemTap,
          ),
          TransactionCategoryTree(
            key: Key("Categories-panel-${widget.key.toString()}-expense"),
            categories: transactionCategories.categoriesMap[TransactionType.expense] ?? [],
            transactionType: TransactionType.expense,
            itemTap: widget.itemTap,
          ),
        ],
      );

      if (kDebugMode) {
        print("Body $body with categories ${transactionCategories.categoriesMap}\n");
      }

      return DefaultTabController(
        length: 2, // Number of tabs
        child: Scaffold(
          appBar: AppBar(
            leading: appBarLeading,
            title: Text(listPanelTitle),
            bottom: appBarBottom,
          ),
          body: body,
        ),
      );
    } else {
      var categoriesEntry = transactionCategories.categoriesMap.entries.first;
      body = TransactionCategoryTree(
        key: Key("Categories-panel-${widget.key.toString()}"),
        categories: categoriesEntry.value,
        transactionType: categoriesEntry.key,
        itemTap: widget.itemTap,
      );

      if (kDebugMode) {
        print("Body $body with categories ${transactionCategories.categoriesMap}\n");
      }

      return Scaffold(
        appBar: AppBar(leading: appBarLeading, title: Text(listPanelTitle)),
        body: body,
      );
    }
  }
}

class AddTransactionCategoryPanel extends StatefulWidget {
  final TransactionCategory? editingCategory;
  final Function(List<TransactionCategory> cats)? editCallback;
  final String addPanelTitle;
  final TransactionType transactionType;

  const AddTransactionCategoryPanel(
      {super.key, this.editingCategory, this.editCallback, required this.addPanelTitle, required this.transactionType});

  @override
  State<AddTransactionCategoryPanel> createState() => _AddTransactionCategoryPanelState();
}

class _AddTransactionCategoryPanelState extends State<AddTransactionCategoryPanel> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  late bool _isChecking;
  late bool _isValidCategoryName;
  late IconData _selectedIcon;
  late TextEditingController _categoryNameController;
  late TransactionCategory? _selectedParentCategory;
  late bool _enableMultiLanguage;
  TransactionCategory? _editingCategory;
  late Map<String, TextEditingController> _localizeNamesMap;
  late String _addPanelTitle;

  @override
  void initState() {
    super.initState();
    _addPanelTitle = widget.addPanelTitle;
    if (widget.editingCategory != null) {
      _editingCategory = widget.editingCategory;
      _selectedIcon = _editingCategory!.icon ?? defaultIconData;
      _categoryNameController = TextEditingController(text: _editingCategory!.name);
      _isChecking = false;
      _isValidCategoryName = true;
      _localizeNamesMap = localeMap.map((key, value) => MapEntry(key, TextEditingController(text: '')));
      _enableMultiLanguage = false;
      for (var entry in _editingCategory!.localizeNames.entries) {
        _localizeNamesMap[entry.key] = TextEditingController(text: entry.value);
        if (entry.value.isNotEmpty) {
          _enableMultiLanguage = true;
        }
      }
      _selectedParentCategory = _editingCategory?.parent;
      if (kDebugMode) {
        print("Selected parent UID [${_editingCategory!.parentUid}], parent object: $_selectedParentCategory");
      }
    } else {
      _initEmptyForm();
    }
  }

  _initEmptyForm() {
    _selectedIcon = defaultIconData;
    _categoryNameController = TextEditingController(text: '');
    _isChecking = false;
    _isValidCategoryName = false;
    _enableMultiLanguage = false;
    _localizeNamesMap = {};
    _selectedParentCategory = null;
    localeMap.forEach((key, _) => _localizeNamesMap[key] = TextEditingController(text: ''));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Consumer<TransactionCategoriesListenable>(builder: (context, transactionCategories, child) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.error),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(_addPanelTitle),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      Text(AppLocalizations.of(context)!.transactionCategoryActionSelectIcon),
                      IconButton(
                        onPressed: () {
                          showIconPicker(context).then((IconPickerIcon? iconData) {
                            if (iconData != null) setState(() => _selectedIcon = iconData.data);
                          });
                        },
                        icon: Icon(_selectedIcon),
                        iconSize: 50,
                        color: theme.iconTheme.color,
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: TextFormField(
                          obscureText: false,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: AppLocalizations.of(context)!.transactionCategoryName,
                          ),
                          controller: _categoryNameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!.transactionCategoryValidateNameEmpty;
                            }
                            if (!_isValidCategoryName) {
                              return AppLocalizations.of(context)!.transactionCategoryValidateNameExisted;
                            }
                            return null;
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // You can also use the controller to manipulate what is shown in the
                          // text field. For example, the clear() method removes all the text
                          // from the text field.
                          _categoryNameController.clear();
                        },
                        icon: const Icon(Icons.clear),
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      Text(AppLocalizations.of(context)!.transactionCategoryParent),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 100, 0),
                          child: ElevatedButton(
                            onPressed: () => _chooseParentCategory(context, transactionCategories),
                            child: Row(children: _buildParentCategoryDisplay(theme)),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedParentCategory = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Flexible(
                          child: FormUtil().buildCheckboxFormField(context, theme,
                              value: _enableMultiLanguage,
                              title: AppLocalizations.of(context)!.transactionCategoryTurnOnLocalizeNames, onChanged: (value) {
                        setState(() {
                          _enableMultiLanguage = value!;
                          if (_enableMultiLanguage) {
                            for (var entry in _localizeNamesMap.entries) {
                              if (entry.value.text.isEmpty) {
                                entry.value.text = _categoryNameController.text;
                              }
                            }
                          }
                        });
                      })),
                    ],
                  ),
                  if (_enableMultiLanguage)
                    for (var entry in _localizeNamesMap.entries)
                      Column(children: [
                        const SizedBox(height: 10),
                        Row(children: [
                          Flexible(
                            child: TextFormField(
                              obscureText: false,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: '${AppLocalizations.of(context)!.transactionCategoryName} (${localeMap[entry.key]})',
                              ),
                              controller: entry.value,
                              validator: (value) {
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              entry.value.clear();
                            },
                            icon: const Icon(Icons.clear),
                            color: theme.colorScheme.error,
                          ),
                        ]),
                      ]),
                  const SizedBox(height: 20),
                  Row(
                    children: FormUtil().buildCategoryFormActions(
                      context,
                      () {
                        _validateForm(context, transactionCategories, (List<TransactionCategory> cats) {
                          if (kDebugMode) {
                            print("\n");
                            print("\nCats: $cats\n");
                            print("\n");
                          }
                          if (widget.editCallback != null) {
                            var callback = widget.editCallback!;
                            if (kDebugMode) {
                              print("\nCallback: $callback\n");
                            }
                            callback(cats);
                          }
                          Navigator.of(context).pop();
                        });
                      },
                      _isChecking,
                      AppLocalizations.of(context)!.transactionCategoryActionSave,
                      () {
                        _validateForm(context, transactionCategories, (List<TransactionCategory> cats) {
                          _initEmptyForm();
                          if (widget.editCallback != null) {
                            var callback = widget.editCallback!;
                            callback(cats);
                          }
                        });
                      },
                      AppLocalizations.of(context)!.transactionCategoryActionSaveAddMore,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  void _validateForm(BuildContext context, TransactionCategoriesListenable transactionCategoriesListenable,
      Function(List<TransactionCategory> cats) callback) async {
    setState(() {
      _isChecking = true;
      _isValidCategoryName = true;
    });
    var future = TransactionDao().loadCategoryByTransactionTypeAndNameAndIgnoreSpecificCategory(
        widget.transactionType, _categoryNameController.text, _editingCategory?.id);
    future.then((List<Map<String, dynamic>> data) {
      setState(() {
        _isChecking = false;
        _isValidCategoryName = data.isEmpty;
      });
    });

    await future;
    if (!_isValidCategoryName) {
      _formKey.currentState?.validate();
    } else {
      _formKey.currentState?.validate();
      Map<String, String> localizeMap = (!_enableMultiLanguage) ? {} : _localizeNamesMap.map((key, value) => MapEntry(key, value.text));
      if (kDebugMode) {
        print("Enable language: $_enableMultiLanguage, Localize map: $localizeMap, _localizeNamesMap: $_localizeNamesMap");
      }
      if (_editingCategory != null) {
        DatabaseService().database.then((db) {
          var olParentUid = _editingCategory?.parentUid;
          var newParentUid = _selectedParentCategory?.id;
          _editingCategory!.icon = _selectedIcon;
          _editingCategory!.name = _categoryNameController.text;
          _editingCategory!.localizeNames = localizeMap;
          _editingCategory!.parentUid = newParentUid;
          _editingCategory?.lastUpdated = DateTime.now();
          var updateFuture = db.update(
            tableNameTransactionCategory,
            _editingCategory!.toMap(),
            where: "uid = ?",
            whereArgs: [_editingCategory!.id],
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          updateFuture.then((_) => transactionCategoriesListenable.refreshItem(_editingCategory!, olParentUid, newParentUid, callback));
        });
      } else {
        var categories = transactionCategoriesListenable.categoriesMap[widget.transactionType] ?? [];
        List<TransactionCategory> sibling =
            Util().findSiblingCategories(categories, widget.transactionType, _selectedParentCategory?.id) ?? [];
        TransactionCategory transactionCategory = TransactionCategory(
            id: const UuidV8().generate(),
            icon: _selectedIcon,
            name: _categoryNameController.text,
            parentUid: _selectedParentCategory?.id,
            localizeNames: localizeMap,
            index: sibling.length,
            transactionType: widget.transactionType);
        DatabaseService().database.then((db) {
          db.insert(tableNameTransactionCategory, transactionCategory.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
          setState(() {
            transactionCategoriesListenable.addItem(transactionCategory);
            callback(categories);
          });
        });
      }
    }
  }

  void _chooseParentCategory(BuildContext context, TransactionCategoriesListenable transactionCategoriesListenable) {
    final ThemeData theme = Theme.of(context);
    // Get the current screen size
    final Size screenSize = MediaQuery.of(context).size;
    // Set min and max size based on the screen size
    final double maxWidth = screenSize.width * 0.9; // 80% of screen width
    final double maxHeight = screenSize.height * 0.9; // 50% of screen height
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.transactionCategoryParent),
        content: SizedBox(
          width: maxWidth,
          height: maxHeight,
          child: ChangeNotifierProvider(
            create: (context) => TransactionCategoriesListenable(categoriesMap: transactionCategoriesListenable.categoriesMap),
            builder: (BuildContext context, Widget? child) => TransactionCategoryTree(
              key: Key("transaction-categories-dialog-${widget.key.toString()}"),
              categories: transactionCategoriesListenable.categoriesMap[widget.transactionType] ?? [],
              itemTap: (TransactionCategory item) {
                _selectedParentCategory = item;
                if (kDebugMode) {
                  print("Selected item $item and set to $_selectedParentCategory");
                }
                Navigator.of(context).pop();
                setState(() {});
              },
              transactionType: widget.transactionType,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ButtonStyle(foregroundColor: WidgetStateProperty.all(theme.colorScheme.error)),
            child: Text(AppLocalizations.of(context)!.actionClose),
          )
        ],
      ),
    );
  }

  List<Widget> _buildParentCategoryDisplay(ThemeData theme) {
    final selectedParentCategory = _selectedParentCategory;
    if (kDebugMode) {
      print("Selected parent $_selectedParentCategory");
    }
    if (selectedParentCategory != null) {
      return [Icon(selectedParentCategory.icon, color: theme.iconTheme.color), const SizedBox(width: 5), Text(selectedParentCategory.name)];
    } else {
      return [const Text("")];
    }
  }
}
