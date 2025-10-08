// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // Cần import để định dạng số
// import 'package:provider/provider.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';
// import '../utils/responsive_extensions.dart';

// import '../classes/constants.dart';
// import '../localization/methods.dart'; // Cần import để dịch thuật
// import '../provider/analysis_provider.dart';
// import '../provider/navigation_provider.dart'; // Cần import để điều hướng

// /// Widget Tornado Chart - Hiển thị Thu và Chi trong cùng một biểu đồ dạng Tornado
// class TornadoChartAnalysis extends StatelessWidget {
//   const TornadoChartAnalysis({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<AnalysisProvider>();
//     final combinedData = provider.combinedSummaries;

//     if (combinedData.isEmpty) {
//       return _buildEmptyChartState(context);
//     }

//     // Validate data before using it
//     final validData = combinedData.where((data) {
//       return data.category.isNotEmpty && 
//              data.income.isFinite && 
//              data.expense.isFinite;
//     }).toList();

//     if (validData.isEmpty) {
//       return _buildEmptyChartState(context);
//     }

//     // --- LOGIC ĐIỀU HƯỚNG KHI NHẤN VÀO CỘT ---
//     void handleIncomePointTap(ChartPointDetails details) {
//       if (details.pointIndex == null) return;

//       final int index = details.pointIndex!;
//       if (index >= validData.length) return;

//       final summary = validData[index];
//       final navProvider = context.read<NavigationProvider>();
//       final dateRange = provider.getDateRange();

//       navProvider.navigateToCalendarWithFilter(
//         type: 'Income',
//         category: summary.category,
//         icon: summary.icon,
//         color: summary.color,
//         startDate: dateRange['start'],
//         endDate: dateRange['end'],
//         isOthersGroup: summary.category == 'Others',
//       );
//     }

//     void handleExpensePointTap(ChartPointDetails details) {
//       if (details.pointIndex == null) return;

//       final int index = details.pointIndex!;
//       if (index >= validData.length) return;

//       final summary = validData[index];
//       final navProvider = context.read<NavigationProvider>();
//       final dateRange = provider.getDateRange();

//       navProvider.navigateToCalendarWithFilter(
//         type: 'Expense',
//         category: summary.category,
//         icon: summary.icon,
//         color: summary.color,
//         startDate: dateRange['start'],
//         endDate: dateRange['end'],
//         isOthersGroup: summary.category == 'Others',
//       );
//     }
//     // ---------------------------------------------

//     return Container(
//       padding: EdgeInsets.all(8.w),
//       child: Column(
//         children: [
//           // Legend
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _buildLegendItem(context, 'Income', green),
//               SizedBox(width: 24.w),
//               _buildLegendItem(context, 'Expense', red),
//             ],
//           ),
//           SizedBox(height: 12.h),

//           // Tornado Chart
//           Expanded(
//             child: SfCartesianChart(
//               plotAreaBorderWidth: 0,
//               primaryXAxis: CategoryAxis( // Đổi trục X thành Category
//                 majorGridLines: const MajorGridLines(width: 0),
//                 axisLine: const AxisLine(width: 0),
//                 labelStyle: TextStyle(
//                   fontSize: 11.sp,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               primaryYAxis: NumericAxis( // Đổi trục Y thành Numeric
//                 majorGridLines: const MajorGridLines(width: 0.5),
//                 axisLine: const AxisLine(width: 1),
//                 opposedPosition: false,
//                 // Định dạng số để bỏ dấu âm
//                 numberFormat: NumberFormat.compact(),
//                 labelStyle: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
//               ),
//               tooltipBehavior: TooltipBehavior(
//                 enable: true,
//                 duration: 1500,
//                 // Sửa format tooltip để hiển thị số dương
//                 builder: (dynamic data, dynamic point, dynamic series,
//                     int pointIndex, int seriesIndex) {
//                   final summary = data as CombinedCategorySummary;
//                   final value = series.name == 'Expense' ? summary.expense : summary.income;
//                   return Container(
//                     padding: EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(5),
//                       boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
//                     ),
//                     child: Text('${summary.category}: ${format(value)}'),
//                   );
//                 },
//               ),
//               series: <CartesianSeries>[
//                 // Series 1: Income (bên phải, giá trị dương)
//                 BarSeries<CombinedCategorySummary, String>(
//                   name: 'Income',
//                   dataSource: validData,
//                   xValueMapper: (CombinedCategorySummary data, _) => data.category,
//                   yValueMapper: (CombinedCategorySummary data, _) => data.income,
//                   color: green.withValues(alpha: 0.8),
//                   borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
//                   // --- THÊM TƯƠNG TÁC ---
//                   selectionBehavior: SelectionBehavior(enable: true),
//                   onPointTap: handleIncomePointTap,
//                 ),

//                 // Series 2: Expense (bên trái, giá trị âm)
//                 BarSeries<CombinedCategorySummary, String>(
//                   name: 'Expense',
//                   dataSource: validData,
//                   xValueMapper: (CombinedCategorySummary data, _) => data.category,
//                   yValueMapper: (CombinedCategorySummary data, _) => -data.expense,
//                   color: red.withValues(alpha: 0.8),
//                   borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
//                   // --- THÊM TƯƠNG TÁC ---
//                   selectionBehavior: SelectionBehavior(enable: true),
//                   onPointTap: handleExpensePointTap,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Helper để tạo legend item
//   Widget _buildLegendItem(BuildContext context, String label, Color color) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 16.w,
//           height: 16.w,
//           decoration: BoxDecoration(
//             color: color.withValues(alpha: 0.8),
//             borderRadius: BorderRadius.circular(4.r),
//           ),
//         ),
//         SizedBox(width: 6.w),
//         Text(
//           getTranslated(context, label) ?? label, // FIX: Dùng getTranslated
//           style: TextStyle(
//             fontSize: 13.sp,
//             fontWeight: FontWeight.w600,
//             color: color,
//           ),
//         ),
//       ],
//     );
//   }

//   /// Empty state cho chart
//   Widget _buildEmptyChartState(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.bar_chart_outlined,
//             size: 64.sp,
//             color: Colors.grey[400],
//           ),
//           SizedBox(height: 16.h),
//           Text(
//             getTranslated(context, 'No chart data available') ?? 'No chart data available',
//             style: TextStyle(
//               fontSize: 16.sp,
//               color: Colors.grey[600],
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           SizedBox(height: 8.h),
//           Text(
//             getTranslated(context, 'Add transactions to see analysis') ?? 'Add transactions to see analysis',
//             style: TextStyle(
//               fontSize: 13.sp,
//               color: Colors.grey[500],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
