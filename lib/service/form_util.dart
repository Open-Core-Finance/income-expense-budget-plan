import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/service/year_month_filter_data.dart';
import 'package:intl/intl.dart';

class FormUtil {
  // Singleton pattern
  static final FormUtil _util = FormUtil._internal();
  factory FormUtil() => _util;
  FormUtil._internal();

  List<Widget> buildCategoryFormActions(BuildContext context, Function() formSubmit, bool isChecking, String categoryActionSaveLabel,
      Function() formSubmitAndAddMore, String categoryActionSaveAddMoreLabel) {
    return [
      ElevatedButton(
        onPressed: formSubmit,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.lightBlueAccent),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 15, horizontal: 30)),
        ),
        child: isChecking
            ? const CircularProgressIndicator()
            : Text(categoryActionSaveLabel, style: const TextStyle(fontSize: 14, color: Colors.white)),
      ),
      const SizedBox(width: 10),
      ElevatedButton(
        onPressed: formSubmitAndAddMore,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.lightBlueAccent),
          padding: WidgetStateProperty.all(const EdgeInsets.all(15)),
        ),
        child: isChecking
            ? const CircularProgressIndicator()
            : Text(
                categoryActionSaveAddMoreLabel,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
      ),
    ];
  }

  String resolveAccountTypeLocalize(BuildContext context, String typeName) {
    switch (typeName) {
      case "genericAccount":
        return AppLocalizations.of(context)!.accountType_generic;
      case "bankCasa":
        return AppLocalizations.of(context)!.accountType_bankCasa;
      case "loan":
        return AppLocalizations.of(context)!.accountType_loan;
      case "eWallet":
        return AppLocalizations.of(context)!.accountType_eWallet;
      case "creditCard":
        return AppLocalizations.of(context)!.accountType_creditCard;
      case "payLaterAccount":
        return AppLocalizations.of(context)!.accountType_payLaterAccount;
      default:
        return typeName;
    }
  }

  CurrencyTextInputFormatter buildFormatter(Currency selectedCurrency) {
    return CurrencyTextInputFormatter.currency(
        locale: selectedCurrency.language, symbol: selectedCurrency.symbol, decimalDigits: selectedCurrency.decimalPoint);
  }

  Widget buildCheckboxFormField(BuildContext context, ThemeData theme,
      {required bool value, required String title, void Function(bool? value)? onChanged}) {
    return FormField<bool>(
      initialValue: value,
      builder: (FormFieldState<bool> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: Text(title),
              value: value,
              onChanged: (value) {
                if (onChanged != null) onChanged(value);
                state.didChange(value);
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  double? parseAmount(String amountText, NumberFormat moneyFormat) {
    amountText = amountText.trim();
    String symbol = moneyFormat.currencySymbol;
    while (amountText.startsWith(symbol)) {
      amountText = amountText.substring(symbol.length).trim();
    }
    while (amountText.endsWith(symbol)) {
      amountText = amountText.substring(0, amountText.length - symbol.length);
    }
    return moneyFormat.tryParse(amountText)?.toDouble();
  }

  AppBar? buildYearMonthFilteredAppBar(
      BuildContext context, YearMonthFilterData? mainFilter, YearMonthFilterData? localFilter, Function? stateChangeCallback) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    AppBar? appBar;
    YearMonthFilterData filterData;
    if (mainFilter == null) {
      if (localFilter != null) {
        YearMonthFilterData filterData = localFilter;
        appBar = AppBar(
          leading: IconButton(
            icon: Icon(Icons.navigate_before, color: colorScheme.primary),
            onPressed: () {
              filterData.previousMonth();
              if (stateChangeCallback != null) stateChangeCallback();
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.navigate_next, color: colorScheme.primary),
              onPressed: () {
                filterData.nextMonth();
                if (stateChangeCallback != null) stateChangeCallback();
              },
            ),
          ],
          title: Center(child: Text("${filterData.getMonthAsNumberString()}/${filterData.year}")),
        );
      }
    }
    return appBar;
  }
}
