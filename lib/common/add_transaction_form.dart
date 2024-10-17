import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/common/account_panel.dart';
import 'package:income_expense_budget_plan/common/date_time_form_field.dart';
import 'package:income_expense_budget_plan/common/no_data.dart';
import 'package:income_expense_budget_plan/common/transaction_categories_panel.dart';
import 'package:income_expense_budget_plan/common/transaction_item_display.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/name_localized_model.dart';
import 'package:income_expense_budget_plan/model/transaction.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/v8.dart';

class AddTransactionForm extends StatefulWidget {
  final Transactions? editingTransaction;
  final Function(Transactions transaction, Transactions? deletedTran)? editCallback;
  const AddTransactionForm({super.key, this.editingTransaction, this.editCallback});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  late bool _isChecking;
  bool _formValidatedPassed = false;
  bool _isValidFeeAmount = false;
  bool _isValidAmount = false;
  late TextEditingController _transactionDescriptionController;
  late TextEditingController _transactionAmountController;
  late TextEditingController _transactionMySplitAmountController;
  late TextEditingController _transactionFeeController;
  Transactions? _editingTransaction;
  ShareBillTransaction? _selectedBillToReturn;
  late TransactionType _selectedTransactionType;

  late Currency _selectedCurrency;
  late TransactionCategory? _selectedCategory;
  late CurrencyTextInputFormatter _currencyTextInputFormatter;
  late Asset? _selectedAccount;
  late Asset? _selectedToAccount;

  late DateTime _selectedTxnDate;
  late TimeOfDay _selectedTxnTime;

  late bool _haveFee;
  bool _feeApplyToFromAccount = true;

  late bool _skipReport;

  List<ShareBillTransaction> _inCompletedSharedBills = [];

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
      var transaction = widget.editingTransaction!;
      _selectedTransactionType = transaction.getType();
      _editingTransaction = transaction;
      _transactionDescriptionController = TextEditingController(text: transaction.description);
      _transactionAmountController = TextEditingController(text: '${transaction.amount}');
      _transactionFeeController = TextEditingController(text: '${transaction.feeAmount}');

      _isChecking = false;
      _selectedCategory = transaction.transactionCategory;
      _selectedAccount = transaction.account;
      _selectedTxnDate = transaction.transactionDate;
      _selectedTxnTime = transaction.transactionTime;
      _selectedToAccount = null;

      _transactionMySplitAmountController = TextEditingController(text: '');

      if (_editingTransaction is TransferTransaction) {
        _selectedToAccount = (_editingTransaction as TransferTransaction).toAccount;
        _feeApplyToFromAccount = (_editingTransaction as TransferTransaction).feeApplyToFromAccount;
      } else if (_editingTransaction is ShareBillTransaction) {
        _transactionMySplitAmountController.text = '${(_editingTransaction as ShareBillTransaction).mySplit}';
      } else if (_editingTransaction is ShareBillReturnTransaction) {
        _selectedBillToReturn = (_editingTransaction as ShareBillReturnTransaction).sharedBill;
      }
      _haveFee = transaction.withFee;
      _skipReport = transaction.notIncludeToReport;
      reloadInCompleteSharedBills();
    } else {
      _initEmptyForm();
    }
    if (_selectedAccount != null) {
      _selectedCurrency = currentAppState.currencies.firstWhere((currency) => currency.id == _selectedAccount?.currencyUid);
    } else {
      _selectedCurrency = currentAppState.systemSetting.defaultCurrency!;
    }
    _currencyTextInputFormatter = FormUtil().buildFormatter(_selectedCurrency);
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
    _haveFee = false;
    _transactionFeeController = TextEditingController(text: '');
    _feeApplyToFromAccount = true;
    _skipReport = false;
    _selectedTransactionType = TransactionType.expense;
    reloadInCompleteSharedBills();
  }

  void reloadInCompleteSharedBills() {
    TransactionDao().inCompleteSharedBills().then((values) => _inCompletedSharedBills = values);
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
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.error),
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
                if (_selectedTransactionType != TransactionType.shareBillReturn) ...[
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
                ],
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
                        child: ElevatedButton(
                          onPressed: () => _chooseAccount(context, false),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                            child: Row(
                              children: _buildSelectedLocalizedItemDisplay(theme, _selectedToAccount),
                            ),
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
                          controller:
                              TextEditingController(text: _currencyTextInputFormatter.formatDouble(_selectedAccount!.availableAmount)),
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
                    if (_isValidAmount != true) {
                      return AppLocalizations.of(context)!.transactionInvalidAmount;
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
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                          child: ElevatedButton(
                            onPressed: () => _chooseSharedBill(context),
                            child: Row(children: _buildShareBillSelectionItemDisplay(context, theme, _selectedBillToReturn)),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _selectedBillToReturn = null),
                        icon: const Icon(Icons.clear),
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Flexible(
                      child: FormUtil().buildCheckboxFormField(
                        context,
                        theme,
                        value: _haveFee,
                        title: AppLocalizations.of(context)!.transactionHaveFee,
                        onChanged: (bool? value) => setState(() {
                          _haveFee = value!;
                        }),
                      ),
                    ),
                  ],
                ),
                if (_haveFee == true) ...[
                  const SizedBox(height: 10),
                  ..._moneyInputField(true, appLocalizations.transactionFee, _transactionFeeController, theme, validator: (String? value) {
                    if (_isValidFeeAmount != true) {
                      return AppLocalizations.of(context)!.transactionInvalidFee;
                    }
                    return null;
                  }),
                  if (_selectedTransactionType == TransactionType.transfer) ...[
                    const SizedBox(height: 10),
                    Column(
                      // mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        RadioListTile<bool>(
                          title: const Text('Fee apply to source account'),
                          value: true,
                          groupValue: _feeApplyToFromAccount,
                          onChanged: (value) {
                            setState(() {
                              _feeApplyToFromAccount = value ?? true;
                            });
                          },
                        ),
                        RadioListTile<bool>(
                          title: const Text('Fee apply to dest account'),
                          value: false,
                          groupValue: _feeApplyToFromAccount,
                          onChanged: (value) {
                            setState(() {
                              _feeApplyToFromAccount = value ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Flexible(
                      child: FormUtil().buildCheckboxFormField(
                        context,
                        theme,
                        value: _skipReport,
                        title: AppLocalizations.of(context)!.transactionSkipReport,
                        onChanged: (bool? value) => setState(() {
                          _skipReport = value!;
                        }),
                      ),
                    ),
                  ],
                ),
                if (_canSubmit()) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: FormUtil().buildCategoryFormActions(
                      context,
                      () => _validateForm(context, (Transactions transaction, Transactions? deletedTran) {
                        if (widget.editCallback != null) {
                          var callback = widget.editCallback!;
                          if (kDebugMode) {
                            print("\nCallback: $callback\n");
                          }
                          callback(transaction, deletedTran);
                        }
                        Navigator.of(context).pop();
                      }),
                      _isChecking,
                      appLocalizations.accountCategoryActionSave,
                      () => _validateForm(context, (Transactions transaction, Transactions? deletedTran) {
                        _initEmptyForm();
                        if (widget.editCallback != null) {
                          var callback = widget.editCallback!;
                          callback(transaction, deletedTran);
                        }
                      }),
                      accountCategoryActionSaveAddMoreLabel,
                    ),
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canSubmit() {
    if (_selectedTransactionType == TransactionType.adjustment || _selectedTransactionType == TransactionType.shareBillReturn) {
      return _selectedAccount != null;
    } else {
      bool result = _selectedAccount != null && _selectedCategory != null;
      if (_selectedTransactionType == TransactionType.transfer) {
        result = result && _selectedToAccount != null;
      }
      return result;
    }
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

  void _validateForm(BuildContext context, Function(Transactions transaction, Transactions? deletedTran) callback) {
    setState(() {
      _isChecking = true;
      _isValidFeeAmount = true;
      _formValidatedPassed = true;
      _isValidAmount = true;
    });
    var moneyFormat = _currencyTextInputFormatter.numberFormat;
    var formUtil = FormUtil();
    var amount = formUtil.parseAmount(_transactionAmountController.text, moneyFormat);
    var feeAmount = formUtil.parseAmount(_transactionFeeController.text, moneyFormat) ?? 0.0;
    if (_haveFee) {
      if (feeAmount <= 0) {
        _isValidFeeAmount = false;
      }
    }
    if (amount == null || amount <= 0) {
      _isValidAmount = false;
    }
    _formValidatedPassed = _isValidFeeAmount && _isValidAmount;
    if (!_formValidatedPassed) {
      _formKey.currentState?.validate();
      _isChecking = false;
    } else {
      String tableName = tableNameTransaction;
      DatabaseService().database.then((db) {
        if (_editingTransaction != null) {
          db.delete(tableName, where: '${_editingTransaction!.idFieldName()} = ?', whereArgs: [_editingTransaction!.id]).then(
              (deletedCount) {
            if (deletedCount > 0) {
              _proceedSave(db, tableName, amount!, feeAmount, _editingTransaction!, callback);
            } else {
              String errorMessage = AppLocalizations.of(context)!.transactionUpdateError;
              Util().showErrorDialog(context, errorMessage, null);
            }
          });
        } else {
          _proceedSave(db, tableName, amount!, feeAmount, null, callback);
        }
      });
    }
  }

  void _proceedSave(Database db, String tableName, double availableAmount, double feeAmount, Transactions? deletedTran,
      Function(Transactions transaction, Transactions? deletedTran) callback) {
    final Transactions transaction = _createTransaction(availableAmount, feeAmount);
    if (transaction.withFee != true) {
      transaction.feeAmount = 0;
    }
    db.insert(tableName, transaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace).then((_) => callback(transaction, deletedTran));
  }

  Transactions _createTransaction(double amount, double feeAmount) {
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
            feeAmount: feeAmount,
            amount: amount,
            account: _selectedAccount!,
            currencyUid: _selectedCurrency.id,
            updatedDateTime: DateTime.now(),
            skipReport: _skipReport);
      case TransactionType.expense:
        return ExpenseTransaction(
            id: const UuidV8().generate(),
            transactionDate: _selectedTxnDate,
            transactionTime: _selectedTxnTime,
            transactionCategory: _selectedCategory,
            description: _transactionDescriptionController.text,
            withFee: _haveFee,
            feeAmount: feeAmount,
            amount: amount,
            account: _selectedAccount!,
            currencyUid: _selectedCurrency.id,
            updatedDateTime: DateTime.now(),
            skipReport: _skipReport);
      case TransactionType.transfer:
        return TransferTransaction(
            id: const UuidV8().generate(),
            transactionDate: _selectedTxnDate,
            transactionTime: _selectedTxnTime,
            transactionCategory: _selectedCategory,
            description: _transactionDescriptionController.text,
            withFee: _haveFee,
            feeAmount: feeAmount,
            amount: amount,
            account: _selectedAccount!,
            currencyUid: _selectedCurrency.id,
            toAccount: _selectedToAccount!,
            updatedDateTime: DateTime.now(),
            feeApplyTo: _feeApplyToFromAccount,
            skipReport: _skipReport);
      case TransactionType.lend:
        return LendTransaction(
            id: const UuidV8().generate(),
            transactionDate: _selectedTxnDate,
            transactionTime: _selectedTxnTime,
            transactionCategory: _selectedCategory,
            description: _transactionDescriptionController.text,
            withFee: _haveFee,
            feeAmount: feeAmount,
            amount: amount,
            account: _selectedAccount!,
            currencyUid: _selectedCurrency.id,
            updatedDateTime: DateTime.now(),
            skipReport: _skipReport);
      case TransactionType.borrowing:
        return BorrowingTransaction(
            id: const UuidV8().generate(),
            transactionDate: _selectedTxnDate,
            transactionTime: _selectedTxnTime,
            transactionCategory: _selectedCategory,
            description: _transactionDescriptionController.text,
            withFee: _haveFee,
            feeAmount: feeAmount,
            amount: amount,
            account: _selectedAccount!,
            currencyUid: _selectedCurrency.id,
            updatedDateTime: DateTime.now(),
            skipReport: _skipReport);
      case TransactionType.adjustment:
        double adjustedAmount = 0;
        if (_selectedAccount is LoanAccount) {
          adjustedAmount = (_selectedAccount as LoanAccount).loanAmount - amount;
        } else {
          adjustedAmount = _selectedAccount!.availableAmount - amount;
        }
        return AdjustmentTransaction(
            id: const UuidV8().generate(),
            transactionDate: _selectedTxnDate,
            transactionTime: _selectedTxnTime,
            transactionCategory: _selectedCategory,
            description: _transactionDescriptionController.text,
            withFee: _haveFee,
            feeAmount: feeAmount,
            amount: amount,
            account: _selectedAccount!,
            currencyUid: _selectedCurrency.id,
            updatedDateTime: DateTime.now(),
            adjustedAmount: adjustedAmount,
            skipReport: _skipReport);
      case TransactionType.shareBill:
        var mySplit = FormUtil().parseAmount(_transactionMySplitAmountController.text, moneyFormat)!;
        return ShareBillTransaction(
            id: const UuidV8().generate(),
            transactionDate: _selectedTxnDate,
            transactionTime: _selectedTxnTime,
            transactionCategory: _selectedCategory,
            description: _transactionDescriptionController.text,
            withFee: _haveFee,
            feeAmount: feeAmount,
            amount: amount,
            account: _selectedAccount!,
            currencyUid: _selectedCurrency.id,
            mySplit: mySplit,
            updatedDateTime: DateTime.now(),
            skipReport: _skipReport);
      case TransactionType.shareBillReturn:
        return ShareBillReturnTransaction(
          id: const UuidV8().generate(),
          transactionDate: _selectedTxnDate,
          transactionTime: _selectedTxnTime,
          transactionCategory: _selectedCategory,
          description: _transactionDescriptionController.text,
          withFee: _haveFee,
          feeAmount: feeAmount,
          amount: amount,
          account: _selectedAccount!,
          currencyUid: _selectedCurrency.id,
          updatedDateTime: DateTime.now(),
          skipReport: _skipReport,
          sharedBill: _selectedBillToReturn,
        );
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

  List<DropdownMenuItem<TransactionType>> _buildTransactionTypeDropdownMenuEntries(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;
    List<List<dynamic>> iconMap = [
      [TransactionType.income, incomeIconData, Colors.green, 1.0, appLocalization.transactionTypeIncome],
      [TransactionType.expense, expenseIconData, Colors.red, 1.0, appLocalization.transactionTypeExpense],
      // [TransactionType.lend, lendIconData, Colors.blue, 1.0, appLocalization.transactionTypeLend],
      // [TransactionType.borrowing, Icons.add_business_sharp, Colors.blue, 1.0, appLocalization.transactionTypeBorrowing],
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
              _currencyTextInputFormatter = FormUtil().buildFormatter(_selectedCurrency);
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

  List<Widget> _buildShareBillSelectionItemDisplay(BuildContext context, ThemeData theme, ShareBillTransaction? sharedBill) {
    final category = sharedBill?.transactionCategory;
    IconData? iconData = category?.icon;
    String text = "";
    if (sharedBill != null) {
      if (_selectedBillToReturn!.description.isNotEmpty == true) {
        text = _selectedBillToReturn!.description;
      } else {
        text = category?.getTitleText(currentAppState.systemSetting) ?? "";
      }
    }
    return [if (iconData != null) Icon(iconData, color: theme.iconTheme.color), const SizedBox(width: 5), Text(text)];
  }

  void _chooseSharedBill(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Get the current screen size
    final Size screenSize = MediaQuery.of(context).size;
    // Set min and max size based on the screen size
    final double maxWidth = screenSize.width * 0.9; // 80% of screen width
    final double maxHeight = screenSize.height * 0.9; // 50% of screen height
    Widget dialogBody;
    if (_inCompletedSharedBills.isEmpty) {
      dialogBody = const NoDataCard();
    } else {
      dialogBody = SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              minHeight: 0, maxHeight: TransactionItemConfigKey.eachTransactionHeight + 4, maxWidth: screenSize.width * 0.85),
          child: ListView(
            children: <Widget>[
              for (var item in _inCompletedSharedBills)
                SharedBillTransactionTileForDialog(
                  transaction: item,
                  onTap: (Transactions transaction) {
                    _selectedBillToReturn = transaction as ShareBillTransaction;
                    Navigator.of(context).pop();
                    setState(() {});
                  },
                )
            ],
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.transactionInCompleteSharedBillDialogTitle),
        content: SizedBox(width: maxWidth, height: maxHeight, child: dialogBody),
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
