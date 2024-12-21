import 'dart:math';

import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/currency.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/ui-common/bar_chart_report.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CurrencyAssetsSummarize extends CurrencySummarizeReport {
  CurrencyAssetsSummarize({required super.currency, required List<Asset> assets}) {
    refresh(assets);
  }

  refresh(List<Asset> assets) {
    totalOutstanding = 0;
    totalAvailable = 0;
    for (Asset asset in assets) {
      _readAssetData(asset);
    }
  }

  void _readAssetData(Asset asset) {
    String assetCurrencyId = asset.currencyUid;
    if (assetCurrencyId == currency.id) {
      String assetType = asset.getAssetType();
      totalFeePaid += asset.paidFee;
      if (assetType == AssetType.genericAccount.name || assetType == AssetType.bankCasa.name || assetType == AssetType.eWallet.name) {
        totalAvailable += asset.availableAmount;
      } else if (assetType == AssetType.creditCard.name) {
        var creditCard = (asset as CreditCard);
        totalCreditAvailable += creditCard.availableAmount;
        totalOutstanding += creditCard.creditLimit - creditCard.availableAmount;
      } else if (assetType == AssetType.payLaterAccount.name) {
        var payLater = (asset as PayLaterAccount);
        totalPayLaterAvailable += payLater.availableAmount;
        totalOutstanding += payLater.paymentLimit - payLater.availableAmount;
      } else if (assetType == AssetType.loan.name) {
        LoanAccount loanAccount = asset as LoanAccount;
        totalOutstanding += loanAccount.availableAmount;
        totalLoan += loanAccount.loanAmount;
      }
    }
  }
}

class CurrencySummarizeReport extends BarChartListData {
  Currency currency;
  double totalOutstanding = 0;
  double totalAvailable = 0;
  double totalCreditAvailable = 0;
  double totalPayLaterAvailable = 0;
  double totalLoan = 0;
  double totalFeePaid = 0;
  CurrencySummarizeReport({
    required this.currency,
    double? totalOutstanding,
    double? totalAvailable,
    double? totalCreditAvailable,
    double? totalPayLaterAvailable,
    double? totalLoan,
    double? totalFeePaid,
  })  : totalOutstanding = totalOutstanding ?? 0,
        totalAvailable = totalAvailable ?? 0,
        totalCreditAvailable = totalCreditAvailable ?? 0,
        totalPayLaterAvailable = totalPayLaterAvailable ?? 0,
        totalLoan = totalLoan ?? 0,
        totalFeePaid = totalFeePaid ?? 0;

  @override
  List<BarChartItemData> getItems(BuildContext context) {
    var appLocalizations = AppLocalizations.of(context)!;
    List<BarChartItemData> result = [
      BarChartItemData(value: totalAvailable, color: Colors.blue, label: appLocalizations.reportTotalAvailableAmount),
      BarChartItemData(
          value: totalOutstanding, color: Colors.red, label: appLocalizations.reportTotalOutstandingBalance, showAsNegativeInLabel: true)
    ];
    if (totalCreditAvailable > deltaCompareValue) {
      result.add(BarChartItemData(value: totalCreditAvailable, color: Colors.cyan, label: appLocalizations.reportTotalCreditAvailable));
    }
    if (totalPayLaterAvailable > deltaCompareValue) {
      result.add(BarChartItemData(value: totalPayLaterAvailable, color: Colors.grey, label: appLocalizations.reportTotalPayLaterAvailable));
    }
    if (totalFeePaid > deltaCompareValue) {
      result.add(BarChartItemData(
          value: totalFeePaid, color: Colors.grey, label: appLocalizations.reportTotalPaidFee, showAsNegativeInLabel: true));
    }
    return result;
  }

  @override
  double getMaxY() {
    return max(totalCreditAvailable, max(totalOutstanding, totalAvailable));
  }
}
