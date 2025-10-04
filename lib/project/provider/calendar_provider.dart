import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../classes/input_model.dart';
import '../database_management/sqflite_services.dart';

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
  
  CalendarState _state = CalendarState.loading;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  
  // Dữ liệu giao dịch
  Map<DateTime, List<InputModel>> _allEvents = {};
  List<InputModel> _selectedDayEvents = [];
  
  String? _errorMessage;
  
  // ============ GETTERS ============
  
  CalendarState get state => _state;
  CalendarFormat get calendarFormat => _calendarFormat;
  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  DateTime? get rangeStart => _rangeStart;
  DateTime? get rangeEnd => _rangeEnd;
  RangeSelectionMode get rangeSelectionMode => _rangeSelectionMode;
  List<InputModel> get selectedDayEvents => _selectedDayEvents;
  String? get errorMessage => _errorMessage;
  
  // ============ CONSTRUCTOR ============
  
  CalendarProvider() {
    _selectedDay = _focusedDay;
    fetchTransactions();
  }
  
  // ============ PHƯƠNG THỨC CHÍNH ============
  
  /// Tải và xử lý tất cả giao dịch từ database
  Future<void> fetchTransactions() async {
    try {
      // Đặt trạng thái loading
      _state = CalendarState.loading;
      notifyListeners();
      
      // Gọi DB MỘT LẦN duy nhất
      final List<InputModel> allTransactions = await DB.inputModelList();
      
      // Kiểm tra nếu không có dữ liệu
      if (allTransactions.isEmpty) {
        _state = CalendarState.empty;
        _allEvents = {};
        _selectedDayEvents = [];
        notifyListeners();
        return;
      }
      
      // Nhóm giao dịch theo ngày
      _allEvents = _groupTransactionsByDate(allTransactions);
      
      // Cập nhật giao dịch cho ngày được chọn
      _updateSelectedDayEvents();
      
      // Cập nhật trạng thái thành công
      _state = CalendarState.loaded;
      
    } catch (e) {
      _state = CalendarState.error;
      _errorMessage = e.toString();
      _allEvents = {};
      _selectedDayEvents = [];
    } finally {
      notifyListeners();
    }
  }
  
  /// Xóa giao dịch và làm mới dữ liệu
  Future<void> deleteTransaction(int id) async {
    try {
      await DB.delete(id);
      await fetchTransactions();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  /// Nhân bản giao dịch và làm mới dữ liệu
  Future<void> duplicateTransaction(InputModel model) async {
    try {
      // Tạo bản sao với id = null để insert mới
      final duplicatedModel = InputModel(
        type: model.type,
        amount: model.amount,
        category: model.category,
        description: model.description,
        date: model.date,
        time: model.time,
      );
      await DB.insert(duplicatedModel);
      await fetchTransactions();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
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
  
  /// Lấy danh sách giao dịch cho một ngày cụ thể
  List<InputModel> getEventsForDay(DateTime day) {
    return _allEvents[_normalizeDate(day)] ?? [];
  }
  
  /// Nhóm giao dịch theo ngày
  Map<DateTime, List<InputModel>> _groupTransactionsByDate(
    List<InputModel> transactions,
  ) {
    final Map<DateTime, List<InputModel>> grouped = {};
    
    for (final transaction in transactions) {
      if (transaction.date == null) continue;
      
      try {
        final DateTime date = DateFormat('dd/MM/yyyy').parse(transaction.date!);
        final DateTime normalizedDate = _normalizeDate(date);
        
        if (grouped[normalizedDate] == null) {
          grouped[normalizedDate] = [];
        }
        grouped[normalizedDate]!.add(transaction);
      } catch (e) {
        // Bỏ qua giao dịch có format ngày không hợp lệ
        continue;
      }
    }
    
    return grouped;
  }
  
  /// Chuẩn hóa ngày về UTC 00:00:00
  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
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
