// responsive_extensions.dart

import 'package:responsive_scaler/responsive_scaler.dart';

/// Extension methods để cung cấp các đơn vị tỷ lệ tiện lợi,
/// lấy cảm hứng từ cú pháp của flutter_screenutil.
extension ResponsiveScalerExtensions on num {
  /// Scale một giá trị dựa trên tỷ lệ chiều rộng của màn hình.
  /// Tương đương với .w trong flutter_screenutil.
  /// Dùng cho: chiều rộng, padding ngang, margin ngang, v.v.
  double get w => scale(toDouble());

  /// Scale một giá trị dựa trên tỷ lệ chiều rộng của màn hình.
  /// Lưu ý: Dù có tên là `.h`, nó vẫn scale theo chiều rộng để giữ đúng tỷ lệ khung hình (aspect ratio) của widget.
  /// Dùng cho: chiều cao, padding dọc, margin dọc, v.v.
  double get h => scale(toDouble());

  /// Scale một giá trị font size. Nó cũng dựa trên tỷ lệ chiều rộng
  /// để đảm bảo văn bản trông hài hòa với layout.
  /// Tương đương với .sp trong flutter_screenutil.
  double get sp => scale(toDouble());

  /// Scale một giá trị bán kính (radius).
  /// Tương đương với .r trong flutter_screenutil.
  double get r => scale(toDouble());
}