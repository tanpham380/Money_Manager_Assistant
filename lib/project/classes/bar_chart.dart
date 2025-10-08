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
  final Function(int index)? onSelection;

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
    final totalAmount = type == 'Income' ? provider.totalIncome : provider.totalExpense;

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
        // Biểu đồ cột
        Expanded(
          flex: 2,
          child: SfCartesianChart(
      // Title
      title: ChartTitle(
        text: getTranslated(context, type == 'Income' ? 'Income by Category' : 'Expense by Category') ??
            (type == 'Income' ? 'Thu nhập theo danh mục' : 'Chi tiêu theo danh mục'),
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
        
        // Phần thông tin chi tiết bên dưới
        if (provider.selectedIndex != null)
          Expanded(
            flex: 1,
            child: _buildDetailSection(context, provider, totalAmount),
          ),
      ],
    );
  }
  
  /// Phần hiển thị thông tin chi tiết và nút xem giao dịch - COMPACT
  Widget _buildDetailSection(
    BuildContext context,
    AnalysisProvider provider,
    double totalAmount,
  ) {
    final selectedSummary = provider.getSelectedSummary(type);
    
    if (selectedSummary == null) return const SizedBox.shrink();
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200), // Hiệu ứng nhanh
      curve: Curves.easeInOut,
      margin: EdgeInsets.fromLTRB(scale(12), 0, scale(12), scale(8)),
      padding: EdgeInsets.all(scale(12)),
      decoration: BoxDecoration(
        color: selectedSummary.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(scale(10)),
        border: Border.all(
          color: selectedSummary.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Icon(
            selectedSummary.icon,
            color: selectedSummary.color,
            size: scale(32),
          ),
          SizedBox(width: scale(12)),
          
          // Thông tin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getTranslated(context, selectedSummary.category) ?? 
                      selectedSummary.category,
                  style: TextStyle(
                    fontSize: scale(15),
                    fontWeight: FontWeight.bold,
                    color: selectedSummary.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: scale(2)),
                Text(
                  '${format(selectedSummary.totalAmount)} $currency • ${((selectedSummary.totalAmount / totalAmount) * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: scale(13),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          SizedBox(width: scale(8)),
          
          // Nút xem chi tiết - COMPACT
          Material(
            color: selectedSummary.color,
            borderRadius: BorderRadius.circular(scale(8)),
            child: InkWell(
              onTap: () {
                if (onSelection != null && provider.selectedIndex != null) {
                  onSelection!(provider.selectedIndex!);
                }
              },
              borderRadius: BorderRadius.circular(scale(8)),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: scale(12),
                  vertical: scale(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: scale(16),
                      color: Colors.white,
                    ),
                    SizedBox(width: scale(6)),
                    Text(
                      getTranslated(context, 'View') ?? 'Xem',
                      style: TextStyle(
                        fontSize: scale(13),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget cho Line/Spline Chart hiển thị xu hướng
class TrendChartAnalysis extends StatelessWidget {
  final String type;
  final List<TrendData> trendData;

  const TrendChartAnalysis({
    Key? key,
    required this.type,
    required this.trendData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasData = trendData.isNotEmpty;

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
        text: getTranslated(context, type == 'Income' ? 'Income Trend' : 'Expense Trend') ??
            (type == 'Income' ? 'Xu hướng thu nhập' : 'Xu hướng chi tiêu'),
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
      
      // Series
      series: <CartesianSeries<TrendData, DateTime>>[
        SplineSeries<TrendData, DateTime>(
          dataSource: trendData,
          xValueMapper: (TrendData data, _) => data.month,
          yValueMapper: (TrendData data, _) => data.totalAmount,
          
          color: type == 'Income' ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error,
          width: 3,
          
          // Markers
          markerSettings: MarkerSettings(
            isVisible: true,
            height: 6,
            width: 6,
            shape: DataMarkerType.circle,
            borderWidth: 2,
            borderColor: type == 'Income' ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error,
          ),
          
          // Animation - nhanh hơn
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
