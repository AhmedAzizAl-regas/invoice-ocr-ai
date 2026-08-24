import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Formats any amount (num or string) with comma thousand separators (e.g. 1250.50 -> "1,250.50").
  static String format(dynamic amount, {int decimals = 2}) {
    if (amount == null) return '0.00';
    double? val;
    if (amount is num) {
      val = amount.toDouble();
    } else if (amount is String) {
      val = double.tryParse(amount.replaceAll(',', '').trim());
    }
    if (val == null) return amount.toString();
    
    final pattern = decimals > 0 ? '#,##0.${'0' * decimals}' : '#,##0';
    return NumberFormat(pattern, 'en_US').format(val);
  }
}
