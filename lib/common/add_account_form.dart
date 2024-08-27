import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:income_expense_budget_plan/dao/assets_dao.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/v8.dart';

class AddAccountForm extends StatefulWidget {
  final Asset? editingAsset;
  final Function(List<Asset> assets, bool isAddNew)? editCallback;
  const AddAccountForm({super.key, this.editingAsset, this.editCallback});

  @override
  State<AddAccountForm> createState() => _AddAccountFormState();
}

class _AddAccountFormState extends State<AddAccountForm> {
  late bool _isChecking;
  late bool _isValidAssetName;
  late IconData _selectedIcon;
  late TextEditingController _assetNameController;
  late TextEditingController _assetDescriptionController;
  late bool _enableMultiLanguage;
  Asset? _editingAsset;
  late Map<String, TextEditingController> _localizeNamesMap;
  late Map<String, TextEditingController> _localizeDescriptionMap;
  late String _selectedAccountType;
  late TextEditingController _availableAmountController;
  late TextEditingController _loanAmountController;
  late TextEditingController _depositAmountController;
  late TextEditingController _creditLimitController;
  late AssetCategory _selectedCategory;
  late Currency _selectedCurrency;
  late CurrencyTextInputFormatter _currencyTextInputFormatter;

  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedCategory = currentAppState.assetCategories[0];
    if (widget.editingAsset != null) {
      _editingAsset = widget.editingAsset;
      _selectedIcon = _editingAsset!.icon ?? defaultIconData;
      _assetNameController = TextEditingController(text: _editingAsset!.name);
      _isChecking = false;
      _isValidAssetName = true;
      _localizeNamesMap = localeMap.map((key, value) => MapEntry(key, TextEditingController(text: '')));
      _localizeDescriptionMap = localeMap.map((key, value) => MapEntry(key, TextEditingController(text: '')));
      _enableMultiLanguage = false;
      for (var entry in _editingAsset!.localizeNames.entries) {
        _localizeNamesMap[entry.key] = TextEditingController(text: entry.value);
        if (entry.value.isNotEmpty) {
          _enableMultiLanguage = true;
        }
      }
      for (var entry in _editingAsset!.localizeDescriptions.entries) {
        _localizeDescriptionMap[entry.key] = TextEditingController(text: entry.value);
        if (entry.value.isNotEmpty) {
          _enableMultiLanguage = true;
        }
      }
      _assetDescriptionController = TextEditingController(text: _editingAsset!.description);
      _loanAmountController = TextEditingController(text: '');
      _depositAmountController = TextEditingController(text: '');
      _creditLimitController = TextEditingController(text: '');
      if (_editingAsset is CashAccount) {
        _selectedAccountType = AssetType.cash.name;
        _availableAmountController = TextEditingController(text: '${(_editingAsset! as CashAccount).availableAmount}');
      } else if (_editingAsset is BankCasaAccount) {
        _selectedAccountType = AssetType.bankCasa.name;
        _availableAmountController = TextEditingController(text: '${(_editingAsset! as BankCasaAccount).availableAmount}');
      } else if (_editingAsset is EWallet) {
        _selectedAccountType = AssetType.eWallet.name;
        _availableAmountController = TextEditingController(text: '${(_editingAsset! as EWallet).availableAmount}');
      } else if (_editingAsset is LoanAccount) {
        _selectedAccountType = AssetType.loan.name;
        _availableAmountController = TextEditingController(text: '');
        _loanAmountController.text = '${(_editingAsset! as LoanAccount).loanAmount}';
      } else if (_editingAsset is TermDepositAccount) {
        _selectedAccountType = AssetType.termDeposit.name;
        _availableAmountController = TextEditingController(text: '');
        _depositAmountController.text = '${(_editingAsset! as TermDepositAccount).depositAmount}';
      } else {
        // Credit card
        _selectedAccountType = AssetType.creditCard.name;
        _availableAmountController = TextEditingController(text: '${(_editingAsset! as CreditCard).availableAmount}');
        _creditLimitController.text = '${(_editingAsset! as CreditCard).creditLimit}';
      }
      _selectedCurrency = currentAppState.currencies.firstWhere((currency) => currency.id == _editingAsset?.currencyUid);
      _selectedCategory = currentAppState.assetCategories.firstWhere((cat) => cat.id == _editingAsset?.categoryUid);
    } else {
      _initEmptyForm();
    }
    _currencyTextInputFormatter = CurrencyTextInputFormatter.currency(
        locale: _selectedCurrency.language, symbol: _selectedCurrency.symbol, decimalDigits: _selectedCurrency.decimalPoint);
  }

  _initEmptyForm() {
    _editingAsset = null;
    _selectedIcon = defaultIconData;
    _assetNameController = TextEditingController(text: '');
    _assetDescriptionController = TextEditingController(text: '');
    _isChecking = false;
    _isValidAssetName = false;
    _enableMultiLanguage = false;
    _localizeNamesMap = {};
    _localizeDescriptionMap = {};
    localeMap.forEach((key, _) {
      _localizeNamesMap[key] = TextEditingController(text: '');
      _localizeDescriptionMap[key] = TextEditingController(text: '');
    });
    _availableAmountController = TextEditingController(text: '');
    _selectedAccountType = AssetType.cash.name;
    _loanAmountController = TextEditingController(text: '');
    _depositAmountController = TextEditingController(text: '');
    _creditLimitController = TextEditingController(text: '');
    _selectedCurrency = currentAppState.systemSetting.defaultCurrency!;
  }

  @override
  Widget build(BuildContext context) {
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
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Row(
                  children: [
                    const SizedBox(width: 10),
                    Text(AppLocalizations.of(context)!.accountActionSelectIcon),
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
                for (var widget in _formFields(context, theme)) widget,
                const SizedBox(height: 20),
                Row(
                  children: FormUtil().buildCategoryFormActions(
                    context,
                    () => _validateForm(context, (List<Asset> assets, bool isAddNew) {
                      if (widget.editCallback != null) {
                        var callback = widget.editCallback!;
                        if (kDebugMode) {
                          print("\nCallback: $callback\n");
                        }
                        callback(assets, isAddNew);
                      }
                      Navigator.of(context).pop();
                    }),
                    _isChecking,
                    AppLocalizations.of(context)!.accountActionSave,
                    () => _validateForm(context, (List<Asset> assets, bool isAddNew) {
                      _initEmptyForm();
                      if (widget.editCallback != null) {
                        var callback = widget.editCallback!;
                        callback(assets, isAddNew);
                      }
                    }),
                    AppLocalizations.of(context)!.accountActionSaveAddMore,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _validateForm(BuildContext context, Function(List<Asset> assets, bool isAddNew) callback) async {
    final appState = Provider.of<AppState>(context, listen: false);
    setState(() {
      _isChecking = true;
      _isValidAssetName = true;
    });
    var future = AssetsDao().loadAssetsByNameAndIgnoreSpecificCategory(_assetNameController.text, _editingAsset?.id);
    future.then((List<Map<String, dynamic>> data) {
      setState(() {
        _isChecking = false;
        _isValidAssetName = data.isEmpty;
      });
    });

    await future;
    if (!_isValidAssetName) {
      _formKey.currentState?.validate();
    } else {
      _formKey.currentState?.validate();
      Map<String, String> localizeMap = (!_enableMultiLanguage) ? {} : _localizeNamesMap.map((key, value) => MapEntry(key, value.text));
      Map<String, String> localizeDesc =
          (!_enableMultiLanguage) ? {} : _localizeDescriptionMap.map((key, value) => MapEntry(key, value.text));
      if (kDebugMode) {
        print("Enable language: $_enableMultiLanguage, Localize map: $localizeMap, _localizeNamesMap: $_localizeNamesMap");
      }

      var moneyFormat = _currencyTextInputFormatter.numberFormat;
      var availableAmountNumber = moneyFormat.tryParse(_availableAmountController.text)?.toDouble();
      var loanAmountNumber = moneyFormat.tryParse(_loanAmountController.text)?.toDouble();
      var depositAmountNumber = moneyFormat.tryParse(_depositAmountController.text)?.toDouble();
      var creditLimitNumber = moneyFormat.tryParse(_creditLimitController.text)?.toDouble();

      if (_editingAsset != null) {
        DatabaseService().database.then((db) {
          _editingAsset?.icon = _selectedIcon;
          _editingAsset?.name = _assetNameController.text;
          _editingAsset?.localizeNames = localizeMap;
          _editingAsset?.localizeDescriptions = localizeDesc;
          _editingAsset?.description = _assetDescriptionController.text;
          _editingAsset?.categoryUid = _selectedCategory.id!;

          if (_editingAsset is CashAccount) {
            (_editingAsset! as CashAccount).availableAmount = availableAmountNumber!;
          } else if (_editingAsset is BankCasaAccount) {
            (_editingAsset! as BankCasaAccount).availableAmount = availableAmountNumber!;
          } else if (_editingAsset is EWallet) {
            (_editingAsset! as EWallet).availableAmount = availableAmountNumber!;
          } else if (_editingAsset is LoanAccount) {
            (_editingAsset! as LoanAccount).loanAmount = loanAmountNumber!;
          } else if (_editingAsset is TermDepositAccount) {
            (_editingAsset! as TermDepositAccount).depositAmount = depositAmountNumber!;
          } else {
            // Credit card
            (_editingAsset! as CreditCard).availableAmount = availableAmountNumber!;
            (_editingAsset! as CreditCard).creditLimit = creditLimitNumber!;
          }
          _editingAsset?.lastUpdated = DateTime.now();

          db.update(tableNameAsset, _editingAsset!.toMap(),
              where: "uid = ?", whereArgs: [_editingAsset!.id], conflictAlgorithm: ConflictAlgorithm.replace);
          setState(() {
            appState.triggerNotify();
            callback(appState.assets, false);
          });
        });
      } else {
        Asset assets;
        switch (_selectedAccountType) {
          case "cash":
            assets = CashAccount(
                id: const UuidV8().generate(),
                icon: _selectedIcon,
                name: _assetNameController.text,
                localizeNames: localizeMap,
                index: appState.assets.length,
                localizeDescriptions: localizeDesc,
                description: _assetDescriptionController.text,
                currencyUid: _selectedCurrency.id,
                categoryUid: _selectedCategory.id!,
                availableAmount: availableAmountNumber!);
            break;
          case "bankCasa":
            assets = BankCasaAccount(
                id: const UuidV8().generate(),
                icon: _selectedIcon,
                name: _assetNameController.text,
                localizeNames: localizeMap,
                index: appState.assets.length,
                localizeDescriptions: localizeDesc,
                description: _assetDescriptionController.text,
                currencyUid: _selectedCurrency.id,
                categoryUid: _selectedCategory.id!,
                availableAmount: availableAmountNumber!);
            break;
          case "loan":
            assets = LoanAccount(
                id: const UuidV8().generate(),
                icon: _selectedIcon,
                name: _assetNameController.text,
                localizeNames: localizeMap,
                index: appState.assets.length,
                localizeDescriptions: localizeDesc,
                description: _assetDescriptionController.text,
                currencyUid: _selectedCurrency.id,
                categoryUid: _selectedCategory.id!,
                loanAmount: loanAmountNumber!);
            break;
          case "termDeposit":
            assets = TermDepositAccount(
                id: const UuidV8().generate(),
                icon: _selectedIcon,
                name: _assetNameController.text,
                localizeNames: localizeMap,
                index: appState.assets.length,
                localizeDescriptions: localizeDesc,
                description: _assetDescriptionController.text,
                currencyUid: _selectedCurrency.id,
                categoryUid: _selectedCategory.id!,
                depositAmount: depositAmountNumber!);
            break;
          case "eWallet":
            assets = EWallet(
                id: const UuidV8().generate(),
                icon: _selectedIcon,
                name: _assetNameController.text,
                localizeNames: localizeMap,
                index: appState.assets.length,
                localizeDescriptions: localizeDesc,
                description: _assetDescriptionController.text,
                currencyUid: _selectedCurrency.id,
                categoryUid: _selectedCategory.id!,
                availableAmount: availableAmountNumber!);
            break;
          default:
            assets = CreditCard(
                id: const UuidV8().generate(),
                icon: _selectedIcon,
                name: _assetNameController.text,
                localizeNames: localizeMap,
                index: appState.assets.length,
                localizeDescriptions: localizeDesc,
                description: _assetDescriptionController.text,
                currencyUid: _selectedCurrency.id,
                categoryUid: _selectedCategory.id!,
                availableAmount: availableAmountNumber!,
                creditLimit: creditLimitNumber!);
            break;
        }
        DatabaseService().database.then((db) {
          db.insert(tableNameAsset, assets.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
          setState(() {
            appState.assets.add(assets);
            appState.triggerNotify();
            callback(appState.assets, true);
          });
        });
      }
    }
  }

  List<DropdownMenuItem<AssetCategory>> _buildListCategoriesDropdown() {
    var currentLocale = currentAppState.systemSetting.locale?.languageCode;
    return currentAppState.assetCategories.map<DropdownMenuItem<AssetCategory>>((AssetCategory cat) {
      var localizedNameTxt = cat.localizeNames[currentLocale];
      var menuText = FormUtil().resolveAccountTypeLocalize(context, localizedNameTxt?.isNotEmpty == true ? localizedNameTxt! : cat.name);
      return _buildDropdownMenuItem(context, cat, menuText);
    }).toList();
  }

  List<DropdownMenuItem<Currency>> _buildListCurrenciesDropdown() {
    return currentAppState.currencies
        .map<DropdownMenuItem<Currency>>(
            (Currency currency) => _buildDropdownMenuItem(context, currency, FormUtil().resolveAccountTypeLocalize(context, currency.name)))
        .toList();
  }

  List<Widget> _buildLocalizedComponents(BuildContext context, ThemeData theme) {
    List<Widget> result = [];

    onchange(bool? value) => setState(() {
          _enableMultiLanguage = value!;
          if (_enableMultiLanguage) {
            for (var entry in _localizeNamesMap.entries) {
              if (entry.value.text.isEmpty) {
                entry.value.text = _assetNameController.text;
              }
            }
            for (var entry in _localizeDescriptionMap.entries) {
              if (entry.value.text.isEmpty) {
                entry.value.text = _assetDescriptionController.text;
              }
            }
          }
        });
    result.add(Row(
      children: [
        Flexible(
          child: FormUtil().buildCheckboxFormField(context, theme,
              value: _enableMultiLanguage, title: AppLocalizations.of(context)!.accountTurnOnLocalizeNames, onChanged: onchange),
        ),
      ],
    ));
    if (_enableMultiLanguage) {
      for (var entry in _localizeNamesMap.entries) {
        result.add(_localizeInputRow('${AppLocalizations.of(context)!.accountName} (${localeMap[entry.key]})', entry.value, theme));
      }

      for (var entry in _localizeDescriptionMap.entries) {
        result.add(_localizeInputRow('${AppLocalizations.of(context)!.accountDescription} (${localeMap[entry.key]})', entry.value, theme));
      }
    }

    return result;
  }

  IconButton _clearButton(TextEditingController textEditingController, ThemeData theme) {
    return IconButton(onPressed: () => textEditingController.clear(), icon: const Icon(Icons.clear), color: theme.colorScheme.error);
  }

  Widget _localizeInputRow(String label, TextEditingController textEditingController, ThemeData theme,
      {FormFieldValidator<String>? validator}) {
    return Column(children: [
      const SizedBox(height: 10),
      Row(children: [
        Flexible(
          child: TextFormField(
              obscureText: false,
              decoration: InputDecoration(border: const OutlineInputBorder(), labelText: label),
              controller: textEditingController,
              validator: validator),
        ),
        _clearButton(textEditingController, theme)
      ]),
    ]);
  }

  DropdownMenuItem<T> _buildDropdownMenuItem<T>(BuildContext context, T value, String text) {
    return DropdownMenuItem<T>(
        key: const Key("accountTypeDropdownItem"),
        value: value,
        child: Padding(padding: const EdgeInsets.fromLTRB(10, 0, 0, 0), child: Text(text)));
  }

  List<Widget> _moneyInputField(bool show, String label, TextEditingController textEditingController, ThemeData theme,
      {FormFieldValidator<String>? validator}) {
    List<Widget> result = [];
    if (show) {
      result.add(const SizedBox(height: 10));
      result.add(Row(
        children: [
          Flexible(
            child: TextFormField(
              maxLines: 1,
              keyboardType: TextInputType.number,
              inputFormatters: [_currencyTextInputFormatter],
              decoration: InputDecoration(border: const OutlineInputBorder(), labelText: label),
              controller: textEditingController,
              validator: validator,
            ),
          )
        ],
      ));
    }
    return result;
  }

  List<Widget> _textFormField(BuildContext context, ThemeData theme, String label, TextEditingController textEditingController,
      {FormFieldValidator<String>? validator}) {
    return [
      const SizedBox(height: 10),
      Row(
        children: [
          Flexible(
            child: TextFormField(
                obscureText: false,
                decoration: InputDecoration(border: const OutlineInputBorder(), labelText: label),
                controller: textEditingController,
                validator: validator),
          ),
          _clearButton(textEditingController, theme)
        ],
      )
    ];
  }

  List<Widget> _dropdownButtonFormField<T>(BuildContext context,
      {required String label,
      required T value,
      FormFieldValidator<String>? validator,
      Function(T? value)? onChange,
      required List<DropdownMenuItem<T>> items}) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return [
      const SizedBox(height: 10),
      Row(
        children: [
          const SizedBox(width: 10),
          Text(label),
          const SizedBox(width: 10),
          Flexible(
            child: DropdownButtonFormField<T>(
                value: value,
                icon: const Icon(Icons.arrow_downward),
                elevation: 16,
                style: TextStyle(color: colorScheme.primary),
                onChanged: onChange,
                items: items),
          ),
        ],
      )
    ];
  }

  List<Widget> _formFields(BuildContext context, ThemeData theme) {
    List<Widget> result = [];
    result.addAll(_dropdownButtonFormField(
      context,
      value: _selectedAccountType,
      label: AppLocalizations.of(context)!.accountCategorySelect,
      items: AssetType.values
          .map<DropdownMenuItem<String>>(
            (AssetType t) => _buildDropdownMenuItem(context, t.name, FormUtil().resolveAccountTypeLocalize(context, t.name)),
          )
          .toList(),
      onChange: (String? value) => setState(() => _selectedAccountType = value!),
    ));

    result.addAll(_dropdownButtonFormField(
      context,
      value: _selectedCategory,
      label: AppLocalizations.of(context)!.accountCategorySelect,
      items: _buildListCategoriesDropdown(),
      onChange: (AssetCategory? value) => setState(() => _selectedCategory = value!),
    ));

    result.addAll(_dropdownButtonFormField(
      context,
      value: _selectedCurrency,
      label: AppLocalizations.of(context)!.accountCurrencySelect,
      items: _buildListCurrenciesDropdown(),
      onChange: (Currency? value) => setState(
        () {
          _selectedCurrency = value!;
          _currencyTextInputFormatter = CurrencyTextInputFormatter.currency(
              locale: _selectedCurrency.language, symbol: _selectedCurrency.symbol, decimalDigits: _selectedCurrency.decimalPoint);
          _availableAmountController.text = _currencyTextInputFormatter.formatString(_availableAmountController.text);
          _depositAmountController.text = _currencyTextInputFormatter.formatString(_depositAmountController.text);
          _loanAmountController.text = _currencyTextInputFormatter.formatString(_loanAmountController.text);
          _creditLimitController.text = _currencyTextInputFormatter.formatString(_creditLimitController.text);
        },
      ),
    ));

    assetsNameValidator(value) {
      if (value == null || value.isEmpty) {
        return AppLocalizations.of(context)!.accountValidateNameEmpty;
      }
      if (!_isValidAssetName) {
        return AppLocalizations.of(context)!.accountValidateNameExisted;
      }
      return null;
    }

    result.addAll(
        _textFormField(context, theme, AppLocalizations.of(context)!.accountName, _assetNameController, validator: assetsNameValidator));
    result.addAll(_textFormField(context, theme, AppLocalizations.of(context)!.accountDescription, _assetDescriptionController));
    result.addAll(_moneyInputField(
      [AssetType.cash.name, AssetType.bankCasa.name, AssetType.eWallet.name, AssetType.creditCard.name].contains(_selectedAccountType),
      AppLocalizations.of(context)!.accountAvailableAmount,
      _availableAmountController,
      theme,
    ));
    result.addAll(_moneyInputField(
        AssetType.loan.name == _selectedAccountType, AppLocalizations.of(context)!.accountLoanAmount, _loanAmountController, theme));
    result.addAll(_moneyInputField(AssetType.termDeposit.name == _selectedAccountType, AppLocalizations.of(context)!.accountDepositAmount,
        _depositAmountController, theme));
    result.addAll(_moneyInputField(AssetType.creditCard.name == _selectedAccountType, AppLocalizations.of(context)!.accountCreditLimit,
        _creditLimitController, theme));
    result.addAll(_buildLocalizedComponents(context, theme));
    return result;
  }
}
