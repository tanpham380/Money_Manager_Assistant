import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';

/// Utility class để quy chuẩn tất cả format ngày tháng và thứ trong app
/// Thay thế tất cả các DateFormat hardcoded để dễ maintain và consistent
class DateFormatUtils {
  // ==================== USER DATE FORMAT ====================
  /// Format ngày theo setting của user (dd/MM/yyyy, MM/dd/yyyy, etc.)
  static DateFormat get userDateFormat => DateFormat(sharedPrefs.dateFormat);

  /// Parse ngày từ string theo format user
  static DateTime parseUserDate(String dateString) {
    return userDateFormat.parse(dateString);
  }

  /// Format ngày thành string theo format user
  static String formatUserDate(DateTime date) {
    return userDateFormat.format(date);
  }

  // ==================== INTERNAL FORMATS ====================
  /// Format internal cho key tháng (yyyy-MM) - dùng cho grouping và sorting
  static DateFormat get monthKeyFormat => DateFormat('yyyy-MM');

  /// Parse/format key tháng
  static String formatMonthKey(DateTime date) {
    return monthKeyFormat.format(date);
  }

  static DateTime parseMonthKey(String monthKey) {
    return monthKeyFormat.parse(monthKey);
  }

  /// Format internal cho ngày (dd/MM/yyyy) - dùng để matching với database
  /// Internal date format for database storage (ISO format: yyyy-MM-dd)
  /// This is language-agnostic and ensures consistent sorting/comparison
  static DateFormat get internalDateFormat => DateFormat('yyyy-MM-dd');

  /// Format DateTime to ISO format string for database storage
  static String formatInternalDate(DateTime date) {
    return internalDateFormat.format(date);
  }

  /// Parse ISO format string from database to DateTime
  static DateTime parseInternalDate(String dateString) {
    return internalDateFormat.parse(dateString);
  }

  // ==================== DISPLAY FORMATS ====================
  /// Format label tháng ngắn (MMM yyyy) - dùng cho chart labels
  static DateFormat get shortMonthFormat => DateFormat('MMM yyyy');

  static String formatShortMonth(DateTime date) {
    return shortMonthFormat.format(date);
  }

  /// Format tháng cho bar chart (MMM yy)
  static DateFormat get chartMonthFormat => DateFormat('MMM yy');

  static String formatChartMonth(DateTime date) {
    return chartMonthFormat.format(date);
  }

  // ==================== FULL DATE FORMATS ====================
  /// Format ngày đầy đủ với thứ (EEEE, MMMM dd, yyyy)
  /// Ví dụ: "Monday, January 15, 2024"
  static DateFormat get fullWeekdayFormat => DateFormat('EEEE, MMMM dd, yyyy');

  static String formatFullWeekday(DateTime date) {
    return fullWeekdayFormat.format(date);
  }

  /// Format ngày với thứ và ngày ngắn (EEEE, dd/MM/yyyy)
  /// Ví dụ: "Monday, 15/01/2024"
  static String formatWeekdayWithUserDate(DateTime date) {
    final weekday = DateFormat('EEEE').format(date);
    final dateStr = formatUserDate(date);
    return '$weekday, $dateStr';
  }

  // ==================== WEEKDAY FORMATS ====================
  /// Chỉ lấy tên thứ (Monday, Tuesday, etc.)
  static String getWeekdayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  /// Lấy tên thứ ngắn (Mon, Tue, etc.)
  static String getShortWeekdayName(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  // ==================== MONTH FORMATS ====================
  /// Lấy tên tháng đầy đủ (January, February, etc.)
  static String getMonthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  /// Lấy tên tháng ngắn (Jan, Feb, etc.)
  static String getShortMonthName(DateTime date) {
    return DateFormat('MMM').format(date);
  }

  // ==================== LOCALIZED FORMATS ====================
  /// Lấy tên thứ đã được dịch theo locale
  static String getLocalizedWeekdayName(BuildContext context, DateTime date) {
    final weekdayIndex = date.weekday;
    final weekdayKeys = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    final key = weekdayKeys[
        weekdayIndex - 1]; // DateTime.weekday is 1-7 (Monday=1, Sunday=7)
    return getTranslated(context, key) ?? key;
  }

  /// Lấy tên tháng đã được dịch theo locale
  static String getLocalizedMonthName(BuildContext context, DateTime date) {
    final monthIndex = date.month - 1;
    final monthKeys = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final key = monthKeys[monthIndex];
    return getTranslated(context, key) ?? key;
  }

  /// Format ngày đầy đủ với thứ và tháng đã được dịch
  static String formatLocalizedFullWeekday(
      BuildContext context, DateTime date) {
    final weekday = getLocalizedWeekdayName(context, date);
    final month = getLocalizedMonthName(context, date);
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  /// Format ngày đầy đủ với thứ và tháng đã được dịch
  /// Ví dụ: "Thứ Hai, 04 Tháng 10 2025" (vi) hoặc "Monday, October 04, 2025" (en)
  /// Sử dụng localization thay vì hardcode if-else
  static String formatLocalizedFullDate(BuildContext context, DateTime date) {
    final weekday = getLocalizedWeekdayName(context, date);
    final month = getLocalizedMonthName(context, date);
    final locale = Localizations.localeOf(context).languageCode;

    // Format khác nhau cho tiếng Việt và tiếng Anh
    if (locale == 'vi') {
      // Tiếng Việt: "Thứ Hai, 04 Tháng 10 2025"
      return '$weekday, ${date.day} $month ${date.year}';
    } else {
      // Tiếng Anh: "Monday, October 04, 2025"
      return '$weekday, $month ${date.day.toString().padLeft(2, '0')}, ${date.year}';
    }
  }

  /// Format ngày với thứ và ngày ngắn (theo user format)
  static String formatLocalizedWeekdayWithUserDate(
      BuildContext context, DateTime date) {
    final weekday = getLocalizedWeekdayName(context, date);
    final dateStr = formatUserDate(date);
    return '$weekday, $dateStr';
  }

  /// Format ngày với format cụ thể (dùng cho preview các format khác nhau)
  static String formatWithSpecificFormat(String format, DateTime date) {
    return DateFormat(format).format(date);
  }
}
