import 'package:flutter/material.dart';

import 'app_localization.dart';

Locale locale(String languageCode) {
  switch (languageCode) {
    case 'en':
      return Locale('en', 'US');
    case 'vi':
      return Locale('vi', "VN");
    default:
      return Locale('en', 'US');
  }
}

String? getTranslated(BuildContext context, String key) {
  return AppLocalization.of(context)?.translate(key);
}

Map<String, String>? localizedMap(BuildContext context) =>
    AppLocalization.of(context)?.localizedMap();
