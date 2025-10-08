import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/analysis_provider.dart';
import '../localization/methods.dart';
import '../utils/responsive_extensions.dart';
import '../classes/constants.dart'; // Import for format() function
import '../database_management/shared_preferences_services.dart'; // Import for currency
import '../widgets/comparison_indicator.dart';
import '../widgets/sankey_painter.dart';

/// Class đại diện cho mục "Số dư" trong cột phân bổ
class BalanceItem {
  final String category;
  final IconData icon;
  final double totalAmount;

  BalanceItem({
    required this.category,
    required this.icon,
    required this.totalAmount,
  });
}

class SankeyChartAnalysis extends StatefulWidget {
  final Function(String category, String type)? onCategoryTap;
  final Function(String category, String type)? onCategoryLongPress;
  
  const SankeyChartAnalysis({
    Key? key, 
    this.onCategoryTap,
    this.onCategoryLongPress,
  }) : super(key: key);

  @override
  State<SankeyChartAnalysis> createState() => _SankeyChartAnalysisState();
}

class _SankeyChartAnalysisState extends State<SankeyChartAnalysis> {
  // GlobalKey tracking cho các category items
  final Map<String, GlobalKey> _incomeKeys = {};
  final Map<String, GlobalKey> _expenseKeys = {};
  final Map<String, Offset> _itemPositions = {};
  
  // ⚠️ KHÔNG dùng final! Key phải được tạo mới mỗi lần widget rebuild
  late GlobalKey _painterKey;

  @override
  void initState() {
    super.initState();
    // Tạo painter key MỚI cho widget instance này
    _painterKey = GlobalKey();
    
    // Schedule update SAU KHI build hoàn tất và các GlobalKeys đã được tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateItemPositions();
      }
    });
  }

  @override
  void didUpdateWidget(SankeyChartAnalysis oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update positions khi widget được update (nhưng không dispose)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateItemPositions();
      }
    });
  }

  /// Lấy hoặc tạo GlobalKey cho income/expense category
  GlobalKey _getKey(String category, String type) {
    final map = type == 'Income' ? _incomeKeys : _expenseKeys;
    return map.putIfAbsent(category, () => GlobalKey());
  }

  /// Cập nhật vị trí của các category items một cách an toàn
  void _updateItemPositions() {
    if (!mounted) return;

    final painterRenderBox = _painterKey.currentContext?.findRenderObject() as RenderBox?;
    
    if (painterRenderBox == null || !painterRenderBox.hasSize) {
      // Painter chưa ready, thử lại
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateItemPositions();
      });
      return;
    }

    // Kiểm tra có GlobalKeys không - QUAN TRỌNG!
    if (_incomeKeys.isEmpty && _expenseKeys.isEmpty) {
      // Chưa có keys nào, thử lại sau khi build tạo keys
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateItemPositions();
      });
      return;
    }

    final newPositions = <String, Offset>{};

    void calculatePositions(Map<String, GlobalKey> keys, String prefix) {
      for (var entry in keys.entries) {
        final renderBox = entry.value.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize && renderBox.attached) {
          try {
            final globalPosition = renderBox.localToGlobal(Offset.zero);
            final localPosition = painterRenderBox.globalToLocal(globalPosition);
            final size = renderBox.size;
            final key = '$prefix${entry.key}';

            if (prefix == 'income_') {
              newPositions[key] = Offset(
                localPosition.dx + size.width, // Cạnh phải
                localPosition.dy + size.height / 2, // Trung tâm
              );
            } else {
              newPositions[key] = Offset(
                localPosition.dx, // Cạnh trái
                localPosition.dy + size.height / 2, // Trung tâm
              );
            }
          } catch (e) {
            debugPrint("Could not calculate position for ${entry.key}: $e");
          }
        }
      }
    }

    calculatePositions(_incomeKeys, 'income_');
    calculatePositions(_expenseKeys, 'expense_');

    // Chỉ setState nếu CÓ positions mới và KHÁC với cũ
    if (newPositions.isNotEmpty && newPositions.toString() != _itemPositions.toString()) {
      setState(() {
        _itemPositions.clear();
        _itemPositions.addAll(newPositions);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final hasIncome = provider.incomeSummaries.isNotEmpty;
    final hasExpense = provider.expenseSummaries.isNotEmpty;

    if (!hasIncome && !hasExpense) {
      return _buildEmptyChartState(context);
    }

    // Get current categories
    final currentIncomeCategories = provider.incomeSummaries.map((s) => s.category).toSet();
    final currentExpenseCategories = provider.expenseSummaries.map((s) => s.category).toSet();
    
    // Remove keys for categories that no longer exist
    _incomeKeys.removeWhere((key, value) => !currentIncomeCategories.contains(key));
    _expenseKeys.removeWhere((key, value) => !currentExpenseCategories.contains(key));
    
    // Remove stale position data
    _itemPositions.removeWhere((key, value) {
      if (key.startsWith('income_')) {
        final category = key.substring('income_'.length);
        return !currentIncomeCategories.contains(category);
      } else if (key.startsWith('expense_')) {
        final category = key.substring('expense_'.length);
        return !currentExpenseCategories.contains(category);
      }
      return false;
    });

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: _buildMoneyFlowLayout(context, provider),
      ),
    );
  }

  /// Layout trực quan hóa dòng tiền (2 cột)
  Widget _buildMoneyFlowLayout(BuildContext context, AnalysisProvider provider) {
    // Tính toán số dư
    final balance = provider.totalIncome - provider.totalExpense;

    // Tạo một danh sách các "đích đến" của dòng tiền
    final List<dynamic> destinations = [
      ...provider.expenseSummaries,
      // Thêm "Số dư" như một hạng mục nếu có số dư dương
      if (balance > 0)
        _createBalanceItem(context, balance),
    ];
    // Sắp xếp các hạng mục chi theo số tiền giảm dần
    destinations.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            getTranslated(context, 'Money Flow Analysis') ?? 'Money Flow Analysis',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 24.h),
          // Layout chính với categories và flows
          _buildMainLayout(context, provider, destinations),
        ],
      ),
    );
  }

  /// Layout chính với hai cột categories
  Widget _buildMainLayout(BuildContext context, AnalysisProvider provider, List<dynamic> destinations) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cột 1: Nguồn thu
        Expanded(
          flex: 3,
          child: _buildColumn(
            context,
            title: getTranslated(context, 'Income Sources') ?? 'Income Sources',
            summaries: provider.incomeSummaries,
            totalAmount: provider.totalIncome,
            themeColor: Colors.green,
            categoryType: 'Income',
          ),
        ),

        // Dòng chảy ở giữa - Sankey Flows
        Expanded(
          flex: 1,
          child: _buildSankeyFlowLayer(context, provider),
        ),

        // Cột 2: Phân bổ (Chi tiêu + Số dư)
        Expanded(
          flex: 3,
          child: _buildColumn(
            context,
            title: getTranslated(context, 'Allocation') ?? 'Allocation',
            summaries: destinations,
            totalAmount: provider.totalIncome, // Tổng phân bổ bằng tổng thu
            themeColor: Colors.blue, // Dùng màu trung tính
            isDestination: true,
            categoryType: 'Expense',
          ),
        ),
      ],
    );
  }

  /// Layer chứa Sankey flows (CustomPainter)
  Widget _buildSankeyFlowLayer(BuildContext context, AnalysisProvider provider) {
    // Kiểm tra có dữ liệu flows không
    final visibleFlows = provider.sankeyFlows.where((flow) => flow.isVisible).toList();
    if (visibleFlows.isEmpty) {
      return Container(
        child: Center(
          child: Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[200],
            size: 16,
          ),
        ),
      );
    }

    // Hiển thị flows với CustomPaint - render luôn để có RenderBox
    return SizedBox(
      width: double.infinity,
      height: 400, // ⚠️ FORCE HEIGHT để tránh Canvas height = 0
      child: CustomPaint(
        key: _painterKey,
        size: Size.infinite,
        painter: SankeyPainter(
          flows: provider.sankeyFlows,
          incomeCategories: provider.incomeSummaries,
          expenseCategories: provider.expenseSummaries,
          itemPositions: _itemPositions, // Painter sẽ check empty và skip paint
          onCategoryTap: (category) {
            provider.setFocusedCategory(category);
          },
        ),
        // Hiển thị loading overlay nếu chưa có positions
        child: _itemPositions.isEmpty 
          ? Center(child: Text('Loading...', style: TextStyle(color: Colors.grey)))
          : null,
      ),
    );
  }

  /// Tạo item "Số dư" giả lập
  dynamic _createBalanceItem(BuildContext context, double balance) {
    return BalanceItem(
      category: getTranslated(context, 'Balance') ?? 'Savings',
      icon: Icons.savings_outlined,
      totalAmount: balance,
    );
  }

  /// Widget chung để xây dựng một cột (Nguồn thu hoặc Phân bổ)
  Widget _buildColumn(
    BuildContext context, {
    required String title,
    required List<dynamic> summaries,
    required double totalAmount,
    required Color themeColor,
    bool isDestination = false,
    String categoryType = '',
  }) {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: themeColor.withValues(alpha: 0.8),
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Danh sách các hạng mục
        if (summaries.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 20.h),
            child: Text(
              getTranslated(context, 'No data') ?? 'No data',
              style: TextStyle(color: Colors.grey[500], fontSize: 12.sp),
            ),
          )
        else
          ...summaries.map((summary) {
            // Xác định màu sắc cho từng item trong cột Phân Bổ
            Color itemColor = themeColor;
            if (isDestination) {
              // Nếu là hạng mục "Số dư" thì màu xanh, còn lại là màu đỏ
              final balanceLabel = getTranslated(context, 'Balance') ?? 'Savings';
              itemColor = (summary.category == balanceLabel) ? Colors.green : Colors.red;
            }

            return _buildCategoryItem(
              context,
              summary,
              itemColor,
              totalAmount,
            );
          }),
      ],
    );
  }

  /// Widget cho từng hạng mục
  Widget _buildCategoryItem(
    BuildContext context,
    dynamic summary,
    Color themeColor,
    double totalAmount,
  ) {
    final provider = context.watch<AnalysisProvider>();
    final percentage = totalAmount > 0 ? (summary.totalAmount / totalAmount) : 0.0;

    // Xác định type dựa trên themeColor hoặc category
    String type = '';
    final balanceLabel = getTranslated(context, 'Balance') ?? 'Savings';
    final isBalanceItem = summary.category == balanceLabel;
    
    if (!isBalanceItem) {
      if (themeColor == Colors.green) {
        type = 'Income';
      } else if (themeColor == Colors.red) {
        type = 'Expense';
      }
    }

    // Kiểm tra focus mode - highlight cả categories có flow liên quan
    final isFocused = provider.focusedCategory == summary.category && 
                     provider.focusedType == type;
    final hasAnyFocus = provider.focusedCategory != null;
    
    // Kiểm tra xem category này có liên quan đến focused category không
    bool isRelated = false;
    if (hasAnyFocus && !isFocused) {
      // Tìm flows liên quan
      for (final flow in provider.sankeyFlows) {
        if ((flow.fromCategory == provider.focusedCategory && flow.toCategory == summary.category) ||
            (flow.toCategory == provider.focusedCategory && flow.fromCategory == summary.category)) {
          isRelated = true;
          break;
        }
      }
    }
    
    final shouldDim = hasAnyFocus && !isFocused && !isRelated;

    // Lấy GlobalKey cho category để track position
    GlobalKey? categoryKey;
    if (!isBalanceItem) {
      categoryKey = _getKey(summary.category, type);
    }

    return Container(
      // Wrap trong Container với GlobalKey để track position
      key: categoryKey,
      child: GestureDetector(
        onTap: (!isBalanceItem && widget.onCategoryTap != null) ? () {
          widget.onCategoryTap!(summary.category, type);
        } : null,
        onLongPress: (!isBalanceItem && widget.onCategoryLongPress != null) ? () {
          widget.onCategoryLongPress!(summary.category, type);
        } : null,
        child: AnimatedOpacity(
        duration: Duration(milliseconds: 250),
        opacity: shouldDim ? 0.3 : 1.0,
        child: Container(
          margin: EdgeInsets.only(bottom: 6.h),
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: isFocused 
                ? themeColor.withValues(alpha: 0.15)
                : themeColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: isFocused 
                  ? themeColor.withValues(alpha: 0.4)
                  : themeColor.withValues(alpha: 0.2),
              width: isFocused ? 2 : 1,
            ),
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
                        fontWeight: isFocused ? FontWeight.w700 : FontWeight.w500,
                        color: themeColor.withValues(alpha: 0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              // Hiển thị amount và comparison indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatAmount(summary.totalAmount),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: themeColor.withValues(alpha: 0.7),
                        fontWeight: isFocused ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                  // Time comparison indicator
                  if (!isBalanceItem && provider.categoryComparisons.containsKey(summary.category))
                    ComparisonIndicator(
                      comparison: provider.categoryComparisons[summary.category]!,
                    ),
                ],
              ),
              SizedBox(height: 4.h),
              // Thanh %
              if (percentage > 0)
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
                              color: isFocused 
                                  ? themeColor.withValues(alpha: 0.8)
                                  : themeColor.withValues(alpha: 0.6),
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
                        fontWeight: isFocused ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ), // Container (inner - with decoration)
        ), // AnimatedOpacity
      ), // GestureDetector
    ); // Container wrapper (outer - with GlobalKey)
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
            getTranslated(context, 'No flow data available') ?? 'No flow data available',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            getTranslated(context, 'Add income and expenses to see the flow') ?? 'Add income and expenses to see the flow',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }



  /// Format amount with currency using project's existing format system
  String _formatAmount(double amount) {
    return '${format(amount)} $currency';
  }
}