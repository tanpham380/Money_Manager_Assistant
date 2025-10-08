import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:icofont_flutter/icofont_flutter.dart';
import '../classes/input_model.dart';
import '../classes/constants.dart';
import 'transaction_provider.dart';
import '../utils/date_format_utils.dart';

/// Trạng thái của màn hình phân tích
enum AnalysisState {
  initial, // Khởi tạo ban đầu
  loading, // Đang tải dữ liệu
  loaded, // Đã tải xong dữ liệu
  empty, // Không có dữ liệu
  error // Có lỗi xảy ra
}

/// Loại biểu đồ hiển thị
enum ChartType {
  // bar, // Biểu đồ cột
  line, // Biểu đồ đường (trend)
  sankey // Sơ đồ Sankey
}

/// Class chứa thông tin tổng hợp cho mỗi danh mục
class CategorySummary {
  final String category;
  final double totalAmount;
  final IconData icon;
  final Color color;

  CategorySummary({
    required this.category,
    required this.totalAmount,
    required this.icon,
    required this.color,
  });
}

/// Class chứa dữ liệu xu hướng theo thời gian
class TrendData {
  final DateTime month;
  final double totalAmount;
  final String label;

  TrendData({
    required this.month,
    required this.totalAmount,
    required this.label,
  });
}

/// Class chứa dữ liệu cho Sankey diagram
/// Note: These are simplified data classes, not the Syncfusion Sankey classes
class SankeyNodeData {
  final String id;
  final String label;
  final Color color;

  SankeyNodeData({
    required this.id,
    required this.label,
    required this.color,
  });
}

class SankeyLinkData {
  final String source;
  final String target;
  final double value;
  final Color color;

  SankeyLinkData({
    required this.source,
    required this.target,
    required this.value,
    required this.color,
  });
}

/// Provider quản lý trạng thái và logic cho màn hình Analysis
class AnalysisProvider with ChangeNotifier {
  // ============ THUỘC TÍNH PRIVATE ============

  final TransactionProvider _transactionProvider;
  AnalysisState _state = AnalysisState.initial;
  String _selectedDateOption = 'All';
  String _selectedType = 'Expense'; // Mặc định là Expense
  ChartType _selectedChartType = ChartType.sankey; // Mặc định là Sankey thay vì Bar

  // Dữ liệu đã được tính toán
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  List<CategorySummary> _expenseSummaries = [];
  List<CategorySummary> _incomeSummaries = [];
  List<TrendData> _trendData = [];
  List<TrendData> _incomeTrendData = [];
  List<TrendData> _expenseTrendData = [];

  // Dữ liệu Sankey
  List<SankeyNodeData> _sankeyNodes = [];
  List<SankeyLinkData> _sankeyLinks = [];

  // Tương tác với biểu đồ
  int? _selectedIndex;

  String? _errorMessage;

  // Ngưỡng để nhóm các danh mục nhỏ (5% của tổng)
  static const double _groupThreshold = 0.05;

  // ============ GETTERS ============

  AnalysisState get state => _state;
  String get selectedDateOption => _selectedDateOption;
  String get selectedType => _selectedType;
  ChartType get selectedChartType => _selectedChartType;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _totalIncome - _totalExpense;
  double get total => _totalIncome + _totalExpense;
  List<CategorySummary> get expenseSummaries => _expenseSummaries;
  List<CategorySummary> get incomeSummaries => _incomeSummaries;
  List<TrendData> get trendData => _trendData;
  List<TrendData> get incomeTrendData => _incomeTrendData;
  List<TrendData> get expenseTrendData => _expenseTrendData;
  List<SankeyNodeData> get sankeyNodes => _sankeyNodes;
  List<SankeyLinkData> get sankeyLinks => _sankeyLinks;
  int? get selectedIndex => _selectedIndex;
  String? get errorMessage => _errorMessage;

  /// Lấy category summary được chọn
  CategorySummary? getSelectedSummary(String type) {
    if (_selectedIndex == null) return null;
    final summaries = type == 'Income' ? _incomeSummaries : _expenseSummaries;
    if (_selectedIndex! >= 0 && _selectedIndex! < summaries.length) {
      return summaries[_selectedIndex!];
    }
    return null;
  }

  /// Lấy khoảng thời gian dưới dạng DateTime từ selectedDateOption
  Map<String, DateTime?> getDateRange() {
    final now = DateTime.now();

    switch (_selectedDateOption) {
      case 'Today':
        return {
          'start': DateTime(now.year, now.month, now.day),
          'end': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };

      case 'This week':
        final start = startOfThisWeek;
        final end =
            start.add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return {'start': start, 'end': end};

      case 'This month':
        final start = startOfThisMonth;
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return {'start': start, 'end': end};

      case 'This quarter':
        final start = startOfThisQuarter;
        final end = DateTime(start.year, start.month + 3, 0, 23, 59, 59);
        return {'start': start, 'end': end};

      case 'This year':
        final start = startOfThisYear;
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return {'start': start, 'end': end};

      case 'All':
      default:
        return {'start': null, 'end': null}; // Không giới hạn thời gian
    }
  }

  // ============ PHƯƠNG THỨC PUBLIC ============

  // ============ CONSTRUCTOR ============

  /// Constructor - Tự động fetch data khi khởi tạo
  AnalysisProvider(this._transactionProvider) {
    // Listen to TransactionProvider changes
    _transactionProvider.addListener(_onTransactionsChanged);
    fetchData();
  }

  // ============ CLEANUP ============

  @override
  void dispose() {
    _transactionProvider.removeListener(_onTransactionsChanged);
    super.dispose();
  }

  /// Cập nhật lựa chọn khoảng thời gian và tải lại dữ liệu
  void updateDateOption(String newOption) {
    if (_selectedDateOption != newOption) {
      _selectedDateOption = newOption;
      _selectedIndex = null; // Reset selection
      fetchData();
    }
  }

  /// Cập nhật loại biểu đồ hiển thị
  void updateChartType(ChartType newType) {
    if (_selectedChartType != newType) {
      _selectedChartType = newType;
      _selectedIndex = null; // Reset selection
      notifyListeners();
    }
  }

  /// Cập nhật loại giao dịch (Expense/Income)
  void updateSelectedType(String newType) {
    if (_selectedType != newType) {
      _selectedType = newType;
      _selectedIndex = null; // Reset selection
      notifyListeners();
    }
  }

  /// Cập nhật index được chọn trên biểu đồ
  void updateSelectedIndex(int? index) {
    _selectedIndex = index;
    notifyListeners();
  }

  /// Tải và xử lý dữ liệu từ TransactionProvider
  Future<void> fetchData() async {
    try {
      // Đặt trạng thái loading
      _state = AnalysisState.loading;
      notifyListeners();

      // Lấy tất cả dữ liệu từ TransactionProvider thay vì DB
      final allTransactions = _transactionProvider.allTransactions;

      // Lọc dữ liệu theo khoảng thời gian đã chọn
      final filteredTransactions = _filterTransactionsByDate(allTransactions);

      // Kiểm tra nếu không có dữ liệu
      if (filteredTransactions.isEmpty) {
        _state = AnalysisState.empty;
        _resetData();
        notifyListeners();
        return;
      }

      // Tính toán dữ liệu - chỉ lặp QUA DANH SÁCH MỘT LẦN
      _calculateData(filteredTransactions);

      // Generate Sankey data
      _generateSankeyData(filteredTransactions);

      // Cập nhật trạng thái thành công
      _state = AnalysisState.loaded;
    } catch (e) {
      _state = AnalysisState.error;
      _errorMessage = e.toString();
      _resetData();
    } finally {
      notifyListeners();
    }
  }

  // ============ PHƯƠNG THỨC PRIVATE ============

  /// Callback khi TransactionProvider có changes
  void _onTransactionsChanged() {
    fetchData();
  }

  /// Lọc giao dịch theo khoảng thời gian đã chọn
  List<InputModel> _filterTransactionsByDate(List<InputModel> transactions) {
    if (_selectedDateOption == 'All') {
      return transactions;
    }

    return transactions.where((transaction) {
      if (transaction.date == null) return false;

      try {
        // Parse from ISO format (yyyy-MM-dd)
        final DateTime transactionDate =
            DateFormatUtils.parseInternalDate(transaction.date!);

        switch (_selectedDateOption) {
          case 'Today':
            return transactionDate
                    .isAfter(todayDT.subtract(Duration(days: 1))) &&
                transactionDate.isBefore(todayDT.add(Duration(days: 1)));

          case 'This week':
            return transactionDate
                    .isAfter(startOfThisWeek.subtract(Duration(days: 1))) &&
                transactionDate
                    .isBefore(startOfThisWeek.add(Duration(days: 7)));

          case 'This month':
            return transactionDate
                    .isAfter(startOfThisMonth.subtract(Duration(days: 1))) &&
                transactionDate
                    .isBefore(DateTime(todayDT.year, todayDT.month + 1, 1));

          case 'This quarter':
            return transactionDate
                    .isAfter(startOfThisQuarter.subtract(Duration(days: 1))) &&
                transactionDate.isBefore(DateTime(
                    startOfThisQuarter.year, startOfThisQuarter.month + 3, 1));

          case 'This year':
            return transactionDate
                    .isAfter(startOfThisYear.subtract(Duration(days: 1))) &&
                transactionDate.isBefore(DateTime(todayDT.year + 1, 1, 1));

          default:
            return true;
        }
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Tính toán tất cả dữ liệu cần thiết
  void _calculateData(List<InputModel> transactions) {
    // Reset về 0
    _totalIncome = 0.0;
    _totalExpense = 0.0;

    // Maps để nhóm các giao dịch theo category
    final Map<String, double> expenseMap = {};
    final Map<String, double> incomeMap = {};

    // Chỉ lặp qua danh sách MỘT LẦN duy nhất
    for (final transaction in transactions) {
      final amount = transaction.amount ?? 0.0;
      final category = transaction.category ?? 'Unknown';

      if (transaction.type == 'Expense') {
        _totalExpense += amount;
        expenseMap[category] = (expenseMap[category] ?? 0.0) + amount;
      } else if (transaction.type == 'Income') {
        _totalIncome += amount;
        incomeMap[category] = (incomeMap[category] ?? 0.0) + amount;
      }
    }

    // Chuyển đổi maps thành lists với màu sắc
    _expenseSummaries = _mapToSummaryList(expenseMap, 'Expense');
    _incomeSummaries = _mapToSummaryList(incomeMap, 'Income');
  }

  /// Chuyển đổi Map thành List CategorySummary với màu sắc và icon
  /// Có nhóm các danh mục nhỏ vào "Khác"
  List<CategorySummary> _mapToSummaryList(
    Map<String, double> categoryMap,
    String type,
  ) {
    if (categoryMap.isEmpty) return [];

    // Tính tổng
    final total =
        categoryMap.values.fold<double>(0.0, (sum, value) => sum + value);

    // Sắp xếp theo giá trị giảm dần
    final sortedEntries = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Tách danh mục lớn và nhỏ
    final List<MapEntry<String, double>> majorCategories = [];
    double othersAmount = 0.0;

    for (final entry in sortedEntries) {
      final percentage = entry.value / total;
      if (percentage >= _groupThreshold) {
        majorCategories.add(entry);
      } else {
        othersAmount += entry.value;
      }
    }

    // Chuyển đổi thành CategorySummary với màu sắc
    final List<CategorySummary> result =
        majorCategories.mapIndexed((index, entry) {
      final color = chartPieColors[index % chartPieColors.length];
      final icon = _getIconForCategory(entry.key);

      return CategorySummary(
        category: entry.key,
        totalAmount: entry.value,
        icon: icon,
        color: color,
      );
    }).toList();

    // Thêm "Khác" nếu có
    if (othersAmount > 0) {
      result.add(CategorySummary(
        category: 'Others',
        totalAmount: othersAmount,
        icon: Icons.more_horiz,
        color: chartPieColors[result.length % chartPieColors.length],
      ));
    }

    return result;
  }

  /// Lấy dữ liệu xu hướng theo thời gian cho một type cụ thể
  Future<void> fetchTrendData(String type, int months) async {
    try {
      // Lấy tất cả giao dịch từ TransactionProvider thay vì DB
      final allTransactions = _transactionProvider.allTransactions;

      // Lọc theo loại
      final transactions =
          allTransactions.where((t) => t.type == type).toList();

      // Nhóm theo tháng
      final Map<String, double> monthlyData = {};
      final now = DateTime.now();

      // Khởi tạo tất cả các tháng với giá trị 0
      for (int i = months - 1; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthKey = DateFormatUtils.formatMonthKey(monthDate);
        monthlyData[monthKey] = 0.0;
      }

      // Điền dữ liệu thực tế
      for (final transaction in transactions) {
        if (transaction.date == null) continue;

        try {
          // Parse from ISO format (yyyy-MM-dd)
          final date = DateFormatUtils.parseInternalDate(transaction.date!);

          // Chỉ lấy dữ liệu trong X tháng gần nhất
          final monthsAgo = DateTime(now.year, now.month - months, 1);
          if (date.isBefore(monthsAgo)) continue;

          final monthKey = DateFormatUtils.formatMonthKey(date);
          if (monthlyData.containsKey(monthKey)) {
            monthlyData[monthKey] =
                monthlyData[monthKey]! + (transaction.amount ?? 0.0);
          }
        } catch (e) {
          continue;
        }
      }

      // Chuyển đổi thành TrendData với tất cả các tháng
      final trendData = monthlyData.entries.map((entry) {
        final date = DateFormatUtils.parseMonthKey(entry.key);
        return TrendData(
          month: date,
          totalAmount: entry.value,
          label: DateFormatUtils.formatShortMonth(date),
        );
      }).toList()
        ..sort((a, b) => a.month.compareTo(b.month));

      // Lưu vào field tương ứng
      if (type == 'Income') {
        _incomeTrendData = trendData;
      } else if (type == 'Expense') {
        _expenseTrendData = trendData;
      }

      // Cũng cập nhật _trendData cho compatibility
      _trendData = trendData;

      notifyListeners();
    } catch (e) {
      // Xử lý lỗi nếu cần
      if (type == 'Income') {
        _incomeTrendData = [];
      } else if (type == 'Expense') {
        _expenseTrendData = [];
      }
      _trendData = [];
    }
  }

  /// Reset tất cả dữ liệu về 0/empty
  void _resetData() {
    _totalIncome = 0.0;
    _totalExpense = 0.0;
    _expenseSummaries = [];
    _incomeSummaries = [];
    _trendData = [];
    _incomeTrendData = [];
    _expenseTrendData = [];
    _sankeyNodes = [];
    _sankeyLinks = [];
  }

  /// Generate Sankey diagram data from transactions
  /// Creates flow: Income Categories -> Total Income -> Total Expense -> Expense Categories
  void _generateSankeyData(List<InputModel> transactions) {
    try {
      _sankeyNodes = [];
      _sankeyLinks = [];

      if (transactions.isEmpty) return;

      // Prepare data structures
      final Map<String, double> incomeByCategory = {};
      final Map<String, double> expenseByCategory = {};
      double totalIncome = 0.0;
      double totalExpense = 0.0;

      // Collect data
      for (final transaction in transactions) {
        final amount = transaction.amount ?? 0.0;
        final category = transaction.category ?? 'Unknown';

        if (transaction.type == 'Income') {
          totalIncome += amount;
          incomeByCategory[category] =
              (incomeByCategory[category] ?? 0.0) + amount;
        } else if (transaction.type == 'Expense') {
          totalExpense += amount;
          expenseByCategory[category] =
              (expenseByCategory[category] ?? 0.0) + amount;
        }
      }

      if (totalIncome == 0 && totalExpense == 0) return;

      // Create nodes
      final List<SankeyNodeData> nodes = [];

      // Add income category nodes (left side)
      int colorIndex = 0;
      for (final entry in incomeByCategory.entries) {
        nodes.add(SankeyNodeData(
          id: 'income_${entry.key}',
          label: entry.key,
          color: chartPieColors[colorIndex % chartPieColors.length]
              .withValues(alpha: 0.7),
        ));
        colorIndex++;
      }

      // Add central nodes
      nodes.add(SankeyNodeData(
        id: 'total_income',
        label: 'Total Income',
        color: green.withValues(alpha: 0.8),
      ));

      nodes.add(SankeyNodeData(
        id: 'total_expense',
        label: 'Total Expense',
        color: red.withValues(alpha: 0.8),
      ));

      // Add expense category nodes (right side)
      colorIndex = 0;
      for (final entry in expenseByCategory.entries) {
        nodes.add(SankeyNodeData(
          id: 'expense_${entry.key}',
          label: entry.key,
          color: chartPieColors[colorIndex % chartPieColors.length]
              .withValues(alpha: 0.7),
        ));
        colorIndex++;
      }

      // Create links
      final List<SankeyLinkData> links = [];

      // Links: Income Categories -> Total Income
      colorIndex = 0;
      for (final entry in incomeByCategory.entries) {
        links.add(SankeyLinkData(
          source: 'income_${entry.key}',
          target: 'total_income',
          value: entry.value,
          color: chartPieColors[colorIndex % chartPieColors.length]
              .withValues(alpha: 0.5),
        ));
        colorIndex++;
      }

      // Link: Total Income -> Total Expense (the balance/flow)
      if (totalIncome > 0 && totalExpense > 0) {
        links.add(SankeyLinkData(
          source: 'total_income',
          target: 'total_expense',
          value: totalExpense > totalIncome ? totalIncome : totalExpense,
          color: Colors.blue.withValues(alpha: 0.4),
        ));
      }

      // Links: Total Expense -> Expense Categories
      colorIndex = 0;
      for (final entry in expenseByCategory.entries) {
        links.add(SankeyLinkData(
          source: 'total_expense',
          target: 'expense_${entry.key}',
          value: entry.value,
          color: chartPieColors[colorIndex % chartPieColors.length]
              .withValues(alpha: 0.5),
        ));
        colorIndex++;
      }

      _sankeyNodes = nodes;
      _sankeyLinks = links;
    } catch (e) {
      // Handle errors gracefully
      _sankeyNodes = [];
      _sankeyLinks = [];
    }
  }

  /// Lấy icon tương ứng cho mỗi category name
  IconData _getIconForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      // Food & Dining
      case 'food':
        return MdiIcons.food;
      case 'breakfast':
        return Icons.free_breakfast_outlined;
      case 'lunch':
        return Icons.restaurant_outlined;
      case 'dinner':
        return Icons.dinner_dining_outlined;
      case 'coffee':
        return Icons.coffee_outlined;
      case 'restaurant':
        return Icons.restaurant;

      // Transportation
      case 'transportation':
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
      case 'electricity':
        return Icons.electric_bolt;
      case 'water':
        return Icons.water_drop;
      case 'internet':
        return IcoFontIcons.globe;
      case 'phone':
        return Icons.phone;
      case 'rent':
        return Icons.home;

      // Health & Fitness
      case 'health':
      case 'medical':
        return Icons.medical_services;
      case 'fitness':
      case 'gym':
        return Icons.fitness_center;
      case 'pharmacy':
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
        return Icons.business_center;
      case 'investment':
        return Icons.trending_up;
      case 'gift':
        return Icons.card_giftcard;
      case 'bonus':
        return Icons.money;

      // Other
      case 'travel':
        return Icons.flight;
      case 'gift & donation':
        return Icons.volunteer_activism;
      case 'pets':
        return Icons.pets;
      case 'beauty':
        return Icons.face;
      case 'insurance':
        return Icons.verified_user;

      // Default
      default:
        return Icons.category_outlined;
    }
  }
}
