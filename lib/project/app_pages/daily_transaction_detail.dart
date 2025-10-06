import 'package:flutter/material.dart';
 import '../utils/responsive_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../classes/app_bar.dart';
import '../classes/constants.dart';
import '../classes/input_model.dart';
import '../classes/transaction_list_item.dart';
import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';
import '../services/alert_service.dart';
import '../utils/category_icon_helper.dart';
import '../provider/transaction_provider.dart';
import 'edit.dart';

/// Màn hình hiển thị chi tiết các giao dịch trong một ngày
/// ĐÃ CHUYỂN ĐỔI SANG STATELESS - Single Source of Truth từ TransactionProvider
class DailyTransactionDetail extends StatelessWidget {
  final DateTime date;

  const DailyTransactionDetail({
    Key? key,
    required this.date,
  }) : super(key: key);

  /// Xóa giao dịch với confirmation
  Future<void> _deleteTransaction(BuildContext context, int id) async {
    final confirmed = await NotificationService.show(
      context,
      type: NotificationType.delete,
      title: 'Delete Transaction',
      message:
          'Are you sure you want to delete this transaction? This action cannot be undone.',
      actionText: 'Delete',
      cancelText: 'Cancel',
    );

    if (confirmed == true) {
      try {
        // Sử dụng TransactionProvider thay vì DB trực tiếp
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
        print('Error deleting transaction: $e');
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
      // Sử dụng TransactionProvider thay vì DB trực tiếp
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
      print('Error duplicating transaction: $e');
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

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        // Lấy transactions từ TransactionProvider - SINGLE SOURCE OF TRUTH
        final dateString = DateFormat('dd/MM/yyyy').format(date);
        final transactions = transactionProvider.allTransactions
            .where((t) => t.date == dateString)
            .toList()
          ..sort((a, b) {
            // Sort by time if available (mới nhất trước)
            if (a.time != null && b.time != null) {
              return b.time!.compareTo(a.time!);
            }
            return 0;
          });

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

        return Scaffold(
          backgroundColor: blue1,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: BasicAppBar(dateLabel),
          ),
          body: Column(
            children: [
              // Summary Card
              Container(
                margin: EdgeInsets.all(16.w),
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [blue2, blue3],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: blue3.withValues(alpha: 0.3),
                      blurRadius: 12.r,
                      offset: Offset(0, 6.h),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Total transactions count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          color: white,
                          size: 24.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${transactions.length} ${getTranslated(context, transactions.length == 1 ? 'Transaction' : 'Transactions') ?? (transactions.length == 1 ? 'Transaction' : 'Transactions')}',
                          style: GoogleFonts.poppins(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: white,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    // Income, Expense, Balance summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSummaryColumn(
                          context,
                          label: 'Income',
                          amount: totalIncome,
                          icon: Icons.arrow_downward_rounded,
                        ),
                        Container(
                          width: 1.w,
                          height: 50.h,
                          color: white.withValues(alpha: 0.3),
                        ),
                        _buildSummaryColumn(
                          context,
                          label: 'Expense',
                          amount: totalExpense,
                          icon: Icons.arrow_upward_rounded,
                        ),
                        Container(
                          width: 1.w,
                          height: 50.h,
                          color: white.withValues(alpha: 0.3),
                        ),
                        _buildSummaryColumn(
                          context,
                          label: 'Balance',
                          amount: balance,
                          icon: Icons.account_balance_wallet_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Transaction list
              Expanded(
                child: Container(
                  color: Colors.grey[50],
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.only(
                      top: 8.h,
                      bottom: 24.h,
                      left: 4.w,
                      right: 4.w,
                    ),
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) => SizedBox(height: 6.h),
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];

                      return TransactionListItem(
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
                          // Không cần reload - Consumer tự động cập nhật
                        },
                        onDelete: () async {
                          await _deleteTransaction(context, transaction.id!);
                        },
                        onDuplicate: () async {
                          await _duplicateTransaction(context, transaction);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryColumn(
    BuildContext context, {
    required String label,
    required double amount,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: white,
          size: 24.sp,
        ),
        SizedBox(height: 6.h),
        Text(
          getTranslated(context, label) ?? label,
          style: TextStyle(
            fontSize: 12.sp,
            color: white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${format(amount.abs())} $currency',
            style: GoogleFonts.aBeeZee(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: white,
            ),
          ),
        ),
      ],
    );
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
      // Format tiếng Việt: Thứ Hai, 04 Tháng 10 2025
      final weekdayNames = [
        'Chủ Nhật',
        'Thứ Hai',
        'Thứ Ba',
        'Thứ Tư',
        'Thứ Năm',
        'Thứ Sáu',
        'Thứ Bảy'
      ];
      final monthNames = [
        'Tháng 1',
        'Tháng 2',
        'Tháng 3',
        'Tháng 4',
        'Tháng 5',
        'Tháng 6',
        'Tháng 7',
        'Tháng 8',
        'Tháng 9',
        'Tháng 10',
        'Tháng 11',
        'Tháng 12'
      ];
      final weekday = weekdayNames[date.weekday % 7];
      final month = monthNames[date.month - 1];
      return '$weekday, ${date.day} $month ${date.year}';
    } else {
      // Format English: Monday, October 04, 2025
      return DateFormat('EEEE, MMMM dd, yyyy').format(date);
    }
  }
}
