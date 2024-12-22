import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/transaction_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/v8.dart';

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
  TransactionService transactionService = TransactionService();

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
    var colorScheme = theme.colorScheme;
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
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
                      Text(appLocalizations.transactionCategoryActionSelectIcon),
                      IconButton(
                        onPressed: () => showIconPicker(context, configuration: iconPickerConfig).then((IconPickerIcon? iconData) {
                          if (iconData != null) setState(() => _selectedIcon = iconData.data);
                        }),
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
                            labelText: appLocalizations.transactionCategoryName,
                            suffixIcon: IconButton(
                                onPressed: () => _categoryNameController.clear(),
                                icon: const Icon(Icons.clear),
                                color: theme.colorScheme.error),
                          ),
                          controller: _categoryNameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return appLocalizations.transactionCategoryValidateNameEmpty;
                            }
                            if (!_isValidCategoryName) {
                              return appLocalizations.transactionCategoryValidateNameExisted;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<TransactionCategory>(
                    value: _selectedParentCategory,
                    icon: const Icon(Icons.arrow_downward),
                    elevation: 16,
                    style: TextStyle(color: colorScheme.primary),
                    onChanged: (cat) => setState(() => _selectedParentCategory = cat),
                    items: _buildListCategoriesDropdown(context, transactionCategories),
                    decoration: InputDecoration(labelText: appLocalizations.transactionCategoryParent, border: OutlineInputBorder()),
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
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    entry.value.clear();
                                  },
                                  icon: const Icon(Icons.clear),
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              controller: entry.value,
                              validator: (value) => null,
                            ),
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
      var validateResult = _formKey.currentState?.validate();
      if (validateResult != null && validateResult != true) {
        if (kDebugMode) {
          print("Form validate fail!. [$validateResult]");
        }
        return;
      }
    } else {
      var validateResult = _formKey.currentState?.validate();
      if (validateResult != null && validateResult != true) {
        if (kDebugMode) {
          print("Form validate fail again!. [$validateResult]");
        }
        return;
      }
      Map<String, String> localizeMap = (!_enableMultiLanguage) ? {} : _localizeNamesMap.map((key, value) => MapEntry(key, value.text));
      if (kDebugMode) {
        print("Enable language: $_enableMultiLanguage, Localize map: $localizeMap, _localizeNamesMap: $_localizeNamesMap");
      }
      var dbService = DatabaseService();
      if (_editingCategory != null) {
        dbService.database.then((db) {
          var olParentUid = _editingCategory?.parentUid;
          var newParentUid = _selectedParentCategory?.id;
          _editingCategory!.icon = _selectedIcon;
          _editingCategory!.name = _categoryNameController.text;
          _editingCategory!.localizeNames = localizeMap;
          _editingCategory!.parentUid = newParentUid;
          _editingCategory?.lastUpdated = DateTime.now();
          db
              .update(
                tableNameTransactionCategory,
                _editingCategory!.toMap(),
                where: "uid = ?",
                whereArgs: [_editingCategory!.id],
                conflictAlgorithm: ConflictAlgorithm.replace,
              )
              .then((_) => transactionCategoriesListenable.refreshItem(_editingCategory!, olParentUid, newParentUid, callback))
              .catchError((e) => dbService.recordCodingError(e, 'update transaction category', null));
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
        dbService.database.then((db) {
          db.insert(tableNameTransactionCategory, transactionCategory.toMap(), conflictAlgorithm: ConflictAlgorithm.replace).then((_) {
            setState(() {
              transactionCategoriesListenable.addItem(transactionCategory);
              callback(categories);
            });
          }).catchError((e) {
            dbService.recordCodingError(e, 'add new transaction category', null);
          });
        });
      }
    }
  }

  List<DropdownMenuItem<TransactionCategory>> _buildListCategoriesDropdown(
      BuildContext context, TransactionCategoriesListenable transactionCategoriesListenable) {
    List<DropdownMenuItem<TransactionCategory>> categoryItems = [];
    for (var entry in transactionCategoriesListenable.categoriesMap.entries) {
      for (TransactionCategory cat in entry.value) {
        categoryItems.add(transactionService.buildTransactionCategoryDropdownItem(context, cat, false));
        if (cat.child.isNotEmpty) {
          for (TransactionCategory c in cat.child) {
            categoryItems.add(transactionService.buildTransactionCategoryDropdownItem(context, c, true));
          }
        }
      }
    }
    return categoryItems;
  }
}
