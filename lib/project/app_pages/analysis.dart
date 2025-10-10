import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/responsive_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../classes/detailed_trend_chart.dart'; // Chứa DetailedTrendChartAnalysis
import '../classes/constants.dart';
import '../classes/dropdown_box.dart';
import '../classes/sankey_chart.dart';
import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';
import '../provider/analysis_provider.dart';
import '../provider/navigation_provider.dart';
import '../provider/transaction_provider.dart';
import '../utils/date_format_utils.dart';

/// Màn hình phân tích thu chi - StatefulWidget để quản lý state tốt hơn
class Analysis extends StatefulWidget {
  const Analysis({Key? key}) : super(key: key);

  @override
  State<Analysis> createState() => _AnalysisState();
}

class _AnalysisState extends State<Analysis> with AutomaticKeepAliveClientMixin {
  // Keep state alive khi switch tabs
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Đơn giản hóa - chỉ cần AnalysisProvider với proper instance reuse
    return ChangeNotifierProxyProvider<TransactionProvider, AnalysisProvider>(
      create: (context) {
        final provider = AnalysisProvider(context.read<TransactionProvider>());
        return provider;
      },
      update: (context, transactionProvider, previous) {
        if (previous != null) {
          return previous;
        } else {
          final provider = AnalysisProvider(transactionProvider);
          return provider;
        }
      },
      child: Scaffold(
        backgroundColor: blue1,
        appBar: AppBar(
          backgroundColor: blue2,
          title: Text(
            context.tr('Analysis'), // Optimized localization
            style: TextStyle(fontSize: 21.sp, color: Colors.white),
          ),
        ),
        body: Consumer<AnalysisProvider>(
          builder: (context, provider, child) {
            // Xử lý các trạng thái khác nhau
            switch (provider.state) {
              case AnalysisState.loading:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(blue2),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Loading analysis...',
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );

              case AnalysisState.empty:
                return const EmptyStateWidget();

              case AnalysisState.error:
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 64.sp,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'Something went wrong',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        if (provider.errorMessage != null)
                          Text(
                            provider.errorMessage!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        SizedBox(height: 24.h),
                        ElevatedButton.icon(
                          onPressed: () {
                            provider.fetchData();
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            'Retry',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blue2,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );

              case AnalysisState.loaded:
                return Column(
                  children: [
                    // Date selector
                    ShowDate(
                      selectedDate: provider.selectedDateOption,
                      onDateChanged: (newDate) {
                        provider.updateDateOption(newDate);
                      },
                    ),

                    // Money Frame tổng hợp
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      child: ShowMoneyFrame(
                        type: 'All', // Hiển thị tổng hợp
                        typeValue: 0, // Không cần vì hiển thị tổng hợp
                        balance: provider.balance,
                        total: provider.total,
                      ),
                    ),

                    // Chart Type Toggle
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: _buildChartToggle(context, provider),
                    ),

                    // Combined Chart Area - Hiển thị cả Income và Expense
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        child: _buildCombinedChart(context, provider),
                      ),
                    ),
                  ],
                );

              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
  
  /// Widget toggle chọn loại biểu đồ
  Widget _buildChartToggle(BuildContext context, AnalysisProvider provider) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      child: CupertinoSegmentedControl<ChartType>(
        children: {
          ChartType.sankey: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_tree, size: 18.sp),
                SizedBox(width: 4.w),
                Text(
                  context.tr('Sankey'), // Optimized
                  style: TextStyle(fontSize: 13.sp),
                ),
              ],
            ),
          ),
          ChartType.line: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.show_chart, size: 18.sp),
                SizedBox(width: 4.w),
                Text(
                  context.tr('Trend'), // Optimized
                  style: TextStyle(fontSize: 13.sp),
                ),
              ],
            ),
          ),
          
        },
        // Safety check: nếu groupValue không hợp lệ, dùng sankey làm default
        groupValue: ChartType.values.contains(provider.selectedChartType) 
            ? provider.selectedChartType 
            : ChartType.sankey,
        onValueChanged: (ChartType value) {
          // Chỉ cần cập nhật loại biểu đồ
          provider.updateChartType(value);
          
          // XÓA BỎ HOÀN TOÀN CÁC LỆNH GỌI fetchTrendData
          // Dữ liệu trend đã được tính toán sẵn trong fetchData
        },
      ),
    );
  }

  /// Xây dựng biểu đồ tổng hợp hiển thị cả Income và Expense với animations
  Widget _buildCombinedChart(BuildContext context, AnalysisProvider provider) {
    // Callback xử lý selection - tận dụng provider's calculations
    void handleSelection(int index,
        {bool forceNavigate = false, required String type}) {
      if (index < 0) return;

      final summaries = type == 'Income'
          ? provider.incomeSummaries
          : provider.expenseSummaries;
      if (index >= summaries.length) return;

      final summary = summaries[index];

      // Luôn navigate khi click - sử dụng trực tiếp provider method
      provider.updateSelectedIndex(index);

      // Điều hướng sang Calendar - tận dụng provider's dateRange calculation
      final navProvider = context.read<NavigationProvider>();
      final dateRange = provider.getDateRange(); // Reuse existing calculation

      // Check if this is "Others" grouped category
      final isOthersGroup = summary.category == 'Others';

      navProvider.navigateToCalendarWithFilter(
        type: type,
        category: summary.category,
        icon: summary.icon,
        color: summary.color,
        startDate: dateRange['start'],
        endDate: dateRange['end'],
        isOthersGroup: isOthersGroup,
      );
    }

    // Animated switcher cho smooth transitions khi thay đổi chart type
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
      child: _buildChartByType(context, provider, handleSelection),
    );
  }

  /// Helper để build chart theo type với unique key
  Widget _buildChartByType(
      BuildContext context,
      AnalysisProvider provider,
      Function(int, {bool forceNavigate, required String type})
          handleSelection) {
    switch (provider.selectedChartType) {
      case ChartType.sankey:
        return Container(
          key: const ValueKey('sankey'),
          child: _buildCombinedSankeyChart(context, provider),
        );

      case ChartType.line:
        return Container(
          key: const ValueKey('line'),
          child: _buildCombinedTrendChart(provider),
        );
    }
  }

  /// Biểu đồ Trend tổng hợp - Combined Income & Expense in one chart
  Widget _buildCombinedTrendChart(AnalysisProvider provider) {
    final hasData = provider.incomeTrendData.isNotEmpty || 
                    provider.expenseTrendData.isNotEmpty;

    if (!hasData) {
      return _buildEmptyChartState();
    }

    // Detailed trend chart dựa theo selectedDateOption với cả Income và Expense
    return DetailedTrendChartAnalysis(
      key: ValueKey('detailed_trend_${provider.selectedDateOption}'),
    );
  }

  Widget _buildCombinedSankeyChart(BuildContext context, AnalysisProvider provider) {
    // Calculate dateRange once và pass xuống
    final dateRange = provider.getDateRange();
    
    // Use ValueKey với date option để force rebuild khi thay đổi
    return SankeyChartAnalysis(
      key: ValueKey('sankey_${provider.selectedDateOption}'),
      dateRange: dateRange, // Pass calculated dateRange
      // XÓA BỎ callback onCategoryTap ĐỂ TRÁNH DOUBLE-CALL
      // Logic xử lý tap được gói gọn bên trong SankeyChartAnalysis
    );
  }

  /// Empty state cho charts
  Widget _buildEmptyChartState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No chart data available',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add transactions to see analysis',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị Empty State với animation
class EmptyStateWidget extends StatefulWidget {
  const EmptyStateWidget({Key? key}) : super(key: key);

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inbox_outlined,
                    size: 80.sp,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  getTranslated(context, 'No data available') ??
                      'No data available',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Start tracking your finances by\nadding your first transaction',
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/input');
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(
                    getTranslated(context, 'Add new transaction') ??
                        'Add Transaction',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue2,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 28.w,
                      vertical: 14.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget hiển thị ngày và dropdown chọn khoảng thời gian
class ShowDate extends StatelessWidget {
  final String selectedDate;
  final Function(String) onDateChanged;

  const ShowDate({
    Key? key,
    required this.selectedDate,
    required this.onDateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 6.w, // Thu nhỏ từ 8.w xuống 6.w
        vertical: 12.h, // Thu nhỏ từ 16.h xuống 12.h
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 22.sp, // Thu nhỏ từ 24.sp xuống 22.sp
            color: const Color.fromRGBO(82, 179, 252, 1),
          ),
          SizedBox(width: 6.w), // Thu nhỏ từ 8.w xuống 6.w
          DateDisplay(selectedDate),
          const Spacer(),
          DropDownBox(true, selectedDate),
        ],
      ),
    );
  }
}

/// Widget hiển thị text ngày đã chọn
class DateDisplay extends StatelessWidget {
  final String selectedDate;

  const DateDisplay(this.selectedDate, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String today = DateFormatUtils.formatUserDate(todayDT);
    String since = getTranslated(context, 'Since') ?? 'Since';
    TextStyle style = GoogleFonts.aBeeZee(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold); // Thu nhỏ từ 18.sp xuống 16.sp

    final Map<String, Widget> dateMap = {
      'Today': Text(today, style: style),
      'This week': Text(
        '$since ${DateFormatUtils.formatUserDate(startOfThisWeek)}',
        style: style,
      ),
      'This month': Text(
        '$since ${DateFormatUtils.formatUserDate(startOfThisMonth)}',
        style: style,
      ),
      'This quarter': Text(
        '$since ${DateFormatUtils.formatUserDate(startOfThisQuarter)}',
        style: style,
      ),
      'This year': Text(
        '$since ${DateFormatUtils.formatUserDate(startOfThisYear)}',
        style: style,
      ),
      'All': Text(getTranslated(context, 'All') ?? 'All', style: style),
    };

    return dateMap[selectedDate] ?? Container();
  }
}

/// Widget hiển thị thông tin tổng thu, chi, chênh lệch - Đã nâng cấp
class ShowMoneyFrame extends StatelessWidget {
  final String type;
  final double typeValue;
  final double balance;
  final double total;

  const ShowMoneyFrame({
    Key? key,
    required this.type,
    required this.typeValue,
    required this.balance,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lấy provider để truy cập totalIncome và totalExpense
    final analysisProvider = context.watch<AnalysisProvider>();

    Widget rowFrame(String typeName, double value, {Color? valueColor}) {
      return Padding(
        padding:
            EdgeInsets.symmetric(vertical: 4.h), // Thu nhỏ từ 6.h xuống 4.h
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              getTranslated(context, typeName) ?? typeName,
              style: TextStyle(
                fontSize: 14.sp, // Thu nhỏ từ 16.sp xuống 14.sp
                fontWeight: FontWeight.w500,
              ),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${format(value)} $currency',
                  style: GoogleFonts.aBeeZee(
                    fontSize: 14.sp, // Thu nhỏ từ 16.sp xuống 14.sp
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Xác định màu cho chênh lệch - sử dụng balance từ provider
    Color balanceColor = analysisProvider.balance >= 0 ? green : red;

    return Card(
      elevation: 2, // Giảm elevation từ 4 xuống 2
      margin: EdgeInsets.zero, // Loại bỏ margin
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
            12.r), // Giảm border radius từ 16.r xuống 12.r
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w), // Thu nhỏ padding từ 16.w xuống 12.w
        child: Column(
          children: [
            // Xử lý hiển thị theo loại - tận dụng values từ provider
            if (type == 'All') ...[
              // Hiển thị tổng hợp - sử dụng trực tiếp từ provider
              rowFrame(getTranslated(context, 'Total Income') ?? 'Total Income',
                  analysisProvider.totalIncome,
                  valueColor: green),
              Divider(height: 12.h),
              rowFrame(
                  getTranslated(context, 'Total Expense') ?? 'Total Expense',
                  analysisProvider.totalExpense,
                  valueColor: red),
            ] else ...[
              // Hiển thị cho màn hình riêng biệt Income/Expense
              rowFrame(
                  getTranslated(context, 'Total Income') ?? 'Total Income',
                  total > 0
                      ? (type == 'Income' ? typeValue : total - typeValue)
                      : 0,
                  valueColor: green),
              Divider(height: 12.h),
              rowFrame(
                  getTranslated(context, 'Total Expense') ?? 'Total Expense',
                  total > 0
                      ? (type == 'Expense' ? typeValue : total - typeValue)
                      : 0,
                  valueColor: red),
            ],
            Divider(height: 12.h), // Thu nhỏ divider từ 16.h xuống 12.h
            rowFrame(getTranslated(context, 'Balance') ?? 'Balance', 
                analysisProvider.balance, // Sử dụng trực tiếp từ provider
                valueColor: balanceColor),
          ],
        ),
      ),
    );
  }
}
