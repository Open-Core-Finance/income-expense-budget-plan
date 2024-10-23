import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';

class SqlImport extends StatefulWidget {
  final bool showBackArrow;
  const SqlImport({super.key, required this.showBackArrow});

  @override
  State<SqlImport> createState() => _SqlImportState();
}

class _SqlImportState extends State<SqlImport> {
  PlatformFile? _selectedFile;
  DatabaseService databaseService = DatabaseService();
  Util util = Util();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    Widget? leading;
    if (widget.showBackArrow) {
      leading = IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.error),
        onPressed: () => Navigator.of(context).pop(),
      );
    }
    return Scaffold(
      appBar: AppBar(leading: leading, title: Text(appLocalizations.sqlImportMenu)),
      body: Padding(
        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("SQL file:"),
                SizedBox(width: 5),
                Expanded(
                  child: Text(_selectedFile?.path ?? "",
                      style: TextStyle(backgroundColor: Colors.grey, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                SizedBox(width: 5),
                ElevatedButton.icon(
                  onPressed: () {
                    FilePicker.platform
                        .pickFiles(type: FileType.custom, allowedExtensions: ['sql', 'txt', 'dat']).then((FilePickerResult? result) {
                      if (result != null) {
                        setState(() => _selectedFile = result.files.first);
                      }
                    });
                  },
                  icon: Icon(Icons.file_open, color: theme.primaryColor),
                  label: Text("Select file"),
                ),
              ],
            ),
            SizedBox(height: 10),
            if (_selectedFile != null)
              Row(children: [
                ElevatedButton.icon(
                  onPressed: () => File(_selectedFile!.path!)
                      .readAsString()
                      .then((content) => databaseService.executeSqlContent(content).then((success) {
                            if (context.mounted) {
                              if (success) {
                                _selectedFile = null;
                                util.showSuccessDialog(context, "SQL executed successfully!", () {});
                              } else {
                                util.showSuccessDialog(context, "SQL executed fail!", () {});
                              }
                            }
                          })),
                  icon: Icon(Icons.play_arrow, color: theme.primaryColor),
                  label: Text("Execute as SQL"),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => File(_selectedFile!.path!).readAsString().then(
                        (content) => databaseService.executeTriggersSqlFile(content).then((success) {
                          if (context.mounted) {
                            if (success) {
                              _selectedFile = null;
                              util.showSuccessDialog(context, "Trigger executed successfully!", () {});
                            } else {
                              util.showSuccessDialog(context, "Trigger executed fail!", () {});
                            }
                          }
                        }),
                      ),
                  icon: Icon(Icons.play_arrow, color: theme.primaryColor),
                  label: Text("Execute as trigger"),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}
