import 'package:flutter/material.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
 import 'package:money_assistant/project/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:responsive_scaler/responsive_scaler.dart';
import 'classes/lockscreen.dart';
import 'database_management/shared_preferences_services.dart';
import 'database_management/sqflite_services.dart';
import 'localization/app_localization.dart';
import 'provider/navigation_provider.dart';
import 'home.dart';

// Global key để navigate từ bất cứ đâu
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void realMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await  NotificationService.init();

  // Set up callback để xử lý khi user tap notification
   NotificationService.onNotificationTap = (String? payload) {
    if (payload == 'add_input') {
      // Navigate đến tab Input (index 0)
      if (navigatorKey.currentContext != null) {
        // Đợi một chút để đảm bảo context đã sẵn sàng
        Future.delayed(Duration(milliseconds: 300), () {
          if (navigatorKey.currentState != null) {
            // Đưa về màn hình Home tab Input
            navigatorKey.currentState!.popUntil((route) => route.isFirst);
          }
        });
      }
    }
  };
  await sharedPrefs.sharePrefsInit();
  await DB.init(); // Initialize database early
  await _checkStoragePermission();
  sharedPrefs.setItems(setCategoriesToDefault: false);
  sharedPrefs.getCurrency();
  sharedPrefs.getAllExpenseItemsLists();

  // Reschedule reminder nếu đã được bật
  if (sharedPrefs.isReminderEnabled) {
    await  NotificationService.scheduleDailyReminder(
      sharedPrefs.reminderHour,
      sharedPrefs.reminderMinute,
    );
  }

  // Initialize ResponsiveScaler
  ResponsiveScaler.init(
    designWidth: 428,
    minScale: 0.8,
    maxScale: 1.3,
    maxAccessibilityScale: 1.5,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => NavigationProvider(),
      child: MyApp(),
    ),
  );
}

Future<void> _checkStoragePermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    await Permission.storage.request();
  }
}

class MyApp extends StatefulWidget {
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(newLocale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale? _locale;
  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void didChangeDependencies() {
    Locale appLocale = sharedPrefs.getLocale();
    setState(() {
      _locale = appLocale;
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (_locale == null) {
      return Container(
        child: Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[800]!)),
        ),
      );
    } else {
      return MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Money Save',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: TextTheme(
            displaySmall: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 45.0,
              color: Colors.deepOrangeAccent,
            ),
            labelLarge: TextStyle(
              fontFamily: 'OpenSans',
            ),
            titleMedium: TextStyle(fontFamily: 'NotoSans'),
            bodyMedium: TextStyle(fontFamily: 'NotoSans'),
          ),
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo)
              .copyWith(secondary: Colors.orange),
          textSelectionTheme:
              TextSelectionThemeData(cursorColor: Colors.amberAccent),
        ),
        builder: (context, widget) {
          // Apply ResponsiveScaler
          final scaledChild = ResponsiveScaler.scale(
            context: context,
            child: widget!,
          );
          
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1)),
            child: scaledChild,
          );
        },
        // home: Home(),
        home: AppLock(
          builder: (BuildContext context, Object? args) => Home(),
          lockScreenBuilder: (BuildContext context) => MainLockScreen(),
          initiallyEnabled: true,
          initialBackgroundLockLatency: const Duration(seconds: 10),
        ),
        // Home(),
        locale: _locale,
        localizationsDelegates: [
          AppLocalization.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale!.languageCode &&
                supportedLocale.countryCode == locale.countryCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        supportedLocales: [
          Locale('en', 'US'),
          Locale('vi', 'VN'),
        ],
      );
    }
  }
}
