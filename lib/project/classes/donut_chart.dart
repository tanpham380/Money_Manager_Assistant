import 'package:flutter/material.dart';
 import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:responsive_scaler/responsive_scaler.dart';
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

    return Column(
      children: [
        // Biểu đồ donut - thu nhỏ lại
        SizedBox(
          height: scale(220), // Giảm thêm chiều cao để tiết kiệm không gian
          child: SfCircularChart(
      tooltipBehavior: TooltipBehavior(
        enable: hasData,
        format: 'point.x: point.y%',
        duration: 1000, // Giảm từ 2000 xuống 1000ms
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
          
          // Callback khi tap vào segment - CHỈ hiển thị thông tin, KHÔNG chuyển trang
          onPointTap: (ChartPointDetails details) {
            if (hasData && details.pointIndex != null) {
              provider.updateSelectedIndex(details.pointIndex);
              // KHÔNG gọi onSelection để tránh chuyển hướng ngay lập tức
            }
          },
          
          startAngle: 90,
          endAngle: 90,
          animationDuration: hasData ? 600 : 0, // Giảm từ 1200 xuống 600ms
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
            textStyle: TextStyle(fontSize: scale(12), fontWeight: FontWeight.w600),
          ),
          
          innerRadius: '60%', // Tạo lỗ ở giữa lớn hơn
          radius: '85%',
        ),
      ],
          ),
        ),
        
        // Thông tin chi tiết bên dưới biểu đồ
        if (hasData) _buildDetailSection(context, provider, totalAmount),
      ],
    );
  }
  
  /// Phần hiển thị thông tin chi tiết và nút xem giao dịch - Tối ưu cho 1 màn hình
  Widget _buildDetailSection(
    BuildContext context,
    AnalysisProvider provider,
    double totalAmount,
  ) {
    final selectedSummary = provider.getSelectedSummary(type);
    
    if (selectedSummary == null) {
      // Hiển thị legend danh sách các category - COMPACT hơn
      return Expanded(
        child: _buildCategoryLegend(context, totalAmount),
      );
    }
    
    // Hiển thị thông tin chi tiết category được chọn - COMPACT
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200), // Hiệu ứng mượt và nhanh
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
                if (onSelection != null) {
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
  
  /// Legend hiển thị danh sách các category với % và số tiền - COMPACT
  Widget _buildCategoryLegend(BuildContext context, double totalAmount) {
    final provider = context.watch<AnalysisProvider>();
    return Container(
      margin: EdgeInsets.fromLTRB(scale(12), 0, scale(12), scale(8)),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: summaries.length,
        itemBuilder: (context, index) {
          final summary = summaries[index];
          final percentage = summary.totalAmount / totalAmount * 100;
          final isSelected = provider.selectedIndex == index;
          
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(scale(8)),
            child: InkWell(
              onTap: () {
                final provider = context.read<AnalysisProvider>();
                provider.updateSelectedIndex(index);
              },
              borderRadius: BorderRadius.circular(scale(8)),
              child: Container(
                margin: EdgeInsets.only(bottom: scale(6)),
                padding: EdgeInsets.symmetric(
                  horizontal: scale(10),
                  vertical: scale(8),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(scale(8)),
                  border: Border.all(
                    color: isSelected ? summary.color : Colors.grey[200]!, 
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected ? summary.color.withValues(alpha: 0.05) : Colors.white,
                ),
                child: Row(
                  children: [
                    // Thanh màu
                    Container(
                      width: scale(4),
                      height: scale(32),
                      decoration: BoxDecoration(
                        color: summary.color,
                        borderRadius: BorderRadius.circular(scale(2)),
                      ),
                    ),
                    SizedBox(width: scale(10)),
                    
                    // Icon
                    Icon(
                      summary.icon,
                      color: summary.color,
                      size: scale(22),
                    ),
                    SizedBox(width: scale(10)),
                    
                    // Tên và số tiền
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            getTranslated(context, summary.category) ?? 
                                summary.category,
                            style: TextStyle(
                              fontSize: scale(13),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${format(summary.totalAmount)} $currency',
                            style: GoogleFonts.aBeeZee(
                              fontSize: scale(12),
                              color: summary.color,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(width: scale(8)),
                    
                    // Phần trăm - compact
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: scale(8),
                        vertical: scale(4),
                      ),
                      decoration: BoxDecoration(
                        color: summary.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(scale(8)),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: scale(12),
                          fontWeight: FontWeight.bold,
                          color: summary.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
        padding: EdgeInsets.all(scale(16)),
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
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selectedSummary.icon,
              size: scale(22),
              color: selectedSummary.color,
            ),
            SizedBox(height: scale(3)),
            Text(
              getTranslated(context, selectedSummary.category) ?? selectedSummary.category,
              style: TextStyle(
                fontSize: scale(11),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: scale(2)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${format(selectedSummary.totalAmount)} $currency',
                style: GoogleFonts.aBeeZee(
                  fontSize: scale(13),
                  fontWeight: FontWeight.bold,
                  color: selectedSummary.color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: scale(2)),
            Text(
              '${((selectedSummary.totalAmount / totalAmount) * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: scale(10),
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    // Hiển thị tổng số mặc định
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Flexible(
        //   child: Text(
        //     getTranslated(context, type == 'Income' ? 'Total Income' : 'Total Expense') ??
        //         (type == 'Income' ? 'Tổng Thu' : 'Tổng Chi'),
        //     style: TextStyle(
        //       fontSize: scale(11),
        //       color: Colors.black54,
        //       fontWeight: FontWeight.w500,
        //     ),
        //     textAlign: TextAlign.center,
        //     maxLines: 2,
        //     overflow: TextOverflow.ellipsis,
        //   ),
        // ),
        // SizedBox(height: scale(4)),
        // Flexible(
        //   child: FittedBox(
        //     fit: BoxFit.scaleDown,
        //     child: Text(
        //       '${format(totalAmount)}',
        //       style: GoogleFonts.aBeeZee(
        //         fontSize: scale(18),
        //         fontWeight: FontWeight.bold,
        //         color: type == 'Income' ? green : red,
        //       ),
        //       textAlign: TextAlign.center,
        //       maxLines: 1,
        //     ),
        //   ),
        // ),
        // SizedBox(height: scale(2)),
        // Text(
        //   currency,
        //   style: TextStyle(
        //     fontSize: scale(12),
        //     color: Colors.black54,
        //   ),
        // ),
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
          fontSize: scale(15),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
