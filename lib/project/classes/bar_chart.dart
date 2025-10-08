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

/// Biểu đồ cột (Bar Chart) hiển thị chi tiêu/thu nhập theo danh mục
class BarChartAnalysis extends StatelessWidget {
  final String type;
  final List<CategorySummary> summaries;
  final Function(int index, {bool forceNavigate})? onSelection;

  const BarChartAnalysis({
    Key? key,
    required this.type,
    required this.summaries,
    this.onSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final hasData = summaries.isNotEmpty && summaries[0].category.isNotEmpty;
    final totalAmount =
        type == 'Income' ? provider.totalIncome : provider.totalExpense;

    if (!hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
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

    return Column(
      children: [
        // Biểu đồ cột - tối ưu cho layout side-by-side
        SizedBox(
          height: scale(140), // Chiều cao cố định để fit trong layout combined
          child: SfCartesianChart(
            // Title
            title: ChartTitle(
              text: getTranslated(
                      context,
                      type == 'Income'
                          ? 'Income by Category'
                          : 'Expense by Category') ??
                  (type == 'Income'
                      ? 'Thu nhập theo danh mục'
                      : 'Chi tiêu theo danh mục'),
              textStyle: TextStyle(
                fontSize: scale(16),
                fontWeight: FontWeight.bold,
              ),
            ),

            // Tooltip
            tooltipBehavior: TooltipBehavior(
              enable: true,
              format: 'point.x: point.y $currency',
              duration: 2000,
            ),

            // Selection
            selectionGesture: ActivationMode.singleTap,

            // Axes
            primaryXAxis: CategoryAxis(
              labelStyle: TextStyle(fontSize: scale(11)),
              labelRotation: -45,
              majorGridLines: const MajorGridLines(width: 0),
            ),

            primaryYAxis: NumericAxis(
              labelFormat: '{value}',
              labelStyle: TextStyle(fontSize: scale(11)),
              numberFormat: NumberFormat.compact(),
            ),

            // Series
            series: <CartesianSeries<CategorySummary, String>>[
              ColumnSeries<CategorySummary, String>(
                dataSource: summaries,
                xValueMapper: (CategorySummary data, _) =>
                    getTranslated(context, data.category) ?? data.category,
                yValueMapper: (CategorySummary data, _) => data.totalAmount,
                pointColorMapper: (CategorySummary data, _) => data.color,

                // Tương tác
                selectionBehavior: SelectionBehavior(
                  enable: true,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  unselectedOpacity: 0.5,
                ),

                onPointTap: (ChartPointDetails details) {
                  if (details.pointIndex != null) {
                    provider.updateSelectedIndex(details.pointIndex);
                    // CHỈ hiển thị thông tin, KHÔNG tự động chuyển hướng
                    // Người dùng sẽ nhấn nút riêng để xem chi tiết
                  }
                },

                // Animation - nhanh hơn
                animationDuration: 600,

                // Data labels
                dataLabelSettings: DataLabelSettings(
                  isVisible: false,
                  textStyle: TextStyle(fontSize: scale(10)),
                ),

                // Border
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(scale(4)),
                ),
              ),
            ],
          ),
        ),

        // Phần thông tin chi tiết - chỉ hiển thị khi có selection và compact
        if (provider.selectedIndex != null)
          _buildCompactDetailSection(context, provider, totalAmount),
      ],
    );
  }

  /// Phần hiển thị thông tin chi tiết compact chỉ khi có selection
  Widget _buildCompactDetailSection(
    BuildContext context,
    AnalysisProvider provider,
    double totalAmount,
  ) {
    final selectedSummary = provider.getSelectedSummary(type);

    if (selectedSummary == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.fromLTRB(scale(8), 0, scale(8), scale(4)),
      padding: EdgeInsets.all(scale(8)),
      decoration: BoxDecoration(
        color: selectedSummary.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(scale(6)),
        border: Border.all(
          color: selectedSummary.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon nhỏ hơn
          Icon(
            selectedSummary.icon,
            color: selectedSummary.color,
            size: scale(20),
          ),
          SizedBox(width: scale(6)),

          // Thông tin compact
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getTranslated(context, selectedSummary.category) ??
                      selectedSummary.category,
                  style: TextStyle(
                    fontSize: scale(12),
                    fontWeight: FontWeight.bold,
                    color: selectedSummary.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${format(selectedSummary.totalAmount)} $currency',
                  style: TextStyle(
                    fontSize: scale(11),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Nút xem nhỏ hơn
          Material(
            color: selectedSummary.color,
            borderRadius: BorderRadius.circular(scale(4)),
            child: InkWell(
              onTap: () {
                if (onSelection != null && provider.selectedIndex != null) {
                  onSelection!(provider.selectedIndex!, forceNavigate: true);
                }
              },
              borderRadius: BorderRadius.circular(scale(4)),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: scale(8),
                  vertical: scale(6),
                ),
                child: Icon(
                  Icons.calendar_today,
                  size: scale(14),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget cho Line/Spline Chart hiển thị xu hướng - Combined Income & Expense
class TrendChartAnalysis extends StatelessWidget {
  // FIX 1.1: Bỏ các tham số không cần thiết, lấy trực tiếp từ provider
  const TrendChartAnalysis({Key? key}) : super(key: key);

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
