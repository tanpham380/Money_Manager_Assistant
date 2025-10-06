import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
 import '../utils/responsive_extensions.dart';
import 'package:provider/provider.dart';

import '../classes/constants.dart';
import '../localization/methods.dart';
import '../provider.dart';

class FormatDate extends StatelessWidget {
  const FormatDate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> dateFormats = [
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'yyyy/MM/dd',
      'yMMMd',
      'MMMEd',
      'MEd',
      'MMMMd',
      'MMMd',
    ];
    return Scaffold(
        appBar: AppBar(
            backgroundColor: blue3,
            title: Text(
                getTranslated(context, 'Select a date format') ??
                    'Select a date format',
                style: TextStyle(fontSize: 21.sp)),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 5.w),
                child: TextButton(
                    child: Text(
                      getTranslated(context, 'Save') ?? 'Save',
                      style: TextStyle(fontSize: 18.5.sp, color: white),
                    ),
                    onPressed: () => Navigator.pop(context)),
              )
            ]),
        body: ChangeNotifierProvider<OnDateFormatSelected>(
            create: (context) => OnDateFormatSelected(),
            builder: (context, widget) => Container(
                  color: white,
                  child: ListView.builder(
                      itemCount: dateFormats.length,
                      itemBuilder: (context, index) => GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              context
                                  .read<OnDateFormatSelected>()
                                  .onDateFormatSelected(dateFormats[index]);
                            },
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(27.h),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${DateFormat(dateFormats[index]).format(now)}',
                                          style: TextStyle(
                                            fontSize: 19.sp,
                                          ),
                                        ),
                                        Spacer(),
                                        context
                                                    .watch<
                                                        OnDateFormatSelected>()
                                                    .dateFormat ==
                                                dateFormats[index]
                                            ? Icon(Icons.check_circle,
                                                size: 25.sp, color: blue3)
                                            : SizedBox()
                                      ],
                                    ),
                                  ),
                                  Divider(
                                      height: 0, thickness: 0.25, color: grey)
                                ]),
                          )),
                )));
  }
}
