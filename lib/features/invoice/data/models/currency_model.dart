/// CurrencyModel defines the properties of currencies supported by the system.
/// Tracks localization symbols, names, and the exchange rate coefficient relative to SAR.
class CurrencyModel {
  final String code;
  final String nameEn;
  final String nameAr;
  final String symbolEn;
  final String symbolAr;
  final double exchangeRate;

  CurrencyModel({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.symbolEn,
    required this.symbolAr,
    required this.exchangeRate,
  });

  /// Creates a CurrencyModel from a database row map.
  factory CurrencyModel.fromMap(Map<String, dynamic> map) {
    return CurrencyModel(
      code: map['code'] as String,
      nameEn: map['name_en'] as String,
      nameAr: map['name_ar'] as String,
      symbolEn: map['symbol_en'] as String,
      symbolAr: map['symbol_ar'] as String,
      exchangeRate: (map['exchange_rate'] as num).toDouble(),
    );
  }

  /// Converts the CurrencyModel into a map for database insertion.
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name_en': nameEn,
      'name_ar': nameAr,
      'symbol_en': symbolEn,
      'symbol_ar': symbolAr,
      'exchange_rate': exchangeRate,
    };
  }

  /// Helper to get the localized symbol based on locale string ('ar' or 'en').
  String getSymbol(String locale) {
    return locale == 'ar' ? symbolAr : symbolEn;
  }

  /// Helper to get the localized name based on locale string ('ar' or 'en').
  String getName(String locale) {
    return locale == 'ar' ? nameAr : nameEn;
  }
}
