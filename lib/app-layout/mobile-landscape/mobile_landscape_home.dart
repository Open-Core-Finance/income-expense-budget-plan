import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/extensions/string_extensions.dart';
import 'package:income_expense_budget_plan/common/account_panel.dart';
import 'package:income_expense_budget_plan/common/assets_categories_panel.dart';
import 'package:income_expense_budget_plan/common/default_currency_selection.dart';
import 'package:income_expense_budget_plan/app-layout/mobile-portrait/mobile_more_panel.dart';
import 'package:income_expense_budget_plan/common/report_panel.dart';
import 'package:income_expense_budget_plan/common/sql_import.dart';
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
  int _tapCount = 0;

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
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
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
                SizedBox(
                    height: 30,
                    child: ElevatedButton(
                        onPressed: () {}, style: styleForIndex(theme, -1, sideSpaceSize, sideButtonShape), child: Container())),
                ElevatedButton.icon(
                  onPressed: () => _switchTap(appState, 0),
                  icon: Icon(Icons.history, color: theme.primaryColor),
                  label: Text(appLocalizations.navHistory),
                  style: styleForIndex(theme, 0, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                ElevatedButton.icon(
                  onPressed: () => _switchTap(appState, 1),
                  icon: Icon(Icons.account_box, color: theme.primaryColor),
                  label: Text(appLocalizations.navAccount),
                  style: styleForIndex(theme, 1, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                ElevatedButton.icon(
                  onPressed: () => _switchTap(appState, 2),
                  icon: Icon(Icons.analytics, color: theme.primaryColor),
                  label: Text(appLocalizations.navReport),
                  style: styleForIndex(theme, 2, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                ElevatedButton.icon(
                  onPressed: () => _switchTap(appState, 3),
                  icon: Icon(Icons.manage_accounts, color: theme.primaryColor),
                  label: Text(appLocalizations.navAccountCategory),
                  style: styleForIndex(theme, 3, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                ElevatedButton.icon(
                  onPressed: () => _switchTap(appState, 4),
                  icon: Icon(Icons.more, color: theme.primaryColor),
                  label: Text(appLocalizations.navMore),
                  style: styleForIndex(theme, 4, sideButtonSize, sideButtonShape),
                ),
                const Divider(height: 0.5),
                ElevatedButton.icon(
                  onPressed: () => Util().chooseBrightnessMode(context),
                  icon: Icon(Icons.brightness_6_outlined, color: theme.primaryColor),
                  label: Text("${appLocalizations.settingsDarkMode}\n${currentAppState.systemSetting.getDarkModeText(context)}"),
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
                if (_tapCount >= showHiddenCount)
                  ElevatedButton.icon(
                    onPressed: () => _switchTap(appState, 5),
                    icon: Icon(Icons.dataset_linked, color: theme.primaryColor),
                    label: Text(appLocalizations.sqlImportMenu),
                    style: styleForIndex(theme, 5, sideButtonSize, sideButtonShape),
                  ),
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
              ReportPanel(),
              const AssetCategoriesPanel(),
              const Material(child: MobilePortraitMorePanel()),
              const SqlImport(showBackArrow: false)
            ][appState.currentHomePageIndex % 6]),
          ],
        ),
      ),
    );
  }

  void _switchTap(AppState appState, int index) {
    if (appState.currentHomePageIndex != index) {
      if (index != 5) {
        _tapCount = 0;
      }
      setState(() {
        appState.currentHomePageIndex = index;
      });
    } else {
      if (_tapCount != showHiddenCount - 1) {
        _tapCount++;
      } else {
        setState(() => _tapCount++);
      }
    }
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
    ButtonStyle buttonStyle;
    if (currentAppState.currentHomePageIndex == buttonIndex) {
      buttonStyle = ElevatedButton.styleFrom(
          elevation: 0,
          shape: sideButtonShape,
          minimumSize: buttonSize,
          maximumSize: buttonSize,
          alignment: Alignment.centerLeft,
          backgroundColor: tabSelectedColor);
    } else {
      buttonStyle = ElevatedButton.styleFrom(
          elevation: 0, shape: sideButtonShape, minimumSize: buttonSize, maximumSize: buttonSize, alignment: Alignment.centerLeft);
    }
    return buttonStyle;
  }
}
