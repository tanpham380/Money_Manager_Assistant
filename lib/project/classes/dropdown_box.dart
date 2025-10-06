import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
 import '../utils/responsive_extensions.dart';

import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';
import '../provider.dart';
import '../provider/analysis_provider.dart';
import 'constants.dart';

class DropDownBox extends StatelessWidget {
  final bool forAnalysis;
  final String selectedDate;
  const DropDownBox(this.forAnalysis, this.selectedDate);
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        shadows: [BoxShadow()],
        color: blue2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.r))),
      ),
      child: SizedBox(
        height: 35.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: DropdownButtonHideUnderline(
            child: DropdownButton(
              dropdownColor: blue2,
              value: selectedDate,
              elevation: 10,
              icon: Icon(
                Icons.arrow_drop_down_outlined,
                size: 28.sp,
              ),
              onChanged: (value) {
                if (forAnalysis) {
                  // Chỉ cập nhật AnalysisProvider cho màn hình Analysis
                  try {
                    final analysisProvider = context.read<AnalysisProvider>();
                    analysisProvider.updateDateOption(value.toString());
                    sharedPrefs.selectedDate = value.toString();
                  } catch (e) {
                    // Fallback: nếu không tìm thấy AnalysisProvider
                    print('AnalysisProvider not found in context: $e');
                  }
                } else {
                  // Cho màn hình Report, vẫn dùng provider cũ
                  try {
                    context.read<ChangeSelectedDate>().changeSelectedReportDate(
                        newSelectedDate: value.toString());
                  } catch (e) {
                    print('ChangeSelectedDate not found in context: $e');
                  }
                }
              },
              items: timeline
                  .map((time) => DropdownMenuItem(
                        value: time,
                        child: Text(
                          getTranslated(context, time)!,
                          style: TextStyle(fontSize: 18.5.sp),
                          textAlign: TextAlign.center,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
