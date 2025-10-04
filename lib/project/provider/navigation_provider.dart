import 'package:flutter/material.dart';

/// Provider quản lý navigation giữa các tabs và filter
class NavigationProvider with ChangeNotifier {
  int _currentTabIndex = 0;
  
  // Filter cho Calendar
  String? _filterType;
  String? _filterCategory;
  IconData? _filterIcon;
  Color? _filterColor;
  
  // Getters
  int get currentTabIndex => _currentTabIndex;
  String? get filterType => _filterType;
  String? get filterCategory => _filterCategory;
  IconData? get filterIcon => _filterIcon;
  Color? get filterColor => _filterColor;
  
  /// Chuyển sang tab chỉ định
  void changeTab(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }
  
  /// Chuyển sang Calendar với filter
  void navigateToCalendarWithFilter({
    required String type,
    required String category,
    IconData? icon,
    Color? color,
  }) {
    _filterType = type;
    _filterCategory = category;
    _filterIcon = icon;
    _filterColor = color;
    _currentTabIndex = 2; // Index của Calendar tab
    notifyListeners();
  }
  
  /// Clear filter
  void clearFilter() {
    _filterType = null;
    _filterCategory = null;
    _filterIcon = null;
    _filterColor = null;
    notifyListeners();
  }
  
  /// Check nếu có filter active
  bool get hasActiveFilter => _filterCategory != null;
}
