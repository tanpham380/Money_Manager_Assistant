import 'package:flutter_test/flutter_test.dart';
import 'package:money_assistant/project/database_management/sqflite_services.dart';

void main() {
  group('DB', () {
    test('init initializes database without throwing', () async {
      // DB.init() should complete without error
      await expectLater(DB.init(), completes);
    });
  });
}
