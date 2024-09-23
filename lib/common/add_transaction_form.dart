import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:income_expense_budget_plan/common/account_panel.dart';
import 'package:income_expense_budget_plan/common/date_time_form_field.dart';
import 'package:income_expense_budget_plan/common/transaction_categories_panel.dart';
import 'package:income_expense_budget_plan/common/transaction_category_tree.dart';
import 'package:income_expense_budget_plan/dao/assets_dao.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/name_localized_model.dart';
import 'package:income_expense_budget_plan/model/transaction.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/v8.dart';

class AddTransactionForm extends StatefulWidget {
  final Transactions? editingTransaction;
  final Function(List<AssetCategory> assets, bool isAddNew)? editCallback;
  const AddTransactionForm({super.key, this.editingTransaction, this.editCallback});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  late bool _isChecking;
  bool _formValidatedPassed = false;
  bool _isValidAmount = false;
  late TextEditingController _transactionDescriptionController;
  late TextEditingController _transactionAmountController;
  late TextEditingController _transactionMySplitAmountController;
  late TextEditingController _transactionReturnSharedBillIdController;
  Transactions? _editingTransaction;
  Transactions? _selectedBillToReturn;
  TransactionType _selectedTransactionType = TransactionType.expense;

  late Currency _selectedCurrency;
  late TransactionCategory? _selectedCategory;
  late CurrencyTextInputFormatter _currencyTextInputFormatter;
  late Asset? _selectedAccount;
  late Asset? _selectedToAccount;

  late DateTime _selectedTxnDate;
  late TimeOfDay _selectedTxnTime;

  late bool _haveFee;
  late double _feeAmount;

  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.editingTransaction != null) {
      _editingTransaction = widget.editingTransaction;
      _transactionDescriptionController = TextEditingController(text: _editingTransaction!.description);
      _transactionAmountController = TextEditingController(text: '${_editingTransaction!.amount}');

      _isChecking = false;
      _selectedCategory = _editingTransaction!.transactionCategory;
      _selectedAccount = _editingTransaction!.account;
      _selectedTxnDate = _editingTransaction!.transactionDate;
      _selectedTxnTime = _editingTransaction!.transactionTime;
      _selectedToAccount = null;

      _transactionMySplitAmountController = TextEditingController(text: '');
      _transactionReturnSharedBillIdController = TextEditingController(text: '');
      if (_editingTransaction is TransferTransaction) {
        _selectedAccount = (_editingTransaction as TransferTransaction).toAccount;
      } else if (_editingTransaction is ShareBillTransaction) {
        _transactionMySplitAmountController.text = '${(_editingTransaction as ShareBillTransaction).mySplit}';
      } else if (_editingTransaction is ShareBillReturnTransaction) {
        // _selectedBillToReturn= (_editingTransaction as ShareBillReturnTransaction).sharedBillId;
        // TODO fill in bill to return
        _transactionReturnSharedBillIdController.text = _selectedBillToReturn != null ? _selectedBillToReturn!.description : '';
      }
    } else {
      _initEmptyForm();
    }
    if (_selectedAccount != null) {
      _selectedCurrency = currentAppState.currencies.firstWhere((currency) => currency.id == _selectedAccount?.currencyUid);
    } else {
      _selectedCurrency = currentAppState.systemSetting.defaultCurrency!;
    }
    _currencyTextInputFormatter = CurrencyTextInputFormatter.currency(
        locale: _selectedCurrency.language, symbol: _selectedCurrency.symbol, decimalDigits: _selectedCurrency.decimalPoint);
  }

  _initEmptyForm() {
    _editingTransaction = null;
    _transactionDescriptionController = TextEditingController(text: '');
    _transactionAmountController = TextEditingController(text: '');
    _isChecking = false;
    _selectedCurrency = currentAppState.systemSetting.defaultCurrency!;
    _selectedCategory = null;
    _selectedAccount = currentAppState.retrieveLastSelectedAsset();
    _selectedTxnDate = DateTime.now();
    _selectedTxnTime = TimeOfDay(hour: _selectedTxnDate.hour, minute: _selectedTxnDate.minute);
    _selectedToAccount = null;
    _transactionMySplitAmountController = TextEditingController(text: '');
    _selectedBillToReturn = null;
    _transactionReturnSharedBillIdController = TextEditingController(text: '');
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final String accountCategoryActionSaveAddMoreLabel = appLocalizations.transactionActionSaveAddMore;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    if (_selectedCategory != null) {
      if ((_selectedTransactionType == TransactionType.income || _selectedTransactionType == TransactionType.expense) &&
          _selectedCategory?.transactionType != _selectedTransactionType) {
        _selectedCategory = null;
      }
    }
    String amountLabel = appLocalizations.transactionAmount;
    if (_selectedTransactionType == TransactionType.adjustment) {
      amountLabel = appLocalizations.adjustmentNewAmount;
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.error),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Center(
          child: DropdownButton<TransactionType>(
            value: _selectedTransactionType,
            items: _buildTransactionTypeDropdownMenuEntries(context),
            onChanged: (TransactionType? value) {
              if (kDebugMode) {
                print("Changed transaction type: $value");
              }
              if (value != null) setState(() => _selectedTransactionType = value);
            },
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                if (_selectedTransactionType == TransactionType.adjustment && _selectedAccount != null) ...[
                  Row(
                    children: [
                      Text(appLocalizations.adjustmentCurrentAmount),
                      const SizedBox(width: 10),
                      Flexible(
                        child: TextFormField(
                          maxLines: 1,
                          keyboardType: TextInputType.number,
                          inputFormatters: [_currencyTextInputFormatter],
                          controller: TextEditingController(
                              text: _currencyTextInputFormatter.formatString("${_selectedAccount!.availableAmount})")),
                          enabled: false,
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10)
                ],
                if (_selectedTransactionType != TransactionType.adjustment || _selectedAccount != null) ...[
                  ..._moneyInputField(true, amountLabel, _transactionAmountController, theme, validator: (String? value) {
                    if (kDebugMode) {
                      print("Value: $value");
                    }
                    return null;
                  }),
                  const SizedBox(height: 10)
                ],
                if (_selectedTransactionType == TransactionType.shareBill) ...[
                  ..._moneyInputField(true, appLocalizations.sharedBillMySplit, _transactionMySplitAmountController, theme),
                  const SizedBox(height: 10)
                ],
                Row(
                  children: [
                    Text(appLocalizations.transactionCategory),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: ElevatedButton(
                          onPressed: () => _chooseCategory(context, _selectedTransactionType),
                          child: Row(children: _buildSelectedLocalizedItemDisplay(theme, _selectedCategory)),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                      color: theme.colorScheme.error,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    transactionAccountLabel(context, _selectedTransactionType),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                        child: ElevatedButton(
                          onPressed: () => _chooseAccount(context, true),
                          child: Row(children: _buildSelectedLocalizedItemDisplay(theme, _selectedAccount)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_selectedTransactionType == TransactionType.transfer) ...[
                  Row(
                    children: [
                      Text(appLocalizations.transferToAccount),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                          child: ElevatedButton(
                            onPressed: () => _chooseAccount(context, false),
                            child: Row(children: _buildSelectedLocalizedItemDisplay(theme, _selectedToAccount)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10)
                ],
                Row(
                  children: [
                    Text(appLocalizations.transactionCurrency),
                    const SizedBox(width: 10),
                    Flexible(
                      child: TextFormField(
                          controller: TextEditingController(text: "${_selectedCurrency.name} (${_selectedCurrency.symbol})"),
                          enabled: false,
                          style: TextStyle(color: theme.colorScheme.primary)),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Flexible(
                      child: TextFormField(
                        obscureText: false,
                        decoration: InputDecoration(border: const OutlineInputBorder(), labelText: appLocalizations.transactionDescription),
                        controller: _transactionDescriptionController,
                        validator: (value) => null,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // You can also use the controller to manipulate what is shown in the
                        // text field. For example, the clear() method removes all the text
                        // from the text field.
                        _transactionDescriptionController.clear();
                      },
                      icon: const Icon(Icons.clear),
                      color: theme.colorScheme.error,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                  child: DateTimeFormField(
                      initialDate: _selectedTxnDate,
                      initialTime: _selectedTxnTime,
                      onDateSelected: (DateTime date) {
                        if (kDebugMode) {
                          print("Selected date [$date]");
                        }
                        _selectedTxnDate = date;
                      },
                      onTimeSelected: (TimeOfDay time) {
                        if (kDebugMode) {
                          print("Selected time [$time]");
                        }
                        _selectedTxnTime = time;
                      }),
                ),
                if (_selectedTransactionType == TransactionType.shareBillReturn) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Flexible(
                        child: TextFormField(
                          obscureText: false,
                          enabled: false,
                          decoration:
                              InputDecoration(border: const OutlineInputBorder(), labelText: appLocalizations.sharedBillReturnForBill),
                          controller: _transactionReturnSharedBillIdController,
                          validator: (value) {
                            return null;
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // You can also use the controller to manipulate what is shown in the
                          // text field. For example, the clear() method removes all the text
                          // from the text field.
                          _transactionReturnSharedBillIdController.clear();
                        },
                        icon: const Icon(Icons.clear),
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ),
                ],
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
                    appLocalizations.accountCategoryActionSave,
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

  Widget transactionAccountLabel(BuildContext context, TransactionType type) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    String label;
    switch (type) {
      case TransactionType.transfer:
        label = appLocalizations.transferFromAccount;
        break;
      case TransactionType.lend:
        label = appLocalizations.lendingAccount;
        break;
      case TransactionType.borrowing:
        label = appLocalizations.borrowingAccount;
        break;
      default:
        label = appLocalizations.transactionAccount;
        break;
    }
    return Text(label);
  }

  void _validateForm(BuildContext context, Function(List<AssetCategory> categories, bool isAddNew) callback) async {
    setState(() {
      _isChecking = true;
      _isValidAmount = true;
      _formValidatedPassed = true;
    });
    var moneyFormat = _currencyTextInputFormatter.numberFormat;
    var formUtil = FormUtil();
    var amountTxt = formUtil.parseAmount(_transactionAmountController.text, moneyFormat);
    if (amountTxt == null || amountTxt < 0) {
      _isValidAmount = false;
    }
    // var future = AssetsDao().loadCategoryByNameAndIgnoreSpecificCategory(_categoryNameController.text, _editingCategory?.id);
    // future.then((List<Map<String, dynamic>> data) {
    //   setState(() {
    //     _isChecking = false;
    //     _isValidCategoryName = data.isEmpty;
    //   });
    // });
    //
    // await future;
    if (!_formValidatedPassed) {
      _formKey.currentState?.validate();
    } else {
      String tableName = tableNameTransaction;
      DatabaseService().database.then((db) {
        if (_editingTransaction != null) {
          db.delete(tableName, where: '${_editingTransaction!.idFieldName()} = ?', whereArgs: [_editingTransaction!.id]).then(
              (deletedCount) {
            if (deletedCount > 0) {
              _proceedSave(db, tableName, amountTxt!);
            } else {
              String errorMessage = AppLocalizations.of(context)!.transactionUpdateError;
              Util().showErrorDialog(context, errorMessage, null);
            }
          });
        } else {
          _proceedSave(db, tableName, amountTxt!);
        }
      });
    }
  }

  void _proceedSave(Database db, String tableName, double availableAmount) {
    Transactions transaction = _createTransaction(availableAmount);
    db.insert(tableName, transaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace).then((_) {
      setState(() {
        // TODO trigger update.
      });
    });
  }

  Transactions _createTransaction(double amountTxt) {
    var moneyFormat = _currencyTextInputFormatter.numberFormat;
    switch (_selectedTransactionType) {
      case TransactionType.income:
        return IncomeTransaction(
            id: const UuidV8().generate(),
            transactionDate: _selectedTxnDate,
            transactionTime: _selectedTxnTime,
            transactionCategory: _selectedCategory,
            description: _transactionDescriptionController.text,
            withFee: _haveFee,
            feeAmount: _feeAmount,
            amount: amountTxt,
            account: _selectedAccount!,
            currencyUid: _selectedCurrency.id,
            updatedDateTime: DateTime.now());
      case TransactionType.expense:
        return ExpenseTransaction(
            id: const UuidV8().generate(),
            transactionDate: _selectedTxnDate,
            transactionTime: _selectedTxnTime,
            transactionCategory: _selectedCategory,
            description: _transactionDescriptionController.text,
            withFee: _haveFee,
            feeAmount: _feeAmount,
            amount: amountTxt,
            account: _selectedAccount!,
            currencyUid: _selectedCurrency.id,
            updatedDateTime: DateTime.now());
      case TransactionType.transfer:
        return TransferTransaction(
            id: const UuidV8().generate(),
            transactionDate: _selectedTxnDate,
            transactionTime: _selectedTxnTime,
            transactionCategory: _selectedCategory,
            description: _transactionDescriptionController.text,
            withFee: _haveFee,
            feeAmount: _feeAmount,
            amount: amountTxt,
            account: _selectedAccount!,
            currencyUid: _selectedCurrency.id,
            toAccount: _selectedToAccount!,
            updatedDateTime: DateTime.now());
      case TransactionType.lend:
        return LendTransaction(
            id: const UuidV8().generate(),
            transactionDate: _selectedTxnDate,
            transactionTime: _selectedTxnTime,
            transactionCategory: _selectedCategory,
            description: _transactionDescriptionController.text,
            withFee: _haveFee,
            feeAmount: _feeAmount,
            amount: amountTxt,
            account: _selectedAccount!,
            currencyUid: _selectedCurrency.id,
            updatedDateTime: DateTime.now());
      case TransactionType.borrowing:
        return BorrowingTransaction(
            id: const UuidV8().generate(),
            transactionDate: _selectedTxnDate,
            transactionTime: _selectedTxnTime,
            transactionCategory: _selectedCategory,
            description: _transactionDescriptionController.text,
            withFee: _haveFee,
            feeAmount: _feeAmount,
            amount: amountTxt,
            account: _selectedAccount!,
            currencyUid: _selectedCurrency.id,
            updatedDateTime: DateTime.now());
      case TransactionType.adjustment:
        return AdjustmentTransaction(
            id: const UuidV8().generate(),
            transactionDate: _selectedTxnDate,
            transactionTime: _selectedTxnTime,
            transactionCategory: _selectedCategory,
            description: _transactionDescriptionController.text,
            withFee: _haveFee,
            feeAmount: _feeAmount,
            amount: amountTxt,
            account: _selectedAccount!,
            currencyUid: _selectedCurrency.id,
            updatedDateTime: DateTime.now());
      case TransactionType.shareBill:
        var mySplit = FormUtil().parseAmount(_transactionMySplitAmountController.text, moneyFormat)!;
        return ShareBillTransaction(
            id: const UuidV8().generate(),
            transactionDate: _selectedTxnDate,
            transactionTime: _selectedTxnTime,
            transactionCategory: _selectedCategory,
            description: _transactionDescriptionController.text,
            withFee: _haveFee,
            feeAmount: _feeAmount,
            amount: amountTxt,
            account: _selectedAccount!,
            currencyUid: _selectedCurrency.id,
            mySplit: mySplit,
            updatedDateTime: DateTime.now());
      case TransactionType.shareBillReturn:
        return ShareBillReturnTransaction(
            id: const UuidV8().generate(),
            transactionDate: _selectedTxnDate,
            transactionTime: _selectedTxnTime,
            transactionCategory: _selectedCategory,
            description: _transactionDescriptionController.text,
            withFee: _haveFee,
            feeAmount: _feeAmount,
            amount: amountTxt,
            account: _selectedAccount!,
            currencyUid: _selectedCurrency.id,
            updatedDateTime: DateTime.now());
    }
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
          ),
          IconButton(
            onPressed: () {
              // You can also use the controller to manipulate what is shown in the
              // text field. For example, the clear() method removes all the text
              // from the text field.
              textEditingController.clear();
            },
            icon: const Icon(Icons.clear),
            color: theme.colorScheme.error,
          ),
        ],
      ));
    }
    return result;
  }

  DropdownMenuItem<T> _buildDropdownMenuItem<T>(BuildContext context, T value, String text) {
    return DropdownMenuItem<T>(value: value, child: Padding(padding: const EdgeInsets.fromLTRB(10, 0, 0, 0), child: Text(text)));
  }

  List<DropdownMenuItem<TransactionType>> _buildTransactionTypeDropdownMenuEntries(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;
    List<List<dynamic>> iconMap = [
      [TransactionType.income, incomeIconData, Colors.green, 1.0, appLocalization.transactionTypeIncome],
      [TransactionType.expense, expenseIconData, Colors.red, 1.0, appLocalization.transactionTypeExpense],
      [TransactionType.lend, lendIconData, Colors.blue, 1.0, appLocalization.transactionTypeLend],
      [TransactionType.borrowing, Icons.add_business_sharp, Colors.blue, 1.0, appLocalization.transactionTypeBorrowing],
      [TransactionType.transfer, Icons.currency_exchange_outlined, Colors.blueGrey, 1.0, appLocalization.transactionTypeTransfer],
      [TransactionType.shareBill, Icons.receipt_long_outlined, Colors.deepOrangeAccent, 1.0, appLocalization.transactionTypeShareBill],
      [
        TransactionType.shareBillReturn,
        Icons.assignment_return_outlined,
        Colors.deepOrangeAccent,
        1.0,
        appLocalization.transactionTypeShareBillReturn
      ],
      [TransactionType.adjustment, Icons.auto_awesome_outlined, Colors.purple, 1.0, appLocalization.transactionTypeAdjustment]
    ];
    return iconMap.map((List<dynamic> list) {
      return DropdownMenuItem<TransactionType>(
        value: list[0] as TransactionType,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Row(children: [
            Icon(list[1] as IconData, color: list[2] as Color, fill: list[3] as double),
            const SizedBox(width: 10),
            Text(list[4] as String),
          ]),
        ),
      );
    }).toList();
  }

  List<Widget> _buildSelectedLocalizedItemDisplay(ThemeData theme, NameLocalizedModel<dynamic>? item) {
    final selectedItem = item;
    if (kDebugMode) {
      print("Selected parent $selectedItem");
    }
    IconData? iconData;
    if (selectedItem is TransactionCategory) {
      iconData = selectedItem.icon;
    } else if (selectedItem is Asset) {
      iconData = selectedItem.icon;
    }
    if (selectedItem != null) {
      return [
        if (iconData != null) Icon(iconData, color: theme.iconTheme.color),
        const SizedBox(width: 5),
        Text(selectedItem.getTitleText(currentAppState.systemSetting))
      ];
    } else {
      return [const Text("")];
    }
  }

  void _chooseCategory(BuildContext context, TransactionType type) {
    final ThemeData theme = Theme.of(context);
    // Get the current screen size
    final Size screenSize = MediaQuery.of(context).size;
    // Set min and max size based on the screen size
    final double maxWidth = screenSize.width * 0.9; // 80% of screen width
    final double maxHeight = screenSize.height * 0.9; // 50% of screen height

    AppLocalizations apLocalizations = AppLocalizations.of(context)!;
    String expenseTitle = apLocalizations.menuExpenseCategory;
    String incomeTitle = apLocalizations.menuIncomeCategory;
    String dialogTitle;
    Map<TransactionType, List<TransactionCategory>> categoriesMap;
    if (type == TransactionType.income || type == TransactionType.expense) {
      categoriesMap = {type: currentAppState.categoriesMap[type] ?? []};
      if (type == TransactionType.income) {
        dialogTitle = incomeTitle;
      } else {
        dialogTitle = expenseTitle;
      }
    } else {
      categoriesMap = currentAppState.categoriesMap;
      dialogTitle = apLocalizations.transactionCategory;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.transactionCategory),
        content: SizedBox(
          width: maxWidth,
          height: maxHeight,
          child: ChangeNotifierProvider(
            create: (context) => TransactionCategoriesListenable(categoriesMap: categoriesMap),
            builder: (BuildContext context, Widget? child) => TransactionCategoriesPanel(
              key: Key("transaction-categories-dialog-${widget.key.toString()}-add-txn"),
              listPanelTitle: dialogTitle,
              itemTap: (TransactionCategory item) {
                _selectedCategory = item;
                if (kDebugMode) {
                  print("Selected item $item and set to $_selectedCategory");
                }
                Navigator.of(context).pop();
                setState(() {});
              },
              disableBack: true,
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

  void _chooseAccount(BuildContext context, bool fromAccount) {
    final ThemeData theme = Theme.of(context);
    // Get the current screen size
    final Size screenSize = MediaQuery.of(context).size;
    // Set min and max size based on the screen size
    final double maxWidth = screenSize.width * 0.9; // 80% of screen width
    final double maxHeight = screenSize.height * 0.9; // 50% of screen height
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.transactionAccount),
        content: SizedBox(
          width: maxWidth,
          height: maxHeight,
          child: AccountPanel(accountTap: (account) {
            if (kDebugMode) {
              print("Account currency [${account.currencyUid}]");
            }
            if (fromAccount) {
              _selectedCurrency = currentAppState.currencies.firstWhere((c) => c.id == account.currencyUid);
              _selectedAccount = account;
              _currencyTextInputFormatter = CurrencyTextInputFormatter.currency(
                  locale: _selectedCurrency.language, symbol: _selectedCurrency.symbol, decimalDigits: _selectedCurrency.decimalPoint);
              currentAppState.updateLastSelectedAsset(account);
            } else {
              _selectedToAccount = account;
            }
            if (kDebugMode) {
              print("Selected currency [$_selectedCurrency]");
            }
            setState(() {});
            Navigator.of(context).pop();
          }),
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
}
