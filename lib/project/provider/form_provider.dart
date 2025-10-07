import 'package:flutter/material.dart';
import '../classes/input_model.dart';
import '../classes/category_item.dart';
import '../classes/constants.dart';
import '../services/alert_service.dart';
import '../localization/methods.dart';
import '../utils/amount_formatter.dart';
import '../utils/date_format_utils.dart';
import 'transaction_provider.dart';

class FormProvider with ChangeNotifier {
  late InputModel _model;
  late TextEditingController amountController;
  late TextEditingController descriptionController;
  late FocusNode amountFocusNode;
  late FocusNode descriptionFocusNode;
  late CategoryItem _selectedCategory;
  late TimeOfDay _currentTime;
  final TransactionProvider _transactionProvider;

  InputModel get model => _model;
  CategoryItem get selectedCategory => _selectedCategory;
  TimeOfDay get currentTime => _currentTime;

  // Constructor để khởi tạo state cho form
  FormProvider({
    InputModel? input, 
    String? type, 
    IconData? categoryIcon,
    required TransactionProvider transactionProvider,
  }) : _transactionProvider = transactionProvider {
    // Khởi tạo các controller và focus node
    amountFocusNode = FocusNode();
    descriptionFocusNode = FocusNode();

    if (input != null) {
      // Trường hợp chỉnh sửa (Edit)
      _model = input;
      _selectedCategory = categoryItem(categoryIcon!, _model.category!);
      amountController =
          TextEditingController(text: format(_model.amount ?? 0));
      descriptionController =
          TextEditingController(text: _model.description ?? '');

      // Parse time từ string nếu có
      if (_model.time != null) {
        _currentTime = _parseTimeOfDay(_model.time!);
      } else {
        _currentTime = TimeOfDay.now();
      }
    } else {
      // Trường hợp thêm mới (Add)
      final now = DateTime.now();
      _currentTime = TimeOfDay.now();
      _model = InputModel(
        type: type,
        date: DateFormatUtils.formatInternalDate(now),
        time: null,
      );
      _selectedCategory = categoryItem(Icons.category_outlined, 'Category');
      amountController = TextEditingController();
      descriptionController = TextEditingController();
    }
  }

  /// Parse TimeOfDay từ string format "HH:mm"
  TimeOfDay _parseTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  // Cập nhật Category
  void updateCategory(CategoryItem newCategory) {
    _selectedCategory = newCategory;
    _model.category = newCategory.text;
    notifyListeners();
  }

  // Cập nhật ngày
  // ALWAYS store in ISO format (yyyy-MM-dd) for consistency
  void updateDate(DateTime newDate) {
    _model.date = DateFormatUtils.formatInternalDate(newDate);
    notifyListeners();
  }

  // Cập nhật giờ
  void updateTime(TimeOfDay newTime) {
    _currentTime = newTime;
    notifyListeners();
  }

  /// Format time để hiển thị trên UI
  String getFormattedTime(BuildContext context) {
    return _currentTime.format(context);
  }

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Validate input trước khi save
  String? validateInput(BuildContext context) {
    // Kiểm tra amount
    final amount = AmountFormatter.parseAmount(amountController.text);
    if (amount <= 0) {
      return getTranslated(context, 'Please enter an amount greater than 0') ??
          'Please enter an amount greater than 0';
    }

    // Kiểm tra category
    if (_model.category == null ||
        _model.category == 'Category' ||
        _model.category!.isEmpty) {
      return getTranslated(context, 'Please select a category') ??
          'Please select a category';
    }

    return null;
  }

  /// Format time thành string chuẩn "HH:mm"
  String _formatTimeToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Hàm lưu dữ liệu
  Future<void> saveInput(BuildContext context, {bool isNewInput = true}) async {
    final validationError = validateInput(context);
    if (validationError != null) {
       AlertService.show(
        context,
        type: NotificationType.error,
        message: validationError,
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _model.amount = AmountFormatter.parseAmount(amountController.text);
      _model.description = descriptionController.text;
      _model.time = _formatTimeToString(_currentTime);

      if (isNewInput) {
        await _transactionProvider.addTransaction(_model);
        amountController.clear();
        descriptionController.clear();
        _selectedCategory = categoryItem(Icons.category_outlined, 'Category');
        _model.category = 'Category';
        _currentTime = TimeOfDay.now();

         AlertService.show(
          context,
          type: NotificationType.success,
          message: getTranslated(context, 'Data has been saved') ??
              'Data has been saved',
        );
      } else {
        await _transactionProvider.updateTransaction(_model);
        Navigator.pop(context);
         AlertService.show(
          context,
          type: NotificationType.success,
          message: 'Transaction has been updated',
        );
      }
    } catch (e) {
      print('Error saving input: $e');
       AlertService.show(
        context,
        type: NotificationType.error,
        message: 'Error saving data',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm xóa dữ liệu
  Future<void> deleteInput(BuildContext context) async {
    final confirmed = await  AlertService.show(
      context,
      type: NotificationType.delete,
      title: 'Delete Transaction',
      message: 'Are you sure you want to delete this transaction?',
      actionText: 'Delete',
      cancelText: 'Cancel',
    );

    if (confirmed == true) {
      try {
        await _transactionProvider.deleteTransaction(_model.id!);
        Navigator.pop(context);
         AlertService.show(
          context,
          type: NotificationType.success,
          message: 'Transaction has been deleted',
        );
      } catch (e) {
        print('Error deleting input: $e');
         AlertService.show(
          context,
          type: NotificationType.error,
          message: 'Error deleting data',
        );
      }
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    amountFocusNode.dispose();
    descriptionFocusNode.dispose();
    super.dispose();
  }
}
