import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../classes/constants.dart';
import '../classes/input_model.dart';
import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';
import '../provider/analysis_provider.dart';

/// Biểu đồ Donut nâng cấp với annotation và tương tác
class DonutChartAnalysis extends StatelessWidget {
  final String type;
  final List<CategorySummary> summaries;
  final Function(int index)? onSelection;

  const DonutChartAnalysis({
    Key? key,
    required this.type,
    required this.summaries,
    this.onSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final totalAmount = type == 'Income' ? provider.totalIncome : provider.totalExpense;
    final hasData = summaries.isNotEmpty && summaries[0].category.isNotEmpty;

    // Chuyển đổi CategorySummary thành InputModel cho chart
    final chartData = hasData
        ? summaries.map((s) => InputModel(
              type: type,
              amount: s.totalAmount,
              category: s.category,
              color: s.color,
            )).toList()
        : [
            InputModel(
              type: type,
              amount: 1,
              category: '',
              color: const Color.fromRGBO(0, 220, 252, 1),
            )
          ];

    return SfCircularChart(
      tooltipBehavior: TooltipBehavior(
        enable: hasData,
        format: 'point.x: point.y%',
        duration: 2000,
      ),
      selectionGesture: ActivationMode.singleTap,
      
      // Annotation ở trung tâm
      annotations: <CircularChartAnnotation>[
        CircularChartAnnotation(
          width: '67%',
          height: '67%',
          widget: _buildCenterAnnotation(context, provider, totalAmount, hasData),
        ),
      ],
      
      series: <CircularSeries<InputModel, String>>[
        DoughnutSeries<InputModel, String>(
          selectionBehavior: SelectionBehavior(
            enable: hasData,
            selectedColor: Colors.blue,
            unselectedOpacity: 0.5,
          ),
          
          // Callback khi tap vào segment
          onPointTap: (ChartPointDetails details) {
            if (hasData && details.pointIndex != null) {
              provider.updateSelectedIndex(details.pointIndex);
              // Gọi callback điều hướng nếu có
              if (onSelection != null) {
                onSelection!(details.pointIndex!);
              }
            }
          },
          
          startAngle: 90,
          endAngle: 90,
          animationDuration: hasData ? 1200 : 0,
          sortingOrder: SortingOrder.descending,
          sortFieldValueMapper: (InputModel data, _) => data.amount,
          enableTooltip: hasData,
          
          dataSource: chartData,
          pointColorMapper: (InputModel data, _) => data.color,
          xValueMapper: (InputModel data, _) =>
              getTranslated(context, data.category!) ?? data.category,
          yValueMapper: (InputModel data, _) =>
              (data.amount! / totalAmount) * 100,
          
          dataLabelSettings: DataLabelSettings(
            showZeroValue: false,
            useSeriesColor: true,
            labelPosition: ChartDataLabelPosition.outside,
            isVisible: hasData,
            textStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
          
          innerRadius: '60%', // Tạo lỗ ở giữa lớn hơn
          radius: '85%',
        ),
      ],
    );
  }

  /// Widget annotation ở trung tâm biểu đồ
  Widget _buildCenterAnnotation(
    BuildContext context,
    AnalysisProvider provider,
    double totalAmount,
    bool hasData,
  ) {
    return PhysicalModel(
      shape: BoxShape.circle,
      elevation: 8,
      shadowColor: Colors.black26,
      color: const Color.fromRGBO(245, 245, 245, 1),
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: hasData
            ? _buildDataAnnotation(context, provider, totalAmount)
            : _buildEmptyAnnotation(context),
      ),
    );
  }

  /// Annotation khi có dữ liệu
  Widget _buildDataAnnotation(
    BuildContext context,
    AnalysisProvider provider,
    double totalAmount,
  ) {
    final selectedSummary = provider.getSelectedSummary(type);

    if (selectedSummary != null) {
      // Hiển thị thông tin category được chọn
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selectedSummary.icon,
            size: 24.sp,
            color: selectedSummary.color,
          ),
          SizedBox(height: 4.h),
          Flexible(
            child: Text(
              getTranslated(context, selectedSummary.category) ?? selectedSummary.category,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 2.h),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${format(selectedSummary.totalAmount)} $currency',
                style: GoogleFonts.aBeeZee(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: selectedSummary.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '${((selectedSummary.totalAmount / totalAmount) * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.black54,
            ),
          ),
        ],
      );
    }

    // Hiển thị tổng số mặc định
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            getTranslated(context, type == 'Income' ? 'Total Income' : 'Total Expense') ??
                (type == 'Income' ? 'Tổng Thu' : 'Tổng Chi'),
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: 4.h),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${format(totalAmount)}',
              style: GoogleFonts.aBeeZee(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: type == 'Income' ? green : red,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          currency,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  /// Annotation khi không có dữ liệu
  Widget _buildEmptyAnnotation(BuildContext context) {
    return Center(
      child: Text(
        getTranslated(context, 'There is no data') ?? 'Không có dữ liệu',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: const Color.fromRGBO(0, 0, 0, 0.5),
          fontSize: 15.sp,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
