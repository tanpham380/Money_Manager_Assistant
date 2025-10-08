import 'package:flutter/material.dart';
import '../utils/responsive_extensions.dart';
import 'package:provider/provider.dart';

import '../classes/app_bar.dart';
import '../classes/constants.dart';
import '../localization/methods.dart';
import '../provider.dart';
import 'add_category.dart';
import 'edit_income_category.dart';

class IncomeCategory extends StatefulWidget {
  @override
  _IncomeCategoryState createState() => _IncomeCategoryState();
}

class _IncomeCategoryState extends State<IncomeCategory> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChangeIncomeItem>(
        create: (context) => ChangeIncomeItem(),
        child: Builder(
            builder: (buildContext) => Scaffold(
                backgroundColor: blue1,
                appBar: CategoryAppBar(EditIncomeCategory(buildContext)),
                body: IncomeCategoryBody(
                    context: buildContext, editIncomeCategory: false))));
  }
}

class IncomeCategoryBody extends StatefulWidget {
  final BuildContext? context, contextEdit;
  final bool editIncomeCategory;
  IncomeCategoryBody(
      {this.context, this.contextEdit, required this.editIncomeCategory});

  @override
  _IncomeCategoryBodyState createState() => _IncomeCategoryBodyState();
}

class _IncomeCategoryBodyState extends State<IncomeCategoryBody> {
  @override
  Widget build(BuildContext context) {
    var incomeList = widget.contextEdit == null
        ? Provider.of<ChangeIncomeItem>(widget.context!).incomeItems
        : Provider.of<ChangeIncomeItemEdit>(widget.contextEdit!).incomeItems;
    return Padding(
      padding: EdgeInsets.only(top: 30.h),
      child: ListView.builder(
        itemCount: incomeList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(top: 3.h, left: 10.w, right: 10.w),
            child: GestureDetector(
              onLongPress: () {
                if (widget.editIncomeCategory) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddCategory(
                              contextIn: widget.context,
                              contextInEdit: widget.contextEdit,
                              type: 'Income',
                              appBarTitle: 'Add Income Category',
                              categoryName: incomeList[index].text,
                              categoryIcon: iconData(incomeList[index]),
                              description: incomeList[index].description!)));
                }
              },
              onTap: () {
                if (widget.editIncomeCategory) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddCategory(
                              contextIn: widget.context,
                              contextInEdit: widget.contextEdit,
                              type: 'Income',
                              appBarTitle: 'Add Income Category',
                              categoryName: incomeList[index].text,
                              categoryIcon: iconData(incomeList[index]),
                              description: incomeList[index].description!)));
                } else {
                  Navigator.pop(context, incomeList[index]);
                }
              },
              child: Card(
                elevation: 5,
                color: white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35.r),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40.h,
                      ),
                      CircleAvatar(
                        backgroundColor: Color.fromRGBO(215, 223, 231, 1),
                        radius: 25.r,
                        child: Icon(
                          iconData(incomeList[index]),
                          size: 33.sp,
                          color: green,
                        ),
                      ),
                      SizedBox(
                        width: 25.w,
                      ),
                      Text(
                        getTranslated(context, incomeList[index].text) ??
                            incomeList[index].text,
                        style: TextStyle(
                            fontSize: 20.sp, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
