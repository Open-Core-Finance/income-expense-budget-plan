import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/dao/assets_dao.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/data_export_import.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';

import 'package:income_expense_budget_plan/service/util.dart';
import 'package:intl/intl.dart';

/// import 'package:income_expense_budget_plan/service/permission_request_widget.dart';
/// import 'package:permission_handler/permission_handler.dart';

class DataFileExport extends StatefulWidget {
  final bool showBackArrow;
  const DataFileExport({super.key, required this.showBackArrow});

  @override
  State<DataFileExport> createState() => _DataFileExportState();
}

class _DataFileExportState extends State<DataFileExport> with TickerProviderStateMixin {
  final DateFormat dateFormat = DateFormat("yyyy-MM-dd");
  late DateTime _fromDate;
  late DateTime _toDate;
  late TextEditingController _fromDateController;
  late TextEditingController _toDateController;
  late DateTime _firstDate;
  late DateTime _lastDate;
  bool _saveInProgress = false;
  late AnimationController _progressController;
  final _formKey = GlobalKey<FormState>();

  DatabaseService databaseService = DatabaseService();
  Util util = Util();

  // Map<Permission, PermissionStatus> _requiredPermissions = {};

  @override
  void initState() {
    /// [AnimationController]s can be created with `vsync: this` because of [TickerProviderStateMixin].
    // _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 5))
    _progressController = AnimationController(vsync: this)
      ..addListener(() {
        setState(() {});
      });
    _progressController.value = 0.5;
    super.initState();
    _toDate = DateTime.now();
    _fromDate = _toDate.subtract(Duration(days: 30));
    _fromDateController = TextEditingController(text: dateFormat.format(_fromDate));
    _toDateController = TextEditingController(text: dateFormat.format(_toDate));
    _firstDate = DateTime(_toDate.year - 3);
    _lastDate = DateTime(_toDate.year + 3);

    // List required permission
    // _requiredPermissions = {Permission.storage: PermissionStatus.denied, Permission.manageExternalStorage: PermissionStatus.denied};
    // for (var perEntry in _requiredPermissions.entries) {
    //   perEntry.key.status.then((status) => _requiredPermissions[perEntry.key] = status);
    // }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: buildAppBar(context, appLocalizations, appLocalizations.dataExportFileMenu),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              // ...[for (var perEntry in _requiredPermissions.entries) PermissionWidget(permission: perEntry.key)],
              SizedBox(height: 10),
              TextFormField(
                controller: _fromDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: appLocalizations.dataExportFileExportFromDate,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDate(context, true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return appLocalizations.selectDateEmpty;
                  }
                  if (!isFromDateLessThanToDate(_fromDate, _toDate)) {
                    return appLocalizations.dataExportFileDateRangeError;
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _toDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: appLocalizations.dataExportFileExportToDate,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDate(context, false),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return appLocalizations.selectDateEmpty;
                  }

                  if (!isFromDateLessThanToDate(_fromDate, _toDate)) {
                    return appLocalizations.dataExportFileDateRangeError;
                  }
                  return null;
                },
              ),
              if (_saveInProgress) ...[
                SizedBox(height: 20),
                LinearProgressIndicator(
                  value: _progressController.value,
                  semanticsLabel: 'Linear progress indicator',
                ),
              ],
              SizedBox(height: 20),
              Row(children: [
                if (!_saveInProgress && (_formKey.currentState == null || _formKey.currentState!.validate()))
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _exportData(context);
                      }
                    },
                    icon: Icon(Icons.play_arrow, color: theme.primaryColor),
                    label: Text(appLocalizations.dataExportFileExportButton),
                  ),
                if (_saveInProgress)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _saveInProgress = false;
                      });
                    },
                    icon: Icon(Icons.play_arrow, color: theme.primaryColor),
                    label: Text(appLocalizations.dataExportFileCancelButton),
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  String _buildDefaultFileName() {
    return "income-expense-data-${DateFormat("yyyy-MM-dd-hh-mm-ss").format(DateTime.now())}.${DataExport.autoAppendMissingExtension}";
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    DateTime? pickedDate =
        await showDatePicker(context: context, initialDate: isFromDate ? _fromDate : _toDate, firstDate: _firstDate, lastDate: _lastDate);

    if (pickedDate != null) {
      TextEditingController dateController;
      if (isFromDate) {
        _fromDate = pickedDate;
        dateController = _fromDateController;
      } else {
        _toDate = pickedDate;
        dateController = _toDateController;
      }
      setState(() {
        dateController.text = dateFormat.format(pickedDate);
        _formKey.currentState?.validate();
      });
    }
  }

  void _exportDataDesktop(BuildContext context, String outputFile) async {
    if (kDebugMode) {
      print("Exporting data to [$outputFile] ...");
    }
    setState(() {
      _saveInProgress = true;
    });
    int totalDataCount = currentAppState.currencies.length + currentAppState.assetCategories.length + currentAppState.assets.length;
    setState(() {
      _progressController.reset();
    });

    var txnListFuture = TransactionDao().transactionsFromDateRange(DateTimeRange(start: _fromDate, end: _toDate));
    var accountCategoriesFuture = AssetsDao().assetCategories();
    var txnCategoriesFuture = databaseService.loadListModel(tableNameTransactionCategory, TransactionCategory.fromMap);

    var txnList = await txnListFuture;
    var txnCategories = await txnCategoriesFuture;
    var accountCategories = await accountCategoriesFuture;
    totalDataCount += txnList.length + txnCategories.length + accountCategories.length;

    int savedCount = 0;
    int refreshRate = 1;
    if (totalDataCount > 20) {
      refreshRate = totalDataCount ~/ 20;
    }
    increaseSavedCount() {
      savedCount++;
      if ((savedCount % refreshRate) == 0) {
        setState(() {
          _progressController.animateTo(savedCount / totalDataCount, duration: Duration(seconds: 1));
        });
      }
    }

    try {
      await DataExportV1().writingDataDesktop(
          file: File(outputFile),
          currencies: currentAppState.currencies,
          categories: accountCategories,
          assets: currentAppState.assets,
          transactionCategories: txnCategories,
          transactions: txnList,
          lineWroteListener: increaseSavedCount,
          isTerminated: _isTerminated);
      await Future.delayed(Duration(seconds: 1));
      if (context.mounted) {
        util.showSuccessDialog(context, AppLocalizations.of(context)!.dataExportFileSuccess, () {});
      }
    } catch (e) {
      await Future.delayed(Duration(seconds: 1));
      if (context.mounted) {
        util.showErrorDialog(context, '${AppLocalizations.of(context)!.dataExportFileFail}. Error: $e', () {});
      }
    }
    setState(() {
      _saveInProgress = false;
    });
  }

  void _exportDataMobile(BuildContext context) async {
    setState(() {
      _saveInProgress = true;
    });
    int totalDataCount = currentAppState.currencies.length + currentAppState.assetCategories.length + currentAppState.assets.length;
    setState(() {
      _progressController.reset();
    });

    var txnListFuture = TransactionDao().transactionsFromDateRange(DateTimeRange(start: _fromDate, end: _toDate));
    var accountCategoriesFuture = AssetsDao().assetCategories();
    var txnCategoriesFuture = databaseService.loadListModel(tableNameTransactionCategory, TransactionCategory.fromMap);

    var txnList = await txnListFuture;
    var txnCategories = await txnCategoriesFuture;
    var accountCategories = await accountCategoriesFuture;
    totalDataCount += txnList.length + txnCategories.length + accountCategories.length;

    int savedCount = 0;
    int refreshRate = 1;
    if (totalDataCount > 20) {
      refreshRate = totalDataCount ~/ 20;
    }
    increaseSavedCount() {
      savedCount++;
      if ((savedCount % refreshRate) == 0) {
        setState(() {
          _progressController.animateTo(savedCount / totalDataCount, duration: Duration(seconds: 1));
        });
      }
    }

    try {
      var data = await DataExportV1().writingDataMobile(
          currencies: currentAppState.currencies,
          categories: accountCategories,
          assets: currentAppState.assets,
          transactionCategories: txnCategories,
          transactions: txnList,
          lineWroteListener: increaseSavedCount,
          isTerminated: _isTerminated);
      await Future.delayed(Duration(seconds: 1));
      String fileName = _buildDefaultFileName();
      FilePicker.platform.saveFile(bytes: data, fileName: fileName).then((String? outputFile) {
        if (kDebugMode) {
          print("Exporting data to [$outputFile] ...");
        }
        if (context.mounted) {
          if (outputFile != null) {
            util.showSuccessDialog(context, AppLocalizations.of(context)!.dataExportFileSuccess, () {});
          } else {
            util.showErrorDialog(context, '${AppLocalizations.of(context)!.dataExportFileFail}.', () {});
          }
        }
      });
    } catch (e) {
      await Future.delayed(Duration(seconds: 1));
      if (context.mounted) {
        util.showErrorDialog(context, '${AppLocalizations.of(context)!.dataExportFileFail}. Error: $e', () {});
      }
    }
    setState(() {
      _saveInProgress = false;
    });
  }

  bool isFromDateLessThanToDate(DateTime fromDate, DateTime toDate) {
    // I'm not sure why compareTo not working somehow. I need to re-write it here.
    int fromDateVal = (fromDate.year * 365) + (fromDate.month * 31) + fromDate.day;
    int toDateVal = (toDate.year * 365) + (toDate.month * 31) + toDate.day;
    return fromDateVal - toDateVal <= 0;
  }

  bool _isTerminated() {
    // TODO implement terminate support later
    return false;
  }

  AppBar buildAppBar(BuildContext context, AppLocalizations appLocalizations, String title) {
    final ThemeData theme = Theme.of(context);
    Widget? leading;
    if (widget.showBackArrow) {
      leading = IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.error),
        onPressed: () => Navigator.of(context).pop(),
      );
    }
    return AppBar(leading: leading, title: Text(title));
  }

  void _exportData(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      if (Platform.isAndroid || Platform.isIOS) {
        _exportDataMobile(context);
      } else {
        String fileName = _buildDefaultFileName();
        FilePicker.platform
            .saveFile(type: FileType.custom, allowedExtensions: DataExport.allowedExtensions, fileName: fileName)
            .then((String? outputFile) {
          if (context.mounted) {
            if (outputFile != null) {
              _exportDataDesktop(context, outputFile);
            } else {
              util.showErrorDialog(context, '${AppLocalizations.of(context)!.dataExportFileFail}.', () {});
            }
          }
        });
      }
    }
  }
}
