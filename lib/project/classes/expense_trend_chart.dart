import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../classes/constants.dart';
import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';
import '../provider/analysis_provider.dart';
import '../utils/date_format_utils.dart';
import '../utils/responsive_extensions.dart';

/// Class chứa dữ liệu chi tiêu theo category với comparison
class ExpenseTrendData {
  final String category;
  final double currentWeekAmount;
  final double previousWeekAmount;
  final double changePercentage;
  final bool isPositiveChange; // Giảm chi tiêu = tích cực
  final Color color;
  final IconData icon;

  ExpenseTrendData({
    required this.category,
    required this.currentWeekAmount,
    required this.previousWeekAmount,
    required this.changePercentage,
    required this.isPositiveChange,
    required this.color,
    required this.icon,
  });

  bool get hasValidComparison => previousWeekAmount > 0;
}

/// Widget chart hiển thị xu hướng chi tiêu từng category với so sánh tuần
class ExpenseTrendChartAnalysis extends StatelessWidget {
  const ExpenseTrendChartAnalysis({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    
    // Lấy dữ liệu expense trend với comparison
    final expenseTrendData = _buildExpenseTrendData(provider);

    if (expenseTrendData.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // Title với thông tin so sánh
        _buildChartTitle(context),
        
        SizedBox(height: 16.h),
        
        // Chart chính
        Expanded(
          child: _buildColumnChart(context, expenseTrendData),
        ),
        
        SizedBox(height: 16.h),
        
        // Legend với comparison indicators
        _buildComparisonLegend(context, expenseTrendData),
      ],
    );
  }

  /// Xây dựng dữ liệu expense trend với comparison
  List<ExpenseTrendData> _buildExpenseTrendData(AnalysisProvider provider) {
    final now = DateTime.now();
    
    // Xác định tuần này (Monday to Sunday)
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    final currentWeekStart = now.subtract(Duration(days: weekday - 1));
    final currentWeekEnd = currentWeekStart.add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    
    // Tuần trước
    final previousWeekStart = currentWeekStart.subtract(Duration(days: 7));
    final previousWeekEnd = currentWeekStart.subtract(Duration(seconds: 1));
    
    // Lấy tất cả transactions
    final allTransactions = provider.allTransactions;
    
    // Lọc transactions cho tuần này (expenses only)
    final currentWeekExpenses = allTransactions.where((transaction) {
      if (transaction.type != 'Expense') return false;
      try {
        final date = DateFormatUtils.parseInternalDate(transaction.date!);
        return date.isAfter(currentWeekStart.subtract(Duration(seconds: 1))) && 
               date.isBefore(currentWeekEnd.add(Duration(seconds: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
    
    // Lọc transactions cho tuần trước (expenses only)
    final previousWeekExpenses = allTransactions.where((transaction) {
      if (transaction.type != 'Expense') return false;
      try {
        final date = DateFormatUtils.parseInternalDate(transaction.date!);
        return date.isAfter(previousWeekStart.subtract(Duration(seconds: 1))) && 
               date.isBefore(previousWeekEnd.add(Duration(seconds: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
    
    // Tính tổng theo category cho tuần này
    final Map<String, double> currentWeekByCategory = {};
    for (final transaction in currentWeekExpenses) {
      final category = transaction.category ?? 'Unknown';
      final amount = transaction.amount ?? 0.0;
      currentWeekByCategory[category] = (currentWeekByCategory[category] ?? 0.0) + amount;
    }
    
    // Tính tổng theo category cho tuần trước
    final Map<String, double> previousWeekByCategory = {};
    for (final transaction in previousWeekExpenses) {
      final category = transaction.category ?? 'Unknown';
      final amount = transaction.amount ?? 0.0;
      previousWeekByCategory[category] = (previousWeekByCategory[category] ?? 0.0) + amount;
    }
    
    // Lấy tất cả categories (từ cả 2 tuần)
    final allCategories = <String>{
      ...currentWeekByCategory.keys,
      ...previousWeekByCategory.keys,
    };
    
    // Tạo ExpenseTrendData cho mỗi category
    final result = <ExpenseTrendData>[];
    for (final category in allCategories) {
      final currentAmount = currentWeekByCategory[category] ?? 0.0;
      final previousAmount = previousWeekByCategory[category] ?? 0.0;
      
      // Tính phần trăm thay đổi
      double changePercentage = 0.0;
      bool isPositiveChange = true; // Giảm chi tiêu = tích cực
      
      if (previousAmount > 0) {
        changePercentage = ((currentAmount - previousAmount) / previousAmount) * 100;
        isPositiveChange = changePercentage < 0; // Giảm chi tiêu = tích cực
      } else if (currentAmount > 0) {
        changePercentage = 100.0; // Tăng từ 0 = 100%
        isPositiveChange = false; // Tăng chi tiêu = tiêu cực
      }
      
      // Lấy icon và color từ provider summaries
      IconData icon = Icons.category;
      Color color = Colors.grey;
      
      final existingSummary = provider.expenseSummaries.firstWhere(
        (s) => s.category == category,
        orElse: () => CategorySummary(
          category: category,
          totalAmount: 0,
          icon: Icons.category,
          color: Colors.grey,
        ),
      );
      
      icon = existingSummary.icon;
      color = existingSummary.color;
      
      // Chỉ thêm nếu có dữ liệu (ít nhất 1 tuần có chi tiêu)
      if (currentAmount > 0 || previousAmount > 0) {
        result.add(ExpenseTrendData(
          category: category,
          currentWeekAmount: currentAmount,
          previousWeekAmount: previousAmount,
          changePercentage: changePercentage,
          isPositiveChange: isPositiveChange,
          color: color,
          icon: icon,
        ));
      }
    }
    
    // Sắp xếp theo số tiền tuần này (giảm dần)
    result.sort((a, b) => b.currentWeekAmount.compareTo(a.currentWeekAmount));
    
    return result;
  }

  /// Title của chart
  Widget _buildChartTitle(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Icon(
            Icons.trending_up,
            color: blue2,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            getTranslated(context, 'Expense Trends') ?? 'Xu hướng Chi tiêu',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: blue2,
            ),
          ),
          Spacer(),
          Text(
            'Tuần này vs Tuần trước',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Column chart chính
  Widget _buildColumnChart(BuildContext context, List<ExpenseTrendData> data) {
    return SfCartesianChart(
      // Tooltip
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.seriesName: point.y $currency',
        duration: 2000,
      ),

      // Axes
      primaryXAxis: CategoryAxis(
        labelStyle: TextStyle(
          fontSize: 10.sp,
          color: Colors.grey[700],
        ),
        majorGridLines: const MajorGridLines(width: 0),
      ),

      primaryYAxis: NumericAxis(
        labelFormat: '{value}',
        labelStyle: TextStyle(fontSize: 10.sp),
        numberFormat: NumberFormat.compact(),
        majorGridLines: MajorGridLines(
          width: 0.5,
          color: Colors.grey[300],
        ),
      ),

      // Series - Tuần này và tuần trước
      series: <CartesianSeries>[
        // Tuần trước (background)
        ColumnSeries<ExpenseTrendData, String>(
          name: 'Tuần trước',
          dataSource: data,
          xValueMapper: (ExpenseTrendData data, _) => data.category,
          yValueMapper: (ExpenseTrendData data, _) => data.previousWeekAmount,
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
          width: 0.6,
          spacing: 0.2,
        ),

        // Tuần này (foreground)
        ColumnSeries<ExpenseTrendData, String>(
          name: 'Tuần này',
          dataSource: data,
          xValueMapper: (ExpenseTrendData data, _) => data.category,
          yValueMapper: (ExpenseTrendData data, _) => data.currentWeekAmount,
          pointColorMapper: (ExpenseTrendData data, _) => data.color,
          borderRadius: BorderRadius.circular(4),
          width: 0.6,
          spacing: 0.2,
          
          // Data labels với comparison
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.top,
            textStyle: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.bold,
            ),
            builder: (data, point, series, pointIndex, seriesIndex) {
              final expenseData = data as ExpenseTrendData;
              if (!expenseData.hasValidComparison) return Container();
              
              return _buildComparisonArrow(expenseData);
            },
          ),
        ),
      ],
    );
  }

  /// Legend với comparison indicators
  Widget _buildComparisonLegend(BuildContext context, List<ExpenseTrendData> data) {
    return Container(
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          return Container(
            width: 120.w,
            margin: EdgeInsets.only(right: 12.w),
            child: Column(
              children: [
                // Icon và category name
                Row(
                  children: [
                    Icon(
                      item.icon,
                      color: item.color,
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 4.h),
                
                // Amounts comparison
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tuần này',
                          style: TextStyle(
                            fontSize: 8.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          format(item.currentWeekAmount),
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: item.color,
                          ),
                        ),
                      ],
                    ),
                    
                    if (item.hasValidComparison)
                      _buildComparisonArrow(item),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Empty state
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_down,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            getTranslated(context, 'No expense data') ?? 'Không có dữ liệu chi tiêu',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Cần ít nhất 2 tuần để so sánh',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Tạo arrow indicator cho comparison
  Widget _buildComparisonArrow(ExpenseTrendData data) {
    if (!data.hasValidComparison) return Container();
    
    final color = data.isPositiveChange ? Colors.green : Colors.red;
    final icon = data.isPositiveChange ? Icons.arrow_drop_down : Icons.arrow_drop_up;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 12.sp,
        ),
        Text(
          '${data.changePercentage.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 8.sp,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}