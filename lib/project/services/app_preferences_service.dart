import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Service quản lý preferences cơ bản của app
class AppPreferencesService {
  static final AppPreferencesService _instance = AppPreferencesService._internal();
  factory AppPreferencesService() => _instance;
  AppPreferencesService._internal();

  static SharedPreferences? _sharedPrefs;
  static late String currency;

  /// Initialize SharedPreferences
  Future<void> init() async {
    _sharedPrefs ??= await SharedPreferences.getInstance();
    _updateCurrency();
  }

  /// Update currency symbol based on current locale
  void _updateCurrency() {
    if (_sharedPrefs!.containsKey('appCurrency')) {
      var format = NumberFormat.simpleCurrency(locale: appCurrency);
      currency = format.currencySymbol;
    } else {
      var format = NumberFormat.simpleCurrency(locale: Platform.localeName);
      currency = format.currencySymbol;
    }
  }

  // Date preferences
  String get selectedDate => _sharedPrefs!.getString('selectedDate') ?? 'Today';
  set selectedDate(String value) => _sharedPrefs!.setString('selectedDate', value);

  // Currency preferences
  String get appCurrency => _sharedPrefs!.getString('appCurrency') ?? Platform.localeName;
  set appCurrency(String value) {
    _sharedPrefs!.setString('appCurrency', value);
    _updateCurrency();
  }

  // Date format preferences
  String get dateFormat => _sharedPrefs!.getString('dateFormat') ?? 'dd/MM/yyyy';
  set dateFormat(String value) => _sharedPrefs!.setString('dateFormat', value);

  // Passcode preferences
  bool get isPasscodeOn => _sharedPrefs!.getBool('isPasscodeOn') ?? false;
  set isPasscodeOn(bool value) => _sharedPrefs!.setBool('isPasscodeOn', value);

  String get passcodeScreenLock => _sharedPrefs!.getString('passcodeScreenLock') ?? '';
  set passcodeScreenLock(String value) => _sharedPrefs!.setString('passcodeScreenLock', value);

  // Reminder preferences
  bool get isReminderEnabled => _sharedPrefs!.getBool('isReminderEnabled') ?? false;
  set isReminderEnabled(bool value) => _sharedPrefs!.setBool('isReminderEnabled', value);

  int get reminderHour => _sharedPrefs!.getInt('reminderHour') ?? 21;
  set reminderHour(int value) => _sharedPrefs!.setInt('reminderHour', value);

  int get reminderMinute => _sharedPrefs!.getInt('reminderMinute') ?? 0;
  set reminderMinute(int value) => _sharedPrefs!.setInt('reminderMinute', value);

  // Language preferences
  String get languageCode => _sharedPrefs!.getString('languageCode') ?? 'en';
  set languageCode(String value) => _sharedPrefs!.setString('languageCode', value);

  /// Remove a specific preference
  Future<bool> removeItem(String key) {
    return _sharedPrefs!.remove(key);
  }

  /// Clear all preferences (use with caution)
  Future<bool> clearAll() {
    return _sharedPrefs!.clear();
  }

  /// Check if a key exists
  bool containsKey(String key) {
    return _sharedPrefs!.containsKey(key);
  }

  /// Get string list from preferences
  List<String>? getStringList(String key) {
    return _sharedPrefs!.getStringList(key);
  }

  /// Set string list to preferences
  Future<bool> setStringList(String key, List<String> value) {
    return _sharedPrefs!.setStringList(key, value);
  }
}