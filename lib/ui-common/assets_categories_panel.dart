import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:income_expense_budget_plan/dao/assets_dao.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/service/account_service.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/v8.dart';

class AssetCategoriesPanel extends StatefulWidget {
  final bool disableBack;
  final bool showDeleted;
  const AssetCategoriesPanel({super.key, bool? disableBack, required this.showDeleted}) : disableBack = disableBack ?? false;

  @override
  State<AssetCategoriesPanel> createState() => _AssetCategoriesPanelState();
}

class _AssetCategoriesPanelState extends State<AssetCategoriesPanel> {
  Util util = Util();
  final AccountService accountService = AccountService();

  @override
  void initState() {
    super.initState();
    accountService.refreshAssetCategories((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final String accountCategoryLabel = AppLocalizations.of(context)!.menuAccountCategory;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final List<AssetCategory> categories = appState.assetCategories.where((category) => category.deleted != true).toList();
    final List<AssetCategory> deletedCategories = appState.assetCategories.where((category) => category.deleted == true).toList();
    bool showTab = widget.showDeleted && deletedCategories.isNotEmpty;
    var scaffold = Scaffold(
      appBar: AppBar(
        leading: widget.disableBack
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back, color: colorScheme.secondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Text(accountCategoryLabel),
        bottom: _topTabBar(theme, appState, categories, deletedCategories, showTab),
      ),
      floatingActionButton: FloatingActionButton(
        foregroundColor: theme.primaryColor,
        backgroundColor: theme.iconTheme.color,
        shape: const CircleBorder(),
        onPressed: () => util.navigateTo(context, const AddAssetCategoryForm()),
        heroTag: "Add-Account-Category-Button",
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: _buildBody(theme, appState, categories, deletedCategories, showTab),
    );
    if (!showTab) {
      return scaffold;
    } else {
      return DefaultTabController(length: 2, child: scaffold);
    }
  }

  Widget _buildBody(
      ThemeData theme, AppState appState, List<AssetCategory> categories, List<AssetCategory> deletedCategories, bool showTab) {
    var activatedCategories = Column(children: [
      Flexible(
        child: ReorderableListView(
          children: _categoriesDisplay(theme, appState, categories),
          onReorder: (oldIndex, newIndex) => appState.reOrderAssetCategory(oldIndex, newIndex),
        ),
      ),
      const SizedBox(height: 25),
    ]);
    if (!showTab) {
      return activatedCategories;
    } else {
      return TabBarView(children: [
        activatedCategories,
        Column(children: [
          Flexible(child: ListView(children: _deletedCategoriesDisplay(theme, appState, deletedCategories))),
          const SizedBox(height: 25),
        ])
      ]);
    }
  }

  List<Widget> _categoriesDisplay(ThemeData theme, AppState appState, List<AssetCategory> categories) {
    return <Widget>[
      for (AssetCategory category in categories)
        ListTile(
          key: ValueKey(category),
          leading: accountService.elementIconDisplay(category, theme),
          title: accountService.elementTextDisplay(category, theme),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: theme.colorScheme.error),
            onPressed: () => AccountService().showRemoveCategoryDialog(context, category,
                onSuccess: () => accountService.refreshAssetCategories((_) => setState(() {}))),
          ),
          onTap: () => Util().navigateTo(context, AddAssetCategoryForm(editingCategory: category)),
        )
    ];
  }

  List<Widget> _deletedCategoriesDisplay(ThemeData theme, AppState appState, List<AssetCategory> categories) {
    if (categories.isEmpty) return [];
    return <Widget>[
      for (AssetCategory category in categories)
        ListTile(
          key: ValueKey(category),
          leading: accountService.elementIconDisplay(category, theme),
          title: accountService.elementTextDisplay(category, theme),
          trailing: IconButton(
            icon: Icon(Icons.restore, color: Colors.green),
            onPressed: () => AccountService().showRestoreCategoryDialog(context, category,
                onSuccess: () => accountService.refreshAssetCategories((_) => setState(() {}))),
          ),
          onTap: () => Util().navigateTo(context, AddAssetCategoryForm(editingCategory: category)),
        ),
    ];
  }

  PreferredSizeWidget? _topTabBar(
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
}

class AddAssetCategoryForm extends StatefulWidget {
  final AssetCategory? editingCategory;
  final Function(List<AssetCategory> assets, bool isAddNew)? editCallback;
  const AddAssetCategoryForm({super.key, this.editingCategory, this.editCallback});

  @override
  State<AddAssetCategoryForm> createState() => _AddAssetCategoryFormState();
}

class _AddAssetCategoryFormState extends State<AddAssetCategoryForm> {
  late bool _isChecking;
  late bool _isValidCategoryName;
  late IconData _selectedIcon;
  late TextEditingController _categoryNameController;
  late bool _enableMultiLanguage;
  AssetCategory? _editingCategory;
  late Map<String, TextEditingController> _localizeNamesMap;

  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
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
    } else {
      _initEmptyForm();
    }
  }

  _initEmptyForm() {
    _editingCategory = null;
    _selectedIcon = defaultIconData;
    _categoryNameController = TextEditingController(text: '');
    _isChecking = false;
    _isValidCategoryName = false;
    _enableMultiLanguage = false;
    _localizeNamesMap = {};
    localeMap.forEach((key, _) => _localizeNamesMap[key] = TextEditingController(text: ''));
  }

  @override
  Widget build(BuildContext context) {
    final String accountCategoryActionSaveAddMoreLabel = AppLocalizations.of(context)!.accountCategoryActionSaveAddMore;
    final String accountCategoryActionSelectIconLabel = AppLocalizations.of(context)!.accountCategoryActionSelectIcon;
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.error),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(AppLocalizations.of(context)!.titleAddAccountCategory),
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
                    Text(accountCategoryActionSelectIconLabel),
                    IconButton(
                      onPressed: () {
                        showIconPicker(context, configuration: iconPickerConfig).then((IconPickerIcon? iconData) {
                          if (iconData != null) setState(() => _selectedIcon = iconData.data);
                        });
                      },
                      icon: Icon(_selectedIcon),
                      iconSize: 50,
                      color: theme.iconTheme.color,
                    )
                  ],
                ),
                TextFormField(
                  obscureText: false,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: AppLocalizations.of(context)!.accountCategoryName,
                    suffixIcon: IconButton(
                        onPressed: () => _categoryNameController.clear(), icon: const Icon(Icons.clear), color: theme.colorScheme.error),
                  ),
                  controller: _categoryNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.accountCategoryValidateNameEmpty;
                    }
                    if (!_isValidCategoryName) {
                      return AppLocalizations.of(context)!.accountCategoryValidateNameExisted;
                    }
                    return null;
                  },
                ),
                Row(
                  children: [
                    Flexible(
                      child: FormUtil().buildCheckboxFormField(context, theme,
                          value: _enableMultiLanguage,
                          title: AppLocalizations.of(context)!.accountCategoryTurnOnLocalizeNames, onChanged: (value) {
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
                      }),
                    ),
                  ],
                ),
                if (_enableMultiLanguage)
                  for (var entry in _localizeNamesMap.entries)
                    Column(children: [
                      const SizedBox(height: 10),
                      TextFormField(
                        obscureText: false,
                        decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: '${AppLocalizations.of(context)!.accountCategoryName} (${localeMap[entry.key]})',
                            suffixIcon: IconButton(
                                onPressed: () => entry.value.clear(), icon: const Icon(Icons.clear), color: theme.colorScheme.error)),
                        controller: entry.value,
                        validator: (value) => null,
                      ),
                    ]),
                const SizedBox(height: 20),
                Row(
                  children: FormUtil().buildCategoryFormActions(
                    context,
                    () => _validateForm(context, (List<AssetCategory> categories, bool isAddNew) {
                      if (widget.editCallback != null) {
                        var callback = widget.editCallback!;
                        if (kDebugMode) {
                          print("\nCallback: $callback\n");
                        }
                        callback(categories, isAddNew);
                      }
                      Navigator.of(context).pop();
                    }),
                    _isChecking,
                    AppLocalizations.of(context)!.accountCategoryActionSave,
                    () => _validateForm(context, (List<AssetCategory> categories, bool isAddNew) {
                      _initEmptyForm();
                      if (widget.editCallback != null) {
                        var callback = widget.editCallback!;
                        callback(categories, isAddNew);
                      }
                    }),
                    accountCategoryActionSaveAddMoreLabel,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _validateForm(BuildContext context, Function(List<AssetCategory> categories, bool isAddNew) callback) async {
    final appState = Provider.of<AppState>(context, listen: false);
    setState(() {
      _isChecking = true;
      _isValidCategoryName = true;
    });
    var future = AssetsDao().loadCategoryByNameAndIgnoreSpecificCategory(_categoryNameController.text, _editingCategory?.id);
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
          _editingCategory?.icon = _selectedIcon;
          _editingCategory?.name = _categoryNameController.text;
          _editingCategory?.localizeNames = localizeMap;
          _editingCategory?.lastUpdated = DateTime.now();
          db.update(tableNameAssetCategory, _editingCategory!.toMap(),
              where: "uid = ?", whereArgs: [_editingCategory!.id], conflictAlgorithm: ConflictAlgorithm.replace);
          setState(() {
            appState.triggerNotify();
            callback(appState.assetCategories, false);
          });
        });
      } else {
        AssetCategory assetCategory = AssetCategory(
          id: const UuidV8().generate(),
          icon: _selectedIcon,
          name: _categoryNameController.text,
          localizeNames: localizeMap,
          index: appState.assetCategories.length,
          deleted: false,
        );
        DatabaseService().database.then((db) {
          db.insert(tableNameAssetCategory, assetCategory.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
          setState(() {
            appState.assetCategories.add(assetCategory);
            appState.triggerNotify();
            callback(appState.assetCategories, true);
          });
        });
      }
    }
  }
}
