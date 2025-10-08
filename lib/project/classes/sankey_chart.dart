import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/analysis_provider.dart';
import '../localization/methods.dart';
import '../utils/responsive_extensions.dart';
import '../classes/constants.dart'; // Import for format() function
import '../database_management/shared_preferences_services.dart'; // Import for currency

class SankeyChartAnalysis extends StatelessWidget {
  const SankeyChartAnalysis({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final hasNodes = provider.sankeyNodes.isNotEmpty;
    final hasLinks = provider.sankeyLinks.isNotEmpty;

    if (!hasNodes || !hasLinks) {
      return _buildEmptyChartState(context);
    }

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Sankey Flow Visualization - 3 columns layout
            _buildEnhancedSankeyLayout(context, provider),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  /// Build enhanced Sankey layout - 3 columns visual representation  
  Widget _buildEnhancedSankeyLayout(BuildContext context, AnalysisProvider provider) {
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
          // Title
          Text(
            getTranslated(context, 'Money Flow Analysis') ?? 'Money Flow Analysis',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 24.h),

          // Main Flow Layout - 3 columns
          _buildMainFlowSection(context, provider),
          
          SizedBox(height: 20.h),
          
          // Summary section
          _buildFlowSummary(context, provider),
        ],
      ),
    );
  }

  /// Build main flow section (3 columns)
  Widget _buildMainFlowSection(BuildContext context, AnalysisProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column 1: Income Sources
        Expanded(
          flex: 2,
          child: _buildIncomeColumn(context, provider),
        ),

        // Arrow 1: Income to Total
        SizedBox(
          width: 40.w,
          child: Column(
            children: [
              SizedBox(height: 60.h),
              Icon(
                Icons.arrow_forward,
                color: Colors.green,
                size: 24.sp,
              ),
            ],
          ),
        ),

        // Column 2: Total Income/Expense
        Expanded(
          flex: 2,
          child: _buildTotalColumn(context, provider),
        ),

        // Arrow 2: Total to Expense  
        SizedBox(
          width: 40.w,
          child: Column(
            children: [
              SizedBox(height: 60.h),
              Icon(
                Icons.arrow_forward,
                color: Colors.red,
                size: 24.sp,
              ),
            ],
          ),
        ),

        // Column 3: Expense Categories
        Expanded(
          flex: 2,
          child: _buildExpenseColumn(context, provider),
        ),
      ],
    );
  }

  /// Build income column (left)
  Widget _buildIncomeColumn(BuildContext context, AnalysisProvider provider) {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            getTranslated(context, 'Income Sources') ?? 'Income Sources',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Income categories
        ...provider.incomeSummaries.take(5).map((summary) => 
          _buildCategoryItem(
            context, 
            summary, 
            Colors.green, 
            provider.totalIncome
          )
        ),

        // Show more indicator
        if (provider.incomeSummaries.length > 5)
          _buildMoreText(
            context, 
            provider.incomeSummaries.length - 5,
            'more income sources'
          ),
      ],
    );
  }

  /// Build total column (center)
  Widget _buildTotalColumn(BuildContext context, AnalysisProvider provider) {
    return Column(
      children: [
        // Total Income
        Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                getTranslated(context, 'Total Income') ?? 'Total Income',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                _formatAmount(provider.totalIncome),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
        ),

        // Flow indicator - vertical gradient line
        Container(
          height: 40.h,
          width: 4.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.withValues(alpha: 0.7), 
                Colors.red.withValues(alpha: 0.7)
              ],
            ),
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),

        // Total Expense
        Container(
          margin: EdgeInsets.only(top: 12.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                getTranslated(context, 'Total Expense') ?? 'Total Expense',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                _formatAmount(provider.totalExpense),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build expense column (right)
  Widget _buildExpenseColumn(BuildContext context, AnalysisProvider provider) {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            getTranslated(context, 'Expense Categories') ?? 'Expense Categories',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Expense categories
        ...provider.expenseSummaries.take(5).map((summary) => 
          _buildCategoryItem(
            context, 
            summary, 
            Colors.red, 
            provider.totalExpense
          )
        ),

        // Show more indicator
        if (provider.expenseSummaries.length > 5)
          _buildMoreText(
            context, 
            provider.expenseSummaries.length - 5,
            'more expense categories'
          ),
      ],
    );
  }

  /// Build category item with percentage bar
  Widget _buildCategoryItem(
    BuildContext context, 
    dynamic summary,  // CategorySummary
    Color themeColor, 
    double totalAmount
  ) {
    final percentage = totalAmount > 0 ? (summary.totalAmount / totalAmount) : 0.0;
    
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: themeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(summary.icon, size: 16.sp, color: themeColor),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  getTranslated(context, summary.category) ?? summary.category,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: themeColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          
          // Amount
          Text(
            _formatAmount(summary.totalAmount),
            style: TextStyle(
              fontSize: 10.sp,
              color: themeColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          
          // Percentage bar
          if (percentage > 0) ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  '${(percentage * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: themeColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build flow summary
  Widget _buildFlowSummary(BuildContext context, AnalysisProvider provider) {
    final balance = provider.totalIncome - provider.totalExpense;
    final isPositive = balance >= 0;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isPositive ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            getTranslated(context, 'Cash Flow Balance') ?? 'Cash Flow Balance',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _formatAmount(balance.abs()),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green[700] : Colors.red[700],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            isPositive 
              ? (getTranslated(context, 'Surplus') ?? 'Surplus')
              : (getTranslated(context, 'Deficit') ?? 'Deficit'),
            style: TextStyle(
              fontSize: 12.sp,
              color: isPositive ? Colors.green[600] : Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state for chart
  Widget _buildEmptyChartState(BuildContext context) {
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
            getTranslated(context, 'No sankey data available') ?? 'No sankey data available',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            getTranslated(context, 'Add transactions to see flow analysis') ?? 'Add transactions to see flow analysis',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper for showing more items text
  Widget _buildMoreText(BuildContext context, int count, String type) {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      child: Text(
        '+ $count ${getTranslated(context, type) ?? type}',
        style: TextStyle(
          fontSize: 10.sp,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  /// Format amount with currency using project's existing format system
  String _formatAmount(double amount) {
    return '${format(amount)} $currency';
  }
}