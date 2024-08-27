import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/extensions/string_extensions.dart';
import 'package:income_expense_budget_plan/common/account_panel.dart';
import 'package:income_expense_budget_plan/common/assets_categories_panel.dart';
import 'package:income_expense_budget_plan/common/more_panel.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/model/setting.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/database_service.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sqflite/sqflite.dart';

class HomePageMobileLandscape extends StatefulWidget {
  const HomePageMobileLandscape({super.key});

  @override
  State<HomePageMobileLandscape> createState() => _HomePageMobileLandscapeState();
}

class _HomePageMobileLandscapeState extends State<HomePageMobileLandscape> {
  _HomePageMobileLandscapeState();

  refresh() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // Show the dialog when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDefaultCurrencyCheck();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print("Current screensize ${MediaQuery.of(context).size}");
    }
    final ThemeData theme = Theme.of(context);
    Size sideButtonSize = const Size(155, 50);
    Size sideSpaceSize = Size(sideButtonSize.width - 8, double.infinity);
    var sideButtonShape = const RoundedRectangleBorder(borderRadius: BorderRadius.zero);
    return Consumer<AppState>(
      builder: (context, appState, child) => Consumer<SettingModel>(
        builder: (context, setting, child) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() => appState.currentHomePageIndex = 0),
                  icon: const Icon(Icons.history),
                  label: Text(AppLocalizations.of(context)!.navHistory),
                  style: styleForIndex(theme, 0, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                ElevatedButton.icon(
                  onPressed: () => setState(() => appState.currentHomePageIndex = 1),
                  icon: const Icon(Icons.account_box),
                  label: Text(AppLocalizations.of(context)!.navAccount),
                  style: styleForIndex(theme, 1, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                ElevatedButton.icon(
                  onPressed: () => setState(() => appState.currentHomePageIndex = 2),
                  icon: const Icon(Icons.analytics),
                  label: Text(AppLocalizations.of(context)!.navReport),
                  style: styleForIndex(theme, 2, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                ElevatedButton.icon(
                  onPressed: () => setState(() => appState.currentHomePageIndex = 3),
                  icon: const Icon(Icons.manage_accounts),
                  label: Text(AppLocalizations.of(context)!.navAccountCategory),
                  style: styleForIndex(theme, 3, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                ElevatedButton.icon(
                  onPressed: () => setState(() => appState.currentHomePageIndex = 4),
                  icon: const Icon(Icons.more),
                  label: Text(AppLocalizations.of(context)!.navMore),
                  style: styleForIndex(theme, 4, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                ElevatedButton.icon(
                  onPressed: () => Util().chooseBrightnessMode(context),
                  icon: const Icon(Icons.brightness_6_outlined),
                  label:
                      Text("${AppLocalizations.of(context)!.settingsDarkMode}\n${currentAppState.systemSetting.getDarkModeText(context)}"),
                  style: styleForIndex(theme, -1, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                ElevatedButton.icon(
                  onPressed: () => Util().chooseLanguage(context),
                  icon: const Icon(Icons.flag),
                  label: Text("Language\n${currentAppState.systemSetting.currentLanguageText}"),
                  style: styleForIndex(theme, -1, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                Flexible(
                  child:
                      ElevatedButton(onPressed: () {}, style: styleForIndex(theme, -1, sideSpaceSize, sideButtonShape), child: Container()),
                ),
              ],
            ),
            Flexible(
                child: [
              Card(
                child: SizedBox.expand(
                  child: Center(
                    child: Text(
                      'Home page',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
              ),
              const AccountPanel(),
              Card(
                //shadowColor: Colors.transparent,
                margin: const EdgeInsets.all(8.0),
                child: SizedBox.expand(
                  child: Center(
                    child: Text(
                      'AAAA page',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
              ),
              const AssetCategoriesPanel(),
              const Material(child: MorePanel())
            ][appState.currentHomePageIndex]),
          ],
        ),
      ),
    );
  }

  Future<void> _startDefaultCurrencyCheck() async {
    String? currencyId = currentAppState.systemSetting.defaultCurrencyUid;
    if (currencyId == null || currencyId.isBlank) {
      if (kDebugMode) {
        print("Default currency [$currencyId] and isBlank [${currencyId?.isBlank}]");
      }
      showDialog(context: context, builder: (BuildContext context) => const DefaultCurrencySelectionDialog());
    }
  }

  ButtonStyle styleForIndex(ThemeData theme, int buttonIndex, Size buttonSize, OutlinedBorder sideButtonShape) {
    return ElevatedButton.styleFrom(
        elevation: 0,
        shape: sideButtonShape,
        minimumSize: buttonSize,
        maximumSize: buttonSize,
        alignment: Alignment.centerLeft,
        backgroundColor: currentAppState.currentHomePageIndex == buttonIndex ? const Color.fromARGB(255, 237, 202, 113) : theme.cardColor);
  }
}

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
