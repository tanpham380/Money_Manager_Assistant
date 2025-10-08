import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/responsive_extensions.dart';

import '../classes/constants.dart';
import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';
import '../provider/analysis_provider.dart';

/// Widget Sankey Diagram - Hiển thị dòng chảy tiền từ Thu đến Chi
/// Sử dụng layout 3 cột với arrows để mô phỏng dòng tiền
class SankeyChartAnalysis extends StatelessWidget {
  const SankeyChartAnalysis({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final hasNodes = provider.sankeyNodes.isNotEmpty;
    final hasLinks = provider.sankeyLinks.isNotEmpty;

    if (!hasNodes || !hasLinks) {
      return _buildEmptyChartState();
    }

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Sankey Flow Visualization - 3 columns layout
            _buildSankeyFlowLayout(context, provider),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  /// Build Sankey Flow Layout - 3 columns visual representation
  Widget _buildSankeyFlowLayout(
      BuildContext context, AnalysisProvider provider) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withValues(alpha: 0.05),
            Colors.blue.withValues(alpha: 0.05),
            Colors.red.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Row 1: Income Categories -> Total Income
          Row(
            children: [
              // Income Categories (Left)
              Expanded(
                flex: 2,
                child: _buildCategoryColumn(
                  context,
                  getTranslated(context, 'Income Sources') ??
                      'Nguồn Thu Nhập',
                  provider.incomeSummaries,
                  green,
                  Alignment.centerLeft,
                ),
              ),
              // Arrow
              Icon(Icons.arrow_forward, color: green, size: 32.sp),
              // Total Income (Center)
              Expanded(
                flex: 1,
                child: _buildTotalBox(
                  context,
                  getTranslated(context, 'Total\nIncome') ?? 'Tổng\nThu',
                  provider.totalIncome,
                  green,
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Arrow Down (Income flows to Expense)
          Column(
            children: [
              Icon(Icons.arrow_downward, color: blue2, size: 40.sp),
              Text(
                '${getTranslated(context, 'Money Flow') ?? 'Dòng tiền'}\n${format(provider.totalIncome < provider.totalExpense ? provider.totalIncome : provider.totalExpense)} $currency',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: blue2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Row 2: Total Expense -> Expense Categories
          Row(
            children: [
              // Total Expense (Center)
              Expanded(
                flex: 1,
                child: _buildTotalBox(
                  context,
                  getTranslated(context, 'Total\nExpense') ?? 'Tổng\nChi',
                  provider.totalExpense,
                  red,
                ),
              ),
              // Arrow
              Icon(Icons.arrow_forward, color: red, size: 32.sp),
              // Expense Categories (Right)
              Expanded(
                flex: 2,
                child: _buildCategoryColumn(
                  context,
                  getTranslated(context, 'Expense Categories') ??
                      'Hạng Mục Chi Tiêu',
                  provider.expenseSummaries,
                  red,
                  Alignment.centerRight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build category column for Sankey
  Widget _buildCategoryColumn(
    BuildContext context,
    String title,
    List<CategorySummary> summaries,
    Color themeColor,
    Alignment alignment,
  ) {
    return Column(
      crossAxisAlignment: alignment == Alignment.centerLeft
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: themeColor,
          ),
        ),
        SizedBox(height: 8.h),
        ...summaries.take(5).map((summary) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: alignment == Alignment.centerLeft
                    ? [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: summary.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            '${getTranslated(context, summary.category) ?? summary.category}: ${format(summary.totalAmount)}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]
                    : [
                        Flexible(
                          child: Text(
                            '${format(summary.totalAmount)}: ${getTranslated(context, summary.category) ?? summary.category}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: summary.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
              ),
            )),
        if (summaries.length > 5)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              '+ ${summaries.length - 5} ${getTranslated(context, 'more') ?? 'more'}',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  /// Build total box for Sankey
  Widget _buildTotalBox(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          FittedBox(
            child: Text(
              '${format(amount)} $currency',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state cho chart
  Widget _buildEmptyChartState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_outlined,
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
