import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/extensions/string_extensions.dart';
import 'package:income_expense_budget_plan/common/account_panel.dart';
import 'package:income_expense_budget_plan/common/assets_categories_panel.dart';
import 'package:income_expense_budget_plan/common/default_currency_selection.dart';
import 'package:income_expense_budget_plan/common/transaction_categories_panel.dart';
import 'package:income_expense_budget_plan/dao/transaction_dao.dart';
import 'package:income_expense_budget_plan/model/setting.dart';
import 'package:income_expense_budget_plan/model/transaction_category.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/service/util.dart';
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

  _HomePageDesktopState();

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

    var txnType = TransactionType.income;
    TransactionDao()
        .transactionCategoryByType(txnType)
        .then((List<TransactionCategory> loadCats) => setState(() => incomeCategories = Util().buildTransactionCategoryTree(loadCats)));
    txnType = TransactionType.expense;
    TransactionDao()
        .transactionCategoryByType(txnType)
        .then((List<TransactionCategory> loadCats) => setState(() => expenseCategories = Util().buildTransactionCategoryTree(loadCats)));
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print("Current screensize ${MediaQuery.of(context).size}");
    }
    final ThemeData theme = Theme.of(context);

    return Consumer<AppState>(
      builder: (context, appState, child) => Consumer<SettingModel>(
        builder: (context, setting, child) => Scaffold(
          appBar: AppBar(actions: []),
          body: <Widget>[
            VerticalSplitView(
              key: const Key("1st_panel"),
              left: Card(
                shadowColor: Colors.transparent,
                margin: const EdgeInsets.all(8.0),
                child: SizedBox.expand(
                  child: Center(
                    child: Text(
                      'Home page',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
              ),
              right: Card(
                shadowColor: Colors.transparent,
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
            ),
            const VerticalSplitView(
                key: Key("2nd_panel"), left: AccountPanel(), right: AssetCategoriesPanel(disableBack: true), ratio: 0.6),
            VerticalSplitView(
              key: const Key("3rd_panel"),
              left: ChangeNotifierProvider(
                create: (context) =>
                    TransactionCategoriesListenable(transactionType: TransactionType.expense, categories: expenseCategories),
                builder: (context, child) => child!,
                child: TransactionCategoriesPanel(
                  listPanelTitle: AppLocalizations.of(context)!.menuExpenseCategory,
                  addPanelTitle: AppLocalizations.of(context)!.titleAddExpenseCategory,
                  disableBack: true,
                ),
              ),
              right: ChangeNotifierProvider(
                create: (context) => TransactionCategoriesListenable(transactionType: TransactionType.income, categories: incomeCategories),
                builder: (context, child) => child!,
                child: TransactionCategoriesPanel(
                  listPanelTitle: AppLocalizations.of(context)!.menuIncomeCategory,
                  addPanelTitle: AppLocalizations.of(context)!.titleAddIncomeCategory,
                  disableBack: true,
                ),
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
                icon: const Icon(Icons.history),
                label: AppLocalizations.of(context)!.navHistory,
              ),
              NavigationDestination(
                selectedIcon: const Icon(Icons.home),
                icon: const Icon(Icons.account_box),
                label: AppLocalizations.of(context)!.navAccount,
              ),
              NavigationDestination(
                icon: const Icon(Icons.more),
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
                      Icon(Icons.brightness_6_outlined, color: theme.textTheme.bodyMedium?.color),
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
                      Icon(Icons.flag, color: theme.textTheme.bodyMedium?.color),
                      Text(currentAppState.systemSetting.currentLanguageText),
                    ]),
                  ),
                ),
              ),
            ],
          ),
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

  ButtonStyle buttonStyle(ThemeData theme, OutlinedBorder sideButtonShape) {
    return ElevatedButton.styleFrom(
      elevation: 0,
      shape: sideButtonShape,
      alignment: Alignment.centerLeft,
      backgroundColor: theme.cardColor,
    );
  }
}
