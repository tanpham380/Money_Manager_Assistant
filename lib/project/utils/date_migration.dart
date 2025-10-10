import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database_management/sqflite_services.dart';
import '../database_management/shared_preferences_services.dart';

/// Migration utility to convert all dates in database from user format to ISO format
/// This should be run once on app startup to migrate existing data
class DateMigration {
  static const String _migrationKey = 'date_format_migrated_v1';

  /// Check if migration has been run before
  static Future<bool> isMigrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey) ?? false;
  }

  /// Mark migration as complete
  static Future<void> markMigrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
  }

  /// Migrate all dates from user format (dd/MM/yyyy or MM/dd/yyyy) to ISO format (yyyy-MM-dd)
  static Future<void> migrateDates() async {
    if (await isMigrationComplete()) {
      return;
    }


    try {
      // Get current user's date format
      final userDateFormat = sharedPrefs.dateFormat; // e.g., 'dd/MM/yyyy'
      final userFormatter = DateFormat(userDateFormat);
      final isoFormatter = DateFormat('yyyy-MM-dd');

      // Get all transactions from database
      final allTransactions = await DB.inputModelList();

      for (final transaction in allTransactions) {
        if (transaction.date == null || transaction.date!.isEmpty) continue;

        try {
          // Check if already in ISO format
          if (_isISOFormat(transaction.date!)) {
            continue;
          }

          // Parse date using user's format
          final date = userFormatter.parse(transaction.date!);

          // Convert to ISO format
          final isoDate = isoFormatter.format(date);

          // Update transaction
          transaction.date = isoDate;
          await DB.update(transaction);
        } catch (e) {
          // Silently ignore failed migrations - transaction will keep original format
        }
      }


      // Mark migration as complete
      await markMigrationComplete();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if a date string is in ISO format (yyyy-MM-dd)
  static bool _isISOFormat(String dateString) {
    // ISO format: yyyy-MM-dd (e.g., 2025-10-07)
    final isoPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!isoPattern.hasMatch(dateString)) return false;

    try {
      // Verify it's a valid date
      DateFormat('yyyy-MM-dd').parseStrict(dateString);
      return true;
    } catch (e) {
      return false;
    }
  }
}
