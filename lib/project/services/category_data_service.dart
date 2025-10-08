import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:icofont_flutter/icofont_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

import '../classes/category_item.dart';
import '../classes/constants.dart';
import 'app_preferences_service.dart';

/// Service quản lý categories của app
class CategoryDataService {
  static final CategoryDataService _instance = CategoryDataService._internal();
  factory CategoryDataService() => _instance;
  CategoryDataService._internal();

  final AppPreferencesService _prefs = AppPreferencesService();

  /// Get categories for a parent item
  List<CategoryItem> getItems(String parentItemName) {
    try {
      final items = _prefs.getStringList(parentItemName);
      if (items == null) return [];
      
      return items
          .map((item) => CategoryItem.fromJson(jsonDecode(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save categories for a parent item
  void saveItems(String parentItemName, List<CategoryItem> items) {
    try {
      final itemsEncoded = items.map((item) => jsonEncode(item.toJson())).toList();
      _prefs.setStringList(parentItemName, itemsEncoded);
    } catch (e) {
      // Handle error silently or log
    }
  }

  /// Get all expense category names
  List<String> get parentExpenseItemNames {
    return _prefs.getStringList('parent expense item names') ?? [];
  }

  /// Set expense category names
  set parentExpenseItemNames(List<String> names) {
    _prefs.setStringList('parent expense item names', names);
  }

  /// Get all expense category lists
  List<List<CategoryItem>> getAllExpenseItemsLists() {
    final expenseItemsLists = <List<CategoryItem>>[];
    for (final parentName in parentExpenseItemNames) {
      expenseItemsLists.add(getItems(parentName));
    }
    return expenseItemsLists;
  }

  /// Initialize default categories if not exists
  void initializeDefaultCategories({bool forceReset = false}) {
    if (!_prefs.containsKey('parent expense item names') || forceReset) {
      _setDefaultExpenseCategories();
      _setDefaultIncomeCategories();
    }
    
    if (!forceReset && !_prefs.containsKey('selectedDate')) {
      _setDefaultAppSettings();
    }
  }

  void _setDefaultExpenseCategories() {
    parentExpenseItemNames = [
      'Food & Beverages',
      'Transport',
      'Personal Development',
      'Shopping',
      'Entertainment',
      'Home',
      'Utility Bills',
      'Health',
      'Gifts & Donations',
      'Kids',
      'OtherExpense'
    ];

    // Food & Beverages
    saveItems('Food & Beverages', [
      categoryItem(MdiIcons.food, 'Food & Beverages'),
      categoryItem(MdiIcons.foodDrumstick, 'Food'),
      categoryItem(Icons.local_bar, 'Beverages'),
      categoryItem(Icons.coffee, 'Coffee'),
      categoryItem(Icons.add_shopping_cart, 'Daily Necessities'),
    ]);

    // Transport
    saveItems('Transport', [
      categoryItem(OMIcons.commute, 'Transport'),
      categoryItem(Icons.local_gas_station, 'Fuel'),
      categoryItem(Icons.local_parking, 'Parking'),
      categoryItem(IcoFontIcons.toolsBag, 'Services & Maintenance'),
      categoryItem(Icons.local_taxi_outlined, 'Taxi'),
    ]);

    // Personal Development
    saveItems('Personal Development', [
      categoryItem(IcoFontIcons.businessman, 'Personal Development'),
      categoryItem(Icons.business, 'Business'),
      categoryItem(IcoFontIcons.education, 'Education'),
      categoryItem(IcoFontIcons.bagAlt, 'InvestmentExpense'),
    ]);

    // Shopping
    saveItems('Shopping', [
      categoryItem(IcoFontIcons.shoppingCart, 'Shopping'),
      categoryItem(Boxicons.bxs_t_shirt, 'Clothes'),
      categoryItem(Boxicons.bxs_binoculars, 'Accessories'),
      categoryItem(Boxicons.bxs_devices, 'Electronic Devices'),
    ]);

    // Entertainment
    saveItems('Entertainment', [
      categoryItem(Icons.add_photo_alternate_outlined, 'Entertainment'),
      categoryItem(Icons.movie_filter, 'Movies'),
      categoryItem(IcoFontIcons.gameController, 'Games'),
      categoryItem(Icons.library_music, 'Music'),
      categoryItem(Icons.airplanemode_active, 'Travel'),
    ]);

    // Home
    saveItems('Home', [
      categoryItem(MdiIcons.homeHeart, 'Home'),
      categoryItem(MdiIcons.dogService, 'Pets'),
      categoryItem(MdiIcons.tableChair, 'Furnishings'),
      categoryItem(MdiIcons.autoFix, 'Home Services'),
    ]);

    // Utility Bills
    saveItems('Utility Bills', [
      categoryItem(FontAwesomeIcons.fileInvoiceDollar, 'Utility Bills'),
      categoryItem(IcoFontIcons.lightBulb, 'Electricity'),
      categoryItem(IcoFontIcons.globe, 'Internet'),
      categoryItem(IcoFontIcons.stockMobile, 'Mobile Phone'),
      categoryItem(IcoFontIcons.waterDrop, 'Water'),
    ]);

    // Health
    saveItems('Health', [
      categoryItem(FontAwesomeIcons.handHoldingMedical, 'Health'),
      categoryItem(MdiIcons.soccer, 'Sports'),
      categoryItem(MdiIcons.fileDocumentMultipleOutline, 'Health Insurance'),
      categoryItem(MdiIcons.doctor, 'Doctor'),
      categoryItem(MdiIcons.medicalBag, 'Medicine'),
    ]);

    // Gifts & Donations
    saveItems('Gifts & Donations', [
      categoryItem(Boxicons.bxs_donate_heart, 'Gifts & Donations'),
      categoryItem(IcoFontIcons.gift, 'GiftsExpense'),
      categoryItem(IcoFontIcons.love, 'Wedding'),
      categoryItem(IcoFontIcons.worried, 'Funeral'),
      categoryItem(IcoFontIcons.usersSocial, 'Charity'),
    ]);

    // Kids
    saveItems('Kids', [
      categoryItem(Icons.child_care, 'Kids'),
      categoryItem(MdiIcons.cashCheck, 'Pocket Money'),
      categoryItem(MdiIcons.babyBottle, 'Baby Products'),
      categoryItem(MdiIcons.humanBabyChangingTable, 'Babysitter & Daycare'),
      categoryItem(MdiIcons.bookCheck, 'Tuition'),
    ]);

    // Other Expense
    saveItems('OtherExpense', [
      categoryItem(MdiIcons.cashPlus, 'OtherExpense'),
    ]);
  }

  void _setDefaultIncomeCategories() {
    saveItems('income items', [
      categoryItem(MdiIcons.accountCash, 'Salary'),
      categoryItem(Icons.business_center_rounded, 'InvestmentIncome'),
      categoryItem(IcoFontIcons.moneyBag, 'Bonus'),
      categoryItem(IcoFontIcons.searchJob, 'Side job'),
      categoryItem(IcoFontIcons.gift, 'GiftsIncome'),
      categoryItem(IcoFontIcons.money, 'Tax Refund'),
      categoryItem(MdiIcons.cashPlus, 'OtherIncome'),
    ]);
  }

  void _setDefaultAppSettings() {
    _prefs.selectedDate = 'Today';
    _prefs.isPasscodeOn = true;
    _prefs.passcodeScreenLock = '123456';
    _prefs.dateFormat = 'dd/MM/yyyy';
  }

  /// Get income items (convenience method)
  List<CategoryItem> get incomeItems => getItems('income items');
}