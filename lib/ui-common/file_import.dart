import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
      FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: getAllowedFileTypes()).then((FilePickerResult? pickedFile) {
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
    final ThemeData theme = Theme.of(context);
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

  void _executeSqlContent(BuildContext context, String filePath) async {
    File(filePath).readAsString().then((content) {
      databaseService.executeSqlContent(content).then(
            (resultMap) => (context.mounted ? _showExecuteResult(context, resultMap, "SQL") : {}),
          );
    });
  }

  void _executeSqlTriggerContent(BuildContext context, String filePath) async {
    File(filePath).readAsString().then((content) {
      databaseService.executeTriggersSqlFile(content).then(
            (resultMap) => (context.mounted ? _showExecuteResult(context, resultMap, "Trigger") : {}),
          );
    });
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
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: buildAppBar(context, appLocalizations, appLocalizations.dataImportFileMenu),
      body: Padding(
        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFileSelectionRow(
                context, appLocalizations, appLocalizations.dataImportFileLabel, appLocalizations.dataImportSelectFile, false),
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
      DataImportV1().readFileData(File(filePath)).then((success) {
        setState(() => _filePath = null);
        if (context.mounted) {
          util.showSuccessDialog(context, AppLocalizations.of(context)!.dataImportFileSuccess, () {});
        }
      }, onError: (e) {
        if (context.mounted) {
          util.showErrorDialog(context, '${AppLocalizations.of(context)!.dataImportFileFail}. Error: $e', () {});
        }
      });
    });
  }

  @override
  List<String>? getAllowedFileTypes() {
    return null;
  }
}
