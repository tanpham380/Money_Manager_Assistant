 
import 'package:responsive_scaler/responsive_scaler.dart';
/// Extension methods để tương thích với flutter_screenutil
/// Cung cấp .w, .h, .sp, .r extensions giống như flutter_screenutil
extension ResponsiveExtensions on num {
  /// Width scaling - tương đương với .w của flutter_screenutil
  double get w => scale(toDouble());
  
  /// Height scaling - tương đương với .h của flutter_screenutil
  double get h => scale(toDouble());
  
  /// Font size scaling - tương đương với .sp của flutter_screenutil
  double get sp => scale(toDouble());
  
  /// Radius scaling - tương đương với .r của flutter_screenutil
  double get r => scale(toDouble());
}
