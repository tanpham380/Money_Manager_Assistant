import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
 import '../utils/responsive_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../classes/app_bar.dart';
import '../classes/bar_chart.dart';
import '../classes/constants.dart';
import '../classes/donut_chart.dart';
import '../classes/dropdown_box.dart';
import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';
import '../provider/analysis_provider.dart';
import '../provider/navigation_provider.dart';
import '../provider/transaction_provider.dart';

/// Màn hình phân tích thu chi - Đã được tái cấu trúc hoàn toàn
class Analysis extends StatelessWidget {
  const Analysis({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use TransactionProvider from ancestor (Home widget)
    return ChangeNotifierProxyProvider<TransactionProvider, AnalysisProvider>(
      create: (context) => AnalysisProvider(context.read<TransactionProvider>()),
      update: (context, transactionProvider, previous) {
        // Reuse previous AnalysisProvider if it exists
        if (previous != null) {
          return previous;
        }
        return AnalysisProvider(transactionProvider);
      },
      child: DefaultTabController(
        initialIndex: 0,
        length: 2,
        child: Scaffold(
          backgroundColor: blue1,
          appBar: InExAppBar(false),
          body: Consumer<AnalysisProvider>(
            builder: (context, provider, child) {
              // Xử lý các trạng thái khác nhau
              switch (provider.state) {
                case AnalysisState.loading:
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                  
                case AnalysisState.empty:
                  return const EmptyStateWidget();
                  
                case AnalysisState.error:
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                        SizedBox(height: 16.h),
                        Text(
                          'Đã xảy ra lỗi',
                          style: TextStyle(fontSize: 20.sp),
                        ),
                        if (provider.errorMessage != null)
                          Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Text(
                              provider.errorMessage!,
                              style: TextStyle(fontSize: 14.sp),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
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
                      
                      // Tab view
                      Expanded(
                        child: TabBarView(
                          children: const [
                            AnalysisTabView(type: 'Expense'),
                            AnalysisTabView(type: 'Income'),
                          ],
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
      ),
    );
  }
}

/// Widget hiển thị Empty State
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 100.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 24.h),
          Text(
            getTranslated(context, 'No data available') ?? 'Không có dữ liệu nào',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/input');
            },
            icon: const Icon(Icons.add),
            label: Text(
              getTranslated(context, 'Add new transaction') ?? 'Thêm giao dịch mới',
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
      ),
    );
  }
}

/// Tab view cho từng loại (Income/Expense) với chart toggle
class AnalysisTabView extends StatefulWidget {
  final String type;

  const AnalysisTabView({
    Key? key,
    required this.type,
  }) : super(key: key);

  @override
  State<AnalysisTabView> createState() => _AnalysisTabViewState();
}

class _AnalysisTabViewState extends State<AnalysisTabView> {
  @override
  void initState() {
    super.initState();
    // Fetch trend data khi khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalysisProvider>().fetchTrendData(widget.type, 6);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, child) {
        final summaries = widget.type == 'Income' 
            ? provider.incomeSummaries 
            : provider.expenseSummaries;
        final typeValue = widget.type == 'Income' 
            ? provider.totalIncome 
            : provider.totalExpense;

        return CustomScrollView(
          slivers: [
            // Money Frame
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: ShowMoneyFrame(
                  type: widget.type,
                  typeValue: typeValue,
                  balance: provider.balance,
                  total: provider.total,
                ),
              ),
            ),
            
            // Chart Type Toggle
            SliverToBoxAdapter(
              child: _buildChartToggle(provider),
            ),
            
            // Chart Area - Flexible để vừa với không gian còn lại
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5, // 50% chiều cao màn hình
                child: Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: _buildChart(provider, summaries),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Widget toggle chọn loại biểu đồ
  Widget _buildChartToggle(AnalysisProvider provider) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: CupertinoSegmentedControl<ChartType>(
        children: {
          ChartType.donut: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.donut_small, size: 18.sp),
                SizedBox(width: 4.w),
                Text(
                  getTranslated(context, 'Donut') ?? 'Donut',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ],
            ),
          ),
          ChartType.bar: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart, size: 18.sp),
                SizedBox(width: 4.w),
                Text(
                  getTranslated(context, 'Bar') ?? 'Bar',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ],
            ),
          ),
          ChartType.line: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.show_chart, size: 18.sp),
                SizedBox(width: 4.w),
                Text(
                  getTranslated(context, 'Trend') ?? 'Trend',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ],
            ),
          ),
        },
        groupValue: provider.selectedChartType,
        onValueChanged: (ChartType value) {
          provider.updateChartType(value);
          if (value == ChartType.line) {
            provider.fetchTrendData(widget.type, 6);
          }
        },
      ),
    );
  }



  /// Xây dựng biểu đồ dựa trên loại được chọn
  Widget _buildChart(AnalysisProvider provider, List<CategorySummary> summaries) {
    // Callback hiển thị chi tiết khi người dùng tap vào biểu đồ
    void handleSelection(int index) {
      if (index < 0 || index >= summaries.length) return;
      final summary = summaries[index];
      
      // Cập nhật selection trong provider để làm nổi bật
      provider.updateSelectedIndex(index);
      
      // Điều hướng sang Calendar với filter chi tiết
      final navProvider = context.read<NavigationProvider>();
      final dateRange = provider.getDateRange();
      
      navProvider.navigateToCalendarWithFilter(
        type: widget.type,
        category: summary.category,
        icon: summary.icon,
        color: summary.color,
        startDate: dateRange['start'],
        endDate: dateRange['end'],
      );
    }
    
    switch (provider.selectedChartType) {
      case ChartType.donut:
        return DonutChartAnalysis(
          type: widget.type,
          summaries: summaries,
          onSelection: handleSelection,
        );
        
      case ChartType.bar:
        return BarChartAnalysis(
          type: widget.type,
          summaries: summaries,
          onSelection: handleSelection,
        );
        
      case ChartType.line:
        return TrendChartAnalysis(
          type: widget.type,
          trendData: provider.trendData,
        );
    }
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
        horizontal: 10.w,
        vertical: 25.h,
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 27.sp,
            color: const Color.fromRGBO(82, 179, 252, 1),
          ),
          SizedBox(width: 10.w),
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
    final String today = DateFormat(sharedPrefs.dateFormat).format(todayDT);
    String since = getTranslated(context, 'Since') ?? 'Since';
    TextStyle style =
        GoogleFonts.aBeeZee(fontSize: 20.sp, fontWeight: FontWeight.bold);

    final Map<String, Widget> dateMap = {
      'Today': Text(today, style: style),
      'This week': Text(
        '$since ${DateFormat(sharedPrefs.dateFormat).format(startOfThisWeek)}',
        style: style,
      ),
      'This month': Text(
        '$since ${DateFormat(sharedPrefs.dateFormat).format(startOfThisMonth)}',
        style: style,
      ),
      'This quarter': Text(
        '$since ${DateFormat(sharedPrefs.dateFormat).format(startOfThisQuarter)}',
        style: style,
      ),
      'This year': Text(
        '$since ${DateFormat(sharedPrefs.dateFormat).format(startOfThisYear)}',
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
    Widget rowFrame(String typeName, double value, {Color? valueColor}) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              getTranslated(context, typeName) ?? typeName,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${format(value)} $currency',
                  style: GoogleFonts.aBeeZee(
                    fontSize: 18.sp,
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

    // Xác định màu cho chênh lệch
    Color balanceColor = balance >= 0 ? green : red;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            rowFrame(getTranslated(context, 'Total Income') ?? 'Total Income', total > 0 ? (type == 'Income' ? typeValue : total - typeValue) : 0),
            Divider(height: 1.h),
            rowFrame(getTranslated(context, 'Total Expense') ?? 'Total Expense', total > 0 ? (type == 'Expense' ? typeValue : total - typeValue) : 0),
            Divider(height: 1.h),
            rowFrame(getTranslated(context, 'Balance') ?? 'Balance', balance, valueColor: balanceColor),
          ],
        ),
      ),
    );
  }
}

/// Widget hiển thị thông tin chi tiết từng category - Đã nâng cấp
class CategoryDetails extends StatelessWidget {
  final CategorySummary summary;
  final String type;
  final VoidCallback? onTap;
  final bool isSelected;

  const CategoryDetails({
    Key? key,
    required this.summary,
    required this.type,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      elevation: isSelected ? 8 : 2,
      color: isSelected ? summary.color.withValues(alpha: 0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: isSelected 
            ? BorderSide(color: summary.color, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: summary.color.withValues(alpha: 0.2),
          child: Icon(
            summary.icon,
            color: summary.color,
            size: 24.sp,
          ),
        ),
        title: Text(
          getTranslated(context, summary.category) ?? summary.category,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${format(summary.totalAmount)} $currency',
                  style: GoogleFonts.aBeeZee(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? summary.color : null,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: isSelected ? summary.color : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
