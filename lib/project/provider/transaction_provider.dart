import 'package:flutter/material.dart';
import '../classes/input_model.dart';
import '../database_management/sqflite_services.dart';
import '../utils/date_format_utils.dart';

/// Global Provider quản lý tất cả transactions
/// Tự động refresh khi có thay đổi trong database
class TransactionProvider with ChangeNotifier {
  // ============ PRIVATE PROPERTIES ============

  List<InputModel> _allTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ============ GETTERS ============

  List<InputModel> get allTransactions => _allTransactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ============ CONSTRUCTOR ============

  TransactionProvider() {
    fetchAllTransactions();
  }

  // ============ PUBLIC METHODS ============

  /// Tải tất cả transactions từ database
  Future<void> fetchAllTransactions() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _allTransactions = await DB.inputModelList();

    } catch (e) {
      _errorMessage = 'Failed to load transactions: $e';
      _allTransactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thêm transaction mới và refresh
  Future<void> addTransaction(InputModel transaction) async {
    try {
      await DB.insert(transaction);
      await fetchAllTransactions(); // Auto refresh
    } catch (e) {
      _errorMessage = 'Failed to add transaction: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Cập nhật transaction và refresh
  Future<void> updateTransaction(InputModel transaction) async {
    try {
      await DB.update(transaction);
      await fetchAllTransactions(); // Auto refresh
    } catch (e) {
      _errorMessage = 'Failed to update transaction: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Xóa transaction và refresh
  Future<void> deleteTransaction(int id) async {
    try {
      await DB.delete(id);
      await fetchAllTransactions(); // Auto refresh
    } catch (e) {
      _errorMessage = 'Failed to delete transaction: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Nhân bản transaction và refresh
  Future<void> duplicateTransaction(InputModel transaction) async {
    try {
      final duplicatedModel = InputModel(
        type: transaction.type,
        amount: transaction.amount,
        category: transaction.category,
        description: transaction.description,
        date: transaction.date,
        time: transaction.time,
      );
      await DB.insert(duplicatedModel);
      await fetchAllTransactions(); // Auto refresh
    } catch (e) {
      _errorMessage = 'Failed to duplicate transaction: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Lấy transactions theo ngày
  List<InputModel> getTransactionsForDate(DateTime date) {
    final dateString = DateFormatUtils.formatInternalDate(date);
    return _allTransactions.where((t) => t.date == dateString).toList();
  }

  /// Lấy transactions theo tháng
  List<InputModel> getTransactionsForMonth(DateTime month) {
    return _allTransactions.where((t) {
      if (t.date == null) return false;
      try {
        // Parse from ISO format (yyyy-MM-dd)
        final transactionDate = DateFormatUtils.parseInternalDate(t.date!);
        return transactionDate.year == month.year && transactionDate.month == month.month;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}