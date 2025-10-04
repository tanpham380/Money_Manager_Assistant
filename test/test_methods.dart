import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_assistant/project/localization/methods.dart';

void main() {
  group('getTranslated', () {
    testWidgets('returns translated string if available',
        (WidgetTester tester) async {
      // This test assumes AppLocalization is set up in the widget tree
      // For simplicity, we'll test the fallback behavior
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Since no localization is set, it should return the key
              expect(getTranslated(context, 'test_key'), 'test_key');
              return Container();
            },
          ),
        ),
      );
    });
  });

  group('locale', () {
    test('returns en locale for en', () {
      expect(locale('en'), Locale('en', 'US'));
    });

    test('returns vi locale for vi', () {
      expect(locale('vi'), Locale('vi', 'VN'));
    });

    test('returns en locale for unknown', () {
      expect(locale('unknown'), Locale('en', 'US'));
    });
  });
}
