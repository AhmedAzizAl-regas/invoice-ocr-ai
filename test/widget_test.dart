import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:invoice_ocr_ai/core/utils/date_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  group('DateFormatter Tests', () {
    test('Gregorian to Hijri Conversion', () {
      // 18th July 2026 Gregorian is approximately 3rd Safar 1448 Hijri
      final date = DateTime(2026, 7, 18);
      final hijri = DateFormatter.convertGregorianToHijri(date);

      expect(hijri.year, equals(1448));
      expect(hijri.month, equals(2)); // Safar is 2nd month
      expect(hijri.day, closeTo(3, 1)); // Allowing deviation of 1 day due to lunar variations
    });

    test('12h Time Formatting Arabic/English', () {
      final time = DateTime(2026, 7, 18, 22, 30); // 10:30 PM
      
      final formattedEn = DateFormatter.formatTime(time, '12h', 'en');
      expect(formattedEn, equals('10:30 PM'));

      final formattedAr = DateFormatter.formatTime(time, '12h', 'ar');
      expect(formattedAr, equals('10:30 م'));
    });

    test('24h Time Formatting', () {
      final time = DateTime(2026, 7, 18, 22, 30);
      final formatted = DateFormatter.formatTime(time, '24h', 'en');
      expect(formatted, equals('22:30'));
    });
  });
}
