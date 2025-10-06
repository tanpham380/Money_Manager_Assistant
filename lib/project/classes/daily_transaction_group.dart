import 'package:flutter/material.dart';
 import '../utils/responsive_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../classes/constants.dart';
import '../classes/input_model.dart';
import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';

/// Widget hiển thị nhóm giao dịch theo ngày
/// Tap để xem chi tiết
class DailyTransactionGroup extends StatelessWidget {
  final DateTime date;
  final List<InputModel> transactions;
  final VoidCallback onTap;

  const DailyTransactionGroup({
    Key? key,
    required this.date,
    required this.transactions,
    required this.onTap,
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

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Ngày và số lượng giao dịch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Ngày
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: blue2.withValues( alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: blue3,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${transactions.length} ${getTranslated(context, transactions.length == 1 ? 'transaction' : 'transactions') ?? (transactions.length == 1 ? 'transaction' : 'transactions')}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Arrow icon
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey[400],
                    size: 28.sp,
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              
              // Divider
              Container(
                height: 1.h,
                color: Colors.grey[200],
              ),
              
              SizedBox(height: 16.h),
              
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
                  
                  SizedBox(width: 12.w),
                  
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
                  
                  SizedBox(width: 12.w),
                  
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
