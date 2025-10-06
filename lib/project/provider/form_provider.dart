import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../classes/input_model.dart';
import '../classes/category_item.dart';
import '../classes/constants.dart';
import '../database_management/sqflite_services.dart';
import '../classes/custom_toast.dart';
import '../localization/methods.dart';
import '../utils/amount_formatter.dart';

class FormProvider with ChangeNotifier {
  late InputModel _model;
  late TextEditingController amountController;
  late TextEditingController descriptionController;
  late FocusNode amountFocusNode;
  late FocusNode descriptionFocusNode;
  late CategoryItem _selectedCategory;
  late PanelController panelController;
  late TimeOfDay _currentTime;

  InputModel get model => _model;
  CategoryItem get selectedCategory => _selectedCategory;
  TimeOfDay get currentTime => _currentTime;

  // Constructor để khởi tạo state cho form
  FormProvider({InputModel? input, String? type, IconData? categoryIcon}) {
    // Khởi tạo các controller và focus node
    amountFocusNode = FocusNode();
    descriptionFocusNode = FocusNode();
    panelController = PanelController();

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
        date: DateFormat('dd/MM/yyyy').format(now),
        time: null, // Sẽ được format khi cần hiển thị
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
  void updateDate(DateTime newDate) {
    _model.date = DateFormat('dd/MM/yyyy').format(newDate);
    notifyListeners();
  }

  // Cập nhật giờ
  void updateTime(TimeOfDay newTime) {
    _currentTime = newTime;
    // Time sẽ được format khi save hoặc hiển thị
    notifyListeners();
  }

  /// Format time để hiển thị trên UI
  String getFormattedTime(BuildContext context) {
    return _currentTime.format(context);
  }

  // Hàm xử lý nhập liệu cho bàn phím tùy chỉnh
  // Delegate logic phức tạp cho AmountFormatter utility class
  void insertAmountText(String myText) {
    AmountFormatter.insertText(amountController, myText);
    notifyListeners();
  }

  void backspaceAmount() {
    AmountFormatter.backspace(amountController);
    notifyListeners();
  }

  // Loading state để hiển thị khi đang save
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
    
    // Kiểm tra category đã được chọn chưa
    if (_model.category == null || 
        _model.category == 'Category' || 
        _model.category!.isEmpty) {
      return getTranslated(context, 'Please select a category') ?? 
             'Please select a category';
    }
    
    return null; // Valid
  }

  /// Format time thành string chuẩn "HH:mm"
  String _formatTimeToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Hàm lưu dữ liệu - ĐÃ SỬA: async, validation, error handling
  Future<void> saveInput(BuildContext context, {bool isNewInput = true}) async {
    // Validate trước khi save
    final validationError = validateInput(context);
    if (validationError != null) {
      customToast(context, validationError);
      return; // Dừng lại nếu không hợp lệ
    }

    // Hiển thị loading state
    _isLoading = true;
    notifyListeners();

    try {
      // Cập nhật model với dữ liệu mới
      _model.amount = AmountFormatter.parseAmount(amountController.text);
      _model.description = descriptionController.text;
      _model.time = _formatTimeToString(_currentTime); // Format chuẩn

      if (isNewInput) {
        // Logic thêm mới - AWAIT database operation
        await DB.insert(_model);
        
        // Clear form sau khi lưu THÀNH CÔNG
        amountController.clear();
        descriptionController.clear();
        // Reset category to default
        _selectedCategory = categoryItem(Icons.category_outlined, 'Category');
        _model.category = 'Category';
        // Reset time to now
        _currentTime = TimeOfDay.now();
        
        customToast(context, getTranslated(context, 'Data has been saved') ?? 'Data has been saved');
      } else {
        // Logic cập nhật - AWAIT database operation
        await DB.update(_model);
        
        Navigator.pop(context);
        customToast(
            context,
            getTranslated(context, 'Transaction has been updated') ??
                'Transaction has been updated');
      }
    } catch (e) {
      // Xử lý lỗi khi save
      print('Error saving input: $e');
      customToast(
        context, 
        getTranslated(context, 'Error saving data') ?? 'Error saving data: ${e.toString()}'
      );
    } finally {
      // Tắt loading state
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm xóa dữ liệu
  void deleteInput(BuildContext context) {
    DB.delete(_model.id!);
    Navigator.pop(context);
    customToast(context, getTranslated(context, 'Transaction has been deleted') ?? 'Transaction has been deleted');
  }

  // Rất quan trọng: Giải phóng tài nguyên
  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    amountFocusNode.dispose();
    descriptionFocusNode.dispose();
    // PanelController không có dispose method
    super.dispose();
  }
}
