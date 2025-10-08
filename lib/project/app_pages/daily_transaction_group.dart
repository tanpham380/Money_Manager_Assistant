import 'package:flutter/material.dart';
import 'package:money_assistant/project/services/category_icon_service.dart';
import '../utils/responsive_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../classes/constants.dart';
import '../classes/input_model.dart';
import '../classes/transaction_list_item.dart';
import '../localization/methods.dart';
import '../utils/date_format_utils.dart';
import '../provider/transaction_provider.dart';
import '../app_pages/edit.dart';
import '../services/alert_service.dart' show AlertService, NotificationType;

// Alias để giữ tính tương thích
typedef NotificationService = AlertService;

/// Widget hiển thị nhóm giao dịch theo ngày
/// SỬ DỤNG EXPANSIONTILE - Xem transactions in-place không cần navigate
class DailyTransactionGroup extends StatelessWidget {
  final DateTime date;
  final List<InputModel> transactions;
  final bool initiallyExpanded;

  const DailyTransactionGroup({
    Key? key,
    required this.date,
    required this.transactions,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tính toán tổng thu nhập và chi phí
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    for (final transaction in transactions) {
      if (transaction.type == 'Income') {
        totalIncome += transaction.amount ?? 0.0;
      } else {
        totalExpense += transaction.amount ?? 0.0;
      }
    }

    final balance = totalIncome - totalExpense;
    final balanceColor = balance >= 0
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.error; // Use theme colors

    // Format ngày
    final isToday = _isToday(date);
    final isYesterday = _isYesterday(date);

    String dateLabel;
    if (isToday) {
      dateLabel = getTranslated(context, 'Today') ?? 'Today';
    } else if (isYesterday) {
      dateLabel = getTranslated(context, 'Yesterday') ?? 'Yesterday';
    } else {
      // Format ngày theo locale
      dateLabel = _formatDate(context, date);
    }

    // SỬ DỤNG CONTAINER thay vì Card để thống nhất với TransactionListItem
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h), // Giảm margin
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r), // Giảm bo tròn cho gọn hơn
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), // Thêm shadow nhẹ
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h), // Giảm padding
          childrenPadding: EdgeInsets.only(
            bottom: 6.h, // Giảm bottom padding
            left: 4.w,
            right: 4.w,
          ),
          leading: Container(
            padding: EdgeInsets.all(6.w), // Giảm padding
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.08), // Nhạt màu background
              borderRadius: BorderRadius.circular(6.r), // Giảm bo tròn
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 16.sp, // Giảm icon size
            ),
          ),
          title: Text(
            dateLabel,
            style: GoogleFonts.poppins(
              fontSize: 13.sp, // Giảm từ 15sp
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.2, // Thêm line height
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h), // Giảm spacing
              Text(
                '${transactions.length} ${getTranslated(context, transactions.length == 1 ? 'transaction' : 'transactions') ?? (transactions.length == 1 ? 'transaction' : 'transactions')}',
                style: TextStyle(
                  fontSize: 10.sp, // Giảm từ 12sp
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5), // Nhạt màu hơn
                  height: 1.2,
                ),
              ),
              SizedBox(height: 8.h), // Giảm spacing
              // Summary: Thu nhập, Chi phí, Cân đối - HORIZONTAL COMPACT
              Row(
                children: [
                  // Thu nhập
                  Expanded(
                    child: _buildCompactSummary(
                      context,
                      label: 'Income',
                      amount: totalIncome,
                      color: Theme.of(context).colorScheme.secondary,
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                  SizedBox(width: 4.w), // Giảm spacing
                  // Chi phí
                  Expanded(
                    child: _buildCompactSummary(
                      context,
                      label: 'Expense',
                      amount: totalExpense,
                      color: Theme.of(context).colorScheme.error,
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  // Cân đối
                  Expanded(
                    child: _buildCompactSummary(
                      context,
                      label: 'Balance',
                      amount: balance,
                      color: balanceColor,
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            // Subtle divider khi expanded
            Container(
              height: 1.h,
              margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Danh sách các transactions - hiển thị khi mở rộng
            ...transactions
                .map((transaction) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h), // Giảm padding
                      child: TransactionListItem(
                        transaction: transaction,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Edit(
                                inputModel: transaction,
                                categoryIcon:
                                    CategoryIconService().getIconForCategory(
                                  transaction.category ?? 'Category',
                                ),
                              ),
                            ),
                          );
                        },
                        onDelete: () async {
                          await _deleteTransaction(context, transaction.id!);
                        },
                        onDuplicate: () async {
                          await _duplicateTransaction(context, transaction);
                        },
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  /// Compact summary widget - Horizontal layout
  Widget _buildCompactSummary(
    BuildContext context, {
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w), // Giảm padding
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06), // Nhạt màu background
        borderRadius: BorderRadius.circular(6.r), // Giảm bo tròn
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon và Label trên cùng 1 row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color.withValues(alpha: 0.8),
                size: 12.sp, // Icon nhỏ hơn
              ),
              SizedBox(width: 3.w),
              Flexible(
                child: Text(
                  getTranslated(context, label) ?? label,
                  style: TextStyle(
                    fontSize: 9.sp, // Font nhỏ hơn
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Amount ở dưới
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${format(amount.abs())}',
              style: GoogleFonts.aBeeZee(
                fontSize: 11.sp, // Giảm từ 13sp
                fontWeight: FontWeight.bold,
                color: color,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Xóa giao dịch với confirmation
  Future<void> _deleteTransaction(BuildContext context, int id) async {
    final confirmed = await NotificationService.show(
      context,
      type: NotificationType.delete,
      title: 'Delete Transaction',
      message: 'Are you sure you want to delete this transaction?',
      actionText: 'Delete',
      cancelText: 'Cancel',
    );

    if (confirmed == true) {
      try {
        final transactionProvider =
            Provider.of<TransactionProvider>(context, listen: false);
        await transactionProvider.deleteTransaction(id);

        if (context.mounted) {
          NotificationService.show(
            context,
            type: NotificationType.success,
            message: 'Transaction has been deleted',
          );
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.show(
            context,
            type: NotificationType.error,
            message: 'Error deleting transaction',
          );
        }
      }
    }
  }

  /// Sao chép giao dịch
  Future<void> _duplicateTransaction(
      BuildContext context, InputModel transaction) async {
    try {
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.duplicateTransaction(transaction);

      if (context.mounted) {
        NotificationService.show(
          context,
          type: NotificationType.success,
          message: 'Transaction has been duplicated',
        );
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.show(
          context,
          type: NotificationType.error,
          message: 'Error duplicating transaction',
        );
      }
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Format ngày theo locale của người dùng
  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;

    if (locale == 'vi') {
      // Sử dụng localization cho tiếng Việt
      return DateFormatUtils.formatLocalizedWeekdayWithUserDate(context, date);
    } else {
      // Sử dụng localization cho tiếng Anh
      return DateFormatUtils.formatFullWeekday(date);
    }
  }
}
