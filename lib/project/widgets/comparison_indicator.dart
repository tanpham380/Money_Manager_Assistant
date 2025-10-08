import 'package:flutter/material.dart';
import '../provider/analysis_provider.dart';
import '../utils/responsive_extensions.dart';

/// Widget hiển thị chỉ báo so sánh với kỳ trước
class ComparisonIndicator extends StatelessWidget {
  final ComparisonData comparison;

  const ComparisonIndicator({
    Key? key,
    required this.comparison,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!comparison.hasValidComparison) {
      return const SizedBox.shrink();
    }

    final isPositive = comparison.isPositiveChange;
    final percentage = comparison.changePercentage;
    
    // Màu sắc: xanh = tích cực, đỏ = tiêu cực
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    
    return Container(
      margin: EdgeInsets.only(top: 2.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10.sp,
            color: color,
          ),
          SizedBox(width: 2.w),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 9.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget cho trend arrow với animation
class TrendArrow extends StatefulWidget {
  final bool isPositive;
  final double percentage;
  final Color color;

  const TrendArrow({
    Key? key,
    required this.isPositive,
    required this.percentage,
    required this.color,
  }) : super(key: key);

  @override
  State<TrendArrow> createState() => _TrendArrowState();
}

class _TrendArrowState extends State<TrendArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(TrendArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPositive != widget.isPositive ||
        oldWidget.percentage != widget.percentage) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 10.sp,
                  color: widget.color,
                ),
                SizedBox(width: 2.w),
                Text(
                  '${widget.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: widget.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}