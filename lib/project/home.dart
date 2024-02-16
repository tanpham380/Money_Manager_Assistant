import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_pages/analysis.dart';
import 'app_pages/input.dart';
import 'classes/constants.dart';
import 'database_management/sqflite_services.dart';
import 'localization/methods.dart';
import 'app_pages/calendar.dart';
import 'app_pages/others.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  List<Widget> myBody = [
    AddInput(),
    Analysis(),
    Calendar(),
    Other(),
  ];
  BottomNavigationBarItem bottomNavigationBarItem(
          IconData iconData, String label) =>
      BottomNavigationBarItem(
        icon: Padding(
          padding: EdgeInsets.only(bottom: 0.h),
          child: Icon(
            iconData,
          ),
        ),
        label: getTranslated(context, label),
      );

  @override
  void initState() {
    super.initState();
    DB.init();
   
  }

  @override
  Widget build(BuildContext context) {
    List<BottomNavigationBarItem> bottomItems = <BottomNavigationBarItem>[
      bottomNavigationBarItem(Icons.add, 'Input'),
      bottomNavigationBarItem(Icons.analytics_outlined, 'Analysis'),
      bottomNavigationBarItem(Icons.calendar_today, 'Calendar'),
      bottomNavigationBarItem(Icons.account_circle, 'Other'),
    ];

    return Scaffold(
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: grey,
              ),
            ],
          ),
          child: BottomNavigationBar(
            iconSize: 27.sp,
            selectedFontSize: 16.sp,
            unselectedFontSize: 14.sp,
            backgroundColor: blue1,
            selectedItemColor: const Color.fromARGB(255, 255, 136, 0),
            unselectedItemColor: Colors.black87,
            type: BottomNavigationBarType.fixed,
            items: bottomItems,
            currentIndex: _selectedIndex,
            onTap: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
        body: myBody[_selectedIndex]);
  }
}
