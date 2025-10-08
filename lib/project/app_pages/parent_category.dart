import 'package:flutter/material.dart';
import '../utils/responsive_extensions.dart';

import '../classes/app_bar.dart';
import '../classes/category_item.dart';
import '../classes/constants.dart';
import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';

class ParentCategoryList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<CategoryItem> parentCategories = sharedPrefs
        .getAllExpenseItemsLists()
        .map((item) => CategoryItem(
            item[0].iconCodePoint,
            item[0].iconFontPackage,
            item[0].iconFontFamily,
            item[0].text,
            item[0].description))
        .toList();
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: BasicAppBar(getTranslated(context, 'Parent category')!),
      ),
      body: ListView.builder(
        itemCount: parentCategories.length,
        itemBuilder: (context, index) {
          return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                Navigator.pop(context, parentCategories[index]);
              },
              child: Column(
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    child: Row(
                      children: [
                        CircleAvatar(
                            backgroundColor: Color.fromRGBO(215, 223, 231, 1),
                            radius: 20.r,
                            child: Icon(
                              iconData(parentCategories[index]),
                              size: 25.sp,
                              color: red,
                            )),
                        SizedBox(
                          width: 28.w,
                        ),
                        Expanded(
                          child: Text(
                            getTranslated(
                                    context, parentCategories[index].text) ??
                                parentCategories[index].text,
                            style: TextStyle(fontSize: 22.sp),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  ),
                  Divider(
                    thickness: 0.25.h,
                    indent: 67.w,
                    color: grey,
                  )
                ],
              ));
        },
      ),
    );
  }
}
