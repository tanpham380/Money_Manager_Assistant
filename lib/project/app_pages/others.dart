import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;

import '../classes/alert_dialog.dart';
import '../classes/constants.dart';
import '../classes/custom_toast.dart';
import '../database_management/shared_preferences_services.dart';
import '../database_management/sqflite_services.dart';
import '../localization/methods.dart';
import '../provider.dart';
import 'currency.dart';
import 'select_date_format.dart';
import 'select_language.dart';

class Other extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        primary: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            150.h,
          ),
          child: Container(
            color: blue3,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 0),
            height: 150.h,
            child: Padding(
              padding: EdgeInsets.only(top: 30.w),
              child: Row(
                children: [
                  CircleAvatar(
                    child: CircleAvatar(
                        child: Icon(
                          FontAwesomeIcons.buildingColumns,
                          color: Colors.black,
                          size: 30.sp,
                        ),
                        radius: 35.r,
                        backgroundColor: blue1),
                    radius: 40.r,
                    // backgroundColor: Colors.orangeAccent,
                  ),
                  SizedBox(
                    width: 20.w,
                  ),
                  Text(
                    '${getTranslated(context, 'Hi you')!}!' ,
                    style: TextStyle(fontSize: 30.sp),
                  ),
                  // Spacer(),
                  // Icon(
                  //   Icons.notifications_rounded,
                  //   size: 25.sp,
                  // )
                ],
              ),
            ),
          ),
        ),
        body: ChangeNotifierProvider<OnSwitch>(
            create: (context) => OnSwitch(),
            builder: (context, widget) => Settings(providerContext: context)));
  }
}

class Settings extends StatefulWidget {
  final BuildContext providerContext;
  const Settings({required this.providerContext});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    List<Widget> pageRoute = [
      SelectLanguage(),
      Currency(),
    ];
    List<Widget> settingsIcons = [
      Icon(
        Icons.language,
        size: 32.sp,
        color: Colors.lightBlue,
      ),
      Icon(
        Icons.monetization_on,
        size: 32.sp,
        color: Colors.orangeAccent,
      ),
      Icon(Icons.date_range, size: 32.sp, color: Colors.lightBlue),
      Icon(Icons.refresh, size: 32.sp, color: Colors.lightBlue),
      Icon(Icons.delete_forever, size: 32.sp, color: red),
      Icon(Icons.lock, size: 32.sp, color: Colors.lightBlue)
    ];
    List<String> settingsList = [
      getTranslated(context, 'Language') ?? 'Language',
      getTranslated(context, 'Currency') ?? 'Currency',
      (getTranslated(context, 'Date format') ?? 'Date format') +
          ' (${DateFormat(sharedPrefs.dateFormat).format(now)})',
      getTranslated(context, 'Reset All Categories') ?? 'Reset All Categories',
      getTranslated(context, 'Delete All Data') ?? 'Delete All Data',
      getTranslated(context, 'Change Passcode') ?? 'Change Passcode',
    ];

    return Container(
      color:  white,  
      child:     ListView.builder(
        itemCount: settingsList.length,
        itemBuilder: (context, int) {
          return GestureDetector(
            onTap: () async {
              if ((int == 0 || int == 1)) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => pageRoute[int]));
              } else if (int == 2) {
                Navigator.push(context,
                        MaterialPageRoute(builder: (context) => FormatDate()))
                    .then((value) => setState(() {}));
              } else if (int == 3) {
                // Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //         builder: (context) => EditIncomeCategory(null)));
                void onReset() {
                  sharedPrefs.setItems(setCategoriesToDefault: true);
                  customToast(context, 'Categories have been reset');
                }

                Platform.isIOS
                    ? await iosDialog(
                        context,
                        'This action cannot be undone. Are you sure you want to reset all categories?',
                        'Reset',
                        onReset)
                    : await androidDialog(
                        context,
                        'This action cannot be undone. Are you sure you want to reset all categories?',
                        'reset',
                        onReset);
              } else if (int == 4) {
                Future onDeletion() async {
                  await DB.deleteAll();
                  customToast(context, 'All data has been deleted');
                }

                Platform.isIOS
                    ? await iosDialog(
                        context,
                        'Deleted data can not be recovered. Are you sure you want to delete all data?',
                        'Delete',
                        onDeletion)
                    : await androidDialog(
                        context,
                        'Deleted data can not be recovered. Are you sure you want to delete all data?',
                        'Delete',
                        onDeletion);
              } else if (int == 5) {
                final controller = InputController();
                screenLockCreate(
                  context: context,
                  title: Text(getTranslated(context, 'Change Passcode') ??
              'Change Passcode',
      ),
                  confirmTitle:      Text(getTranslated(context, 'Confirm Passcode') ??
              'Confirm Passcode',
      ),
                  digits: 6,
                  inputController: controller,
                   customizedButtonChild: Icon(Icons.lock_reset),
                  customizedButtonTap: () {
                    controller.unsetConfirmed();
                  },
                  // footer: TextButton(
                  //         onPressed: () {
                  //            controller.unsetConfirmed();
                  //         },
                  //         child: const Text('Reset input', style: TextStyle(color: Colors.blue),),
                  //       ),
                  onConfirmed: (matchedText) {

                    sharedPrefs.passcodeScreenLock = matchedText;
                    Navigator.of(context).pop();
                    customToast(context, 'Passcode has been changed');
                  }
                      
                );

              }
            },
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 7.h),
                  child: SizedBox(
                    child: Center(
                        child: ListTile(
                      title: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text(
                          '${settingsList[int]}',
                          style: TextStyle(fontSize: 18.5.sp),
                        ),
                      ),
                      leading: CircleAvatar(
                          radius: 24.r,
                          backgroundColor: Color.fromRGBO(229, 231, 234, 1),
                          child: settingsIcons[int]),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 20.sp,
                        color: Colors.blueGrey,
                      ),
                    )),
                  ),
                ),
                Divider(
                  indent: 78.w,
                  height: 0.1.h,
                  thickness: 0.4.h,
                  color: grey,
                ),
              ],
            ),
          );
        }),
  
  
    );
    
    
    

  
  
  
  
  }
}

// class Upgrade extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         Container(
//           height: 165.h,
//           color: Color.fromRGBO(234, 234, 234, 1),
//         ),
//         Container(
//           alignment: Alignment.center,
//           height: 115.h,
//           decoration: BoxDecoration(
//               image: DecorationImage(
//                   fit: BoxFit.fill, image: AssetImage('images/image13.jpg'))),
//         ),
//         Container(
//           alignment: Alignment.center,
//           decoration: BoxDecoration(
//               color: Color.fromRGBO(255, 255, 255, 1),
//               borderRadius: BorderRadius.circular(40),
//               border: Border.all(
//                 color: Colors.grey,
//                 width: 0.5.w,
//               )),
//           height: 55.h,
//           width: 260.w,
//           child: Text(
//             getTranslated(context, 'VIEW UPGRADE OPTIONS')!,
//             style: TextStyle(fontSize: 4.206, fontWeight: FontWeight.bold),
//           ),
//         ),
//       ],
//     );
//   }
// }
