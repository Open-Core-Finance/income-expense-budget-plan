import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:income_expense_budget_plan/service/custom_font.dart';

class NoDataCard extends StatefulWidget {
  const NoDataCard({super.key});

  @override
  State<StatefulWidget> createState() => _NoDataCardState();
}

class _NoDataCardState extends State<NoDataCard> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      //shadowColor: Colors.transparent,
      child: SizedBox.expand(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(MaterialSymbolsOutlinedFont.iconDataDataAlert, size: 60),
            const SizedBox(height: 2.0),
            Text(AppLocalizations.of(context)!.noData, style: theme.textTheme.titleLarge),
          ]),
        ),
      ),
    );
  }
}
