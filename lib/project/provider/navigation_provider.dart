import 'package:flutter/material.dart';

/// Provider quản lý navigation giữa các tabs và filter
class NavigationProvider with ChangeNotifier {
  int _currentTabIndex = 0;
  
  // Filter cho Calendar
  String? _filterType;
  String? _filterCategory;
  IconData? _filterIcon;
  Color? _filterColor;
  
  // Bộ lọc khoảng thời gian
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  
  // Getters
  int get currentTabIndex => _currentTabIndex;
  String? get filterType => _filterType;
  String? get filterCategory => _filterCategory;
  IconData? get filterIcon => _filterIcon;
  Color? get filterColor => _filterColor;
  
  // Getters cho khoảng thời gian
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  
  /// Chuyển sang tab chỉ định
  void changeTab(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }
  
  /// Chuyển sang Calendar với filter và khoảng thời gian
  void navigateToCalendarWithFilter({
    required String type,
    required String category,
    IconData? icon,
    Color? color,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _filterType = type;
    _filterCategory = category;
    _filterIcon = icon;
    _filterColor = color;
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    _currentTabIndex = 2; // Index của Calendar tab
    notifyListeners();
  }
  
  /// Clear filter
  void clearFilter() {
    _filterType = null;
    _filterCategory = null;
    _filterIcon = null;
    _filterColor = null;
    _filterStartDate = null;
    _filterEndDate = null;
    notifyListeners();
  }
  
  /// Check nếu có filter active
  bool get hasActiveFilter => _filterCategory != null;
}
