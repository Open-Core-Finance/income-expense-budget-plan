import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/model/data_import_result.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/data_export_import.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';

abstract class FileImport extends StatefulWidget {
  final bool showBackArrow;
  const FileImport({super.key, required this.showBackArrow});
}

abstract class _FileImportState<T extends FileImport> extends State<T> {
  String? _filePath;
  DatabaseService databaseService = DatabaseService();
  Util util = Util();

  List<String>? getAllowedFileTypes();

  Widget buildFileSelectionRow(BuildContext context, AppLocalizations appLocalizations, String label, String buttonLabel, bool isSave) {
    final ThemeData theme = Theme.of(context);
    TextStyle filePathStyle = TextStyle(backgroundColor: Colors.grey, color: Colors.white);
    return Row(
      children: [
        Text(label),
        SizedBox(width: 5),
        Expanded(child: Text(_filePath ?? "", style: filePathStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
        SizedBox(width: 5),
        ElevatedButton.icon(
          onPressed: pickFile,
          icon: Icon(Icons.file_open, color: theme.primaryColor),
          label: Text(buttonLabel),
        ),
      ],
    );
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

  void pickFile({Function(FilePickerResult? pickedFile)? callback}) {
    if (Platform.isAndroid || Platform.isIOS) {
      FilePicker.platform.pickFiles().then((FilePickerResult? pickedFile) {
        if (pickedFile != null) {
          setState(() {
            _filePath = pickedFile.files.first.path;
          });
          if (callback != null) callback(pickedFile);
        }
      });
    } else {
      FilePicker.platform.pickFiles().then((FilePickerResult? pickedFile) {
        if (pickedFile != null) {
          setState(() {
            _filePath = pickedFile.files.first.path;
          });
          if (callback != null) callback(pickedFile);
        }
      });
    }
  }
}

class SqlImport extends FileImport {
  const SqlImport({super.key, required super.showBackArrow});

  @override
  State<SqlImport> createState() => _SqlImportState();
}

class _SqlImportState extends _FileImportState<SqlImport> {
  final List<String> _allowedExtensions = ['sql'];

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: buildAppBar(context, appLocalizations, appLocalizations.sqlImportMenu),
      body: Padding(
        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(databaseService.databasePath),
            buildFileSelectionRow(
                context, appLocalizations, appLocalizations.sqlImportFileLabel, appLocalizations.sqlImportSelectFile, false),
            ..._buildButtonBar(context)
          ],
        ),
      ),
    );
  }

  List<Widget> _buildButtonBar(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    List<Widget> result = [SizedBox(height: 20)];
    if (_filePath != null) {
      var execSqlButton = ElevatedButton.icon(
        onPressed: () => _executeSqlContent(context, _filePath!),
        icon: Icon(Icons.play_arrow, color: theme.primaryColor),
        label: Text(appLocalizations.sqlImportFileButtonSqlExe),
      );
      var execProcedureButton = ElevatedButton.icon(
        onPressed: () => _executeSqlTriggerContent(context, _filePath!),
        icon: Icon(Icons.play_arrow, color: theme.primaryColor),
        label: Text(appLocalizations.sqlImportFileButtonTriggerExe),
      );
      if (currentAppState.isMobile) {
        result.add(execSqlButton);
        result.add(SizedBox(height: 10));
        result.add(execProcedureButton);
      } else {
        result.add(
          Row(children: [execSqlButton, SizedBox(width: 10), execProcedureButton]),
        );
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> _executeSqlContent(BuildContext context, String filePath) async {
    var content = await File(filePath).readAsString();
    var result = databaseService.executeSqlContent(content);
    result.then((resultMap) {
      if (context.mounted) _showExecuteResult(context, resultMap, "SQL");
      currentAppState.needRefreshTxnPanel = true;
    });
    return result;
  }

  Future<Map<String, dynamic>> _executeSqlTriggerContent(BuildContext context, String filePath) async {
    var content = await File(filePath).readAsString();
    Future<Map<String, dynamic>> result = databaseService.executeTriggersSqlFile(content);
    result.then((resultMap) {
      if (context.mounted) _showExecuteResult(context, resultMap, "Trigger");
      currentAppState.needRefreshTxnPanel = true;
    });
    return result;
  }

  void _showExecuteResult(BuildContext context, Map<String, dynamic> resultMap, String execType) async {
    emptyCallback() {}
    if (resultMap[DatabaseService.execMapSuccessKey] == true) {
      setState(() => _filePath = null);
      util.showSuccessDialog(context, AppLocalizations.of(context)!.sqlImportFileExecSuccessfully(execType), emptyCallback);
    } else {
      var error = resultMap[DatabaseService.execMapErrDetailsKey];
      util.showErrorDialog(context, '${AppLocalizations.of(context)!.sqlImportFileExecFail(execType)}. Error: $error', emptyCallback);
    }
  }

  @override
  List<String>? getAllowedFileTypes() {
    return _allowedExtensions;
  }
}

class DataFileImport extends FileImport {
  const DataFileImport({super.key, required super.showBackArrow});

  @override
  State<DataFileImport> createState() => _DataFileImportState();
}

class _DataFileImportState extends _FileImportState<DataFileImport> {
  /// 0: skip if existed.
  /// 1: force override.
  /// 2: override if newer.
  int _overrideMode = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    var dataPadding = EdgeInsets.fromLTRB(10, 0, 10, 0);
    return Scaffold(
      appBar: buildAppBar(context, appLocalizations, appLocalizations.dataImportFileMenu),
      body: Padding(
        padding: dataPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFileSelectionRow(
                context, appLocalizations, appLocalizations.dataImportFileLabel, appLocalizations.dataImportSelectFile, false),
            SizedBox(height: 20),
            DropdownButtonFormField<int>(
                value: _overrideMode,
                icon: const Icon(Icons.arrow_downward),
                elevation: 16,
                style: TextStyle(color: theme.primaryColor),
                onChanged: (int? value) {
                  if (value != null) setState(() => _overrideMode = value);
                },
                items: [
                  DropdownMenuItem<int>(
                      value: DataImport.dataOverrideModeSkip,
                      child: Padding(padding: dataPadding, child: Text(appLocalizations.dataImportOverrideSkip))),
                  DropdownMenuItem<int>(
                      value: DataImport.dataOverrideModeOverrideNewer,
                      child: Padding(padding: dataPadding, child: Text(appLocalizations.dataImportOverrideIfNewer))),
                  DropdownMenuItem<int>(
                      value: DataImport.dataOverrideModeOverrideAlways,
                      child: Padding(padding: dataPadding, child: Text(appLocalizations.dataImportOverrideAlways)))
                ],
                decoration: InputDecoration(labelText: appLocalizations.dataImportOverrideMode, border: OutlineInputBorder())),
            SizedBox(height: 20),
            if (_filePath != null)
              Row(children: [
                ElevatedButton.icon(
                  onPressed: () => _importData(context, _filePath!),
                  icon: Icon(Icons.play_arrow, color: theme.primaryColor),
                  label: Text(appLocalizations.dataImportFileButton),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  void _importData(BuildContext context, String filePath) async {
    File(filePath).readAsString().then((content) {
      if (context.mounted) {
        DataImportV1().readFileData(context, File(filePath), _overrideMode).then((result) {
          if (context.mounted) {
            showDialog(
                context: context,
                builder: (BuildContext context) => _resultDialogContent(context, result, () => currentAppState.needRefreshTxnPanel = true));
          }
        }, onError: (e) {
          if (context.mounted) {
            util.showErrorDialog(context, '${AppLocalizations.of(context)!.dataImportFileFail}. Error: $e', () {});
          }
        });
      }
    });
  }

  @override
  List<String>? getAllowedFileTypes() {
    return null;
  }

  List<Widget> _buildImportResultListDisplay(BuildContext context, DataImportResult dataImportResult) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return [
      Divider(height: 1),
      ListTile(title: Text(dataImportResult.dataLabel, style: TextStyle(fontWeight: FontWeight.bold))),
      if (dataImportResult.countSuccess != 0)
        ListTile(title: Text('--> ${appLocalizations.dataImportResultCountSuccess(dataImportResult.countSuccess)}')),
      if (dataImportResult.countError != 0)
        ListTile(title: Text('--> ${appLocalizations.dataImportResultCountFail(dataImportResult.countError)}')),
      if (dataImportResult.countSkipped != 0)
        ListTile(title: Text('--> ${appLocalizations.dataImportResultCountSkip(dataImportResult.countSkipped)}')),
      if (dataImportResult.countOverride != 0)
        ListTile(title: Text('--> ${appLocalizations.dataImportResultCountOverride(dataImportResult.countOverride)}'))
    ];
  }

  Widget _resultDialogContent(BuildContext context, Map<int, DataImportResult> result, Function()? callback) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    List<Widget> body = [];
    for (var entry in result.entries) {
      body.addAll(_buildImportResultListDisplay(context, entry.value));
    }
    return Scaffold(
      appBar: AppBar(title: Text(appLocalizations.dataImportResultDialogTitle), automaticallyImplyLeading: false),
      body: ListView(children: body),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              child: Text(appLocalizations.actionConfirm),
              onPressed: () {
                Navigator.of(context).pop();
                if (callback != null) {
                  callback();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
