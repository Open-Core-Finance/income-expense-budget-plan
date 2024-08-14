import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:income_expense_budget_plan/common/transaction_category_tree.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/category_util.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/v8.dart';

class TransactionCategoriesPanel extends StatefulWidget {
  final String listPanelTitle;
  final String addPanelTitle;
  const TransactionCategoriesPanel({
    super.key,
    required this.listPanelTitle,
    required this.addPanelTitle,
  });

  @override
  State<TransactionCategoriesPanel> createState() => _TransactionCategoriesPanelState();
}

class _TransactionCategoriesPanelState extends State<TransactionCategoriesPanel> {
  @override
  Widget build(BuildContext context) {
    final transactionCategoriesListenable = Provider.of<TransactionCategoriesListenable>(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.secondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.listPanelTitle),
      ),
      floatingActionButton: FloatingActionButton(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        shape: const CircleBorder(),
        onPressed: () {
          Util().navigateTo(
            context,
            AddTransactionCategoryPanel(
              addPanelTitle: widget.addPanelTitle,
              transactionCategoriesListenable: transactionCategoriesListenable,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<TransactionCategoriesListenable>(
        builder: (BuildContext context, TransactionCategoriesListenable value, Widget? child) =>
            TransactionCategoryTree(categories: value.categories),
      ),
    );
  }
}

class AddTransactionCategoryPanel extends StatefulWidget {
  final String addPanelTitle;
  final TransactionCategoriesListenable transactionCategoriesListenable;
  const AddTransactionCategoryPanel({super.key, required this.addPanelTitle, required this.transactionCategoriesListenable});

  @override
  State<AddTransactionCategoryPanel> createState() => _AddTransactionCategoryPanelState();
}

class _AddTransactionCategoryPanelState extends State<AddTransactionCategoryPanel> {
  late bool _isChecking;
  late bool _isValidCategoryName;
  late IconData _selectedIcon;
  late TextEditingController _categoryNameController;
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();
  late String transactionCategoryParentLabel;
  TransactionCategory? _selectedParentCategory;

  @override
  void initState() {
    super.initState();
    _initEmptyForm();
  }

  _initEmptyForm() {
    _selectedIcon = defaultIconData;
    _categoryNameController = TextEditingController(text: '');
    _isChecking = false;
    _isValidCategoryName = false;
  }

  @override
  Widget build(BuildContext context) {
    final String categoryNameLabel = AppLocalizations.of(context)!.transactionCategoryName;
    final String transactionCategoryActionSaveLabel = AppLocalizations.of(context)!.transactionCategoryActionSave;
    final String transactionCategoryActionSaveAddMoreLabel = AppLocalizations.of(context)!.transactionCategoryActionSaveAddMore;
    final String transactionCategoryActionSelectIconLabel = AppLocalizations.of(context)!.transactionCategoryActionSelectIcon;
    transactionCategoryParentLabel = AppLocalizations.of(context)!.transactionCategoryParent;
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.error),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.addPanelTitle),
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
                  Text(transactionCategoryActionSelectIconLabel),
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
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: categoryNameLabel,
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
                  Text(transactionCategoryParentLabel),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 100, 0),
                      child: ElevatedButton(
                        onPressed: () => _chooseParentCategory(context),
                        child: Row(children: _buildParentCategoryDisplay(theme)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: CategoryUtil().buildCategoryFormActions(
                  context,
                  () {
                    _validateForm(context, () {
                      Navigator.of(context).pop();
                    });
                  },
                  _isChecking,
                  transactionCategoryActionSaveLabel,
                  () {
                    _validateForm(context, () {
                      _initEmptyForm();
                    });
                  },
                  transactionCategoryActionSaveAddMoreLabel,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _validateForm(BuildContext context, Function() callback) async {
    final transactionCategoriesListenable = widget.transactionCategoriesListenable;
    setState(() {
      _isChecking = true;
      _isValidCategoryName = true;
    });
    var future = TransactionDao().loadCategoryByTransactionTypeAndName(
      transactionCategoriesListenable.transactionType,
      _categoryNameController.text,
    );
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
      TransactionCategory transactionCategory = TransactionCategory(
        uid: const UuidV8().generate(),
        icon: _selectedIcon,
        name: _categoryNameController.text,
        transactionType: transactionCategoriesListenable.transactionType,
        parentUid: _selectedParentCategory?.uid,
      );
      DatabaseService().database.then((db) {
        db.insert(tableNameTransactionCategory, transactionCategory.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        setState(() {
          transactionCategoriesListenable.addItem(transactionCategory);
          callback();
        });
      });
    }
  }

  void _chooseParentCategory(BuildContext context) {
    final transactionCategoriesListenable = widget.transactionCategoriesListenable;
    final ThemeData theme = Theme.of(context);
    // Get the current screen size
    final Size screenSize = MediaQuery.of(context).size;
    // Set min and max size based on the screen size
    final double maxWidth = screenSize.width * 0.9; // 80% of screen width
    final double maxHeight = screenSize.height * 0.9; // 50% of screen height
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(transactionCategoryParentLabel),
          scrollable: true,
          content: SizedBox(
            width: maxWidth,
            height: maxHeight,
            child: TransactionCategoryTree(
              categories: transactionCategoriesListenable.categories,
              itemTap: (TransactionCategory item) {
                setState(() {
                  _selectedParentCategory = item;
                });
                Navigator.of(context).pop();
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ButtonStyle(foregroundColor: WidgetStateProperty.all(theme.colorScheme.error)),
              child: Text(AppLocalizations.of(context)!.actionClose),
            )
          ],
        );
      },
    );
  }

  List<Widget> _buildParentCategoryDisplay(ThemeData theme) {
    final selectedParentCategory = _selectedParentCategory;
    if (selectedParentCategory != null) {
      return [Icon(selectedParentCategory.icon, color: theme.iconTheme.color), const SizedBox(width: 5), Text(selectedParentCategory.name)];
    } else {
      return [const Text("")];
    }
  }
}
