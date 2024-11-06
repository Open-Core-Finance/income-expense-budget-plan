import 'package:flutter/material.dart';
import 'package:income_expense_budget_plan/service/app_const.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FeatureInDevelopment extends StatefulWidget {
  const FeatureInDevelopment({super.key});

  @override
  State<FeatureInDevelopment> createState() => _FeatureInDevelopmentState();
}

class _FeatureInDevelopmentState extends State<FeatureInDevelopment> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return Card(
      //shadowColor: Colors.transparent,
      child: SizedBox.expand(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.engineering, size: 60),
            const SizedBox(height: 2.0),
            Text(appLocalizations.featureTBD, style: theme.textTheme.titleLarge),
          ]),
        ),
      ),
    );
  }
}
