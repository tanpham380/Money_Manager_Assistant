import 'package:flutter/material.dart';
import '../provider/analysis_provider.dart';

/// CustomPainter đơn giản để vẽ dòng chảy Sankey giữa Income và Expense items
class SankeyPainter extends CustomPainter {
  final List<SankeyFlow> flows;
  final List<CategorySummary> incomeCategories;
  final List<CategorySummary> expenseCategories;
  final Map<String, Offset> itemPositions;
  final Function(String category)? onCategoryTap;

  SankeyPainter({
    required this.flows,
    required this.incomeCategories,
    required this.expenseCategories,
    required this.itemPositions,
    this.onCategoryTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final visibleFlows = flows.where((flow) => flow.isVisible).toList();
    
    if (visibleFlows.isEmpty || incomeCategories.isEmpty || expenseCategories.isEmpty) {
      return;
    }

    // Tính max amount để normalize độ dày stroke
    final maxAmount = visibleFlows
        .map((flow) => flow.amount)
        .fold<double>(0.0, (prev, curr) => curr > prev ? curr : prev);

    if (maxAmount <= 0) return;

    // Vẽ flows với cubic Bezier curves và gradient colors
    try {
      // Vẽ secondary flows trước (background)
      for (final flow in visibleFlows.where((f) => !f.isPrimary)) {
        _drawFlowWithBezierCurve(canvas, size, flow, maxAmount);
      }
      
      // Vẽ primary flows sau (foreground)
      for (final flow in visibleFlows.where((f) => f.isPrimary)) {
        _drawFlowWithBezierCurve(canvas, size, flow, maxAmount);
      }
    } catch (e) {
      // Fallback: vẽ tất cả flows nếu có lỗi
      for (final flow in visibleFlows) {
        _drawFlowWithBezierCurve(canvas, size, flow, maxAmount);
      }
    }
  }

  /// Vẽ một flow với cubic Bezier curve và gradient color
  void _drawFlowWithBezierCurve(Canvas canvas, Size size, SankeyFlow flow, double maxAmount) {
    // Lấy position của source và target
    final sourcePos = itemPositions['income_${flow.fromCategory}'];
    final targetPos = itemPositions['expense_${flow.toCategory}'];
    
    if (sourcePos == null || targetPos == null) {
      // Fallback: sử dụng calculation cũ nếu không có position data
      _drawFlowFallback(canvas, size, flow, maxAmount);
      return;
    }

    // Tính toán độ dày dựa trên amount - mảnh mai hơn nữa
    final normalizedAmount = flow.amount / maxAmount;
    final isPrimary = flow.isPrimary;
    double strokeWidth;
    
    if (isPrimary) {
      strokeWidth = (1.0 + normalizedAmount * 2.0).clamp(1.0, 3.0); // Giảm xuống 1-3px
    } else {
      strokeWidth = (0.5 + normalizedAmount * 1.0).clamp(0.5, 1.5); // Giảm xuống 0.5-1.5px
    }

    // Tạo cubic Bezier path cho flow hình chữ S
    final path = _createBezierPath(sourcePos, targetPos, size);

    // Tạo gradient shader từ sourceColor đến targetColor với nhiều điểm dừng
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        flow.sourceColor.withValues(alpha: 0.7),
        Color.lerp(flow.sourceColor, flow.targetColor, 0.5)!.withValues(alpha: 0.6), // Màu blend ở giữa
        flow.targetColor.withValues(alpha: 0.7),
      ],
      stops: const [0.0, 0.5, 1.0], // Vị trí các màu: đầu, giữa, cuối
    );

    // Tạo paint với gradient shader
    final rect = Rect.fromLTWH(
      sourcePos.dx, 
      sourcePos.dy - strokeWidth / 2,
      targetPos.dx - sourcePos.dx,
      strokeWidth,
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Vẽ path
    canvas.drawPath(path, paint);
  }

  /// Tạo cubic Bezier path tạo hình chữ S mượt mà
  Path _createBezierPath(Offset start, Offset end, Size canvasSize) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Tính toán control points cho cubic Bezier curve
    final distance = end.dx - start.dx;
    final controlDistance = distance * 0.6; // 60% của khoảng cách ngang
    
    final controlPoint1 = Offset(start.dx + controlDistance, start.dy);
    final controlPoint2 = Offset(end.dx - controlDistance, end.dy);

    // Tạo cubic Bezier curve tạo hình chữ S uyển chuyển
    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      end.dx, end.dy,
    );

    return path;
  }

  /// Fallback method sử dụng calculation cũ khi không có position data
  void _drawFlowFallback(Canvas canvas, Size size, SankeyFlow flow, double maxAmount) {
    // Tìm index của source và target categories
    final sourceIndex = incomeCategories.indexWhere((cat) => cat.category == flow.fromCategory);
    final targetIndex = expenseCategories.indexWhere((cat) => cat.category == flow.toCategory);

    if (sourceIndex == -1 || targetIndex == -1) return;

    // Tính vị trí theo method cũ
    final totalIncomeItems = incomeCategories.length.clamp(1, 10);
    final totalExpenseItems = expenseCategories.length.clamp(1, 10);
    
    final itemSpacing = 6.0;
    final itemHeight = (size.height - (totalIncomeItems - 1) * itemSpacing) / totalIncomeItems;
    final expenseItemHeight = (size.height - (totalExpenseItems - 1) * itemSpacing) / totalExpenseItems;
    
    final sourceY = sourceIndex * (itemHeight + itemSpacing) + itemHeight / 2;
    final targetY = targetIndex * (expenseItemHeight + itemSpacing) + expenseItemHeight / 2;
    final startX = 0.0;
    final endX = size.width;

    final normalizedAmount = flow.amount / maxAmount;
    final strokeWidth = flow.isPrimary 
        ? (1.0 + normalizedAmount * 2.0).clamp(1.0, 3.0) // Giảm xuống 1-3px
        : (0.5 + normalizedAmount * 1.0).clamp(0.5, 1.5); // Giảm xuống 0.5-1.5px

    // Tạo gradient với blend màu ở giữa
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        flow.sourceColor.withValues(alpha: 0.7),
        Color.lerp(flow.sourceColor, flow.targetColor, 0.5)!.withValues(alpha: 0.6),
        flow.targetColor.withValues(alpha: 0.7),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromLTWH(startX, sourceY - strokeWidth / 2, endX - startX, strokeWidth);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Tạo cubic Bezier path
    final path = Path();
    path.moveTo(startX, sourceY);
    
    final distance = endX - startX;
    final controlDistance = distance * 0.6;
    final controlPoint1 = Offset(startX + controlDistance, sourceY);
    final controlPoint2 = Offset(endX - controlDistance, targetY);
    
    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      endX, targetY,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! SankeyPainter ||
        oldDelegate.flows != flows ||
        oldDelegate.incomeCategories != incomeCategories ||
        oldDelegate.expenseCategories != expenseCategories ||
        oldDelegate.itemPositions != itemPositions;
  }
}