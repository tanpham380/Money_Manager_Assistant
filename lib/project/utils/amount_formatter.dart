import 'package:flutter/material.dart';
import '../classes/constants.dart';

/// Utility class để xử lý logic format số tiền phức tạp
/// Tách biệt logic xử lý chuỗi khỏi state management
class AmountFormatter {
  /// Chèn text vào controller tại vị trí cursor
  /// Xử lý các quy tắc:
  /// - Giới hạn độ dài tối đa 13 ký tự
  /// - Chỉ cho phép 2 số sau dấu thập phân
  /// - Chỉ cho phép 1 dấu chấm
  static void insertText(
    TextEditingController controller,
    String myText,
  ) {
    final text = controller.text;
    final TextSelection textSelection = controller.selection;
    
    String newText = text.replaceRange(
      textSelection.start,
      textSelection.end,
      myText,
    );
    
    // Giới hạn độ dài tối đa
    if (newText.length > 13) {
      newText = newText.substring(0, 13);
    }
    
    // Xử lý số thập phân
    if (newText.contains('.')) {
      newText = _handleDecimalInput(newText);
      controller.text = newText;
    } else {
      // Format số nguyên với dấu phẩy
      controller.text = _formatWithCommas(newText);
    }

    // Đặt cursor ở cuối
    final textSelection2 = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
    controller.selection = textSelection2;
  }

  /// Xử lý backspace
  static void backspace(TextEditingController controller) {
    final text = controller.text;
    final TextSelection textSelection = controller.selection;

    // Cursor ở đầu - không làm gì
    if (textSelection.start == 0) {
      return;
    }

    final selectionLength = textSelection.end - textSelection.start;
    
    // Có selection - xóa selection
    if (selectionLength > 0) {
      final newText = text.replaceRange(
        textSelection.start,
        textSelection.end,
        '',
      );
      _updateControllerText(controller, newText);
      return;
    }

    // Xóa 1 ký tự trước cursor
    final previousCodeUnit = text.codeUnitAt(textSelection.start - 1);
    final offset = _isUtf16Surrogate(previousCodeUnit) ? 2 : 1;
    final newStart = textSelection.start - offset;
    final newEnd = textSelection.start;
    final newText = text.replaceRange(newStart, newEnd, '');
    
    _updateControllerText(controller, newText);
  }

  /// Xử lý input có dấu thập phân
  static String _handleDecimalInput(String newText) {
    final parts = newText.split('.');
    
    if (parts.length > 2) {
      // Có nhiều hơn 1 dấu chấm - loại bỏ dấu chấm cuối cùng
      return newText.substring(0, newText.length - 1);
    }
    
    final fractionalPart = parts.last;
    
    // Giới hạn 2 số sau dấu thập phân
    if (fractionalPart.length > 2) {
      final wholePart = parts.first;
      return '$wholePart.${fractionalPart.substring(0, 2)}';
    }
    
    return newText;
  }

  /// Format số với dấu phẩy
  static String _formatWithCommas(String text) {
    if (text.isEmpty) return text;
    
    try {
      final number = double.parse(text.replaceAll(',', ''));
      return format(number);
    } catch (e) {
      return text;
    }
  }

  /// Cập nhật text của controller và giữ cursor ở cuối
  static void _updateControllerText(
    TextEditingController controller,
    String newText,
  ) {
    // Nếu rỗng hoặc có dấu chấm - không format
    if (newText.isEmpty || newText.contains('.')) {
      controller.text = newText;
    } else {
      controller.text = _formatWithCommas(newText);
    }

    // Đặt cursor ở cuối
    final textSelection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
    controller.selection = textSelection;
  }

  /// Kiểm tra UTF-16 surrogate pair
  static bool _isUtf16Surrogate(int value) {
    return value & 0xF800 == 0xD800;
  }

  /// Parse amount từ formatted string
  static double parseAmount(String formattedText) {
    if (formattedText.isEmpty) return 0;
    
    try {
      return double.parse(formattedText.replaceAll(',', ''));
    } catch (e) {
      return 0;
    }
  }
}
