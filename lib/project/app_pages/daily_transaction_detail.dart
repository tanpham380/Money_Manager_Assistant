import 'package:flutter/material.dart';
import '../utils/responsive_extensions.dart';
import '../utils/date_format_utils.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final confirmed = await AlertService.show(
      context,
      type: NotificationType.delete,
      title: 'Delete Transaction', // Raw key
      message: 'Are you sure you want to delete this transaction?', // Raw key
      actionText: 'Delete', // Raw key
      cancelText: 'Cancel', // Raw key
    );

    if (confirmed == true) {
      try {
        // Sử dụng TransactionProvider thay vì DB trực tiếp
        final transactionProvider =
            Provider.of<TransactionProvider>(context, listen: false);
        await transactionProvider.deleteTransaction(id);

        if (context.mounted) {
          AlertService.show(
            context,
            type: NotificationType.success,
            message: 'Transaction has been deleted', // Raw key
          );
        }
      } catch (e) {
        print('Error deleting transaction: $e');
        if (context.mounted) {
          AlertService.show(
            context,
            type: NotificationType.error,
            message: 'Error deleting transaction', // Raw key
          );
        }
      }
    }
  }

  /// Sao chép giao dịch
  Future<void> _duplicateTransaction(
      BuildContext context, InputModel transaction) async {
    try {
      // Sử dụng TransactionProvider thay vì DB trực tiếp
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.duplicateTransaction(transaction);

      if (context.mounted) {
        AlertService.show(
          context,
          type: NotificationType.success,
          message: 'Transaction has been duplicated', // Raw key
        );
      }
    } catch (e) {
      print('Error duplicating transaction: $e');
      if (context.mounted) {
        AlertService.show(
          context,
          type: NotificationType.error,
          message: 'Error duplicating transaction', // Raw key
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        // Lấy transactions từ TransactionProvider - SINGLE SOURCE OF TRUTH
        final dateString = DateFormatUtils.formatInternalDate(date);
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
                          label: getTranslated(context, 'Income') ?? 'Income',
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
                          label: getTranslated(context, 'Expense') ?? 'Expense',
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
                          label: getTranslated(context, 'Balance') ?? 'Balance',
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
                                categoryIcon:
                                    CategoryIconHelper.getIconForCategory(
                                  transaction.category ??
                                      getTranslated(context, 'Category') ??
                                      'Category',
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

  /// Format ngày theo locale của người dùng - SỬ DỤNG LOCALIZATION
  String _formatDate(BuildContext context, DateTime date) {
    return DateFormatUtils.formatLocalizedFullDate(context, date);
  }
}
