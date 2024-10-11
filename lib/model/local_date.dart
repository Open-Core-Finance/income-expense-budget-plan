import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LocalDate {
  int year;
  int month;
  int day;
  LocalDate({required this.year, required this.month, required this.day});

  factory LocalDate.fromCurrentDate() => LocalDate.fromDate(DateTime.now());

  factory LocalDate.fromDate(DateTime dateTime) {
    return LocalDate(year: dateTime.year, month: dateTime.month, day: dateTime.day);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalDate && other.year == year && other.month == month && other.day == day;
  }

  @override
  String toString() {
    return '$year-$month-$day';
  }

  @override
  int get hashCode => year.hashCode + month.hashCode + day.hashCode;

  String getMonthString() => month < 10 ? "0$month" : "$month";

  String getWeekDay(BuildContext context) {
    // Localization
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    // Create a DateTime object using the provided day, month, and year
    DateTime date = DateTime(year, month, day);

    // Today datetime
    DateTime today = DateTime.now();

    if (today.month == month && today.year == year) {
      int todayDate = today.day;
      if (todayDate == day) {
        return appLocalizations.weekDayToday;
      } else if (todayDate == day - 1) {
        return appLocalizations.weekDayYesterday;
      } else if (todayDate == day + 1) {
        return appLocalizations.weekDayTomorrow;
      }
    }

    // Get the weekday as an integer (1 = Monday, 7 = Sunday)
    int weekday = date.weekday;

    switch (weekday) {
      case 1:
        return appLocalizations.weekDay1;
      case 2:
        return appLocalizations.weekDay2;
      case 3:
        return appLocalizations.weekDay3;
      case 4:
        return appLocalizations.weekDay4;
      case 5:
        return appLocalizations.weekDay5;
      case 6:
        return appLocalizations.weekDay6;
      default:
        return appLocalizations.weekDay7;
    }
  }
}
