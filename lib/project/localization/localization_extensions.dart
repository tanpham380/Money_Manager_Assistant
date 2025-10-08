import 'package:flutter/material.dart';
import 'app_localization.dart';

/// Extension để tối ưu localization calls
extension LocalizationExtension on BuildContext {
  /// Shorthand cho getTranslated với fallback
  String tr(String key, [String? fallback]) {
    return AppLocalization.of(this)?.translate(key) ?? 
           fallback ?? 
           key;
  }

  /// Get localized map
  Map<String, String>? get localizedMap => 
      AppLocalization.of(this)?.localizedMap();

  /// Check if key exists in translations
  bool hasTranslation(String key) {
    return AppLocalization.of(this)?.translate(key) != null;
  }
}

/// Locale helper function
Locale locale(String languageCode) {
  switch (languageCode) {
    case 'en':
      return const Locale('en', 'US');
    case 'vi':
      return const Locale('vi', 'VN');
    default:
      return const Locale('en', 'US');
  }
}

/// Legacy function for backward compatibility
/// TODO: Gradually replace with context.tr()
String? getTranslated(BuildContext context, String key) {
  return context.tr(key);
}

/// Helper cho các text được dùng nhiều
class CommonTexts {
  static String cancel(BuildContext context) => context.tr('Cancel');
  static String ok(BuildContext context) => context.tr('OK');
  static String delete(BuildContext context) => context.tr('Delete');
  static String save(BuildContext context) => context.tr('Save');
  static String edit(BuildContext context) => context.tr('Edit');
  static String add(BuildContext context) => context.tr('Add');
  static String remove(BuildContext context) => context.tr('Remove');
  static String confirm(BuildContext context) => context.tr('Confirm');
  static String yes(BuildContext context) => context.tr('Yes');
  static String no(BuildContext context) => context.tr('No');
  static String loading(BuildContext context) => context.tr('Loading...');
  static String noData(BuildContext context) => context.tr('No data');
  static String error(BuildContext context) => context.tr('Error');
  static String success(BuildContext context) => context.tr('Success');
}

/// Helper cho category translations 
class CategoryTexts {
  static String food(BuildContext context) => context.tr('Food');
  static String transport(BuildContext context) => context.tr('Transport');
  static String shopping(BuildContext context) => context.tr('Shopping');
  static String entertainment(BuildContext context) => context.tr('Entertainment');
  static String health(BuildContext context) => context.tr('Health');
  static String salary(BuildContext context) => context.tr('Salary');
  static String bonus(BuildContext context) => context.tr('Bonus');
  static String investment(BuildContext context) => context.tr('Investment');
  static String others(BuildContext context) => context.tr('Others');
}

/// Helper cho finance texts
class FinanceTexts {
  static String income(BuildContext context) => context.tr('Income');
  static String expense(BuildContext context) => context.tr('Expense');
  static String balance(BuildContext context) => context.tr('Balance');
  static String total(BuildContext context) => context.tr('Total');
  static String amount(BuildContext context) => context.tr('Amount');
  static String category(BuildContext context) => context.tr('Category');
  static String date(BuildContext context) => context.tr('Date');
  static String description(BuildContext context) => context.tr('Description');
}