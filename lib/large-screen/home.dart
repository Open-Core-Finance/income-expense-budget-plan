import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/common/account_panel.dart';
import 'package:income_expense_budget_plan/common/main_navigation_bar.dart';
import 'package:income_expense_budget_plan/common/more_panel.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final MainNavigationBar navBar;

  _HomePageState() {
    navBar = const MainNavigationBar();
  }

  refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListenableBuilder(
        listenable: currentAppState,
        builder: (context, child) {
          return Scaffold(
            body: <Widget>[
              /// Home page
              Card(
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
              const AccountPanel(),
              Card(
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
              const MorePanel()
            ][currentAppState.currentHomePageIndex],
            // bottomNavigationBar: BottomAppBar(
            //   shape: const CircularNotchedRectangle(),
            //   child: Container(height: 50.0)
            // ),
            bottomNavigationBar: navBar,
            // floatingActionButton: FloatingActionButton(
            //   onPressed: () => setState(() {
            //     _count++;
            //   }),
            //   tooltip: 'Increment Counter',
            //   child: const Icon(Icons.add),
            // ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          );
        });
  }
}
