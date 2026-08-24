import 'package:intl/intl.dart';

/// HijriDate represents a converted Islamic Hijri calendar date.
class HijriDate {
  final int year;
  final int month;
  final int day;

  HijriDate(this.year, this.month, this.day);

  @override
  String toString() => '$year-$month-$day';

  String format(String locale) {
    final monthsAr = [
      'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
      'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'
    ];
    final monthsEn = [
      'Muharram', 'Safar', 'Rabi\' al-Awwal', 'Rabi\' al-Thani', 'Jumada al-Awwal', 'Jumada al-Thani',
      'Rajab', 'Sha\'ban', 'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah'
    ];
    
    final int mIdx = month - 1;
    final String monthName = (mIdx >= 0 && mIdx < 12)
        ? (locale == 'ar' ? monthsAr[mIdx] : monthsEn[mIdx])
        : month.toString();

    final yearSuffix = locale == 'ar' ? 'هـ' : 'AH';
    return '$day $monthName $year $yearSuffix';
  }
}

/// DateFormatter handles all localization and display properties of dates and times.
class DateFormatter {
  DateFormatter._();

  /// Converts a Gregorian DateTime into a HijriDate using tabular Islamic calendar algorithm.
  static HijriDate convertGregorianToHijri(DateTime date) {
    // 1. Calculate Julian Day
    int year = date.year;
    int month = date.month;
    int day = date.day;

    if (month < 3) {
      year -= 1;
      month += 12;
    }

    final double a = (year / 100).floorToDouble();
    final double b = (a / 4).floorToDouble();
    final double c = 2 - a + b;
    final double e = (365.25 * (year + 4716)).floorToDouble();
    final double f = (30.6001 * (month + 1)).floorToDouble();
    final double jd = c + day + e + f - 1524.5;

    // 2. Julian Day to Hijri
    const double epoch = 1948439.5;
    final double offset = jd - epoch;
    final int cycle = (offset / 10631).floor();
    final int dayInCycle = (offset % 10631).floor();
    
    int yearInCycle = (dayInCycle / 354.367).floor();
    if (yearInCycle > 29) yearInCycle = 29;
    
    int dayInYear = dayInCycle - (yearInCycle * 354.367).floor();
    
    final int hYear = cycle * 30 + yearInCycle + 1;
    int hMonth = 1;
    int hDay = 1;
    
    final List<int> monthDays = [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29];
    // Leap years in 30-year cycle
    final List<int> leapYears = [2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29];
    final bool isLeap = leapYears.contains(yearInCycle);
    if (isLeap) {
      monthDays[11] = 30;
    }
    
    int acc = 0;
    for (int m = 0; m < 12; m++) {
      if (dayInYear < acc + monthDays[m]) {
        hMonth = m + 1;
        hDay = dayInYear - acc + 1;
        break;
      }
      acc += monthDays[m];
    }
    
    return HijriDate(hYear, hMonth, hDay);
  }

  /// Formats date based on user preferences.
  /// [formatType] can be 'gregorian', 'hijri', or 'both'.
  static String formatDate(DateTime date, String formatType, String locale) {
    final gregStr = DateFormat('yyyy-MM-dd', locale).format(date);
    if (formatType == 'gregorian') {
      return gregStr;
    }

    final hijri = convertGregorianToHijri(date);
    final hijriStr = hijri.format(locale);

    if (formatType == 'hijri') {
      return hijriStr;
    }

    // Both
    return '$gregStr | $hijriStr';
  }

  /// Formats time based on user preferences.
  /// [timeFormat] can be '12h' or '24h'.
  static String formatTime(DateTime time, String timeFormat, String locale) {
    if (timeFormat == '24h') {
      return DateFormat('HH:mm', locale).format(time);
    } else {
      // 12-hour format
      final formatted = DateFormat('hh:mm a', locale).format(time);
      if (locale == 'ar') {
        // Translate AM/PM indicators to Arabic
        return formatted
            .replaceAll('AM', 'ص')
            .replaceAll('PM', 'م');
      }
      return formatted;
    }
  }

  /// Parse text representations of time back to DateTime
  static DateTime parseTimeStr(String timeStr) {
    try {
      // Try 24h
      return DateFormat('HH:mm').parse(timeStr);
    } catch (_) {
      try {
        // Try 12h Arabic
        final cleaned = timeStr.replaceAll('ص', 'AM').replaceAll('م', 'PM');
        return DateFormat('hh:mm a').parse(cleaned);
      } catch (_) {
        return DateTime.now();
      }
    }
  }
}
