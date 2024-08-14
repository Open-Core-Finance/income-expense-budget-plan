class Currency {
  String uid;
  String name;
  String iso;
  bool deleted = false;
  String symbol;
  SymbolPosition symbolPosition = SymbolPosition.P;
  bool mainCurrency = false;
  bool show = true;
  int decimalPoint = 2;

  Currency(
      {required this.uid,
      required this.name,
      required this.iso,
      required this.symbol});

  // Convert a Assets into a Map. The keys must correspond to the names of the columns in the database.
  Map<String, Object?> toMap() {
    return {
      'uid': uid,
      'name': name,
      'iso': iso,
      'deleted': deleted ? 1 : 0,
      'symbol': symbol,
      'symbol_position': symbolPosition == SymbolPosition.S ? "S" : "P",
      'main_currency': mainCurrency ? 1 : 0,
      'show': show ? 1 : 0,
      'decimal_point': decimalPoint
    };
  }

  // Implement toString to make it easier to see information about
  // each Assets when using the print statement.
  @override
  String toString() {
    return '{uid: $uid, name: $name, iso: $iso, deleted: $deleted, symbol: $symbol, symbolPosition: $symbolPosition,'
        'mainCurrency: $mainCurrency, show: $show, decimalPoint: $decimalPoint}';
  }
}

enum SymbolPosition { S, P }
