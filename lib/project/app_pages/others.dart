import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
 import '../utils/responsive_extensions.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../classes/constants.dart';
import '../database_management/shared_preferences_services.dart';
import '../database_management/sqflite_services.dart';
import '../database_management/sync_data.dart';
import '../localization/methods.dart';
import '../provider.dart';
import '../services/notification_service.dart';
import '../services/alert_service.dart';
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
                    '${getTranslated(context, 'Hi you')!}!',
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
  bool _isReminderEnabled = false;
  int _reminderHour = 21;
  int _reminderMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadReminderSettings();
  }

  void _loadReminderSettings() {
    setState(() {
      _isReminderEnabled = sharedPrefs.isReminderEnabled;
      _reminderHour = sharedPrefs.reminderHour;
      _reminderMinute = sharedPrefs.reminderMinute;
    });
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      // Request permission trước khi bật reminder
      bool hasPermission = await  NotificationService.requestPermission();
      if (!hasPermission) {
        AlertService.show(
          context,
          type: NotificationType.error,
          message: getTranslated(context, 'Notification permission denied') ?? 'Notification permission denied',
        );
        return;
      }

      // Bật reminder
      await  NotificationService.scheduleDailyReminder(
          _reminderHour, _reminderMinute);
      setState(() {
        _isReminderEnabled = true;
      });
      sharedPrefs.isReminderEnabled = true;
      AlertService.show(
        context,
        type: NotificationType.success,
        message: getTranslated(context, 'Daily reminder enabled') ?? 'Daily reminder enabled',
      );
    } else {
      // Tắt reminder
      await  NotificationService.cancelReminder();
      setState(() {
        _isReminderEnabled = false;
      });
      sharedPrefs.isReminderEnabled = false;
      AlertService.show(
        context,
        type: NotificationType.success,
        message: getTranslated(context, 'Daily reminder disabled') ?? 'Daily reminder disabled',
      );
      
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay initialTime =
        TimeOfDay(hour: _reminderHour, minute: _reminderMinute);

    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: blue3,
              onPrimary: Colors.black,
              surface: white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });
      sharedPrefs.reminderHour = picked.hour;
      sharedPrefs.reminderMinute = picked.minute;

      // Nếu reminder đang bật, reschedule với thời gian mới
      if (_isReminderEnabled) {
        await  NotificationService.scheduleDailyReminder(
            _reminderHour, _reminderMinute);
        AlertService.show(
          context,
          type: NotificationType.success,
          message: getTranslated(context, 'Reminder time updated') ?? 'Reminder time updated',
        );
      }
    }
  }

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
      Icon(Icons.notifications_active, size: 32.sp, color: Colors.orange),
      Icon(Icons.refresh, size: 32.sp, color: Colors.lightBlue),
      Icon(Icons.delete_forever, size: 32.sp, color: red),
      Icon(Icons.lock, size: 32.sp, color: Colors.lightBlue),
      Icon(Icons.sync, size: 32.sp, color: Colors.lightBlue)
    ];
    List<String> settingsList = [
      getTranslated(context, 'Language') ?? 'Language',
      getTranslated(context, 'Currency') ?? 'Currency',
      '${getTranslated(context, 'Date format') ?? 'Date format'} (${DateFormat(sharedPrefs.dateFormat).format(now)})',
      'Daily Reminder',
      getTranslated(context, 'Reset All Categories') ?? 'Reset All Categories',
      getTranslated(context, 'Delete All Data') ?? 'Delete All Data',
      getTranslated(context, 'Change Passcode') ?? 'Change Passcode',
      getTranslated(context, 'Sync Page') ?? 'Sync Page',
    ];

    return Container(
      color: white,
      child: ListView.builder(
          itemCount: settingsList.length,
          itemBuilder: (context, index) {
            // Daily Reminder có UI riêng
            if (index == 3) {
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: SizedBox(
                      child: Center(
                          child: ListTile(
                        title: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Text(
                            settingsList[index],
                            style: TextStyle(fontSize: 18.5.sp),
                          ),
                        ),
                        subtitle: _isReminderEnabled
                            ? Padding(
                                padding: EdgeInsets.only(left: 8.w, top: 4.h),
                                child: Text(
                                  '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                            : null,
                        leading: CircleAvatar(
                            radius: 24.r,
                            backgroundColor: Color.fromRGBO(229, 231, 234, 1),
                            child: settingsIcons[index]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isReminderEnabled)
                              IconButton(
                                icon: Icon(Icons.access_time, size: 20.sp),
                                onPressed: _pickTime,
                              ),
                            Switch(
                              value: _isReminderEnabled,
                              onChanged: _toggleReminder,
                              activeThumbColor: Colors.orange,
                            ),
                          ],
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
              );
            }

            return GestureDetector(
              onTap: () async {
                // ImportExportScreen

                if (index == 0 || index == 1) {
                  unawaited(Navigator.push(context,
                      MaterialPageRoute(builder: (context) => pageRoute[index])));
                } else if (index == 2) {
                  unawaited(Navigator.push(context,
                          MaterialPageRoute(builder: (context) => FormatDate()))
                      .then((value) => setState(() {})));
                } else if (index == 4) {
                  final confirmed = await AlertService.show(
                    context,
                    type: NotificationType.delete,
                    title: 'Reset Categories',
                    message: 'This action cannot be undone. Are you sure you want to reset all categories?',
                    actionText: 'Reset',
                    cancelText: 'Cancel',
                  );
                  
                  if (confirmed == true) {
                    sharedPrefs.setItems(setCategoriesToDefault: true);
                    AlertService.show(
                      context,
                      type: NotificationType.success,
                      message: 'Categories have been reset',
                    );
                  }
                } else if (index == 5) {
                  final confirmed = await AlertService.show(
                    context,
                    type: NotificationType.delete,
                    title: 'Delete All Data',
                    message: 'Deleted data can not be recovered. Are you sure you want to delete all data?',
                    actionText: 'Delete',
                    cancelText: 'Cancel',
                  );
                  
                  if (confirmed == true) {
                    await DB.deleteAll();
                    AlertService.show(
                      context,
                      type: NotificationType.success,
                      message: 'All data has been deleted',
                    );
                  }
                } else if (index == 6) {
                  final controller = InputController();
                  await screenLockCreate(
                      context: context,
                      title: Text(
                        getTranslated(context, 'Change Passcode') ??
                            'Change Passcode',
                      ),
                      confirmTitle: Text(
                        getTranslated(context, 'Confirm Passcode') ??
                            'Confirm Passcode',
                      ),
                      digits: 6,
                      inputController: controller,
                      customizedButtonChild: Icon(Icons.lock_reset),
                      customizedButtonTap: controller.unsetConfirmed,
                      onConfirmed: (matchedText) {
                        sharedPrefs.passcodeScreenLock = matchedText;
                        Navigator.of(context).pop();
                        AlertService.show(
                          context,
                          type: NotificationType.success,
                          message: 'Passcode has been changed',
                        );
                      });
                } else if (index == 7) {
                  unawaited(Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ImportExportScreen())));
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
                            '${settingsList[index]}',
                            style: TextStyle(fontSize: 18.5.sp),
                          ),
                        ),
                        leading: CircleAvatar(
                            radius: 24.r,
                            backgroundColor: Color.fromRGBO(229, 231, 234, 1),
                            child: settingsIcons[index]),
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
