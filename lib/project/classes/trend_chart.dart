import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:responsive_scaler/responsive_scaler.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../classes/constants.dart';
import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';
import '../provider/analysis_provider.dart';
import '../utils/date_format_utils.dart';


/// Widget cho Line/Spline Chart hiển thị xu hướng - Combined Income & Expense
/// CHỈ hiển thị line chart, KHÔNG có TabBar hay category list
class TrendChartAnalysis extends StatelessWidget {
  const TrendChartAnalysis({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu trực tiếp từ provider
    final provider = context.watch<AnalysisProvider>();
    final incomeTrendData = provider.incomeTrendData;
    final expenseTrendData = provider.expenseTrendData;

    final hasIncomeData = incomeTrendData.isNotEmpty;
    final hasExpenseData = expenseTrendData.isNotEmpty;
    final hasData = hasIncomeData || hasExpenseData;

    if (!hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: scale(64),
              color: Colors.grey[400],
            ),
            SizedBox(height: scale(16)),
            Text(
              getTranslated(context, 'There is no data') ?? 'Không có dữ liệu',
              style: TextStyle(
                fontSize: scale(16),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Build chart widget - CHỈ line chart
    return SfCartesianChart(
      // Title
      title: ChartTitle(
        text: getTranslated(context, 'Income & Expense Trend') ??
            'Xu hướng Thu Chi',
        textStyle: TextStyle(
          fontSize: scale(16),
          fontWeight: FontWeight.bold,
        ),
      ),

      // Legend
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        textStyle: TextStyle(fontSize: scale(12)),
      ),

      // Tooltip
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.seriesName: point.y $currency',
        duration: 2000,
      ),

      // Zoom & Pan
      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: true,
        enableDoubleTapZooming: true,
        enablePanning: true,
      ),

      // Axes
      primaryXAxis: DateTimeAxis(
        labelStyle: TextStyle(fontSize: scale(11)),
        dateFormat: DateFormatUtils.chartMonthFormat,
        intervalType: DateTimeIntervalType.months,
        majorGridLines: const MajorGridLines(width: 0.5),
      ),

      primaryYAxis: NumericAxis(
        labelFormat: '{value}',
        labelStyle: TextStyle(fontSize: scale(11)),
        numberFormat: NumberFormat.compact(),
      ),

      // Series - Both Income and Expense lines
      series: <CartesianSeries<TrendData, DateTime>>[
        // Income line
        if (hasIncomeData)
          SplineSeries<TrendData, DateTime>(
            name: getTranslated(context, 'Income') ?? 'Income',
            dataSource: incomeTrendData,
            xValueMapper: (TrendData data, _) => data.month,
            yValueMapper: (TrendData data, _) => data.totalAmount,

            color: green,
            width: 3,

            // Markers
            markerSettings: MarkerSettings(
              isVisible: true,
              height: 6,
              width: 6,
              shape: DataMarkerType.circle,
              borderWidth: 2,
              borderColor: green,
            ),

            // Animation
            animationDuration: 600,

            // Data labels
            dataLabelSettings: DataLabelSettings(
              isVisible: false,
            ),
          ),

        // Expense line
        if (hasExpenseData)
          SplineSeries<TrendData, DateTime>(
            name: getTranslated(context, 'Expense') ?? 'Expense',
            dataSource: expenseTrendData,
            xValueMapper: (TrendData data, _) => data.month,
            yValueMapper: (TrendData data, _) => data.totalAmount,

            color: red,
            width: 3,

            // Markers
            markerSettings: MarkerSettings(
              isVisible: true,
              height: 6,
              width: 6,
              shape: DataMarkerType.circle,
              borderWidth: 2,
              borderColor: red,
            ),

            // Animation
            animationDuration: 600,

            // Data labels
            dataLabelSettings: DataLabelSettings(
              isVisible: false,
            ),
          ),
      ],
    );
  }
}
