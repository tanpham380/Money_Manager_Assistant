import 'package:flutter/material.dart';
import '../database_management/shared_preferences_services.dart';
import '../classes/category_item.dart';

/// Service thống nhất để quản lý icon cho categories
/// Thay thế CategoryIconHelper và _getIconForCategory duplicate code
class CategoryIconService {
  static final CategoryIconService _instance = CategoryIconService._internal();
  factory CategoryIconService() => _instance;
  CategoryIconService._internal();

  // Cache để tránh lookup nhiều lần
  final Map<String, IconData> _iconCache = {};

  /// Lấy icon cho category name
  /// Ưu tiên: 1. Từ CategoryItem saved data, 2. Fallback to default mapping
  IconData getIconForCategory(String categoryName) {
    // Check cache first
    if (_iconCache.containsKey(categoryName)) {
      return _iconCache[categoryName]!;
    }

    IconData icon = _getIconFromSavedData(categoryName) ?? 
                   _getDefaultIconForCategory(categoryName);
    
    _iconCache[categoryName] = icon;
    return icon;
  }

  /// Tìm icon từ saved CategoryItem data
  IconData? _getIconFromSavedData(String categoryName) {
    try {
      // Check income items
      final incomeItems = sharedPrefs.getItems('income items');
      for (final item in incomeItems) {
        if (_matchesCategory(item.text, categoryName)) {
          return _iconDataFromCategoryItem(item);
        }
      }

      // Check expense categories
      final expenseCategories = sharedPrefs.parentExpenseItemNames;
      for (final parentCategory in expenseCategories) {
        final items = sharedPrefs.getItems(parentCategory);
        for (final item in items) {
          if (_matchesCategory(item.text, categoryName)) {
            return _iconDataFromCategoryItem(item);
          }
        }
      }
    } catch (e) {
      // If SharedPrefs not initialized or error, fallback to default
    }
    
    return null;
  }

  /// Convert CategoryItem to IconData
  IconData _iconDataFromCategoryItem(CategoryItem item) {
    return IconData(
      item.iconCodePoint,
      fontFamily: item.iconFontFamily,
      fontPackage: item.iconFontPackage,
    );
  }

  /// Kiểm tra category name match (flexible matching)
  bool _matchesCategory(String itemText, String categoryName) {
    final normalized1 = itemText.toLowerCase().replaceAll(' ', '').replaceAll('&', '');
    final normalized2 = categoryName.toLowerCase().replaceAll(' ', '').replaceAll('&', '');
    
    return normalized1 == normalized2 || 
           normalized1.contains(normalized2) || 
           normalized2.contains(normalized1);
  }

  /// Default icon mapping (fallback)
  IconData _getDefaultIconForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      // Food & Dining
      case 'food':
      case 'food & beverages':
        return Icons.restaurant;
      case 'breakfast':
        return Icons.free_breakfast_outlined;
      case 'lunch':
        return Icons.restaurant_outlined;
      case 'dinner':
        return Icons.dinner_dining_outlined;
      case 'coffee':
        return Icons.coffee_outlined;

      // Transportation
      case 'transportation':
      case 'transport':
        return Icons.directions_car;
      case 'taxi':
        return Icons.local_taxi;
      case 'fuel':
      case 'gas':
        return Icons.local_gas_station;
      case 'parking':
        return Icons.local_parking;

      // Shopping
      case 'shopping':
        return Icons.shopping_bag;
      case 'daily necessities':
        return Icons.add_shopping_cart;
      case 'clothes':
        return Icons.checkroom;
      case 'electronics':
      case 'electronic devices':
        return Icons.devices;

      // Entertainment
      case 'entertainment':
        return Icons.movie_filter;
      case 'movies':
      case 'cinema':
        return Icons.movie_outlined;
      case 'music':
        return Icons.music_note;
      case 'games':
        return Icons.sports_esports;

      // Bills & Utilities
      case 'utility bills':
        return Icons.receipt_long;
      case 'electricity':
        return Icons.electric_bolt;
      case 'water':
        return Icons.water_drop;
      case 'internet':
        return Icons.wifi;
      case 'phone':
      case 'mobile phone':
        return Icons.phone;
      case 'rent':
        return Icons.home;

      // Health & Fitness
      case 'health':
      case 'medical':
        return Icons.medical_services;
      case 'fitness':
      case 'gym':
      case 'sports':
        return Icons.fitness_center;
      case 'pharmacy':
      case 'medicine':
        return Icons.local_pharmacy;

      // Education
      case 'education':
      case 'school':
        return Icons.school;
      case 'books':
        return Icons.menu_book;

      // Income categories
      case 'salary':
        return Icons.payments;
      case 'business':
      case 'investmentincome':
        return Icons.business_center;
      case 'investment':
        return Icons.trending_up;
      case 'gift':
      case 'giftsincome':
        return Icons.card_giftcard;
      case 'bonus':
        return Icons.money;
      case 'side job':
        return Icons.work;

      // Home & Family
      case 'home':
        return Icons.home;
      case 'pets':
        return Icons.pets;
      case 'kids':
      case 'children':
        return Icons.child_care;

      // Other categories
      case 'travel':
        return Icons.flight;
      case 'gifts & donations':
      case 'giftsexpense':
        return Icons.volunteer_activism;
      case 'beauty':
        return Icons.face;
      case 'insurance':
        return Icons.verified_user;
      case 'others':
      case 'otherexpense':
      case 'otherincome':
        return Icons.more_horiz;

      // Default
      default:
        return Icons.category_outlined;
    }
  }

  /// Clear cache (useful when categories change)
  void clearCache() {
    _iconCache.clear();
  }

  /// Preload icons for performance (optional)
  Future<void> preloadIcons() async {
    try {
      // Preload common categories
      final incomeItems = sharedPrefs.getItems('income items');
      for (final item in incomeItems) {
        getIconForCategory(item.text);
      }

      final expenseCategories = sharedPrefs.parentExpenseItemNames;
      for (final parentCategory in expenseCategories) {
        final items = sharedPrefs.getItems(parentCategory);
        for (final item in items) {
          getIconForCategory(item.text);
        }
      }
    } catch (e) {
      // Silent fail for preloading
    }
  }
}