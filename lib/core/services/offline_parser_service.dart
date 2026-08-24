/// OfflineParserService provides deep heuristic parsing of raw OCR text
/// when there is no internet connection or when LLM API calls fail.
class OfflineParserService {
  OfflineParserService._();

  /// Parses raw OCR text locally using regex patterns and heuristics.
  static Map<String, dynamic> parseRawText(String rawText) {
    final lines = rawText.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(rawText);
    final detectedLanguage = isArabic ? 'ar' : 'en';

    // Extract Store / Merchant Name
    String storeName = _extractStoreName(lines, rawText) ?? 'Unknown Store';

    // Extract Reference / Transaction Number
    String? invoiceNumber = _extractInvoiceNumber(lines, rawText);

    // Extract Date
    String? date = _extractDate(rawText);

    // Extract Time
    String? time = _extractTime(rawText);

    // Extract Currency and Total Amount
    final amountAndCurrency = _extractAmountAndCurrency(lines, rawText);
    final double total = amountAndCurrency['total'] as double;
    final String currency = amountAndCurrency['currency'] as String;

    // Classify Category and Document Type
    final categoryAndType = _classifyCategoryAndType(rawText, storeName);
    final String documentCategory = categoryAndType['category']!;
    final String documentType = categoryAndType['type']!;
    final String documentTitle = categoryAndType['title']!;

    // Extract Dynamic Metadata Header Fields
    final dynamicMetadata = _extractDynamicMetadata(lines, rawText, invoiceNumber);

    return {
      'document_category': documentCategory,
      'detected_language': detectedLanguage,
      'document_type': documentType,
      'document_title': documentTitle,
      'store_name': storeName,
      'invoice_number': invoiceNumber,
      'date': date,
      'time': time,
      'currency': currency,
      'subtotal': total,
      'tax': 0.0,
      'discount': 0.0,
      'total': total,
      'payment_method': _extractPaymentMethod(rawText),
      'sender_name': _extractFieldByKeywords(lines, ['المودع', 'المحول', 'اسم الطالب', 'المستأجر', 'المشتري', 'Sender', 'From']),
      'receiver_name': _extractFieldByKeywords(lines, ['المستفيد', 'العميل', 'المؤجر', 'البائع', 'المستشفى', 'Receiver', 'Beneficiary', 'To']),
      'account_number': _extractFieldByKeywords(lines, ['رقم الحساب', 'رقم الملف', 'رقم العداد', 'رقم الصك', 'رقم الهيكل', 'Account']),
      'branch': _extractFieldByKeywords(lines, ['الفرع', 'الفرع الرئيسي', 'القسم', 'Branch', 'Dept']),
      'employee_name': _extractFieldByKeywords(lines, ['الموظف', 'المستخدم', 'المحاسب', 'Teller', 'User']),
      'notes': _extractNotes(rawText),
      'dynamic_metadata': dynamicMetadata,
      'table_columns': <String>[],
      'table_rows': <List<String>>[],
      'items': <Map<String, dynamic>>[],
    };
  }

  static String? _extractStoreName(List<String> lines, String rawText) {
    // 1. Check for domain name or email
    final domainMatch = RegExp(r'(?:www\.)?([a-zA-Z0-9\-]+)\.(?:com|net|org|io|app|co|info|biz)', caseSensitive: false).firstMatch(rawText);
    if (domainMatch != null) {
      final name = domainMatch.group(1)!;
      if (name.toLowerCase().contains('alhazmi')) return 'شركة الحزمي للصرافة (Alhazmi Express)';
      return name.toUpperCase();
    }

    final emailMatch = RegExp(r'info@([a-zA-Z0-9\-]+)\.', caseSensitive: false).firstMatch(rawText);
    if (emailMatch != null) {
      final name = emailMatch.group(1)!;
      return name.toUpperCase();
    }

    // 2. Pick first line that isn't a date, time, url, or number
    for (final line in lines.take(5)) {
      if (!line.contains('http') &&
          !line.contains('www') &&
          !RegExp(r'^\d+$').hasMatch(line) &&
          !RegExp(r'^\d{2}/\d{2}/\d{4}').hasMatch(line) &&
          line.length > 2) {
        return line;
      }
    }

    return null;
  }

  static String? _extractInvoiceNumber(List<String> lines, String rawText) {
    // Match explicit ref # like #200# or #12345 or Ref: 12345
    final refMatch = RegExp(r'#(?:200#|([0-9]{3,}))|(?:\bRef|\bTRX|\bNO|\bالمرجع|\bرقم العملية|\bرقم الإشعار)[:\s#]*([A-Z0-9\-]{4,})', caseSensitive: false).firstMatch(rawText);
    if (refMatch != null) {
      return refMatch.group(1) ?? refMatch.group(2) ?? refMatch.group(0);
    }

    // Match long standalone transaction number like 17820095386162
    final longNumMatch = RegExp(r'\b([0-9]{10,18})\b').firstMatch(rawText);
    if (longNumMatch != null) {
      return longNumMatch.group(1);
    }

    return null;
  }

  static String? _extractDate(String rawText) {
    // Match yyyy/MM/dd or yyyy-MM-dd
    final isoMatch = RegExp(r'\b(20\d{2})[/\-](0[1-9]|1[0-2])[/\-](0[1-9]|[12]\d|3[01])\b').firstMatch(rawText);
    if (isoMatch != null) {
      return '${isoMatch.group(1)}-${isoMatch.group(2)}-${isoMatch.group(3)}';
    }

    // Match dd/MM/yyyy or dd-MM-yyyy
    final euMatch = RegExp(r'\b(0[1-9]|[12]\d|3[01])[/\-](0[1-9]|1[0-2])[/\-](20\d{2})\b').firstMatch(rawText);
    if (euMatch != null) {
      return '${euMatch.group(3)}-${euMatch.group(2)}-${euMatch.group(1)}';
    }

    return null;
  }

  static String? _extractTime(String rawText) {
    // Match PM/AM HH:mm:ss or HH:mm PM/AM
    final timeMatch = RegExp(r'(?:(AM|PM)\s*)?([0-1]?\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?(?:\s*(AM|PM))?', caseSensitive: false).firstMatch(rawText);
    if (timeMatch != null) {
      final period = timeMatch.group(1) ?? timeMatch.group(5);
      final hourStr = timeMatch.group(2)!;
      final minStr = timeMatch.group(3)!;
      int hour = int.parse(hourStr);

      if (period != null) {
        if (period.toUpperCase() == 'PM' && hour < 12) hour += 12;
        if (period.toUpperCase() == 'AM' && hour == 12) hour = 0;
      }
      return '${hour.toString().padLeft(2, '0')}:$minStr';
    }
    return null;
  }

  static Map<String, dynamic> _extractAmountAndCurrency(List<String> lines, String rawText) {
    double total = 0.0;
    String currency = 'SAR';

    // Check currency symbols
    if (rawText.contains('\$') || rawText.contains('USD')) {
      currency = 'USD';
    } else if (rawText.contains('SAR') || rawText.contains('ر.س') || rawText.contains('ريال سعودي')) {
      currency = 'SAR';
    } else if (rawText.contains('YER') || rawText.contains('ر.ي') || rawText.contains('ريال يمني')) {
      currency = 'YER';
    } else if (rawText.contains('AED') || rawText.contains('د.إ')) {
      currency = 'AED';
    } else if (rawText.contains('EUR') || rawText.contains('€')) {
      currency = 'EUR';
    }

    // Match currency with amount e.g. $230 or 230 USD or $ 230.00
    final priceMatch = RegExp(r'(?:\$|USD|SAR|YER|AED|EUR|ر\.س|ر\.ي)\s*([0-9]+(?:\.[0-9]{1,2})?)|([0-9]+(?:\.[0-9]{1,2})?)\s*(?:\$|USD|SAR|YER|AED|EUR|ر\.س|ر\.ي)', caseSensitive: false).firstMatch(rawText);
    if (priceMatch != null) {
      final valStr = priceMatch.group(1) ?? priceMatch.group(2);
      if (valStr != null) total = double.tryParse(valStr) ?? 0.0;
    }

    // Fallback: Find numbers preceded by Total, المبلغ, الإجمالي
    if (total == 0.0) {
      final totalMatch = RegExp(r'(?:Total|TOTAL|الإجمالي|المبلغ)[:\s]*\$?\s*([0-9]+(?:\.[0-9]{1,2})?)', caseSensitive: false).firstMatch(rawText);
      if (totalMatch != null) {
        total = double.tryParse(totalMatch.group(1)!) ?? 0.0;
      }
    }

    return {'total': total, 'currency': currency};
  }

  static Map<String, String> _classifyCategoryAndType(String rawText, String storeName) {
    final text = rawText.toLowerCase();

    if (text.contains('alhazmi') || text.contains('صرافة') || text.contains('حوالة') || text.contains('إيداع') || text.contains('بنك') || text.contains('bank')) {
      return {
        'category': 'bank_financial',
        'type': 'bank_transfer',
        'title': 'إشعار دائن (إيداع / حوالة مالية)',
      };
    } else if (text.contains('مستشفى') || text.contains('طبيب') || text.contains('علاج') || text.contains('hospital') || text.contains('clinic')) {
      return {
        'category': 'medical',
        'type': 'medical_report',
        'title': 'فاتورة مستشفى / خدمات طبية',
      };
    } else if (text.contains('جامعة') || text.contains('مدرسة') || text.contains('رسوم دراسية') || text.contains('school') || text.contains('tuition')) {
      return {
        'category': 'education_tuition',
        'type': 'tuition_voucher',
        'title': 'فاتورة رسوم دراسية / أكاديمية',
      };
    } else if (text.contains('كهرباء') || text.contains('ماء') || text.contains('عداد') || text.contains('water') || text.contains('electric')) {
      return {
        'category': 'utility',
        'type': 'utility_bill',
        'title': 'فاتورة مرافق (كهرباء / مياه)',
      };
    } else if (text.contains('إيجار') || text.contains('مؤجر') || text.contains('مستأجر') || text.contains('rent')) {
      return {
        'category': 'real_estate_rent',
        'type': 'receipt_voucher',
        'title': 'سند إيجار عقار / محل',
      };
    }

    return {
      'category': 'retail_invoice',
      'type': 'invoice',
      'title': 'فاتورة مبيعات / مشتريات',
    };
  }

  static List<Map<String, String>> _extractDynamicMetadata(List<String> lines, String rawText, String? invoiceNumber) {
    final List<Map<String, String>> metadata = [];

    // Extract Website
    final webMatch = RegExp(r'(www\.[a-zA-Z0-9\-]+\.[a-zA-Z]{2,})', caseSensitive: false).firstMatch(rawText);
    if (webMatch != null) {
      metadata.add({'label': 'الموقع الإلكتروني', 'value': webMatch.group(1)!});
    }

    // Extract Email
    final emailMatch = RegExp(r'([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})', caseSensitive: false).firstMatch(rawText);
    if (emailMatch != null) {
      metadata.add({'label': 'البريد الإلكتروني', 'value': emailMatch.group(1)!});
    }

    // Extract Toll Free / Phone Numbers
    final tollFreeMatch = RegExp(r'(?:Toll free|مجاني)[:\s]*([0-9]{7,})', caseSensitive: false).firstMatch(rawText);
    if (tollFreeMatch != null) {
      metadata.add({'label': 'الرقم المجاني', 'value': tollFreeMatch.group(1)!});
    }

    final phoneMatch = RegExp(r'(?:Jal|الهاتف|جوال|Tel)[:\s]*([0-9]{7,})', caseSensitive: false).firstMatch(rawText);
    if (phoneMatch != null) {
      metadata.add({'label': 'هاتف التواصل', 'value': phoneMatch.group(1)!});
    }

    if (invoiceNumber != null) {
      metadata.add({'label': 'رقم المرجع / الحوالة', 'value': invoiceNumber});
    }

    return metadata;
  }

  static String? _extractPaymentMethod(String rawText) {
    if (rawText.contains('إيداع')) return 'إيداع نقدي';
    if (rawText.contains('حوالة')) return 'حوالة بنكية';
    if (rawText.contains('Cash') || rawText.contains('نقداً')) return 'نقداً';
    if (rawText.contains('Card') || rawText.contains('شبكة')) return 'بطاقة مصرفية';
    return 'إيداع / تحويل';
  }

  static String? _extractFieldByKeywords(List<String> lines, List<String> keywords) {
    for (final line in lines) {
      for (final kw in keywords) {
        if (line.contains(kw)) {
          final parts = line.split(RegExp(r'[:=]'));
          if (parts.length > 1 && parts[1].trim().isNotEmpty) {
            return parts[1].trim();
          }
          return line.replaceAll(kw, '').replaceAll(':', '').trim();
        }
      }
    }
    return null;
  }

  static String? _extractNotes(String rawText) {
    final noteMatch = RegExp(r'(?:Notes|الملاحظات|المبلغ كتابة)[:\s]*(.*)', caseSensitive: false).firstMatch(rawText);
    if (noteMatch != null) {
      return noteMatch.group(1)?.trim();
    }
    return null;
  }
}
