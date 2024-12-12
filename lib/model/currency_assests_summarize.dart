import 'package:income_expense_budget_plan/model/assets.dart';
import 'package:income_expense_budget_plan/model/currency.dart';

class CurrencyAssetsSummarize {
  Currency currency;
  double totalOutstanding = 0;
  double totalAvailable = 0;
  CurrencyAssetsSummarize({required this.currency, required List<Asset> assets}) {
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
      if (assetType == AssetType.genericAccount.name || assetType == AssetType.bankCasa.name || assetType == AssetType.eWallet.name) {
        totalAvailable += asset.availableAmount;
      } else if (assetType == AssetType.creditCard.name) {
        totalAvailable += asset.availableAmount;
        var creditCard = (asset as CreditCard);
        totalOutstanding += creditCard.creditLimit - creditCard.availableAmount;
      } else if (assetType == AssetType.payLaterAccount.name) {
        totalAvailable += asset.availableAmount;
        var payLater = (asset as PayLaterAccount);
        totalOutstanding += payLater.paymentLimit - payLater.availableAmount;
      }
    }
  }
}
