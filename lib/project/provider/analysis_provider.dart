import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../classes/input_model.dart';
import '../classes/constants.dart';
import '../database_management/shared_preferences_services.dart';
import 'transaction_provider.dart';
import '../utils/date_format_utils.dart';
import '../services/category_icon_service.dart';

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

/// Class đại diện cho một dòng chảy tiền trong Sankey
class SankeyFlow {
  final String fromCategory;
  final String toCategory; 
  final double amount;
  final Color? _sourceColor; // Màu nguồn (có thể null)
  final Color? _targetColor; // Màu đích (có thể null)
  final bool isVisible; // Dùng cho focus mode
  final bool isPrimary; // Đánh dấu flow chính

  SankeyFlow({
    required this.fromCategory,
    required this.toCategory,
    required this.amount,
    Color? sourceColor,
    Color? targetColor,
    this.isVisible = true,
    this.isPrimary = false,
  }) : _sourceColor = sourceColor,
       _targetColor = targetColor;

  // Getter với fallback colors
  Color get sourceColor => _sourceColor ?? Colors.green;
  Color get targetColor => _targetColor ?? Colors.red;
}

/// Class chứa thông tin so sánh với kỳ trước
class ComparisonData {
  final double currentAmount;
  final double previousAmount;
  final double changePercentage;
  final bool isPositiveChange; // Thu nhập tăng hoặc chi tiêu giảm = tích cực
  final bool hasValidComparison; // Có dữ liệu kỳ trước không

  ComparisonData({
    required this.currentAmount,
    required this.previousAmount,
    required this.changePercentage,
    required this.isPositiveChange,
    required this.hasValidComparison,
  });

  factory ComparisonData.noComparison(double currentAmount) {
    return ComparisonData(
      currentAmount: currentAmount,
      previousAmount: 0,
      changePercentage: 0,
      isPositiveChange: true,
      hasValidComparison: false,
    );
  }
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
  String _selectedDateOption = sharedPrefs.selectedAnalysisDateOption;
  String _selectedType = 'Expense'; // Mặc định là Expense
  ChartType _selectedChartType = ChartType.sankey; // Mặc định là Sankey

  // Dữ liệu đã được tính toán
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  List<CategorySummary> _expenseSummaries = [];
  List<CategorySummary> _incomeSummaries = [];
  List<TrendData> _incomeTrendData = [];
  List<TrendData> _expenseTrendData = [];

  // Dữ liệu Sankey
  List<SankeyNodeData> _sankeyNodes = [];
  List<SankeyLinkData> _sankeyLinks = [];

  // Focus mode state
  String? _focusedCategory;
  String? _focusedType; // 'Income' or 'Expense'

  // Time comparison data
  List<CategorySummary> _previousIncomeSummaries = [];
  List<CategorySummary> _previousExpenseSummaries = [];
  final Map<String, ComparisonData> _categoryComparisons = {};

  // Sankey flow data for CustomPainter
  final List<SankeyFlow> _sankeyFlows = [];

  // Tương tác với biểu đồ
  int? _selectedIndex;

  String? _errorMessage;

  // Ngưỡng để nhóm các danh mục nhỏ (0% = hiển thị tất cả)
  static const double _groupThreshold = 0.0; // Bỏ nhóm "Others", hiển thị hết

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
  List<TrendData> get incomeTrendData => _incomeTrendData;
  List<TrendData> get expenseTrendData => _expenseTrendData;
  List<SankeyNodeData> get sankeyNodes => _sankeyNodes;
  List<SankeyLinkData> get sankeyLinks => _sankeyLinks;
  int? get selectedIndex => _selectedIndex;
  String? get errorMessage => _errorMessage;
  
  // Focus mode getters
  String? get focusedCategory => _focusedCategory;
  String? get focusedType => _focusedType;

  // Time comparison getters
  Map<String, ComparisonData> get categoryComparisons => _categoryComparisons;
  List<SankeyFlow> get sankeyFlows => _sankeyFlows;

  // TransactionProvider delegate
  List<InputModel> get allTransactions => _transactionProvider.allTransactions;

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
      sharedPrefs.selectedAnalysisDateOption = newOption; // Lưu vào Analysis setting
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

  /// Cập nhật focus mode (category và type)
  void setFocus(String? category, String? type) {
    print('[AnalysisProvider] setFocus START: category=$category, type=$type');
    print('[AnalysisProvider] setFocus BEFORE: _focusedCategory=$_focusedCategory, _focusedType=$_focusedType');
    
    // Nếu click vào cùng category/type đang focus thì bỏ focus
    if (_focusedCategory == category && _focusedType == type) {
      _focusedCategory = null;
      _focusedType = null;
      print('[AnalysisProvider] setFocus TOGGLE OFF: _focusedCategory=$_focusedCategory, _focusedType=$_focusedType');
    } else {
      _focusedCategory = category;
      _focusedType = type;
      print('[AnalysisProvider] setFocus SET: _focusedCategory=$_focusedCategory, _focusedType=$_focusedType');
    }
    
    print('[AnalysisProvider] setFocus AFTER: _focusedCategory=$_focusedCategory, _focusedType=$_focusedType');
    
    // Cập nhật visibility của flows khi focus thay đổi
    _updateSankeyFlowsVisibility();
    print('[AnalysisProvider] setFocus AFTER _updateSankeyFlowsVisibility: _focusedCategory=$_focusedCategory, _focusedType=$_focusedType');
    
    notifyListeners();
    print('[AnalysisProvider] setFocus END: _focusedCategory=$_focusedCategory, _focusedType=$_focusedType');
  }

  /// Đặt focus cho category cụ thể (dành cho Sankey flows)
  void setFocusedCategory(String? category) {
    if (_focusedCategory == category) {
      _focusedCategory = null;
    } else {
      _focusedCategory = category;
    }
    
    _updateSankeyFlowsVisibility();
    notifyListeners();
  }

  /// Tải và xử lý dữ liệu từ TransactionProvider
  Future<void> fetchData() async {
    print('[AnalysisProvider] fetchData START - focusedCategory=$_focusedCategory, focusedType=$_focusedType');
    try {
      // Đặt trạng thái loading
      _state = AnalysisState.loading;
      notifyListeners();

      // BƯỚC 1: Lấy nguồn dữ liệu gốc MỘT LẦN DUY NHẤT
      final allTransactions = _transactionProvider.allTransactions;

      // BƯỚC 2: TÍNH TOÁN CHO SANKEY CHART VÀ CÁC SỐ LIỆU TỔNG QUAN
      // Lọc dữ liệu theo date option người dùng chọn (Today, This week,...)
      final filteredTransactions = _filterTransactionsByDate(allTransactions);
      
      // Lọc dữ liệu kỳ trước để so sánh
      final previousTransactions = _filterTransactionsByPreviousPeriod(allTransactions);

      // Kiểm tra empty state DỰA TRÊN BỘ LỌC NÀY
      if (filteredTransactions.isEmpty) {
        _state = AnalysisState.empty;
        _resetData(); // Reset cả sankey và trend
        print('[AnalysisProvider] fetchData - Empty data, after _resetData: focusedCategory=$_focusedCategory, focusedType=$_focusedType');
        notifyListeners();
        return;
      }

      // Tính toán các số liệu tổng, summary từ dữ liệu đã lọc
      _calculateData(filteredTransactions);

      // BƯỚC 3: TÍNH TOÁN CHO TREND CHART
      // Lọc dữ liệu riêng cho Trend Chart (6 tháng gần nhất)
      final trendTransactions = _filterTransactionsForTrend(allTransactions, 6);
      // Tính toán dữ liệu trend từ bộ dữ liệu riêng này
      _calculateTrendData(trendTransactions, 6);

      // BƯỚC 4: TÍNH TOÁN PHẦN CÒN LẠI CHO SANKEY
      // Tính toán dữ liệu kỳ trước để so sánh
      _calculatePreviousPeriodData(previousTransactions);

      // Tính toán so sánh giữa các kỳ
      _calculateComparisons();

      // Generate Sankey data và flows từ filteredTransactions
      _generateSankeyData(filteredTransactions);
      _generateWaterfallSankeyFlows();

      // BƯỚC 5: HOÀN TẤT
      _state = AnalysisState.loaded;
      print('[AnalysisProvider] fetchData END - focusedCategory=$_focusedCategory, focusedType=$_focusedType');
    } catch (e) {
      _state = AnalysisState.error;
      _errorMessage = e.toString();
      _resetData();
      print('[AnalysisProvider] fetchData ERROR - after _resetData: focusedCategory=$_focusedCategory, focusedType=$_focusedType');
    } finally {
      notifyListeners();
    }
  }

  // ============ PHƯƠNG THỨC PRIVATE ============

  /// Callback khi TransactionProvider có changes
  void _onTransactionsChanged() {
    print('[AnalysisProvider] _onTransactionsChanged - Before fetchData: focusedCategory=$_focusedCategory, focusedType=$_focusedType');
    fetchData();
    print('[AnalysisProvider] _onTransactionsChanged - After fetchData: focusedCategory=$_focusedCategory, focusedType=$_focusedType');
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

  /// Lọc giao dịch chỉ dành cho Trend Chart (X tháng gần nhất)
  List<InputModel> _filterTransactionsForTrend(List<InputModel> transactions, int months) {
    final now = DateTime.now();
    // Lấy ngày đầu tiên của X tháng trước
    final startDate = DateTime(now.year, now.month - (months - 1), 1); 

    return transactions.where((transaction) {
      if (transaction.date == null) return false;
      try {
        final transactionDate = DateFormatUtils.parseInternalDate(transaction.date!);
        // Chỉ lấy các giao dịch từ ngày bắt đầu trở đi
        return !transactionDate.isBefore(startDate);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Lọc giao dịch theo kỳ trước để so sánh
  List<InputModel> _filterTransactionsByPreviousPeriod(List<InputModel> transactions) {
    if (_selectedDateOption == 'All') {
      return []; // Không có kỳ trước cho 'All'
    }

    return transactions.where((transaction) {
      if (transaction.date == null) return false;

      try {
        final DateTime transactionDate =
            DateFormatUtils.parseInternalDate(transaction.date!);

        switch (_selectedDateOption) {
          case 'Today':
            // Ngày hôm qua - so sánh Today vs Yesterday
            final yesterday = DateTime(todayDT.year, todayDT.month, todayDT.day - 1);
            return transactionDate.year == yesterday.year &&
                   transactionDate.month == yesterday.month &&
                   transactionDate.day == yesterday.day;

          case 'This week':
            // Tuần trước - 7 ngày trước
            final startOfLastWeek = startOfThisWeek.subtract(Duration(days: 7));
            final endOfLastWeek = startOfThisWeek.subtract(Duration(days: 1, seconds: 1));
            return transactionDate.isAfter(startOfLastWeek.subtract(Duration(seconds: 1))) &&
                   transactionDate.isBefore(endOfLastWeek.add(Duration(seconds: 1)));

          case 'This month':
            // Tháng trước
            final startOfLastMonth = DateTime(
              startOfThisMonth.month == 1 ? startOfThisMonth.year - 1 : startOfThisMonth.year,
              startOfThisMonth.month == 1 ? 12 : startOfThisMonth.month - 1,
              1
            );
            final endOfLastMonth = startOfThisMonth.subtract(Duration(seconds: 1));
            return transactionDate.isAfter(startOfLastMonth.subtract(Duration(seconds: 1))) &&
                   transactionDate.isBefore(endOfLastMonth.add(Duration(seconds: 1)));

          case 'This quarter':
            // Quý trước
            int lastQuarterMonth = startOfThisQuarter.month - 3;
            int lastQuarterYear = startOfThisQuarter.year;
            if (lastQuarterMonth <= 0) {
              lastQuarterMonth += 12;
              lastQuarterYear -= 1;
            }
            final startOfLastQuarter = DateTime(lastQuarterYear, lastQuarterMonth, 1);
            final endOfLastQuarter = startOfThisQuarter.subtract(Duration(seconds: 1));
            return transactionDate.isAfter(startOfLastQuarter.subtract(Duration(seconds: 1))) &&
                   transactionDate.isBefore(endOfLastQuarter.add(Duration(seconds: 1)));

          case 'This year':
            // Năm trước
            final startOfLastYear = DateTime(startOfThisYear.year - 1, 1, 1);
            final endOfLastYear = startOfThisYear.subtract(Duration(seconds: 1));
            return transactionDate.isAfter(startOfLastYear.subtract(Duration(seconds: 1))) &&
                   transactionDate.isBefore(endOfLastYear.add(Duration(seconds: 1)));

          default:
            return false;
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

  /// Tính toán dữ liệu trend từ một danh sách giao dịch đã được lọc sẵn cho Trend Chart
  void _calculateTrendData(List<InputModel> trendTransactions, int months) {
    // Tách ra Income và Expense transactions
    final incomeTransactions = trendTransactions.where((t) => t.type == 'Income').toList();
    final expenseTransactions = trendTransactions.where((t) => t.type == 'Expense').toList();

    // Hàm helper để nhóm theo tháng
    List<TrendData> groupByType(List<InputModel> filteredTransactions) {
      final Map<String, double> monthlyData = {};
      final now = DateTime.now();

      // Khởi tạo các tháng với giá trị 0
      for (int i = months - 1; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthKey = DateFormatUtils.formatMonthKey(monthDate);
        monthlyData[monthKey] = 0.0;
      }

      // Điền dữ liệu thực tế từ list đã được lọc sẵn
      for (final transaction in filteredTransactions) {
        if (transaction.date == null) continue;
        try {
          final date = DateFormatUtils.parseInternalDate(transaction.date!);
          final monthKey = DateFormatUtils.formatMonthKey(date);
          if (monthlyData.containsKey(monthKey)) {
            monthlyData[monthKey] = monthlyData[monthKey]! + (transaction.amount ?? 0.0);
          }
        } catch (e) {
          continue;
        }
      }

      // Chuyển đổi thành TrendData
      return monthlyData.entries.map((entry) {
        final date = DateFormatUtils.parseMonthKey(entry.key);
        return TrendData(
          month: date,
          totalAmount: entry.value,
          label: DateFormatUtils.formatShortMonth(date),
        );
      }).toList()..sort((a, b) => a.month.compareTo(b.month));
    }

    // Tính toán và lưu trữ
    _incomeTrendData = groupByType(incomeTransactions);
    _expenseTrendData = groupByType(expenseTransactions);
  }

  /// Reset tất cả dữ liệu về 0/empty
  void _resetData() {
    _totalIncome = 0.0;
    _totalExpense = 0.0;
    _expenseSummaries = [];
    _incomeSummaries = [];
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
    return CategoryIconService().getIconForCategory(categoryName);
  }

  /// Tính toán dữ liệu kỳ trước để so sánh
  void _calculatePreviousPeriodData(List<InputModel> transactions) {
    if (transactions.isEmpty) {
      _previousIncomeSummaries = [];
      _previousExpenseSummaries = [];
      return;
    }

    // Tính toán tương tự như _calculateData nhưng lưu vào previous
    final Map<String, double> expenseMap = {};
    final Map<String, double> incomeMap = {};

    for (final transaction in transactions) {
      final amount = transaction.amount ?? 0.0;
      final category = transaction.category ?? 'Unknown';

      if (transaction.type == 'Expense') {
        expenseMap[category] = (expenseMap[category] ?? 0.0) + amount;
      } else if (transaction.type == 'Income') {
        incomeMap[category] = (incomeMap[category] ?? 0.0) + amount;
      }
    }

    _previousExpenseSummaries = _mapToSummaryList(expenseMap, 'Expense');
    _previousIncomeSummaries = _mapToSummaryList(incomeMap, 'Income');
  }

  /// Tính toán so sánh giữa kỳ hiện tại và kỳ trước
  void _calculateComparisons() {
    _categoryComparisons.clear();

    // So sánh expense categories
    for (final currentSummary in _expenseSummaries) {
      final category = currentSummary.category;
      final currentAmount = currentSummary.totalAmount;
      
      final previousSummary = _previousExpenseSummaries
          .firstWhereOrNull((s) => s.category == category);
      final previousAmount = previousSummary?.totalAmount ?? 0.0;

      if (previousAmount > 0) {
        final changePercentage = 
            (currentAmount - previousAmount) / previousAmount * 100;
        final isPositiveChange = changePercentage <= 0; // Chi tiêu giảm = tích cực
        
        _categoryComparisons[category] = ComparisonData(
          currentAmount: currentAmount,
          previousAmount: previousAmount,
          changePercentage: changePercentage.abs(),
          isPositiveChange: isPositiveChange,
          hasValidComparison: true,
        );
      } else {
        _categoryComparisons[category] = ComparisonData.noComparison(currentAmount);
      }
    }

    // So sánh income categories
    for (final currentSummary in _incomeSummaries) {
      final category = currentSummary.category;
      final currentAmount = currentSummary.totalAmount;
      
      final previousSummary = _previousIncomeSummaries
          .firstWhereOrNull((s) => s.category == category);
      final previousAmount = previousSummary?.totalAmount ?? 0.0;

      if (previousAmount > 0) {
        final changePercentage = 
            (currentAmount - previousAmount) / previousAmount * 100;
        final isPositiveChange = changePercentage >= 0; // Thu nhập tăng = tích cực
        
        _categoryComparisons[category] = ComparisonData(
          currentAmount: currentAmount,
          previousAmount: previousAmount,
          changePercentage: changePercentage.abs(),
          isPositiveChange: isPositiveChange,
          hasValidComparison: true,
        );
      } else {
        _categoryComparisons[category] = ComparisonData.noComparison(currentAmount);
      }
    }
  }

  /// TẠO SANKEY FLOWS THEO LOGIC "THÁC NƯỚC" (WATERFALL) - TRỰC QUAN HƠN
  void _generateWaterfallSankeyFlows() {
    _sankeyFlows.clear();

    if (_incomeSummaries.isEmpty) {
      _updateSankeyFlowsVisibility();
      return;
    }

    // Tạo bản sao và sắp xếp: Lớn nhất trước
    final sortedIncomes = List<CategorySummary>.from(_incomeSummaries)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    final sortedExpenses = List<CategorySummary>.from(_expenseSummaries)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    // Dùng Map để theo dõi số tiền còn lại của mỗi nguồn thu/chi
    final remainingIncomes = {for (var item in sortedIncomes) item.category: item.totalAmount};
    final remainingExpenses = {for (var item in sortedExpenses) item.category: item.totalAmount};
    
    final List<SankeyFlow> generatedFlows = [];

    // Chỉ tạo flows Income->Expense nếu có expense categories
    if (_expenseSummaries.isNotEmpty && _totalExpense > 0) {
      // Lặp qua từng KHOẢN CHI
      for (final expense in sortedExpenses) {
        // Lặp qua từng NGUỒN THU để "thanh toán" cho khoản chi này
        for (final income in sortedIncomes) {
          // Nếu khoản chi này đã được thanh toán hết, chuyển sang khoản chi tiếp theo
          if (remainingExpenses[expense.category]! <= 0.01) {
            break; 
          }
          // Nếu nguồn thu này đã cạn, bỏ qua
        if (remainingIncomes[income.category]! <= 0.01) {
          continue; 
        }

        // Xác định số tiền có thể chảy từ nguồn thu hiện tại đến khoản chi hiện tại
        final flowAmount = [
          remainingIncomes[income.category]!,
          remainingExpenses[expense.category]!,
        ].reduce((a, b) => a < b ? a : b); // Lấy giá trị nhỏ hơn

        if (flowAmount > 0.01) {
          generatedFlows.add(SankeyFlow(
            fromCategory: income.category,
            toCategory: expense.category,
            amount: flowAmount,
            sourceColor: income.color,
            targetColor: expense.color,
            isPrimary: false, // Sẽ cập nhật sau
          ));

          // Cập nhật số tiền còn lại
          remainingIncomes[income.category] = remainingIncomes[income.category]! - flowAmount;
          remainingExpenses[expense.category] = remainingExpenses[expense.category]! - flowAmount;
        }
      }
    }
    } // Đóng block "if có expense categories"
    
    // Thêm flows cho số dư (nếu còn tiền thừa từ các nguồn thu)
    for (final income in sortedIncomes) {
      final remaining = remainingIncomes[income.category]!;
      if (remaining > 0.01) {
        generatedFlows.add(SankeyFlow(
          fromCategory: income.category,
          toCategory: 'Balance', // Dùng key chuẩn 'Balance' 
          amount: remaining,
          sourceColor: income.color,
          targetColor: _totalIncome >= _totalExpense ? green : red, // Green nếu dương, red nếu âm
          isPrimary: false,
        ));
      }
    }
    
    // Thêm tất cả flows với độ dày đồng nhất (bỏ phân biệt primary/secondary)
    if (generatedFlows.isNotEmpty) {
      for (final flow in generatedFlows) {
        _sankeyFlows.add(SankeyFlow(
            fromCategory: flow.fromCategory,
            toCategory: flow.toCategory,
            amount: flow.amount,
            sourceColor: flow.sourceColor,
            targetColor: flow.targetColor,
            isPrimary: true, // Tất cả flows đều là primary để có độ dày đồng nhất
            isVisible: true, // Sẽ được cập nhật bởi _updateSankeyFlowsVisibility
        ));
      }
    }
    
    _updateSankeyFlowsVisibility();
  }

  /// Cập nhật Sankey flows khi focus mode thay đổi
  void _updateSankeyFlowsVisibility() {
    for (int i = 0; i < _sankeyFlows.length; i++) {
      final flow = _sankeyFlows[i];
      _sankeyFlows[i] = SankeyFlow(
        fromCategory: flow.fromCategory,
        toCategory: flow.toCategory,
        amount: flow.amount,
        sourceColor: flow._sourceColor,  // Sử dụng private field
        targetColor: flow._targetColor,  // Sử dụng private field
        isPrimary: flow.isPrimary,      // Sử dụng private field
        isVisible: _shouldShowFlow(flow.fromCategory, flow.toCategory),
      );
    }
  }

  /// Kiểm tra có nên hiển thị flow này không (cho focus mode)
  bool _shouldShowFlow(String fromCategory, String toCategory) {
    if (_focusedCategory == null) return true;
    
    // Nếu đang focus vào một category, chỉ hiển thị flows liên quan
    return fromCategory == _focusedCategory || toCategory == _focusedCategory;
  }
}
