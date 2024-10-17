import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/extensions/string_extensions.dart';
import 'package:income_expense_budget_plan/common/account_panel.dart';
import 'package:income_expense_budget_plan/common/assets_categories_panel.dart';
import 'package:income_expense_budget_plan/common/default_currency_selection.dart';
import 'package:income_expense_budget_plan/common/report_panel.dart';
import 'package:income_expense_budget_plan/common/transaction_categories_panel.dart';
import 'package:income_expense_budget_plan/common/transaction_panel.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/setting.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/util.dart';
import 'package:income_expense_budget_plan/service/year_month_filter_data.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../common/vertical_split_view.dart';

class HomePageDesktop extends StatefulWidget {
  const HomePageDesktop({super.key});

  @override
  State<HomePageDesktop> createState() => _HomePageDesktopState();
}

class _HomePageDesktopState extends State<HomePageDesktop> {
  List<TransactionCategory> incomeCategories = [];
  List<TransactionCategory> expenseCategories = [];
  late YearMonthFilterData yearMonthFilterData;

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

    TransactionDao().transactionCategoryByType(TransactionType.income).then((loadCats) => setState(() => incomeCategories = loadCats));
    TransactionDao().transactionCategoryByType(TransactionType.expense).then((loadCats) => setState(() => expenseCategories = loadCats));

    yearMonthFilterData = YearMonthFilterData(refreshFunction: () => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print("Current screen size ${MediaQuery.of(context).size}");
    }
    final ThemeData theme = Theme.of(context);

    return Consumer<AppState>(
      builder: (context, appState, child) => Consumer<SettingModel>(builder: (context, setting, child) {
        String expenseTitle = AppLocalizations.of(context)!.menuExpenseCategory;
        String incomeTitle = AppLocalizations.of(context)!.menuIncomeCategory;
        if (kDebugMode) {
          print("Expense category title [$expenseTitle]\nIncome category title [$incomeTitle]");
        }
        AppBar? appBar;
        if (appState.currentHomePageIndex == 0) {
          appBar = yearMonthFilterData.generateFilterLabel(context, () => setState(() {}));
        }
        return Scaffold(
          appBar: appBar,
          body: <Widget>[
            VerticalSplitView(
              key: const Key("1st_panel"),
              left: TransactionPanel(yearMonthFilterData: yearMonthFilterData),
              right: ReportPanel(yearMonthFilterData: yearMonthFilterData),
            ),
            const VerticalSplitView(
                key: Key("2nd_panel"), left: AccountPanel(), right: AssetCategoriesPanel(disableBack: true), ratio: 0.6),
            VerticalSplitView(
              key: const Key("3rd_panel"),
              left: ChangeNotifierProvider(
                create: (context) => TransactionCategoriesListenable(categoriesMap: {TransactionType.expense: expenseCategories}),
                builder: (context, child) => child!,
                child: TransactionCategoriesPanel(
                    listPanelTitle: expenseTitle, disableBack: true, key: const Key("desktop-expense-category-panel")),
              ),
              right: ChangeNotifierProvider(
                create: (context) => TransactionCategoriesListenable(categoriesMap: {TransactionType.income: incomeCategories}),
                builder: (context, child) => child!,
                child: TransactionCategoriesPanel(
                    listPanelTitle: incomeTitle, disableBack: true, key: const Key("desktop-income-category-panel")),
              ),
            )
          ][appState.currentHomePageIndex % 3],
          bottomNavigationBar: NavigationBar(
            onDestinationSelected: (int index) {
              setState(() {
                currentAppState.currentHomePageIndex = index;
              });
            },
            indicatorColor: tabSelectedColor,
            selectedIndex: currentAppState.currentHomePageIndex,
            destinations: <Widget>[
              NavigationDestination(
                icon: Icon(Icons.history, color: theme.primaryColor),
                label: AppLocalizations.of(context)!.navHistory,
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.home, color: theme.primaryColor),
                icon: Icon(Icons.account_box, color: theme.primaryColor),
                label: AppLocalizations.of(context)!.navAccount,
              ),
              NavigationDestination(
                icon: Icon(Icons.more, color: theme.primaryColor),
                label: AppLocalizations.of(context)!.navTransactionCategory,
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click, // Changes the cursor to a pointer
                child: GestureDetector(
                  onTap: () => Util().chooseBrightnessMode(context),
                  child: Container(
                    color: Colors.transparent, // Ensure the area is clickable
                    child: Column(children: [
                      const SizedBox(height: 20),
                      Icon(Icons.brightness_6_outlined, color: theme.primaryColor),
                      Text(currentAppState.systemSetting.getDarkModeText(context)),
                    ]),
                  ),
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click, // Changes the cursor to a pointer
                child: GestureDetector(
                  onTap: () => Util().chooseLanguage(context),
                  child: Container(
                    color: Colors.transparent, // Ensure the area is clickable
                    child: Column(children: [
                      const SizedBox(height: 20),
                      Icon(Icons.flag, color: theme.primaryColor),
                      Text(currentAppState.systemSetting.currentLanguageText),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
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

  ButtonStyle buttonStyle(ThemeData theme, OutlinedBorder sideButtonShape) {
    return ElevatedButton.styleFrom(
      elevation: 0,
      shape: sideButtonShape,
      alignment: Alignment.centerLeft,
      backgroundColor: theme.cardColor,
    );
  }
}
