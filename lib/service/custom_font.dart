import 'package:flutter/cupertino.dart';

class MaterialSymbolsOutlinedFont {
  static const String fontName = "MaterialSymbolsOutlined";

  // Singleton pattern
  static final MaterialSymbolsOutlinedFont _font = MaterialSymbolsOutlinedFont._internal();
  factory MaterialSymbolsOutlinedFont() => _font;
  MaterialSymbolsOutlinedFont._internal();

  // data_alert
  static const IconData iconDataDataAlert = IconData(0xf7f6, fontFamily: fontName, matchTextDirection: true);
  // add_circle
  static const IconData iconDataAddCircle = IconData(0xe147, fontFamily: fontName, matchTextDirection: true);
  // Icons.remove_circle
  // static const IconData expenseIconData = IconData(0xe644, fontFamily: fontName, matchTextDirection: true);
  // price_change
  static const IconData priceChangeIconData = IconData(0xf04a, fontFamily: fontName, matchTextDirection: true);
}
