import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sqflite/sqflite.dart';

class DefaultCurrencySelectionDialog extends StatefulWidget {
  const DefaultCurrencySelectionDialog({super.key});

  @override
  State<DefaultCurrencySelectionDialog> createState() => _DefaultCurrencySelectionDialog();
}

class _DefaultCurrencySelectionDialog extends State<DefaultCurrencySelectionDialog> {
  Currency? _selectedCurrency;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.currencyDialogTitleSelectDefault),
      content: SingleChildScrollView(
        child: ListBody(children: <Widget>[
          for (var currency in currentAppState.currencies)
            RadioListTile(
              title: Text("${currency.name} (${currency.symbol})"),
              value: currency,
              groupValue: _selectedCurrency,
              onChanged: (Currency? value) => setState(() => _selectedCurrency = value),
            ),
        ]),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(AppLocalizations.of(context)!.actionConfirm),
          onPressed: () {
            if (_selectedCurrency != null) {
              currentAppState.systemSetting.defaultCurrencyUid = _selectedCurrency?.id;
              currentAppState.systemSetting.defaultCurrency = _selectedCurrency;
              DatabaseService().database.then((db) {
                db.update(tableNameSetting, currentAppState.systemSetting.toMap(),
                    where: "id = ?", whereArgs: ["1"], conflictAlgorithm: ConflictAlgorithm.replace);
              });
              Navigator.of(context).pop();
            } else {
              Util().showErrorDialog(context, AppLocalizations.of(context)!.currencyDialogEmptySelectionError, null);
            }
          },
        ),
      ],
    );
  }
}
