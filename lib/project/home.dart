import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'app_pages/analysis.dart';
import 'app_pages/input.dart';
import 'classes/constants.dart';
import 'localization/methods.dart';
import 'app_pages/calendar.dart';
import 'app_pages/others.dart';
import 'provider/navigation_provider.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Sử dụng final để cải thiện hiệu năng
  // Các trang này sẽ được giữ trạng thái bởi IndexedStack
  final List<Widget> _pages = [
    AddInput(),
    Analysis(),
    Calendar(),
    Other(),
  ];

  BottomNavigationBarItem _bottomNavigationBarItem(
          IconData iconData, String label) =>
      BottomNavigationBarItem(
        icon: Padding(
          padding: EdgeInsets.only(bottom: 0.h),
          child: Icon(iconData),
        ),
        label: getTranslated(context, label),
      );

  @override
  void initState() {
    super.initState();
    // DB.init(); // Moved to real_main.dart
  }

  @override
  Widget build(BuildContext context) {
    // Khai báo final vì list này không thay đổi trong suốt quá trình build
    final List<BottomNavigationBarItem> bottomItems = <BottomNavigationBarItem>[
      _bottomNavigationBarItem(Icons.add, 'Input'),
      _bottomNavigationBarItem(Icons.analytics_outlined, 'Analysis'),
      _bottomNavigationBarItem(Icons.calendar_today, 'Calendar'),
      _bottomNavigationBarItem(Icons.account_circle, 'Other'),
    ];

    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        return Scaffold(
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
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
                currentIndex: navProvider.currentTabIndex,
                onTap: (int index) {
                  navProvider.changeTab(index);
                },
              ),
            ),
            body: IndexedStack(
              index: navProvider.currentTabIndex,
              children: _pages,
            ));
      },
    );
  }
}
