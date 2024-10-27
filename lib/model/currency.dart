import 'package:income_expense_budget_plan/model/generic_model.dart';

class Currency extends GenericModel {
  String name;
  String iso;
  late bool deleted;
  String symbol;
  late SymbolPosition symbolPosition;
  late bool mainCurrency;
  bool show = true;
  late int decimalPoint;
  String language;

  Currency(
      {required super.id,
      required this.name,
      required this.iso,
      required this.symbol,
      bool? deleted,
      bool? mainCurrency,
      bool? show,
      SymbolPosition? symbolPosition,
      int? decimalPoint,
      required this.language}) {
    this.deleted = deleted == true;
    this.mainCurrency = mainCurrency == true;
    this.show = show != false;
    this.symbolPosition = symbolPosition ?? SymbolPosition.P;
    this.decimalPoint = decimalPoint ?? 2;
  }

  @override
  Map<String, Object?> toMap() {
    return {
      'uid': id,
      'name': name,
      'iso': iso,
      'deleted': deleted ? 1 : 0,
      'symbol': symbol,
      'symbol_position': symbolPosition == SymbolPosition.S ? "S" : "P",
      'main_currency': mainCurrency ? 1 : 0,
      'show': show ? 1 : 0,
      'decimal_point': decimalPoint,
      'language': language
    };
  }

  @override
  String toString() {
    return '{"uid": "$id", "name": "$name", "iso": "$iso", "deleted": "$deleted", "symbol": "$symbol", "symbolPosition": "$symbolPosition",'
        '"mainCurrency": "$mainCurrency", "show": "$show", "decimalPoint": "$decimalPoint", "language": "$language"}';
  }

  @override
  String displayText() => name;

  @override
  String idFieldName() => "uid";

  factory Currency.fromMap(Map<String, dynamic> json) => Currency(
      id: json['uid'],
      iso: json['iso'],
      name: json['name'],
      deleted: json['deleted'] == 1,
      symbol: json['symbol'],
      symbolPosition: SymbolPosition.values.firstWhere((symbol) => symbol.toString().split('.').last == json['symbol_position']),
      mainCurrency: json['main_currency'] == 1,
      show: json['show'] == 1,
      decimalPoint: json['decimal_point'],
      language: json['language']);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Currency && other.id == id;
  }

  @override
  int get hashCode => iso.hashCode;
}

enum SymbolPosition { S, P }
