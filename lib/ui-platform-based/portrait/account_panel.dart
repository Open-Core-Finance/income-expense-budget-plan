import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/model/asset_category.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/service/app_state.dart';
import 'package:income_expense_budget_plan/ui-common/account_panel.dart';
import 'package:income_expense_budget_plan/ui-common/add_account_form.dart';
import 'package:income_expense_budget_plan/ui-common/assets_categories_panel.dart';
import 'package:provider/provider.dart';

class AccountPanelPortrait extends AccountPanel {
  const AccountPanelPortrait({super.key, super.accountTap, super.floatingButton});

  @override
  State<AccountPanelPortrait> createState() => _AccountPanelPortraitState();
}

class _AccountPanelPortraitState extends AccountPanelState<AccountPanelPortrait> {
  @override
  Widget buildUi(BuildContext context, AppLocalizations appLocalizations, List<Asset> accounts, List<AssetCategory> categories) {
    final ThemeData theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);
    List<Widget> widgets = [];
    for (var category in categories) {
      widgets.add(_categoryDisplay(theme, appState, category, assetCategoriesRefreshed));
      List<Asset> accounts = category.assets;
      for (var account in accounts) {
        widgets.add(_accountDisplay(theme, appState, account, assetRefreshed, showRemoveDialog));
      }
    }
    widgets.add(SizedBox(height: 30));
    return ListView(children: widgets);
  }

  Widget _categoryDisplay(
      ThemeData theme, AppState appState, AssetCategory category, Function(List<AssetCategory> cats, bool isAddNew)? editCategoryCallBack) {
    String tileText = category.getTitleText(appState.systemSetting);
    Widget? subTitle;
    if (category.assets.isEmpty) {
      subTitle = Text(AppLocalizations.of(context)!.accountCategoryEmpty);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click, // Changes the cursor to a pointer
      child: GestureDetector(
        onTap: () {
          util.navigateTo(context, AddAssetCategoryForm(editingCategory: category, editCallback: editCategoryCallBack));
        },
        child: ListTile(
          leading: Icon(category.icon, color: theme.iconTheme.color), // Icon on the left
          title: Text(tileText),
          subtitle: subTitle,
          trailing: IconButton(icon: const Icon(Icons.tune), onPressed: () => util.navigateTo(context, const AssetCategoriesPanel())),
        ),
      ),
    );
  }

  Widget _accountDisplay(ThemeData theme, AppState appState, Asset account, Function(List<Asset> cats, bool isAddNew)? editCallBack,
      Function(BuildContext context, Asset category) removeCall) {
    String tileText = account.getTitleText(appState.systemSetting);
    Widget subTitle = account.getAmountDisplayText();
    return MouseRegion(
      cursor: SystemMouseCursors.click, // Changes the cursor to a pointer
      child: GestureDetector(
        onTap: () {
          if (widget.accountTap != null) {
            widget.accountTap!(account);
          } else {
            util.navigateTo(context, AddAccountForm(editingAsset: account, editCallback: editCallBack));
          }
        },
        child: ListTile(
          leading: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 58),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(height: 20, child: VerticalDivider(thickness: 2, color: theme.dividerColor, endIndent: 0, indent: 0)),
                const Text("---", style: TextStyle(fontSize: 10), textAlign: TextAlign.left),
                Icon(account.icon, color: theme.iconTheme.color),
                SizedBox(width: 2)
              ],
            ),
          ),
          title: Text(tileText),
          subtitle: subTitle,
          trailing: IconButton(icon: Icon(Icons.delete, color: theme.colorScheme.error), onPressed: () => removeCall(context, account)),
        ),
      ),
    );
  }
}
