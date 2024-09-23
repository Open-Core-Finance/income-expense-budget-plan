import 'package:income_expense_budget_plan/model/generic_model.dart';
import 'package:income_expense_budget_plan/model/setting.dart';

abstract class NameLocalizedModel<T> extends GenericModel<T> {
  String name;
  Map<String, String> localizeNames = {};

  NameLocalizedModel({required super.id, required this.name, Map<String, String>? localizeNames}) {
    if (localizeNames != null) {
      this.localizeNames = localizeNames;
    }
  }

  String getTitleText(SettingModel setting) {
    var textLocalizeLanguage = localizeNames[setting.locale?.languageCode];
    String tileText;
    if (textLocalizeLanguage?.isNotEmpty == true) {
      tileText = textLocalizeLanguage!;
    } else {
      tileText = name;
    }
    return tileText;
  }
}
