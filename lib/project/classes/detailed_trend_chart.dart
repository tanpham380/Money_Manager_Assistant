import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../classes/constants.dart';
import '../classes/input_model.dart';
import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';
import '../provider/analysis_provider.dart';
import '../utils/date_format_utils.dart';
import '../utils/responsive_extensions.dart';

/// Class chứa dữ liệu trend theo category với comparison periods
class CategoryTrendData {
  final String category;
  final DateTime period;
  final double amount;
  final String type; // 'Income' hoặc 'Expense'
  final Color color;
  final IconData icon;

  CategoryTrendData({
    required this.category,
    required this.period,
    required this.amount,
    required this.type,
    required this.color,
    required this.icon,
  });
}

/// Detailed Trend Chart hiển thị xu hướng từng category theo selectedDateOption
class DetailedTrendChartAnalysis extends StatelessWidget {
  const DetailedTrendChartAnalysis({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    
    // Lấy dữ liệu trend chi tiết dựa theo selectedDateOption
    final trendData = _buildDetailedTrendData(context, provider);

    if (trendData.isEmpty) {
      return _buildEmptyState(context, provider.selectedDateOption);
    }

    return Column(
      children: [
        // Title với thông tin period
        _buildChartTitle(context, provider.selectedDateOption),
        
        SizedBox(height: 16.h),
        
        // Line chart chính - giảm kích thước
        SizedBox(
          height: 200.h,
          child: _buildLineChart(context, trendData),
        ),
        
        SizedBox(height: 16.h),
        
        // Legend với category colors
        _buildCategoryLegend(context, trendData),
      ],
    );
  }

  /// Xây dựng dữ liệu trend chi tiết theo selectedDateOption
  List<CategoryTrendData> _buildDetailedTrendData(BuildContext context, AnalysisProvider provider) {
    final selectedOption = provider.selectedDateOption;
    final allTransactions = provider.allTransactions;
    
    List<DateTime> periods;
    String periodLabel;
    
    // Xác định periods dựa theo selectedDateOption
    switch (selectedOption) {
      case 'Today':
        // Hôm nay + 6 ngày trước = 7 ngày
        periods = _getLast7Days();
        periodLabel = 'day';
        break;
      case 'This week':
        // Tuần này + 2 tuần trước và sau = 5 tuần
        periods = _getSurrounding5Weeks();
        periodLabel = 'week';
        break;
      case 'This month':
        // Tháng này + 2 tháng trước và sau = 5 tháng
        periods = _getSurrounding5Months();
        periodLabel = 'month';
        break;
      case 'This quarter':
        // Quarter này + 2 quarters trước và sau = 5 quarters
        periods = _getSurrounding5Quarters();
        periodLabel = 'quarter';
        break;
      case 'This year':
        // Năm này + 2 năm trước và sau = 5 năm
        periods = _getSurrounding5Years();
        periodLabel = 'year';
        break;
      default: // 'All'
        // So sánh theo tháng từ transaction đầu tiên
        periods = _getAllMonthsFromTransactions(allTransactions);
        periodLabel = 'month';
    }

    // Nhóm transactions theo period và category
    final Map<String, Map<DateTime, double>> categoryData = {};
    
    for (final transaction in allTransactions) {
      if (transaction.date == null || transaction.category == null) continue;
      
      try {
        final date = DateFormatUtils.parseInternalDate(transaction.date!);
        final category = transaction.category!;
        final amount = transaction.amount ?? 0.0;
        final type = transaction.type ?? 'Unknown';
        
        // Tìm period phù hợp cho transaction này
        final period = _findPeriodForDate(date, periods, periodLabel);
        if (period == null) continue;
        
        // Tạo key unique cho category + type
        final categoryKey = '$type:$category';
        
        categoryData[categoryKey] ??= {};
        categoryData[categoryKey]![period] = 
            (categoryData[categoryKey]![period] ?? 0.0) + amount;
            
      } catch (e) {
        continue;
      }
    }

    // Chuyển đổi thành CategoryTrendData
    final result = <CategoryTrendData>[];
    
    for (final categoryKey in categoryData.keys) {
      final parts = categoryKey.split(':');
      final type = parts[0];
      final rawCategory = parts[1];
      
      // Translate category name
      final category = getTranslated(context, rawCategory) ?? rawCategory;
      
      // Lấy color và icon từ existing summaries
      Color color = Colors.grey;
      IconData icon = Icons.category;
      
      if (type == 'Income') {
        final summary = provider.incomeSummaries.firstWhere(
          (s) => s.category == rawCategory, // So sánh với raw category
          orElse: () => CategorySummary(
            category: rawCategory, totalAmount: 0, icon: Icons.category, color: Colors.green,
          ),
        );
        color = summary.color;
        icon = summary.icon;
      } else {
        final summary = provider.expenseSummaries.firstWhere(
          (s) => s.category == rawCategory, // So sánh với raw category
          orElse: () => CategorySummary(
            category: rawCategory, totalAmount: 0, icon: Icons.category, color: Colors.red,
          ),
        );
        color = summary.color;
        icon = summary.icon;
      }
      
      // Thêm data points cho category này
      for (final period in periods) {
        final amount = categoryData[categoryKey]![period] ?? 0.0;
        result.add(CategoryTrendData(
          category: category,
          period: period,
          amount: amount,
          type: type,
          color: color,
          icon: icon,
        ));
      }
    }
    
    return result;
  }

  /// Lấy 7 ngày gần nhất
  List<DateTime> _getLast7Days() {
    final now = DateTime.now();
    return List.generate(7, (index) => 
        DateTime(now.year, now.month, now.day - index)).reversed.toList();
  }

  /// Lấy 5 tuần xung quanh tuần hiện tại (2 tuần trước, tuần này, 2 tuần sau)
  List<DateTime> _getSurrounding5Weeks() {
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Monday
    final currentWeekStart = now.subtract(Duration(days: weekday - 1));
    
    return List.generate(5, (index) => 
        currentWeekStart.subtract(Duration(days: (2 - index) * 7)));
  }

  /// Lấy 5 tháng xung quanh tháng hiện tại (2 tháng trước, tháng này, 2 tháng sau)
  List<DateTime> _getSurrounding5Months() {
    final now = DateTime.now();
    return List.generate(5, (index) => 
        DateTime(now.year, now.month - 2 + index, 1));
  }

  /// Lấy 5 quarters xung quanh quarter hiện tại
  List<DateTime> _getSurrounding5Quarters() {
    final now = DateTime.now();
    final currentQuarter = ((now.month - 1) ~/ 3) + 1; // 1,2,3,4
    final result = <DateTime>[];
    
    // Tạo 5 quarters: 2 trước, hiện tại, 2 sau
    for (int i = -2; i <= 2; i++) {
      final targetQuarter = currentQuarter + i;
      
      late int year;
      late int quarter;
      
      if (targetQuarter <= 0) {
        // Quarter âm: về năm trước
        year = now.year - 1 + ((targetQuarter - 1) ~/ 4);
        quarter = targetQuarter + 4 * (1 - ((targetQuarter - 1) ~/ 4));
      } else if (targetQuarter > 4) {
        // Quarter > 4: sang năm sau
        year = now.year + ((targetQuarter - 1) ~/ 4);
        quarter = ((targetQuarter - 1) % 4) + 1;
      } else {
        // Quarter bình thường
        year = now.year;
        quarter = targetQuarter;
      }
      
      final month = (quarter - 1) * 3 + 1; // Q1=1, Q2=4, Q3=7, Q4=10
      result.add(DateTime(year, month, 1));
    }
    
    return result;
  }

  /// Lấy 5 năm xung quanh năm hiện tại (2 năm trước, năm này, 2 năm sau)
  List<DateTime> _getSurrounding5Years() {
    final now = DateTime.now();
    return List.generate(5, (index) => 
        DateTime(now.year - 2 + index, 1, 1));
  }

  /// Lấy tất cả tháng từ transactions
  List<DateTime> _getAllMonthsFromTransactions(List<InputModel> transactions) {
    if (transactions.isEmpty) return [];
    
    final months = <DateTime>{};
    for (final tx in transactions) {
      if (tx.date == null) continue;
      try {
        final date = DateFormatUtils.parseInternalDate(tx.date!);
        months.add(DateTime(date.year, date.month, 1));
      } catch (e) {
        continue;
      }
    }
    
    final sortedMonths = months.toList()..sort();
    return sortedMonths;
  }

  /// Tìm period phù hợp cho date
  DateTime? _findPeriodForDate(DateTime date, List<DateTime> periods, String periodType) {
    switch (periodType) {
      case 'day':
        final dayOnly = DateTime(date.year, date.month, date.day);
        return periods.contains(dayOnly) ? dayOnly : null;
        
      case 'week':
        final weekday = date.weekday;
        final weekStart = date.subtract(Duration(days: weekday - 1));
        final weekStartOnly = DateTime(weekStart.year, weekStart.month, weekStart.day);
        return periods.firstWhere((p) => p.isAtSameMomentAs(weekStartOnly), 
            orElse: () => DateTime(1970));
        
      case 'month':
        final monthOnly = DateTime(date.year, date.month, 1);
        return periods.contains(monthOnly) ? monthOnly : null;
        
      case 'quarter':
        final quarter = ((date.month - 1) ~/ 3) + 1;
        final quarterStart = DateTime(date.year, (quarter - 1) * 3 + 1, 1);
        return periods.contains(quarterStart) ? quarterStart : null;
        
      case 'year':
        final yearOnly = DateTime(date.year, 1, 1);
        return periods.contains(yearOnly) ? yearOnly : null;
        
      default:
        return null;
    }
  }

  /// Title của chart
  Widget _buildChartTitle(BuildContext context, String selectedOption) {
    String subtitle;
    switch (selectedOption) {
      case 'Today':
        subtitle = getTranslated(context, 'Last 7 days') ?? 'Last 7 days';
        break;
      case 'This week':
        subtitle = getTranslated(context, 'Surrounding 5 weeks') ?? '5 tuần xung quanh';
        break;
      case 'This month':
        subtitle = getTranslated(context, 'Surrounding 5 months') ?? '5 tháng xung quanh';
        break;
      case 'This quarter':
        subtitle = getTranslated(context, 'Surrounding 5 quarters') ?? '5 quarters xung quanh';
        break;
      case 'This year':
        subtitle = getTranslated(context, 'Surrounding 5 years') ?? '5 năm xung quanh';
        break;
      default:
        subtitle = getTranslated(context, 'All time') ?? 'Tất cả thời gian';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Icon(
            Icons.trending_up,
            color: blue2,
            size: 12.sp,
          ),
          SizedBox(width: 4.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, 'Category Trends') ?? 'Xu hướng theo Danh mục',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: blue2,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Spacer(),
          // Chú thích Income vs Expense
          Row(
            children: [
              _buildTypeIndicator(
                context, 
                getTranslated(context, 'Income') ?? 'Thu nhập', 
                Colors.green, 
                Icons.trending_up
              ),
              SizedBox(width: 8.w),
              _buildTypeIndicator(
                context, 
                getTranslated(context, 'Expense') ?? 'Chi tiêu', 
                Colors.red, 
                Icons.trending_down
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Indicator cho Income/Expense types
  Widget _buildTypeIndicator(BuildContext context, String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 12.sp,
        ),
        SizedBox(width: 2.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Line chart chính với phân biệt rõ Income/Expense
  Widget _buildLineChart(BuildContext context, List<CategoryTrendData> data) {
    // Nhóm data theo category và type
    final Map<String, List<CategoryTrendData>> groupedData = {};
    for (final item in data) {
      final key = '${item.type}:${item.category}';
      groupedData[key] ??= [];
      groupedData[key]!.add(item);
    }

    return SfCartesianChart(
      // Tooltip
      tooltipBehavior: TooltipBehavior(
        enable: true,
        shared: false,
        canShowMarker: true,
        duration: 3000,
        format: 'point.seriesName\npoint.x: point.y $currency',
        textStyle: TextStyle(
          fontSize: 10.sp,
          color: Colors.white,
        ),
        color: Colors.black87,
        borderColor: Colors.transparent,
      ),

      // Legend - tắt legend mặc định, dùng custom
      legend: Legend(isVisible: false),

      // Zoom & Pan
      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: true,
        enableDoubleTapZooming: true,
        enablePanning: true,
        enableSelectionZooming: true,
      ),

      // Axes
      primaryXAxis: DateTimeAxis(
        labelStyle: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
        dateFormat: DateFormatUtils.getChartDateFormat(data.first.period, context),
        intervalType: _getIntervalType(data.first.period),
        majorGridLines: MajorGridLines(
          width: 0.5,
          color: Colors.grey[300],
        ),
        axisLine: AxisLine(color: Colors.grey[400]),
      ),

      primaryYAxis: NumericAxis(
        labelFormat: '{value}',
        labelStyle: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
        numberFormat: NumberFormat.compact(),
        majorGridLines: MajorGridLines(
          width: 0.5,
          color: Colors.grey[300],
        ),
        axisLine: AxisLine(color: Colors.grey[400]),
      ),

      // Series - Separated Income and Expense với styling khác nhau
      series: groupedData.entries.map((entry) {
        final categoryData = entry.value;
        final firstItem = categoryData.first;
        final isIncome = firstItem.type == 'Income';
        
        return LineSeries<CategoryTrendData, DateTime>(
          name: firstItem.category,
          dataSource: categoryData,
          xValueMapper: (CategoryTrendData data, _) => data.period,
          yValueMapper: (CategoryTrendData data, _) => data.amount,
          
          // Color và style khác nhau cho Income vs Expense
          color: firstItem.color,
          width: isIncome ? 3 : 2, // Income line thicker
          
          // Marker style khác nhau
          markerSettings: MarkerSettings(
            isVisible: true,
            height: isIncome ? 8 : 6,
            width: isIncome ? 8 : 6,
            shape: isIncome ? DataMarkerType.diamond : DataMarkerType.circle,
            borderWidth: 2,
            borderColor: firstItem.color,
            color: isIncome ? firstItem.color : Colors.white,
          ),
          
          // Dash pattern cho Income (optional styling)
          dashArray: isIncome ? null : [2, 2], // Expense lines dashed
          
          // Animation
          animationDuration: 800,
          
          // Data labels chỉ hiển thị khi có interaction
          dataLabelSettings: DataLabelSettings(
            isVisible: false,
          ),
          
          // Selection behavior
          selectionBehavior: SelectionBehavior(
            enable: true,
            selectedColor: firstItem.color.withValues(alpha: .8),
            unselectedColor: firstItem.color.withValues(alpha: .3),
          ),
        );
      }).toList(),

      // Plot area customization
      plotAreaBorderColor: Colors.transparent,
      backgroundColor: Colors.transparent,
    );
  }

  /// Xác định interval type
  DateTimeIntervalType _getIntervalType(DateTime samplePeriod) {
    return DateTimeIntervalType.auto; // Default
  }

  /// Legend tùy chỉnh với phân biệt Income/Expense (layout dọc)
  Widget _buildCategoryLegend(BuildContext context, List<CategoryTrendData> data) {
    // Nhóm theo type và category
    final Map<String, List<CategoryTrendData>> groupedByType = {};
    for (final item in data) {
      groupedByType[item.type] ??= [];
      if (!groupedByType[item.type]!.any((existing) => existing.category == item.category)) {
        groupedByType[item.type]!.add(item);
      }
    }

    return Container(
      // Dynamic height - loại bỏ fixed height
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: IntrinsicHeight( // Tự động tính height cần thiết
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Chỉ lấy height cần thiết
          children: [
            // Income section
            if (groupedByType.containsKey('Income')) ...[
              _buildTypeLegendHeader(
                context, 
                getTranslated(context, 'Income') ?? 'Income',
                Colors.green,
                Icons.trending_up,
              ),
              SizedBox(height: 2.h), // Giảm từ 4.h
              SizedBox(
                height: 20.h, // Giảm từ 28.h vì giờ dùng Row
                child: _buildCategoryList(
                  context, 
                  groupedByType['Income']!, 
                  'Income'
                ),
              ),
            ],
            
            // Separator
            if (groupedByType.containsKey('Income') && groupedByType.containsKey('Expense'))
              Padding(
                padding: EdgeInsets.symmetric(vertical: 3.h), // Giảm từ 6.h
                child: Divider(
                  height: 1,
                  color: Colors.grey[300],
                ),
              ),
            
            // Expense section
            if (groupedByType.containsKey('Expense')) ...[
              _buildTypeLegendHeader(
                context,
                getTranslated(context, 'Expense') ?? 'Expense', 
                Colors.red,
                Icons.trending_down,
              ),
              SizedBox(height: 2.h), // Giảm từ 4.h
              SizedBox(
                height: 20.h, // Giảm từ 28.h vì giờ dùng Row
                child: _buildCategoryList(
                  context,
                  groupedByType['Expense']!,
                  'Expense'
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Header cho từng type (Income/Expense)
  Widget _buildTypeLegendHeader(BuildContext context, String title, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14.sp),
        SizedBox(width: 4.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// List categories cho từng type
  Widget _buildCategoryList(BuildContext context, List<CategoryTrendData> categories, String type) {
    final isIncome = type == 'Income';
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final item = categories[index];
        return Container(
          margin: EdgeInsets.only(right: 8.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon với style phù hợp
              Container(
                padding: EdgeInsets.all(3.w), // Giảm thêm
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3.r), // Giảm thêm
                  border: Border.all(
                    color: item.color.withValues(alpha: 0.5),
                    width: isIncome ? 2 : 1, // Income có border thicker
                  ),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 10.sp, // Giảm thêm từ 12.sp
                ),
              ),
              
              SizedBox(width: 4.w), // Thay height thành width
              
              // Category name
              Text(
                item.category,
                style: TextStyle(
                  fontSize: 7.sp, // Giảm thêm từ 8.sp
                  fontWeight: isIncome ? FontWeight.w600 : FontWeight.w400,
                  color: item.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Empty state
  Widget _buildEmptyState(BuildContext context, String selectedOption) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            getTranslated(context, 'No trend data') ?? 'Không có dữ liệu xu hướng',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Cần dữ liệu từ nhiều $selectedOption để hiển thị xu hướng',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}