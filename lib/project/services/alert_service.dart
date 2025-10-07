import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/responsive_extensions.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../localization/methods.dart';

enum NotificationType {
  success,
  error,
  warning,
  info,
  confirm, // Alert style
  delete, // Alert style with red accent
}

class AlertService {
  // Unified styling cho tất cả notifications
  static const _borderRadius = 16.0;
  static final _padding =
      EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h);

  /// Show alert or toast notification
  /// 
  /// IMPORTANT: Pass RAW localization keys, NOT pre-translated strings
  /// AlertService will handle translation internally
  /// 
  /// Example:
  /// ```dart
  /// AlertService.show(
  ///   context,
  ///   type: NotificationType.success,
  ///   message: 'Data has been saved',  // ← Raw key, not translated
  /// );
  /// ```
  static dynamic show(
    BuildContext context, {
    required NotificationType type,
    String? title,
    required String message,
    String? actionText,
    String? cancelText,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) async {
    // Alert types: Modal dialog
    if (type == NotificationType.confirm || type == NotificationType.delete) {
      return await _showUnifiedAlert(
        context,
        type: type,
        title: title,
        message: message,
        actionText: actionText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        barrierDismissible: barrierDismissible,
      );
    }

    // Toast types: Unified toast design
    else {
      _showUnifiedToast(context, message, type);
      return null;
    }
  }

  static Future<bool?> _showUnifiedAlert(
    BuildContext context, {
    required NotificationType type,
    String? title,
    required String message,
    String? actionText,
    String? cancelText,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final colors = _getColors(type);

    if (isIOS) {
      return await showCupertinoDialog<bool>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => CupertinoAlertDialog(
          title: title != null
              ? Text(
                  getTranslated(context, title) ?? title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              // Icon unified design
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: colors['background']?.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  colors['icon'],
                  color: colors['iconColor'],
                  size: 28.sp,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                getTranslated(context, message) ?? message,
                style: TextStyle(
                  fontSize: 15.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                getTranslated(context, cancelText ?? 'Cancel') ?? 'Cancel',
                style: TextStyle(
                  fontSize: 17.sp,
                  color: Colors.grey[600],
                ),
              ),
              isDefaultAction: false,
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context, true);
                onConfirm?.call();
              },
              child: Text(
                getTranslated(context, actionText ?? 'OK') ?? 'OK',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                  color: type == NotificationType.delete
                      ? Colors.red
                      : colors['primary'],
                ),
              ),
              isDefaultAction: true,
              isDestructiveAction: type == NotificationType.delete,
            ),
          ],
        ),
      );
    } else {
      return await showDialog<bool>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 40.w),
            padding: _padding,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_borderRadius.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header với icon
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: colors['background']?.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    colors['icon'],
                    color: colors['iconColor'],
                    size: 32.sp,
                  ),
                ),
                SizedBox(height: 16.h),

                if (title != null) ...[
                  Text(
                    getTranslated(context, title) ?? title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                ],

                // Message
                Text(
                  getTranslated(context, message) ?? message,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.black87.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 24.h),

                // Buttons
                Row(
                  children: [
                    if (cancelText != null) ...[
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            getTranslated(context, cancelText) ?? cancelText,
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                          onConfirm?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: type == NotificationType.delete
                              ? Colors.red
                              : colors['primary'],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          getTranslated(context, actionText ?? 'OK') ?? 'OK',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  static void _showUnifiedToast(
      BuildContext context, String message, NotificationType type) {
    final colors = _getColors(type);

    var fToast = FToast();
    fToast.init(context);
    fToast.showToast(
      child: Container(
        constraints: BoxConstraints(maxWidth: 320.w),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: colors['background'],
          borderRadius: BorderRadius.circular(_borderRadius.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
          border: Border.all(
            color: colors['border'] ?? Colors.transparent,
            width: 1.5.w,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              colors['icon'],
              color: colors['iconColor'],
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Flexible(
              child: Text(
                getTranslated(context, message) ?? message,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: colors['text'],
                ),
              ),
            ),
          ],
        ),
      ),
      gravity: ToastGravity.TOP,
      toastDuration: Duration(seconds: 2),
    );
  }

  static Map<String, dynamic> _getColors(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return {
          'background': Color(0xFFE8F5E9), // xanh nhạt
          'primary': Color(0xFF4CAF50), // xanh lá
          'icon': Icons.check_circle,
          'iconColor': Color(0xFF4CAF50),
          'text': Color(0xFF2E7D32),
          'border': Color(0xFF4CAF50),
        };
      case NotificationType.error:
        return {
          'background': Color(0xFFFFEBEE), // đỏ nhạt
          'primary': Color(0xFFF44336), // đỏ
          'icon': Icons.error,
          'iconColor': Color(0xFFF44336),
          'text': Color(0xFFC62828),
          'border': Color(0xFFF44336),
        };
      case NotificationType.warning:
        return {
          'background': Color(0xFFFFF8E1), // vàng nhạt
          'primary': Color(0xFFFF9800), // cam
          'icon': Icons.warning,
          'iconColor': Color(0xFFFF9800),
          'text': Color(0xFFEF6C00),
          'border': Color(0xFFFF9800),
        };
      case NotificationType.info:
        return {
          'background': Color(0xFFE3F2FD), // xanh dương nhạt
          'primary': Color(0xFF2196F3), // xanh dương
          'icon': Icons.info,
          'iconColor': Color(0xFF2196F3),
          'text': Color(0xFF1565C0),
          'border': Color(0xFF2196F3),
        };
      case NotificationType.confirm:
        return {
          'background': Color(0xFFF5F5F5), // xám nhạt
          'primary': Color(0xFF607D8B), // xám xanh
          'icon': Icons.help_outline,
          'iconColor': Color(0xFF607D8B),
          'text': Color(0xFF37474F),
          'border': Color(0xFF607D8B),
        };
      case NotificationType.delete:
        return {
          'background': Color(0xFFFFEBEE), // đỏ nhạt
          'primary': Color(0xFFF44336), // đỏ
          'icon': Icons.delete_outline,
          'iconColor': Color(0xFFF44336),
          'text': Color(0xFFC62828),
          'border': Color(0xFFF44336),
        };
    }
  }
}
