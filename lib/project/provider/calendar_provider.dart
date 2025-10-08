import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../classes/input_model.dart';
import 'transaction_provider.dart';
import 'navigation_provider.dart';

/// Trạng thái của màn hình Calendar
enum CalendarState {
  loading,    // Đang tải dữ liệu
  loaded,     // Đã tải xong dữ liệu
  empty,      // Không có dữ liệu
  error       // Có lỗi xảy ra
}

/// Provider quản lý trạng thái và logic cho màn hình Calendar
class CalendarProvider with ChangeNotifier {
  // ============ THUỘC TÍNH PRIVATE ============
  
  final TransactionProvider _transactionProvider;
  final NavigationProvider _navigationProvider;
  CalendarFormat _calendarFormat = CalendarFormat.week; // Đổi mặc định từ month thành week
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  
  // Dữ liệu giao dịch (computed từ TransactionProvider)
  List<InputModel> _selectedDayEvents = [];
  
  // ============ GETTERS ============
  
  CalendarFormat get calendarFormat => _calendarFormat;
  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  DateTime? get rangeStart => _rangeStart;
  DateTime? get rangeEnd => _rangeEnd;
  RangeSelectionMode get rangeSelectionMode => _rangeSelectionMode;
  List<InputModel> get selectedDayEvents => _selectedDayEvents;
  
  // Delegate từ TransactionProvider
  List<InputModel> get allTransactions => _transactionProvider.allTransactions;
  bool get isLoading => _transactionProvider.isLoading;
  String? get errorMessage => _transactionProvider.errorMessage;
  
  // Computed state
  CalendarState get state {
    if (_transactionProvider.isLoading) return CalendarState.loading;
    if (_transactionProvider.errorMessage != null) return CalendarState.error;
    if (_transactionProvider.allTransactions.isEmpty) return CalendarState.empty;
    return CalendarState.loaded;
  }
  
  // ============ CONSTRUCTOR ============
  
  CalendarProvider(this._transactionProvider, this._navigationProvider) {
    // Nếu có filter với khoảng thời gian, focus vào ngày bắt đầu
    if (_navigationProvider.filterStartDate != null) {
      _focusedDay = _navigationProvider.filterStartDate!;
      _selectedDay = _navigationProvider.filterStartDate!;
    } else {
      // Không chọn ngày mặc định, chỉ focus vào ngày hiện tại
      _selectedDay = null; // Không chọn ngày nào mặc định
    }
    
    _updateSelectedDayEvents();
    
    // Listen to TransactionProvider changes
    _transactionProvider.addListener(_onTransactionsChanged);
    // Listen to NavigationProvider changes (for filter updates)
    _navigationProvider.addListener(_onFilterChanged);
  }
  
  // ============ CLEANUP ============
  
  @override
  void dispose() {
    _transactionProvider.removeListener(_onTransactionsChanged);
    _navigationProvider.removeListener(_onFilterChanged);
    super.dispose();
  }
  
  // ============ PRIVATE METHODS ============
  
  /// Callback khi TransactionProvider có changes
  void _onTransactionsChanged() {
    _updateSelectedDayEvents();
    notifyListeners();
  }
  
  /// Callback khi NavigationProvider filter có changes
  void _onFilterChanged() {
    _updateSelectedDayEvents();
    notifyListeners();
  }
  
  // ============ PHƯƠNG THỨC CHÍNH ============
  
  /// Refresh data từ TransactionProvider
  Future<void> refreshData() async {
    await _transactionProvider.fetchAllTransactions();
  }
  
  /// Xóa giao dịch (delegate cho TransactionProvider)
  Future<void> deleteTransaction(int id) async {
    await _transactionProvider.deleteTransaction(id);
  }
  
  /// Nhân bản giao dịch (delegate cho TransactionProvider)
  Future<void> duplicateTransaction(InputModel model) async {
    await _transactionProvider.duplicateTransaction(model);
  }
  
  // ============ XỬ LÝ SỰ KIỆN CALENDAR ============
  
  /// Xử lý khi người dùng chọn một ngày
  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _rangeStart = null;
      _rangeEnd = null;
      _rangeSelectionMode = RangeSelectionMode.toggledOff;
      _updateSelectedDayEvents();
      notifyListeners();
    }
  }
  
  /// Bỏ chọn ngày để hiển thị lại danh sách theo calendar format
  void clearSelection() {
    _selectedDay = null;
    _rangeStart = null;
    _rangeEnd = null;
    _rangeSelectionMode = RangeSelectionMode.toggledOff;
    _selectedDayEvents = [];
    notifyListeners();
  }
  
  /// Xử lý khi người dùng chọn một khoảng ngày
  void onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    _selectedDay = null;
    _focusedDay = focusedDay;
    _rangeStart = start;
    _rangeEnd = end;
    _rangeSelectionMode = RangeSelectionMode.toggledOn;
    
    if (start != null && end != null) {
      _selectedDayEvents = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedDayEvents = getEventsForDay(start);
    } else if (end != null) {
      _selectedDayEvents = getEventsForDay(end);
    }
    
    notifyListeners();
  }
  
  /// Xử lý khi thay đổi định dạng lịch
  void onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      _calendarFormat = format;
      notifyListeners();
    }
  }
  
  /// Xử lý khi chuyển trang (tháng)
  void onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    notifyListeners();
  }
  
  // ============ PHƯƠNG THỨC HELPER ============
  
  /// Lấy danh sách giao dịch cho một ngày cụ thể với filter
  List<InputModel> getEventsForDay(DateTime day) {
    // Kiểm tra nếu ngày nằm ngoài khoảng thời gian filter
    if (_navigationProvider.filterStartDate != null) {
      final normalizedFilterStart = DateTime(
        _navigationProvider.filterStartDate!.year,
        _navigationProvider.filterStartDate!.month,
        _navigationProvider.filterStartDate!.day,
      );
      final normalizedDay = DateTime(day.year, day.month, day.day);
      
      if (normalizedDay.isBefore(normalizedFilterStart)) {
        return [];
      }
    }
    
    if (_navigationProvider.filterEndDate != null) {
      final normalizedFilterEnd = DateTime(
        _navigationProvider.filterEndDate!.year,
        _navigationProvider.filterEndDate!.month,
        _navigationProvider.filterEndDate!.day,
      );
      final normalizedDay = DateTime(day.year, day.month, day.day);
      
      if (normalizedDay.isAfter(normalizedFilterEnd)) {
        return [];
      }
    }
    
    var transactions = _transactionProvider.getTransactionsForDate(day);
    
    // Áp dụng filter theo type và category từ NavigationProvider
    if (_navigationProvider.hasActiveFilter) {
      transactions = transactions.where((transaction) {
        // Filter theo type
        if (_navigationProvider.filterType != null && 
            transaction.type != _navigationProvider.filterType) {
          return false;
        }
        
        // Filter theo category
        if (_navigationProvider.filterCategory != null && 
            transaction.category != _navigationProvider.filterCategory) {
          return false;
        }
        
        return true;
      }).toList();
    }
    
    return transactions;
  }
  
  /// Cập nhật danh sách giao dịch cho ngày được chọn
  void _updateSelectedDayEvents() {
    if (_selectedDay != null) {
      _selectedDayEvents = getEventsForDay(_selectedDay!);
    } else {
      _selectedDayEvents = [];
    }
  }
  
  /// Lấy tất cả giao dịch trong một khoảng thời gian
  List<InputModel> _getEventsForRange(DateTime start, DateTime end) {
    final List<InputModel> events = [];
    final days = _daysInRange(start, end);
    
    for (final day in days) {
      events.addAll(getEventsForDay(day));
    }
    
    return events;
  }
  
  /// Tạo danh sách các ngày trong khoảng thời gian
  List<DateTime> _daysInRange(DateTime first, DateTime last) {
    final dayCount = last.difference(first).inDays + 1;
    return List.generate(
      dayCount,
      (index) => DateTime.utc(first.year, first.month, first.day + index),
    );
  }
  
  /// Tính hash code cho DateTime (dùng cho LinkedHashMap)
  int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }
}
