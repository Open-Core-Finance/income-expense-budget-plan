import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/model/setting.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/ui-app-layout/home.dart';
import 'package:income_expense_budget_plan/ui-app-layout/mobile-landscape/landscape_more_panel.dart';
import 'package:income_expense_budget_plan/ui-common/assets_categories_panel.dart';
import 'package:income_expense_budget_plan/ui-common/report_panel.dart';
import 'package:income_expense_budget_plan/ui-common/transaction_panel.dart';
import 'package:income_expense_budget_plan/ui-platform-based/landscape/account_panel.dart';

class HomePageMobileLandscape extends HomePage {
  const HomePageMobileLandscape({super.key}) : super(layoutStyle: layoutStyleMobileLandscape);

  @override
  State<HomePageMobileLandscape> createState() => _HomePageMobileLandscapeState();
}

class _HomePageMobileLandscapeState extends HomePageState<HomePageMobileLandscape> {
  @override
  Widget homePageBuild({
    required BuildContext context,
    required AppState appState,
    required SettingModel setting,
    required AppLocalizations appLocalizations,
    required Widget body,
  }) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    Size sideButtonSize = const Size(155, 50);
    Size sideSpaceSize = Size(sideButtonSize.width - 8, double.infinity);
    var sideButtonShape = const RoundedRectangleBorder(borderRadius: BorderRadius.zero);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
                height: 10,
                child:
                    ElevatedButton(onPressed: () {}, style: styleForIndex(theme, -1, sideSpaceSize, sideButtonShape), child: Container())),
            ElevatedButton.icon(
              onPressed: () => developerTriggerSupport.switchHomeTap(appState, 0, [5]),
              icon: Icon(Icons.history, color: theme.primaryColor),
              label: Text(appLocalizations.navHistory),
              style: styleForIndex(theme, 0, sideButtonSize, sideButtonShape),
            ),
            const Divider(height: 0.5),
            ElevatedButton.icon(
              onPressed: () => developerTriggerSupport.switchHomeTap(appState, 2, [5]),
              icon: Icon(Icons.analytics, color: theme.primaryColor),
              label: Text(appLocalizations.navReport),
              style: styleForIndex(theme, 2, sideButtonSize, sideButtonShape),
            ),
            const Divider(height: 0.5),
            ElevatedButton.icon(
              onPressed: () => developerTriggerSupport.switchHomeTap(appState, 1, [5]),
              icon: Icon(Icons.account_box, color: theme.primaryColor),
              label: Text(appLocalizations.navAccount),
              style: styleForIndex(theme, 1, sideButtonSize, sideButtonShape),
            ),
            const Divider(height: 0.5),
            ElevatedButton.icon(
              onPressed: () => developerTriggerSupport.switchHomeTap(appState, 3, [5]),
              icon: Icon(Icons.manage_accounts, color: theme.primaryColor),
              label: Text(appLocalizations.navAccountCategory),
              style: styleForIndex(theme, 3, sideButtonSize, sideButtonShape),
            ),
            const Divider(height: 0.5),
            ElevatedButton.icon(
              onPressed: () => developerTriggerSupport.switchHomeTap(appState, 4, [5]),
              icon: Icon(Icons.more, color: theme.primaryColor),
              label: Text(appLocalizations.navMore),
              style: styleForIndex(theme, 4, sideButtonSize, sideButtonShape),
            ),
            const Divider(height: 0.5),
            ElevatedButton.icon(
              onPressed: () => util.chooseLanguage(context),
              icon: Icon(Icons.flag, color: theme.primaryColor),
              label: Text("Language\n${setting.currentLanguageText}"),
              style: styleForIndex(theme, -1, sideButtonSize, sideButtonShape),
            ),
            const Divider(height: 0.5),
            Flexible(
              child: ElevatedButton(onPressed: () {}, style: styleForIndex(theme, -1, sideSpaceSize, sideButtonShape), child: Container()),
            ),
          ],
        ),
        Flexible(child: body),
      ],
    );
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

  @override
  List<Widget> allIndexesWidgets(BuildContext context, AppLocalizations appLocalizations) => [
        const TransactionPanel(),
        ReportPanel(),
        const AccountPanelLandscape(),
        const AssetCategoriesPanel(),
        const Material(child: LandscapeMorePanel())
      ];
}
