import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/model/transaction.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:income_expense_budget_plan/service/form_util.dart';
import 'package:income_expense_budget_plan/service/transaction_service.dart';

class TransactionItemConfigKey {
  static const double markDisplaySize = 22;
  static const double iconDisplaySize = 24 * 3 / 2;
  static const double categoryNameSize = 18;
  static const double transactionDescriptionSize = 12;
  static const double amountSize = 22;
  static const double accountNameSize = 16;

  static const double eachTransactionHeight = 80;
}

abstract class GenericTransactionTile<T extends Transactions> extends StatelessWidget {
  final T transaction;
  final FormUtil formUtil = FormUtil();
  final Function(Transactions transaction)? onTap;
  GenericTransactionTile({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    Widget? accountWidget = accountDisplay(context);
    return GestureDetector(
      onTap: () {
        if (onTap != null) onTap!(transaction);
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 0, maxHeight: TransactionItemConfigKey.eachTransactionHeight),
        child: MouseRegion(
          cursor: SystemMouseCursors.click, // Changes the cursor to a pointer
          child: Row(
            children: [
              SizedBox(
                height: TransactionItemConfigKey.eachTransactionHeight,
                child: VerticalDivider(thickness: 2, color: theme.dividerColor, endIndent: 0, indent: 0),
              ),
              const Text("---", style: TextStyle(fontSize: TransactionItemConfigKey.markDisplaySize), textAlign: TextAlign.left),
              iconDisplay(context),
              const SizedBox(width: 5),
              nameDisplay(context),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [amountDisplay(context), if (accountWidget != null) accountWidget],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget amountDisplay(BuildContext context) {
    var formatter = FormUtil().buildFormatter(currentAppState.currencies
        .firstWhere((element) => element.id == transaction.currencyUid, orElse: () => currentAppState.systemSetting.defaultCurrency!));
    return Text(formatter.formatDouble(transaction.amount), style: amountTextStyle(context));
  }

  Widget? accountDisplay(BuildContext context) {
    return Text(transaction.account.name,
        style: const TextStyle(fontSize: TransactionItemConfigKey.accountNameSize), textAlign: TextAlign.right);
  }

  Widget nameDisplay(BuildContext context) {
    var textStyle = const TextStyle(fontSize: TransactionItemConfigKey.categoryNameSize);
    String text = "";
    if (transaction.transactionCategory != null) {
      text = transaction.transactionCategory!.getTitleText(currentAppState.systemSetting);
    }
    if (transaction.description.isNotEmpty) {
      var descriptionTextStyle = const TextStyle(fontSize: TransactionItemConfigKey.transactionDescriptionSize);
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, textAlign: TextAlign.left, style: textStyle),
            Text(transaction.description, textAlign: TextAlign.left, style: descriptionTextStyle)
          ],
        ),
      );
    } else {
      return Expanded(child: Text(text, style: textStyle, textAlign: TextAlign.left));
    }
  }

  TextStyle amountTextStyle(BuildContext context);

  Widget iconDisplay(BuildContext context) =>
      Icon(transaction.transactionCategory?.icon ?? defaultIcon(context), size: TransactionItemConfigKey.iconDisplaySize);

  IconData defaultIcon(BuildContext context) => TransactionService().getDefaultIconData(transaction);
}

class ExpenseTransactionTile extends GenericTransactionTile<ExpenseTransaction> {
  ExpenseTransactionTile({super.key, required super.transaction, super.onTap});

  @override
  TextStyle amountTextStyle(BuildContext context) {
    return const TextStyle(fontSize: TransactionItemConfigKey.amountSize, color: Colors.red);
  }
}

class IncomeTransactionTile extends GenericTransactionTile<IncomeTransaction> {
  IncomeTransactionTile({super.key, required super.transaction, super.onTap});

  @override
  TextStyle amountTextStyle(BuildContext context) {
    return const TextStyle(fontSize: TransactionItemConfigKey.amountSize, color: Colors.blue);
  }
}

class TransferTransactionTile extends GenericTransactionTile<TransferTransaction> {
  TransferTransactionTile({super.key, required super.transaction, super.onTap});

  @override
  TextStyle amountTextStyle(BuildContext context) => const TextStyle(fontSize: TransactionItemConfigKey.amountSize);

  @override
  Widget nameDisplay(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    String text = appLocalizations.transactionTransferTitle(transaction.toAccount.getTitleText(currentAppState.systemSetting));
    if (transaction.description.isNotEmpty) {
      var descriptionTextStyle = const TextStyle(fontSize: TransactionItemConfigKey.transactionDescriptionSize);
      return Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, textAlign: TextAlign.left, style: const TextStyle(fontSize: TransactionItemConfigKey.categoryNameSize)),
          Text(transaction.description, textAlign: TextAlign.left, style: descriptionTextStyle)
        ]),
      );
    } else {
      return Expanded(
        child: Text(text, style: const TextStyle(fontSize: TransactionItemConfigKey.categoryNameSize), textAlign: TextAlign.left),
      );
    }
  }
}

class SharedBillTransactionTile extends GenericTransactionTile<ShareBillTransaction> {
  SharedBillTransactionTile({super.key, required super.transaction, super.onTap});

  @override
  TextStyle amountTextStyle(BuildContext context) => const TextStyle(fontSize: TransactionItemConfigKey.amountSize, color: Colors.red);

  @override
  Widget nameDisplay(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    var formatter = FormUtil().buildFormatter(currentAppState.currencies
        .firstWhere((element) => element.id == transaction.currencyUid, orElse: () => currentAppState.systemSetting.defaultCurrency!));
    String text = appLocalizations.transactionSharedBillTitle(
        formatter.formatDouble(transaction.amount), transaction.transactionCategory?.getTitleText(currentAppState.systemSetting) ?? "");
    if (transaction.description.isNotEmpty) {
      var descriptionTextStyle = const TextStyle(fontSize: TransactionItemConfigKey.transactionDescriptionSize);
      return Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, textAlign: TextAlign.left, style: const TextStyle(fontSize: TransactionItemConfigKey.categoryNameSize)),
          Text(transaction.description, textAlign: TextAlign.left, style: descriptionTextStyle)
        ]),
      );
    } else {
      return Expanded(
        child: Text(text, style: const TextStyle(fontSize: TransactionItemConfigKey.categoryNameSize), textAlign: TextAlign.left),
      );
    }
  }

  @override
  Widget amountDisplay(BuildContext context) {
    var formatter = FormUtil().buildFormatter(currentAppState.currencies
        .firstWhere((element) => element.id == transaction.currencyUid, orElse: () => currentAppState.systemSetting.defaultCurrency!));
    return Text(formatter.formatDouble(transaction.mySplit), style: amountTextStyle(context));
  }
}

class SharedBillTransactionTileForDialog extends SharedBillTransactionTile {
  SharedBillTransactionTileForDialog({super.key, required super.transaction, super.onTap});

  @override
  Widget amountDisplay(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    var formatter = FormUtil().buildFormatter(currentAppState.currencies
        .firstWhere((element) => element.id == transaction.currencyUid, orElse: () => currentAppState.systemSetting.defaultCurrency!));
    const double size = TransactionItemConfigKey.amountSize;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${appLocalizations.transactionSharedBillRemainingLabel} "', style: const TextStyle(fontSize: size, color: Colors.black)),
        Text(formatter.formatDouble(transaction.remainingAmount), style: const TextStyle(fontSize: size, color: Colors.red)),
        const Text('"', style: TextStyle(fontSize: TransactionItemConfigKey.amountSize - 4, color: Colors.black)),
      ],
    );
  }

  @override
  Widget? accountDisplay(BuildContext context) => null;
}

class SharedBillReturnTransactionTile extends GenericTransactionTile<ShareBillReturnTransaction> {
  SharedBillReturnTransactionTile({super.key, required super.transaction, super.onTap});

  @override
  TextStyle amountTextStyle(BuildContext context) => const TextStyle(fontSize: TransactionItemConfigKey.amountSize, color: Colors.blue);

  @override
  IconData defaultIcon(BuildContext context) => const IconData(0xf3ee, fontFamily: 'MaterialSymbolsIcons');

  @override
  Widget nameDisplay(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    String text = appLocalizations
        .transactionSharedBillReturnedTitle(transaction.transactionCategory?.getTitleText(currentAppState.systemSetting) ?? "");
    if (transaction.description.isNotEmpty) {
      var descriptionTextStyle = const TextStyle(fontSize: TransactionItemConfigKey.transactionDescriptionSize - 4);
      return Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, textAlign: TextAlign.left, style: const TextStyle(fontSize: TransactionItemConfigKey.categoryNameSize - 4)),
          Text(transaction.description, textAlign: TextAlign.left, style: descriptionTextStyle)
        ]),
      );
    } else {
      return Expanded(
        child: Text(text, style: const TextStyle(fontSize: TransactionItemConfigKey.categoryNameSize), textAlign: TextAlign.left),
      );
    }
  }
}

class AdjustmentTransactionTile extends GenericTransactionTile<AdjustmentTransaction> {
  late final bool isNegative;
  AdjustmentTransactionTile({super.key, required super.transaction, super.onTap}) {
    isNegative = super.transaction.adjustedAmount < 0;
  }

  @override
  TextStyle amountTextStyle(BuildContext context) {
    Color color = Colors.blue;
    if (isNegative) {
      color = Colors.red;
    }
    return TextStyle(fontSize: TransactionItemConfigKey.amountSize, color: color);
  }

  @override
  Widget nameDisplay(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    var formatter = FormUtil().buildFormatter(currentAppState.currencies
        .firstWhere((element) => element.id == transaction.currencyUid, orElse: () => currentAppState.systemSetting.defaultCurrency!));
    String text = appLocalizations.transactionAdjustedFrom(formatter.formatDouble(transaction.amount));
    if (transaction.description.isNotEmpty) {
      var descriptionTextStyle = const TextStyle(fontSize: TransactionItemConfigKey.transactionDescriptionSize);
      return Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, textAlign: TextAlign.left, style: const TextStyle(fontSize: TransactionItemConfigKey.categoryNameSize)),
          Text(transaction.description, textAlign: TextAlign.left, style: descriptionTextStyle)
        ]),
      );
    } else {
      return Expanded(
        child: Text(text, style: const TextStyle(fontSize: TransactionItemConfigKey.categoryNameSize), textAlign: TextAlign.left),
      );
    }
  }

  @override
  Widget amountDisplay(BuildContext context) {
    var formatter = FormUtil().buildFormatter(currentAppState.currencies
        .firstWhere((element) => element.id == transaction.currencyUid, orElse: () => currentAppState.systemSetting.defaultCurrency!));
    return Text(formatter.formatDouble(transaction.adjustedAmount), style: amountTextStyle(context));
  }
}
