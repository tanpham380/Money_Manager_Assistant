import 'package:flutter/material.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'classes/lockscreen.dart';
import 'database_management/shared_preferences_services.dart';
import 'localization/app_localization.dart';
import 'home.dart';

void realMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await sharedPrefs.sharePrefsInit();
  await _checkStoragePermission();
  sharedPrefs.setItems(setCategoriesToDefault: false);
  sharedPrefs.getCurrency();
  sharedPrefs.getAllExpenseItemsLists();

  runApp(
    MyApp()
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
  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void didChangeDependencies() {
    Locale appLocale = sharedPrefs.getLocale();
    setState(() {
      this._locale = appLocale;
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (this._locale == null) {
      return Container(
        child: Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[800]!)),
        ),
      );
    } else {
      return ScreenUtilInit(
        designSize: Size(428.0, 926.0),
        builder: (_, child) => MaterialApp(
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
          builder: (context, widget) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1)),
            child: widget!,
          ),
          // home: Home(),
          home: AppLock(
            builder: (BuildContext context, Object? args) => Home(),
            lockScreenBuilder: (BuildContext context) => MainLockScreen(),
            enabled:  true,
            
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
            Locale("en", "US"),
            Locale("vi", "VN"),
          ],
        ),
      );
    }
  }
}
