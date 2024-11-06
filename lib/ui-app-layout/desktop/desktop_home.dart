import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/setting.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/year_month_filter_data.dart';
import 'package:income_expense_budget_plan/ui-app-layout/home.dart';
import 'package:income_expense_budget_plan/ui-app-layout/mobile-landscape/landscape_more_panel.dart';
import 'package:income_expense_budget_plan/ui-common/assets_categories_panel.dart';
import 'package:income_expense_budget_plan/ui-common/report_panel.dart';
import 'package:income_expense_budget_plan/ui-common/transaction_panel.dart';
import 'package:income_expense_budget_plan/ui-common/vertical_split_view.dart';
import 'package:income_expense_budget_plan/ui-platform-based/landscape/account_panel.dart';
import 'package:income_expense_budget_plan/ui-platform-based/landscape/transaction_categories_panel.dart';
import 'package:provider/provider.dart';

class HomePageDesktop extends HomePage {
  const HomePageDesktop({super.key}) : super(layoutStyle: layoutStyleDesktop);

  @override
  State<HomePageDesktop> createState() => _HomePageDesktopState();
}

class _HomePageDesktopState extends HomePageState<HomePageDesktop> {
  List<TransactionCategory> incomeCategories = [];
  List<TransactionCategory> expenseCategories = [];
  late YearMonthFilterData yearMonthFilterData;
  late DeveloperTapCountTriggerSupport developerTriggerSupport;

  @override
  void initState() {
    super.initState();
    developerTriggerSupport = DeveloperTapCountTriggerSupport(updateUiState: setState);

    TransactionDao().transactionCategoryByType(TransactionType.income).then((loadCats) => setState(() => incomeCategories = loadCats));
    TransactionDao().transactionCategoryByType(TransactionType.expense).then((loadCats) => setState(() => expenseCategories = loadCats));

    yearMonthFilterData = YearMonthFilterData(
      refreshFunction: () => setState(() {}),
      refreshStatisticFunction: () => setState(() {}),
      supportLoadTransactions: true,
      supportLoadStatisticMonthly: true,
    );
  }

  @override
  Widget homePageBuild({
    required BuildContext context,
    required AppState appState,
    required SettingModel setting,
    required AppLocalizations appLocalizations,
    required Widget body,
  }) {
    final ThemeData theme = Theme.of(context);

    AppBar? appBar;
    if (appState.currentHomePageIndex == 0) {
      appBar = yearMonthFilterData.generateFilterLabel(context, () => setState(() {}));
    }
    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) => developerTriggerSupport.switchHomeTap(currentAppState, index, [3]),
        indicatorColor: tabSelectedColor,
        selectedIndex: appState.currentHomePageIndex,
        destinations: <Widget>[
          NavigationDestination(
            icon: Icon(Icons.history, color: theme.primaryColor),
            label: appLocalizations.navHistory,
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.home, color: theme.primaryColor),
            icon: Icon(Icons.account_box, color: theme.primaryColor),
            label: appLocalizations.navAccount,
          ),
          NavigationDestination(
            icon: Icon(Icons.more, color: theme.primaryColor),
            label: appLocalizations.navTransactionCategory,
          ),
          NavigationDestination(icon: Icon(Icons.more, color: theme.primaryColor), label: appLocalizations.navMore),
          MouseRegion(
            cursor: SystemMouseCursors.click, // Changes the cursor to a pointer
            child: GestureDetector(
              onTap: () => util.chooseBrightnessMode(context),
              child: Container(
                color: Colors.transparent, // Ensure the area is clickable
                child: Column(children: [
                  const SizedBox(height: 20),
                  Icon(Icons.brightness_6_outlined, color: theme.primaryColor),
                  Text(setting.getDarkModeText(context)),
                ]),
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click, // Changes the cursor to a pointer
            child: GestureDetector(
              onTap: () => util.chooseLanguage(context),
              child: Container(
                color: Colors.transparent, // Ensure the area is clickable
                child: Column(children: [
                  const SizedBox(height: 20),
                  Icon(Icons.flag, color: theme.primaryColor),
                  Text(setting.currentLanguageText),
                ]),
              ),
            ),
          )
        ],
      ),
    );
  }

  ButtonStyle buttonStyle(ThemeData theme, OutlinedBorder sideButtonShape) {
    return ElevatedButton.styleFrom(
      elevation: 0,
      shape: sideButtonShape,
      alignment: Alignment.centerLeft,
      backgroundColor: theme.cardColor,
    );
  }

  @override
  List<Widget> allIndexesWidgets(BuildContext context, AppLocalizations appLocalizations) => [
        VerticalSplitView(
          key: const Key("1st_panel"),
          left: TransactionPanel(yearMonthFilterData: yearMonthFilterData),
          right: ReportPanel(yearMonthFilterData: yearMonthFilterData),
        ),
        const VerticalSplitView(
            key: Key("2nd_panel"), left: AccountPanelLandscape(), right: AssetCategoriesPanel(disableBack: true), ratio: 0.6),
        VerticalSplitView(
          key: const Key("3rd_panel"),
          left: ChangeNotifierProvider(
            create: (context) => TransactionCategoriesListenable(categoriesMap: {TransactionType.expense: expenseCategories}),
            builder: (context, child) => child!,
            child: TransactionCategoriesPanelLandscape(
                listPanelTitle: appLocalizations.menuExpenseCategory, disableBack: true, key: const Key("desktop-expense-category-panel")),
          ),
          right: ChangeNotifierProvider(
            create: (context) => TransactionCategoriesListenable(categoriesMap: {TransactionType.income: incomeCategories}),
            builder: (context, child) => child!,
            child: TransactionCategoriesPanelLandscape(
                listPanelTitle: appLocalizations.menuIncomeCategory, disableBack: true, key: const Key("desktop-income-category-panel")),
          ),
        ),
        const Material(child: LandscapeMorePanel()),
      ];
}
