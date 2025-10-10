// Backward compatibility wrapper for SharedPrefs
// TODO: Gradually migrate to use services directly

import 'package:flutter/material.dart';
import '../localization/methods.dart';
import '../classes/category_item.dart';
import 'app_preferences_service.dart';
import 'category_data_service.dart';

class SharedPrefs {
  final AppPreferencesService _appPrefs = AppPreferencesService();
  final CategoryDataService _categoryData = CategoryDataService();

  // Forward all calls to appropriate services
  Future<void> sharePrefsInit() => _appPrefs.init();
  
  String get selectedDate => _appPrefs.selectedDate;
  set selectedDate(String value) => _appPrefs.selectedDate = value;
  
  String get appCurrency => _appPrefs.appCurrency;
  set appCurrency(String value) => _appPrefs.appCurrency = value;
  
  String get dateFormat => _appPrefs.dateFormat;
  set dateFormat(String value) => _appPrefs.dateFormat = value;
  
  bool get isPasscodeOn => _appPrefs.isPasscodeOn;
  set isPasscodeOn(bool value) => _appPrefs.isPasscodeOn = value;
  
  String get passcodeScreenLock => _appPrefs.passcodeScreenLock;
  set passcodeScreenLock(String value) => _appPrefs.passcodeScreenLock = value;
  
  bool get isReminderEnabled => _appPrefs.isReminderEnabled;
  set isReminderEnabled(bool value) => _appPrefs.isReminderEnabled = value;
  
  int get reminderHour => _appPrefs.reminderHour;
  set reminderHour(int value) => _appPrefs.reminderHour = value;
  
  int get reminderMinute => _appPrefs.reminderMinute;
  set reminderMinute(int value) => _appPrefs.reminderMinute = value;
  
  List<String> get parentExpenseItemNames => _categoryData.parentExpenseItemNames;
  set parentExpenseItemNames(List<String> value) => _categoryData.parentExpenseItemNames = value;
  
  List<CategoryItem> getItems(String parentItemName) => _categoryData.getItems(parentItemName);
  void saveItems(String parentItemName, List<CategoryItem> items) => _categoryData.saveItems(parentItemName, items);
  List<List<CategoryItem>> getAllExpenseItemsLists() => _categoryData.getAllExpenseItemsLists();
  
  void removeItem(String itemName) => _appPrefs.removeItem(itemName);
  
  void setItems({required bool setCategoriesToDefault}) {
    _categoryData.initializeDefaultCategories(forceReset: setCategoriesToDefault);
  }
  
  Locale setLocale(String languageCode) {
    _appPrefs.languageCode = languageCode;
    return locale(languageCode);
  }
  
  Locale getLocale() {
    return locale(_appPrefs.languageCode);
  }
  
  void getCurrency() {
    // This is handled automatically in AppPreferencesService
  }
}

// Global instances for backward compatibility
final sharedPrefs = SharedPrefs();
late String currency = AppPreferencesService.currency;
var incomeItems = sharedPrefs.getItems('income items');