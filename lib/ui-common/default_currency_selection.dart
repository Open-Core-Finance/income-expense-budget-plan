import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/service/account_service.dart';
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
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    Widget? bottomBar;
    if (_selectedCurrency != null) {
      bottomBar = BottomAppBar(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              child: Text(appLocalizations.actionConfirm),
              onPressed: () {
                if (_selectedCurrency != null) {
                  var selectedCurrencyId = _selectedCurrency!.id!;
                  currentAppState.systemSetting.defaultCurrencyUid = selectedCurrencyId;
                  currentAppState.systemSetting.defaultCurrency = _selectedCurrency;
                  DatabaseService().database.then((db) {
                    db.update(tableNameSetting, currentAppState.systemSetting.toMap(),
                        where: "id = ?", whereArgs: ["1"], conflictAlgorithm: ConflictAlgorithm.replace);
                    db.execute("update $tableNameAsset set currency_uid=$selectedCurrencyId").then((_) => AccountService().refreshAssets());
                  });
                  Navigator.of(context).pop();
                } else {
                  Util().showErrorDialog(context, appLocalizations.currencyDialogEmptySelectionError, null);
                }
              },
            ),
          ],
        ),
      );
    }
    return Scaffold(
      // appBar: appBar,
      body: SingleChildScrollView(
        child: ListBody(children: <Widget>[
          ListTile(
            leading: Icon(Icons.flag),
            title: Text(appLocalizations.clickSelectLanguage),
            subtitle: Text(currentAppState.systemSetting.currentLanguageText),
            onTap: () => Util().chooseLanguage(context),
            iconColor: colorScheme.primary,
          ),
          ListTile(title: Text(appLocalizations.currencyDialogTitleSelectDefault), iconColor: colorScheme.primary),
          for (var currency in currentAppState.currencies)
            RadioListTile(
              title: Text("${currency.name} (${currency.symbol})"),
              value: currency,
              groupValue: _selectedCurrency,
              onChanged: (Currency? value) => setState(() => _selectedCurrency = value),
            ),
        ]),
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}
