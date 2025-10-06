import 'package:flutter/material.dart';
 import '../utils/responsive_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../classes/constants.dart';
import '../classes/input_model.dart';
import '../classes/transaction_list_item.dart';
import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';
import '../utils/category_icon_helper.dart';
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

  const DailyTransactionGroup({
    Key? key,
    required this.date,
    required this.transactions,
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
    final balanceColor = balance >= 0 ? green : red;
    
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

    // SỬ DỤNG EXPANSIONTILE - Cho phép mở rộng để xem transactions
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          childrenPadding: EdgeInsets.only(bottom: 12.h),
          leading: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: blue2.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: blue3,
              size: 20.sp,
            ),
          ),
          title: Text(
            dateLabel,
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4.h),
              Text(
                '${transactions.length} ${getTranslated(context, transactions.length == 1 ? 'transaction' : 'transactions') ?? (transactions.length == 1 ? 'transaction' : 'transactions')}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 12.h),
              // Summary: Thu nhập, Chi phí, Cân đối
              Row(
                children: [
                  // Thu nhập
                  Expanded(
                    child: _buildSummaryItem(
                      context,
                      label: 'Income',
                      amount: totalIncome,
                      color: green,
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Chi phí
                  Expanded(
                    child: _buildSummaryItem(
                      context,
                      label: 'Expense',
                      amount: totalExpense,
                      color: red,
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Cân đối
                  Expanded(
                    child: _buildSummaryItem(
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
            // Danh sách các transactions - hiển thị khi mở rộng
            ...transactions.map((transaction) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: TransactionListItem(
                transaction: transaction,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Edit(
                        inputModel: transaction,
                        categoryIcon: CategoryIconHelper.getIconForCategory(
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
            )).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(
    BuildContext context, {
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 18.sp,
          ),
          SizedBox(height: 4.h),
          Text(
            getTranslated(context, label) ?? label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${format(amount.abs())} $currency',
              style: GoogleFonts.aBeeZee(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: color,
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
      title: getTranslated(context, 'Delete Transaction') ?? 'Delete Transaction',
      message: getTranslated(context, 'Are you sure you want to delete this transaction?') ??
          'Are you sure you want to delete this transaction?',
      actionText: getTranslated(context, 'Delete') ?? 'Delete',
      cancelText: getTranslated(context, 'Cancel') ?? 'Cancel',
    );

    if (confirmed == true) {
      try {
        final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
        await transactionProvider.deleteTransaction(id);
        
        if (context.mounted) {
          NotificationService.show(
            context,
            type: NotificationType.success,
            message: getTranslated(context, 'Transaction has been deleted') ??
                'Transaction has been deleted',
          );
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.show(
            context,
            type: NotificationType.error,
            message: getTranslated(context, 'Error deleting transaction') ??
                'Error deleting transaction',
          );
        }
      }
    }
  }

  /// Sao chép giao dịch
  Future<void> _duplicateTransaction(BuildContext context, InputModel transaction) async {
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.duplicateTransaction(transaction);
      
      if (context.mounted) {
        NotificationService.show(
          context,
          type: NotificationType.success,
          message: getTranslated(context, 'Transaction has been duplicated') ??
              'Transaction has been duplicated',
        );
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.show(
          context,
          type: NotificationType.error,
          message: getTranslated(context, 'Error duplicating transaction') ??
              'Error duplicating transaction',
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
      // Format tiếng Việt: Thứ Hai, 04/10/2025
      final weekdayNames = [
        'Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư',
        'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'
      ];
      final weekday = weekdayNames[date.weekday % 7];
      return '$weekday, ${DateFormat('dd/MM/yyyy').format(date)}';
    } else {
      // Format English: Monday, October 04, 2025
      return DateFormat('EEEE, MMMM dd, yyyy').format(date);
    }
  }
}
