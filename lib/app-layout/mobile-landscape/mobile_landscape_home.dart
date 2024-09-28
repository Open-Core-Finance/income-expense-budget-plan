import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/extensions/string_extensions.dart';
import 'package:income_expense_budget_plan/common/account_panel.dart';
import 'package:income_expense_budget_plan/common/assets_categories_panel.dart';
import 'package:income_expense_budget_plan/common/default_currency_selection.dart';
import 'package:income_expense_budget_plan/common/more_panel.dart';
import 'package:income_expense_budget_plan/common/report_panel.dart';
import 'package:income_expense_budget_plan/common/transaction_panel.dart';
import 'package:income_expense_budget_plan/model/setting.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
                  icon: Icon(Icons.history, color: theme.primaryColor),
                  label: Text(AppLocalizations.of(context)!.navHistory),
                  style: styleForIndex(theme, 0, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                ElevatedButton.icon(
                  onPressed: () => setState(() => appState.currentHomePageIndex = 1),
                  icon: Icon(Icons.account_box, color: theme.primaryColor),
                  label: Text(AppLocalizations.of(context)!.navAccount),
                  style: styleForIndex(theme, 1, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                ElevatedButton.icon(
                  onPressed: () => setState(() => appState.currentHomePageIndex = 2),
                  icon: Icon(Icons.analytics, color: theme.primaryColor),
                  label: Text(AppLocalizations.of(context)!.navReport),
                  style: styleForIndex(theme, 2, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                ElevatedButton.icon(
                  onPressed: () => setState(() => appState.currentHomePageIndex = 3),
                  icon: Icon(Icons.manage_accounts, color: theme.primaryColor),
                  label: Text(AppLocalizations.of(context)!.navAccountCategory),
                  style: styleForIndex(theme, 3, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                ElevatedButton.icon(
                  onPressed: () => setState(() => appState.currentHomePageIndex = 4),
                  icon: Icon(Icons.more, color: theme.primaryColor),
                  label: Text(AppLocalizations.of(context)!.navMore),
                  style: styleForIndex(theme, 4, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                ElevatedButton.icon(
                  onPressed: () => Util().chooseBrightnessMode(context),
                  icon: Icon(Icons.brightness_6_outlined, color: theme.primaryColor),
                  label:
                      Text("${AppLocalizations.of(context)!.settingsDarkMode}\n${currentAppState.systemSetting.getDarkModeText(context)}"),
                  style: styleForIndex(theme, -1, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                ElevatedButton.icon(
                  onPressed: () => Util().chooseLanguage(context),
                  icon: Icon(Icons.flag, color: theme.primaryColor),
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
              const TransactionPanel(),
              const AccountPanel(),
              const ReportPanel(),
              const AssetCategoriesPanel(),
              const Material(child: MorePanel())
            ][appState.currentHomePageIndex % 5]),
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
        backgroundColor: currentAppState.currentHomePageIndex == buttonIndex ? tabSelectedColor : theme.cardColor);
  }
}
