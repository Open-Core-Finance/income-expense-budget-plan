import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:income_expense_budget_plan/dao/assets_dao.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/category_util.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/v8.dart';

class AssetsCategoriesPanel extends StatefulWidget {
  const AssetsCategoriesPanel({super.key});

  @override
  State<AssetsCategoriesPanel> createState() => _AssetsCategoriesPanelState();
}

class _AssetsCategoriesPanelState extends State<AssetsCategoriesPanel> {
  @override
  void initState() {
    super.initState();
    Util().refreshSystemAssetCategory(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final String accountCategoryLabel = AppLocalizations.of(context)!.menuAccountCategory;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.secondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(accountCategoryLabel),
      ),
      floatingActionButton: FloatingActionButton(
        foregroundColor: theme.primaryColor,
        backgroundColor: theme.iconTheme.color,
        shape: const CircleBorder(),
        onPressed: () => Util().navigateTo(context, AddAssetsCategoryPanel()),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: ListView(
        children: <Widget>[
          for (AssetCategory category in appState.systemAssetCategories)
            ListTile(
              leading: Icon(category.icon, color: theme.iconTheme.color), // Icon on the left
              title: Text(category.localizeNames[currentAppState.systemSettings.locale?.languageCode]?.isNotEmpty == true
                  ? category.localizeNames[currentAppState.systemSettings.locale!.languageCode]!
                  : category.name), // Title of the item
              trailing: category.system
                  ? null
                  : IconButton(
                      icon: Icon(Icons.delete, color: theme.colorScheme.error), onPressed: () => _showRemoveDialog(context, category)),
              onTap: () => Util().navigateTo(context, AddAssetsCategoryPanel(editingCategory: category)),
            ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 40,
        child: Container(color: theme.hoverColor),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, AssetCategory category) {
    Util().showRemoveDialogByField(
      context,
      category,
      titleLocalize: AppLocalizations.of(context)!.accountCategoryDeleteDialogTitle,
      confirmLocalize: AppLocalizations.of(context)!.accountCategoryDeleteConfirm,
      successLocalize: AppLocalizations.of(context)!.accountCategoryDeleteSuccess,
      errorLocalize: AppLocalizations.of(context)!.accountCategoryDeleteError,
      onSuccess: () => Util().refreshSystemAssetCategory(() => setState(() {})),
    );
  }
}

class AddAssetsCategoryPanel extends StatefulWidget {
  AssetCategory? editingCategory;
  AddAssetsCategoryPanel({super.key, this.editingCategory});

  @override
  State<AddAssetsCategoryPanel> createState() => _AddAssetsCategoryPanelState();
}

class _AddAssetsCategoryPanelState extends State<AddAssetsCategoryPanel> {
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
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 10),
                  Text(accountCategoryActionSelectIconLabel),
                  IconButton(
                    onPressed: () {
                      showIconPicker(context, iconPackModes: [IconPack.material, IconPack.cupertino]).then((IconData? iconData) {
                        if (iconData != null) setState(() => _selectedIcon = iconData);
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
                      decoration:
                          InputDecoration(border: const OutlineInputBorder(), labelText: AppLocalizations.of(context)!.accountCategoryName),
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
              Row(
                children: [
                  Flexible(
                    child: FormField<bool>(
                      initialValue: _enableMultiLanguage,
                      validator: (value) {
                        return null;
                      },
                      builder: (FormFieldState<bool> state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              title: Text(AppLocalizations.of(context)!.accountCategoryTurnOnLocalizeNames),
                              value: state.value,
                              onChanged: (value) {
                                setState(() {
                                  _enableMultiLanguage = value!;
                                  state.didChange(value);
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            if (state.hasError)
                              Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Text(
                                  state.errorText!,
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
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
                              labelText: '${AppLocalizations.of(context)!.accountCategoryName} (${localeMap[entry.key]})'),
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
                children: CategoryUtil().buildCategoryFormActions(
                  context,
                  () => _validateForm(context, () => Navigator.of(context).pop()),
                  _isChecking,
                  AppLocalizations.of(context)!.accountCategoryActionSave,
                  () => _validateForm(context, () => _initEmptyForm()),
                  accountCategoryActionSaveAddMoreLabel,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _validateForm(BuildContext context, Function() callback) async {
    final appState = Provider.of<AppState>(context, listen: false);
    setState(() {
      _isChecking = true;
      _isValidCategoryName = true;
    });
    var future = AssetsDao().loadCategoryByNameAndIgnoreSpecificCategory(_categoryNameController.text, widget.editingCategory?.id);
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
          _editingCategory!.icon = _selectedIcon;
          _editingCategory!.name = _categoryNameController.text;
          _editingCategory!.localizeNames = localizeMap;
          db.update(tableNameAssetsCategory, _editingCategory!.toMap(),
              where: "uid = ?", whereArgs: [_editingCategory!.id], conflictAlgorithm: ConflictAlgorithm.replace);
          setState(() {
            appState.triggerNotify();
            callback();
          });
        });
      } else {
        AssetCategory assetCategory = AssetCategory(
            id: const UuidV8().generate(), icon: _selectedIcon, name: _categoryNameController.text, localizeNames: localizeMap);
        DatabaseService().database.then((db) {
          db.insert(tableNameAssetsCategory, assetCategory.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
          setState(() {
            appState.systemAssetCategories.add(assetCategory);
            appState.triggerNotify();
            callback();
          });
        });
      }
    }
  }
}
