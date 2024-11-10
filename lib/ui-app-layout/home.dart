import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/extensions/string_extensions.dart';
import 'package:income_expense_budget_plan/ui-common/default_currency_selection.dart';
import 'package:income_expense_budget_plan/model/setting.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

abstract class HomePage extends StatefulWidget {
  final int layoutStyle;
  const HomePage({super.key, required this.layoutStyle});
}

abstract class HomePageState<T extends HomePage> extends State<T> {
  MediaQueryData? lastMediaData;
  Util util = Util();
  late DeveloperTapCountTriggerSupport developerTriggerSupport;

  @override
  void initState() {
    super.initState();
    developerTriggerSupport = DeveloperTapCountTriggerSupport(updateUiState: setState);
    // Show the dialog when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDefaultCurrencyCheck();
    });
  }

  refresh() {
    setState(() {});
  }

  Future<void> _startDefaultCurrencyCheck() async {
    String? currencyId = currentAppState.systemSetting.defaultCurrencyUid;
    if (currencyId == null || currencyId.isBlank) {
      if (kDebugMode) {
        print("Default currency [$currencyId] and isBlank [${currencyId?.isBlank}]");
      }
      util.navigateTo(context, const DefaultCurrencySelectionDialog());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Media query
    MediaQueryData tmp = MediaQuery.of(context);
    if (kDebugMode) {
      if (lastMediaData != null) {
        if (tmp.size != lastMediaData?.size) {
          print("Switched to screen size ${MediaQuery.of(context).size}");
        }
      } else {
        print("Started with screen size $lastMediaData");
      }
    }
    lastMediaData = tmp;
    // Correct tab index
    if (currentAppState.lastLayoutStyle != -1 && currentAppState.lastLayoutStyle != widget.layoutStyle) {
      // Reset page index when switch from difference styles.
      currentAppState.resetIndexNoRepaint();
    }
    currentAppState.lastLayoutStyle = widget.layoutStyle;
    // Widget
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return Consumer<AppState>(
      builder: (context, appState, child) => Consumer<SettingModel>(
        builder: (context, setting, child) {
          Widget resolvedWidget = widgetByIndex(context, appLocalizations, appState.currentHomePageIndex);
          return homePageBuild(
              context: context, appState: appState, setting: setting, appLocalizations: appLocalizations, body: resolvedWidget);
        },
      ),
    );
  }

  Widget homePageBuild(
      {required BuildContext context,
      required AppState appState,
      required SettingModel setting,
      required AppLocalizations appLocalizations,
      required Widget body});

  Widget widgetByIndex(BuildContext context, AppLocalizations appLocalizations, int index) {
    var widgets = allIndexesWidgets(context, appLocalizations);
    return widgets[index % widgets.length];
  }

  List<Widget> allIndexesWidgets(BuildContext context, AppLocalizations appLocalizations);
}

class DeveloperTapCountTriggerSupport {
  int _tapCount = 0;
  void Function(VoidCallback fn) updateUiState;

  DeveloperTapCountTriggerSupport({required this.updateUiState});

  void switchHomeTap(AppState appState, int index, List<int> ignoreIndexes) {
    if (appState.currentHomePageIndex != index) {
      if (!ignoreIndexes.contains(index)) {
        _tapCount = 0;
      }
      updateUiState(() {
        appState.currentHomePageIndex = index;
      });
    } else {
      increaseTap();
    }
  }

  void increaseTap() {
    if (_tapCount != showHiddenCount - 1) {
      _tapCount++;
    } else {
      updateUiState(() => _tapCount++);
    }
  }

  bool canShowDeveloperMenu() {
    return (_tapCount >= showHiddenCount);
  }

  void resetTapCount() {
    updateUiState(() => _tapCount = 0);
  }
}
