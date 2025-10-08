import 'package:flutter/material.dart';
import '../utils/responsive_extensions.dart';
import 'package:provider/provider.dart';

import '../classes/constants.dart';
import '../localization/language.dart';
import '../localization/methods.dart';
import '../provider.dart';

class Currency extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<Language> languageList = Language.languageList;
    return Scaffold(
        appBar: AppBar(
            backgroundColor: blue3,
            title: Text(
                getTranslated(context, 'Select a currency') ??
                    'Select a currency',
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
        body: ChangeNotifierProvider<OnCurrencySelected>(
          create: (context) => OnCurrencySelected(),
          builder: (context, widget) => Container(
              color: white,
              child: ListView.builder(
                  itemCount: languageList.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        context.read<OnCurrencySelected>().onCurrencySelected(
                            '${languageList[index].languageCode}_${languageList[index].countryCode}');
                      },
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 15.w, vertical: 10.h),
                            child: Row(
                              children: [
                                Text(
                                  Language.languageList[index].flag,
                                  style: TextStyle(fontSize: 45.sp),
                                ),
                                SizedBox(width: 30.w),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        Language
                                            .languageList[index].currencyName,
                                        style: TextStyle(fontSize: 20.sp)),
                                    SizedBox(height: 2.5.h),
                                    Text(
                                        Language
                                            .languageList[index].currencyCode,
                                        style: TextStyle(fontSize: 15.sp))
                                  ],
                                ),
                                Spacer(),
                                context
                                            .watch<OnCurrencySelected>()
                                            .appCurrency ==
                                        '${languageList[index].languageCode}_${languageList[index].countryCode}'
                                    ? Icon(Icons.check_circle,
                                        size: 25.sp, color: blue3)
                                    : SizedBox(),
                                SizedBox(width: 25.w),
                                Text(
                                  Language.languageList[index].currencySymbol,
                                  style: TextStyle(fontSize: 23.sp),
                                ),
                                SizedBox(width: 15.w)
                              ],
                            ),
                          ),
                          Divider(
                            indent: 75.w,
                            height: 0,
                            thickness: 0.25.h,
                            color: grey,
                          ),
                        ],
                      ),
                    );
                  })),
        ));
  }
}
