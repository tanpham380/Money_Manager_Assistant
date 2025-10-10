import 'package:flutter/material.dart';
import '../provider/analysis_provider.dart';

/// CustomPainter đơn giản để vẽ dòng chảy Sankey giữa Income và Expense items
class SankeyPainter extends CustomPainter {
  final List<SankeyFlow> flows;
  final List<CategorySummary> incomeCategories;
  final List<CategorySummary> expenseCategories;
  final List<dynamic> destinations;
  final Map<String, Offset> itemPositions;
  final double? maxAmount; // Pre-calculated maxAmount
  final String? focusedCategory; // Focused category for highlighting
  final String? focusedType; // Focused type for highlighting
  final Function(String category)? onCategoryTap;

  SankeyPainter({
    required this.flows,
    required this.incomeCategories,
    required this.expenseCategories,
    required this.destinations,
    required this.itemPositions,
    this.maxAmount, // Optional pre-calculated maxAmount
    this.focusedCategory, // Optional focused category
    this.focusedType, // Optional focused type
    this.onCategoryTap,
  });

    @override
  void paint(Canvas canvas, Size size) {
    final visibleFlows = flows.where((flow) => flow.isVisible).toList();
    
    if (visibleFlows.isEmpty || incomeCategories.isEmpty) {
      return;
    }

    if (itemPositions.isEmpty) {
      return;
    }

    // Check if we have focus mode active
    final hasFocus = focusedCategory != null;

    // Sử dụng pre-calculated maxAmount hoặc tính mới nếu không có
    final calculatedMaxAmount = maxAmount ?? visibleFlows
        .map((flow) => flow.amount)
        .fold<double>(0.0, (prev, curr) => curr > prev ? curr : prev);

    if (calculatedMaxAmount <= 0) return;

    try {
      // Draw flows with focus-aware rendering
      for (final flow in visibleFlows.where((f) => !f.isPrimary)) {
        _drawFlowWithBezierCurve(canvas, size, flow, calculatedMaxAmount, hasFocus);
      }
      
      for (final flow in visibleFlows.where((f) => f.isPrimary)) {
        _drawFlowWithBezierCurve(canvas, size, flow, calculatedMaxAmount, hasFocus);
      }
    } catch (e) {
      for (final flow in visibleFlows) {
        _drawFlowWithBezierCurve(canvas, size, flow, calculatedMaxAmount, hasFocus);
      }
    }
  }

  void _drawFlowWithBezierCurve(Canvas canvas, Size size, SankeyFlow flow, double maxAmount, bool hasFocus) {
    final sourcePos = itemPositions['income_${flow.fromCategory}'];
    
    String targetKey;
    if (flow.toCategory == 'Balance') {
      targetKey = 'expense_Balance';
    } else {
      targetKey = 'expense_${flow.toCategory}';
    }
    final targetPos = itemPositions[targetKey];
    
    // Debug logging để kiểm tra positions
    if (flow.toCategory == 'Balance') {
    }

    // Check if this flow should be highlighted or dimmed
    bool isHighlighted = false;
    bool shouldDim = false;
    
    if (hasFocus) {
      // Check if this flow involves the focused category
      isHighlighted = (flow.fromCategory == focusedCategory && focusedType == 'Income') ||
                     (flow.toCategory == focusedCategory && focusedType == 'Expense');
      shouldDim = !isHighlighted;
      
    }
    
    final hasValidPositions = sourcePos != null && 
                              targetPos != null &&
                              sourcePos.dx.isFinite && 
                              sourcePos.dy.isFinite &&
                              targetPos.dx.isFinite && 
                              targetPos.dy.isFinite &&
                              targetPos.dx > sourcePos.dx;
    
    if (!hasValidPositions) {
      if (flow.toCategory == 'Balance') {
      }
      _drawFlowFallback(canvas, size, flow, maxAmount, isHighlighted, shouldDim);
      return;
    }

    final normalizedAmount = flow.amount / maxAmount;
    final isPrimary = flow.isPrimary;
    double strokeWidth;
    
    if (isPrimary) {
      strokeWidth = (1.0 + normalizedAmount * 2.0).clamp(1.0, 3.0);
    } else {
      strokeWidth = (0.5 + normalizedAmount * 1.0).clamp(0.5, 1.5);
    }

    final path = _createBezierPath(sourcePos, targetPos, size);

    // Create gradient based on flow type
    LinearGradient gradient;
    
    if (flow.toCategory == 'Balance') {
      // Special gradient for Balance flows based on amount (positive/negative)
      if (flow.amount >= 0) {
        // Positive balance: Full green gradient
        gradient = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF00C851).withValues(alpha: 0.9), // Bright Green
            Color(0xFF32CD32).withValues(alpha: 0.8), // Lime Green  
            Color(0xFF00E676).withValues(alpha: 0.7), // Light Green
            Color(0xFF4CAF50).withValues(alpha: 0.8), // Material Green
            Color(0xFF2E7D32).withValues(alpha: 0.9), // Dark Green
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        );
      } else {
        // Negative balance: Full red gradient
        gradient = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFF5722).withValues(alpha: 0.9), // Deep Orange
            Color(0xFFFF6347).withValues(alpha: 0.8), // Tomato Red  
            Color(0xFFDC143C).withValues(alpha: 0.7), // Crimson
            Color(0xFFB71C1C).withValues(alpha: 0.8), // Dark Red
            Color(0xFF8B0000).withValues(alpha: 0.9), // Dark Red
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        );
      }
    } else {
      // Default teal-green-red gradient for regular flows
      gradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF20B2AA).withValues(alpha: 0.9), // Dark Teal
          Color(0xFF40E0D0).withValues(alpha: 0.7), // Turquoise  
          Color(0xFF32CD32).withValues(alpha: 0.6), // Lime Green
          Color(0xFFFF6347).withValues(alpha: 0.6), // Tomato Red
          Color(0xFFDC143C).withValues(alpha: 0.7), // Crimson
          Color(0xFF8B0000).withValues(alpha: 0.9), // Dark Red
        ],
        stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
      );
    }

    final rect = Rect.fromLTWH(
      sourcePos.dx, 
      sourcePos.dy - strokeWidth / 2,
      (targetPos.dx - sourcePos.dx).clamp(0.0, double.infinity),
      strokeWidth,
    );
    
    // Apply focus effects to paint
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Apply focus effects
    if (hasFocus) {
      if (isHighlighted) {
        // Highlighted flows: brighter and thicker
        paint.strokeWidth = strokeWidth * 1.5;
        // Make colors more vibrant by reducing transparency
        final colors = gradient.colors.map((color) => color.withValues(alpha: 1.0)).toList();
        final highlightGradient = LinearGradient(
          begin: gradient.begin,
          end: gradient.end,
          colors: colors,
        );
        paint.shader = highlightGradient.createShader(rect);
      } else if (shouldDim) {
        // Dimmed flows: more transparent and thinner
        paint.strokeWidth = strokeWidth * 0.6;
        paint.color = Colors.grey.withValues(alpha: 0.3);
        paint.shader = null; // Remove gradient for dimmed flows
      }
    }

    canvas.drawPath(path, paint);
  }

  Path _createBezierPath(Offset start, Offset end, Size canvasSize) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    final distance = end.dx - start.dx;
    final verticalDistance = (end.dy - start.dy).abs();
    
    // Smooth curve calculation based on distance and vertical gap
    final controlDistance = distance * 0.5 + verticalDistance * 0.1;
    
    final controlPoint1 = Offset(start.dx + controlDistance, start.dy);
    final controlPoint2 = Offset(end.dx - controlDistance, end.dy);

    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      end.dx, end.dy,
    );

    return path;
  }

  void _drawFlowFallback(Canvas canvas, Size size, SankeyFlow flow, double maxAmount, bool isHighlighted, bool shouldDim) {
    final sourceIndex = incomeCategories.indexWhere((cat) => cat.category == flow.fromCategory);
    final targetIndex = destinations.indexWhere((item) => item.category == flow.toCategory);

    if (sourceIndex == -1 || targetIndex == -1) return;

    if (!size.width.isFinite || !size.height.isFinite || size.width <= 0 || size.height <= 0) {
      return;
    }

    final totalIncomeItems = incomeCategories.length.clamp(1, 20);
    final totalDestinationItems = destinations.length.clamp(1, 20);
    
    final itemSpacing = totalIncomeItems > 10 ? 4.0 : 6.0;
    final destinationSpacing = totalDestinationItems > 10 ? 4.0 : 6.0;
    
    final itemHeight = (size.height - (totalIncomeItems - 1) * itemSpacing) / totalIncomeItems;
    final destinationItemHeight = (size.height - (totalDestinationItems - 1) * destinationSpacing) / totalDestinationItems;
    
    final sourceY = (sourceIndex * (itemHeight + itemSpacing) + itemHeight / 2).clamp(0.0, size.height);
    final targetY = (targetIndex * (destinationItemHeight + destinationSpacing) + destinationItemHeight / 2).clamp(0.0, size.height);
    
    final startX = size.width * 0.05;
    final endX = size.width * 0.95;

    final normalizedAmount = (flow.amount / maxAmount).clamp(0.0, 1.0);
    final strokeWidth = flow.isPrimary 
        ? (1.0 + normalizedAmount * 2.0).clamp(1.0, 3.0)
        : (0.5 + normalizedAmount * 1.0).clamp(0.5, 1.5);

    // Create gradient for fallback method - same logic as main method
    LinearGradient gradient;
    
    if (flow.toCategory == 'Balance') {
      // Special gradient for Balance flows based on amount (positive/negative)
      if (flow.amount >= 0) {
        // Positive balance: Full green gradient
        gradient = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF00C851).withValues(alpha: 0.9), // Bright Green
            Color(0xFF32CD32).withValues(alpha: 0.8), // Lime Green  
            Color(0xFF00E676).withValues(alpha: 0.7), // Light Green
            Color(0xFF4CAF50).withValues(alpha: 0.8), // Material Green
            Color(0xFF2E7D32).withValues(alpha: 0.9), // Dark Green
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        );
      } else {
        // Negative balance: Full red gradient
        gradient = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFF5722).withValues(alpha: 0.9), // Deep Orange
            Color(0xFFFF6347).withValues(alpha: 0.8), // Tomato Red  
            Color(0xFFDC143C).withValues(alpha: 0.7), // Crimson
            Color(0xFFB71C1C).withValues(alpha: 0.8), // Dark Red
            Color(0xFF8B0000).withValues(alpha: 0.9), // Dark Red
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        );
      }
    } else {
      // Default teal-green-red gradient for regular flows
      gradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF20B2AA).withValues(alpha: 0.9), // Dark Teal
          Color(0xFF40E0D0).withValues(alpha: 0.7), // Turquoise  
          Color(0xFF32CD32).withValues(alpha: 0.6), // Lime Green
          Color(0xFFFF6347).withValues(alpha: 0.6), // Tomato Red
          Color(0xFFDC143C).withValues(alpha: 0.7), // Crimson
          Color(0xFF8B0000).withValues(alpha: 0.9), // Dark Red
        ],
        stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
      );
    }

    final rect = Rect.fromLTWH(
      startX, 
      sourceY - strokeWidth / 2,
      (endX - startX).clamp(0.0, double.infinity),
      strokeWidth,
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Apply focus effects to fallback paint
    if (isHighlighted) {
      // Highlighted flows: brighter and thicker
      paint.strokeWidth = strokeWidth * 1.5;
      final colors = gradient.colors.map((color) => color.withValues(alpha: 1.0)).toList();
      final highlightGradient = LinearGradient(
        begin: gradient.begin,
        end: gradient.end,
        colors: colors,
      );
      paint.shader = highlightGradient.createShader(rect);
    } else if (shouldDim) {
      // Dimmed flows: more transparent and thinner
      paint.strokeWidth = strokeWidth * 0.6;
      paint.color = Colors.grey.withValues(alpha: 0.3);
      paint.shader = null; // Remove gradient for dimmed flows
    }

    final path = Path();
    path.moveTo(startX, sourceY);
    
    final controlX = startX + (endX - startX) * 0.6;
    path.cubicTo(
      controlX, sourceY,
      endX - (endX - startX) * 0.4, targetY,
      endX, targetY,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
