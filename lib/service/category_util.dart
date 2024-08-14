import 'package:flutter/material.dart';

class CategoryUtil {
  // Singleton pattern
  static final CategoryUtil _util = CategoryUtil._internal();
  factory CategoryUtil() => _util;
  CategoryUtil._internal();

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
}
