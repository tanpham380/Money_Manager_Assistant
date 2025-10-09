import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:money_assistant/project/classes/lockscreen.dart'; // Đảm bảo đường dẫn đúng
import 'package:money_assistant/project/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:responsive_scaler/responsive_scaler.dart';
import 'classes/constants.dart';
import 'database_management/shared_preferences_services.dart';
import 'database_management/sqflite_services.dart';
import 'localization/app_localization.dart';
import 'provider/navigation_provider.dart';
import 'provider/transaction_provider.dart';
import 'home.dart';

// Global key để navigate từ bất cứ đâu
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// BƯỚC 1: Ước tính kích thước ban đầu
double _getInitialScreenWidth() {
  final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
  if (dispatcher.views.isNotEmpty) {
    final ui.FlutterView view = dispatcher.views.first;
    final ui.Size physicalSize = view.physicalSize;
    final double devicePixelRatio = view.devicePixelRatio;
    if (devicePixelRatio > 0) {
      return physicalSize.width / devicePixelRatio;
    }
  }
  return 390.0; // Giá trị mặc định an toàn
}

void realMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await sharedPrefs.sharePrefsInit();
  await DB.init();

  NotificationService.onNotificationTap = (String? payload) {
    if (payload == 'add_input' && navigatorKey.currentState != null) {
      navigatorKey.currentState!.popUntil((route) => route.isFirst);
    }
  };

  await _checkStoragePermission();
  sharedPrefs.setItems(setCategoriesToDefault: false);
  sharedPrefs.getCurrency();
  sharedPrefs.getAllExpenseItemsLists();

  if (sharedPrefs.isReminderEnabled) {
    await NotificationService.scheduleDailyReminder(
      sharedPrefs.reminderHour,
      sharedPrefs.reminderMinute,
    );
  }

  // Khởi tạo ResponsiveScaler với giá trị ước tính
  ResponsiveScaler.init(
    designWidth: _getInitialScreenWidth(),
    minScale: 0.8,
    maxScale: 1.3,
    maxAccessibilityScale: 1.5,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: const MyApp(),
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
  const MyApp({Key? key}) : super(key: key);

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    super.initState();
    // BƯỚC 2: Đăng ký hàm để cập nhật lại kích thước chính xác sau khi frame đầu tiên được vẽ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateResponsiveScaler();
    });
  }

  // BƯỚC 2: Hàm cập nhật kích thước chính xác
  void _updateResponsiveScaler() {
    if (mounted && context.mounted) {
      final mediaQuery = MediaQuery.of(context);
      final size = mediaQuery.size;
      final isPortrait = size.height > size.width;

      double designWidth;
      // Logic xác định designWidth dựa trên kích thước thực tế
      if (isPortrait) {
        if (size.width >= 428) designWidth = 428;       // iPhone Pro Max
        else if (size.width >= 390) designWidth = 390;  // iPhone Pro
        else if (size.width >= 375) designWidth = 375;  // iPhone SE
        else designWidth = 360;                         // Android phổ biến
      } else { // Chế độ landscape
        if (size.height >= 428) designWidth = 428;
        else if (size.height >= 390) designWidth = 390;
        else if (size.height >= 375) designWidth = 375;
        else designWidth = 360;
      }

      // Khởi tạo lại ResponsiveScaler với giá trị chính xác
      ResponsiveScaler.init(
        designWidth: designWidth,
        minScale: 0.8,
        maxScale: 1.3,
        maxAccessibilityScale: 1.5,
      );
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Locale appLocale = sharedPrefs.getLocale();
    setState(() {
      _locale = appLocale;
    });
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
            displaySmall: TextStyle(fontFamily: 'OpenSans', fontSize: 45.0, color: blue3),
            labelLarge: TextStyle(fontFamily: 'OpenSans'),
            titleMedium: TextStyle(fontFamily: 'NotoSans'),
            bodyMedium: TextStyle(fontFamily: 'NotoSans'),
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: blue3, primary: blue3, secondary: green,
            error: red, surface: blue1,
          ),
          textSelectionTheme: TextSelectionThemeData(cursorColor: blue3),
          primaryColor: blue3,
          scaffoldBackgroundColor: blue1,
          appBarTheme: AppBarTheme(backgroundColor: blue3, foregroundColor: Colors.white),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: blue3, foregroundColor: Colors.white,
            ),
          ),
        ),
        
        // Vị trí đúng cho AppLock, nằm trong builder
        builder: (context, child) {
          // Đầu tiên áp dụng AppLock
          final appLock = AppLock(
            builder: (context, arg) => child!,
            lockScreenBuilder: (context) => const MainLockScreen(),
            initiallyEnabled: sharedPrefs.isPasscodeOn,
            initialBackgroundLockLatency: const Duration(seconds: 15),
          );

          // Sau đó áp dụng ResponsiveScaler
          final scaledChild = ResponsiveScaler.scale(
            context: context,
            child: appLock,
          );

          // Cuối cùng là MediaQuery để vô hiệu hóa scale font chữ hệ thống
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1)),
            child: scaledChild,
          );
        },
        // Home được đặt ở đây, nó sẽ là `child` được truyền vào builder ở trên
        home: Home(),
        
        locale: _locale,
        localizationsDelegates: [
          AppLocalization.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          if (locale == null) return supportedLocales.first;
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode &&
                supportedLocale.countryCode == locale.countryCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('vi', 'VN'),
        ],
      );
    }
  }
}