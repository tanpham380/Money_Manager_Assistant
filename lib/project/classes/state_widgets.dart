import 'package:flutter/material.dart';
import '../utils/responsive_extensions.dart';
import '../localization/methods.dart';

/// Widget hiển thị Empty State - Khi không có dữ liệu
class EmptyStateWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyStateWidget({
    Key? key,
    this.title,
    this.message,
    this.icon,
    this.onAction,
    this.actionText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 100.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24.h),
            Text(
              title ?? getTranslated(context, 'No data available') ?? 'No data available',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: 12.h),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionText != null) ...[
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(
                  actionText!,
                  style: TextStyle(fontSize: 16.sp),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget hiển thị Error State - Khi có lỗi xảy ra
class ErrorStateWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryText;

  const ErrorStateWidget({
    Key? key,
    this.title,
    this.message,
    this.onRetry,
    this.retryText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 100.sp,
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
            ),
            SizedBox(height: 24.h),
            Text(
              title ?? getTranslated(context, 'Error occurred') ?? 'An error occurred',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: 12.h),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  retryText ?? getTranslated(context, 'Try again') ?? 'Try again',
                  style: TextStyle(fontSize: 16.sp),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget hiển thị Loading State - Khi đang tải dữ liệu
class LoadingStateWidget extends StatelessWidget {
  final String? message;

  const LoadingStateWidget({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3.w,
          ),
          if (message != null) ...[
            SizedBox(height: 16.h),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget hiển thị No Transactions State - Cho Calendar/List views
class NoTransactionsWidget extends StatelessWidget {
  final DateTime? date;
  final VoidCallback? onAddTransaction;

  const NoTransactionsWidget({
    Key? key,
    this.date,
    this.onAddTransaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String message = date != null
        ? getTranslated(context, 'No transactions on this date') ?? 'No transactions on this date'
        : getTranslated(context, 'No transactions found') ?? 'No transactions found';

    return EmptyStateWidget(
      icon: Icons.receipt_long_outlined,
      title: getTranslated(context, 'No transactions') ?? 'No transactions',
      message: message,
      onAction: onAddTransaction,
      actionText: getTranslated(context, 'Add transaction') ?? 'Add transaction',
    );
  }
}
