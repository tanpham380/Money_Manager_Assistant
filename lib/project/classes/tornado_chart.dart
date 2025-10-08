import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../utils/responsive_extensions.dart';

import '../classes/constants.dart';
import '../localization/methods.dart';
import '../provider/analysis_provider.dart';
import '../provider/navigation_provider.dart';

/// Widget Tornado Chart - Hiển thị Thu và Chi trong cùng một biểu đồ dạng Tornado
/// Các cột Thu sẽ vẽ sang phải (dương), các cột Chi sẽ vẽ sang trái (âm)
class TornadoChartAnalysis extends StatelessWidget {
  const TornadoChartAnalysis({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final combinedData = provider.combinedSummaries;

    if (combinedData.isEmpty) {
      return _buildEmptyChartState();
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      child: Column(
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Income', green),
              SizedBox(width: 24.w),
              _buildLegendItem('Expense', red),
            ],
          ),
          SizedBox(height: 12.h),

          // Tornado Chart
          Expanded(
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: NumericAxis(
                // Trục hoành cho số tiền
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 1),
                labelFormat: '{value}',
                numberFormat: NumberFormat.compact(),
                edgeLabelPlacement: EdgeLabelPlacement.shift,
              ),
              primaryYAxis: CategoryAxis(
                // Trục tung cho tên danh mục
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
                labelStyle: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                duration: 1500,
                format: 'point.x: point.y',
              ),
              series: <CartesianSeries>[
                // Series 1: Expense (bên trái, giá trị âm)
                BarSeries<CombinedCategorySummary, String>(
                  name: 'Expense',
                  dataSource: combinedData,
                  xValueMapper: (CombinedCategorySummary data, _) =>
                      getTranslated(context, data.category) ?? data.category,
                  yValueMapper: (CombinedCategorySummary data, _) =>
                      -data.expense, // Giá trị âm để vẽ về bên trái
                  color: red.withValues(alpha: 0.8),
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.outer,
                    textStyle: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: red,
                    ),
                    builder: (data, point, series, pointIndex, seriesIndex) {
                      final summary = combinedData[pointIndex];
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        child: Text(
                          format(summary.expense),
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                            color: red,
                          ),
                        ),
                      );
                    },
                  ),
                  animationDuration: 800,
                  onPointTap: (ChartPointDetails details) {
                    if (details.pointIndex != null) {
                      final index = details.pointIndex!;
                      if (index >= 0 && index < combinedData.length) {
                        _navigateToCalendar(
                          context,
                          provider,
                          combinedData[index],
                          'Expense',
                        );
                      }
                    }
                  },
                ),

                // Series 2: Income (bên phải, giá trị dương)
                BarSeries<CombinedCategorySummary, String>(
                  name: 'Income',
                  dataSource: combinedData,
                  xValueMapper: (CombinedCategorySummary data, _) =>
                      getTranslated(context, data.category) ?? data.category,
                  yValueMapper: (CombinedCategorySummary data, _) =>
                      data.income, // Giá trị dương để vẽ về bên phải
                  color: green.withValues(alpha: 0.8),
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.outer,
                    textStyle: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: green,
                    ),
                    builder: (data, point, series, pointIndex, seriesIndex) {
                      final summary = combinedData[pointIndex];
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        child: Text(
                          format(summary.income),
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                            color: green,
                          ),
                        ),
                      );
                    },
                  ),
                  animationDuration: 800,
                  onPointTap: (ChartPointDetails details) {
                    if (details.pointIndex != null) {
                      final index = details.pointIndex!;
                      if (index >= 0 && index < combinedData.length) {
                        _navigateToCalendar(
                          context,
                          provider,
                          combinedData[index],
                          'Income',
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper để tạo legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16.w,
          height: 16.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Helper để điều hướng đến Calendar với filter
  void _navigateToCalendar(
    BuildContext context,
    AnalysisProvider provider,
    CombinedCategorySummary summary,
    String type,
  ) {
    final navProvider = context.read<NavigationProvider>();
    final dateRange = provider.getDateRange();

    navProvider.navigateToCalendarWithFilter(
      type: type,
      category: summary.category,
      icon: summary.icon,
      color: summary.color,
      startDate: dateRange['start'],
      endDate: dateRange['end'],
      isOthersGroup: summary.category == 'Others',
    );
  }

  /// Empty state cho chart
  Widget _buildEmptyChartState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
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
