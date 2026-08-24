import 'dart:convert';
import 'invoice_item_model.dart';

/// InvoiceModel represents the metadata and items of any global Document, Invoice, Medical Bill, Pharmacy Slip, or Bank Voucher.
class InvoiceModel {
  final String id;
  final String storeName;
  final String? invoiceNumber;
  final String? date; // ISO8601 string
  final String? time; // HH:mm string
  final String? currency;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String? paymentMethod;
  final String? imagePath;
  final String? ocrEngine;
  final double ocrConfidence;
  final String? rawText;
  final String createdAt;
  final List<InvoiceItemModel> items;

  // Financial receipts & bank transfer fields
  final String documentType; // 'invoice', 'bank_transfer', 'receipt_voucher'
  final String? documentTitle; // e.g., "إشعار دائن (إيداع نقدي)", "Hospital Medical Report"
  final String? senderName; // المودع / المحول / العميل
  final String? receiverName; // المستفيد / اسم المريض / العميل
  final String? accountNumber; // رقم الحساب / رقم الملف / رقم الشحنة
  final String? branch; // الفرع / العيادة / القسم
  final String? notes; // الملاحظات / المبلغ كتابة
  final String? employeeName; // اسم المستخدم / الموظف / الطبيب

  // Universal Global Schema fields
  final String documentCategory; // 'medical', 'pharmacy', 'hotel', 'utility', 'logistics', 'bank_financial', 'retail_invoice', 'general'
  final String detectedLanguage; // 'ar', 'en', 'bilingual'
  final List<Map<String, String>> dynamicMetadata; // Dynamic Header Key-Values e.g. [{"label": "Doctor", "value": "Dr. Smith"}]
  final List<String> tableColumns; // Dynamic Column Headers e.g. ["Medicine", "Batch", "Qty", "Price"]
  final List<List<String>> tableRows; // Dynamic 2D Matrix of row items

  InvoiceModel({
    required this.id,
    required this.storeName,
    this.invoiceNumber,
    this.date,
    this.time,
    this.currency,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    this.paymentMethod,
    this.imagePath,
    this.ocrEngine,
    required this.ocrConfidence,
    this.rawText,
    required this.createdAt,
    required this.items,
    this.documentType = 'invoice',
    this.documentTitle,
    this.senderName,
    this.receiverName,
    this.accountNumber,
    this.branch,
    this.notes,
    this.employeeName,
    this.documentCategory = 'general',
    this.detectedLanguage = 'ar',
    this.dynamicMetadata = const [],
    this.tableColumns = const [],
    this.tableRows = const [],
  });

  /// Helper parser for dynamic metadata List<Map<String, String>>
  static List<Map<String, String>> _parseDynamicMetadata(dynamic raw) {
    if (raw == null || raw.toString().isEmpty) return [];
    try {
      final List parsed = raw is String ? jsonDecode(raw) : raw;
      return parsed.map((item) {
        if (item is Map) {
          return {
            'label': item['label']?.toString() ?? '',
            'value': item['value']?.toString() ?? '',
          };
        }
        return <String, String>{};
      }).where((m) => m.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  /// Helper parser for table columns List<String>
  static List<String> _parseTableColumns(dynamic raw) {
    if (raw == null || raw.toString().isEmpty) return [];
    try {
      final List parsed = raw is String ? jsonDecode(raw) : raw;
      return parsed.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Helper parser for table rows List<List<String>>
  static List<List<String>> _parseTableRows(dynamic raw) {
    if (raw == null || raw.toString().isEmpty) return [];
    try {
      final List parsed = raw is String ? jsonDecode(raw) : raw;
      return parsed.map((row) {
        if (row is List) {
          return row.map((cell) => cell.toString()).toList();
        }
        return <String>[];
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Factory constructor to parse from SQLite ResultSet row.
  factory InvoiceModel.fromMap(Map<String, dynamic> map, {List<InvoiceItemModel> items = const []}) {
    return InvoiceModel(
      id: map['id'] as String,
      storeName: map['store_name'] as String,
      invoiceNumber: map['invoice_number'] as String?,
      date: map['date'] as String?,
      time: map['time'] as String?,
      currency: map['currency'] as String?,
      subtotal: (map['subtotal'] as num).toDouble(),
      tax: (map['tax'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String?,
      imagePath: map['image_path'] as String?,
      ocrEngine: map['ocr_engine'] as String?,
      ocrConfidence: (map['ocr_confidence'] as num).toDouble(),
      rawText: map['raw_text'] as String?,
      createdAt: map['created_at'] as String,
      items: items,
      documentType: map['document_type'] as String? ?? 'invoice',
      documentTitle: map['document_title'] as String?,
      senderName: map['sender_name'] as String?,
      receiverName: map['receiver_name'] as String?,
      accountNumber: map['account_number'] as String?,
      branch: map['branch'] as String?,
      notes: map['notes'] as String?,
      employeeName: map['employee_name'] as String?,
      documentCategory: map['document_category'] as String? ?? 'general',
      detectedLanguage: map['detected_language'] as String? ?? 'ar',
      dynamicMetadata: _parseDynamicMetadata(map['dynamic_metadata']),
      tableColumns: _parseTableColumns(map['table_columns']),
      tableRows: _parseTableRows(map['table_rows']),
    );
  }

  /// Converts model back to SQLite parameters.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_name': storeName,
      'invoice_number': invoiceNumber,
      'date': date,
      'time': time,
      'currency': currency,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'image_path': imagePath,
      'ocr_engine': ocrEngine,
      'ocr_confidence': ocrConfidence,
      'raw_text': rawText,
      'created_at': createdAt,
      'document_type': documentType,
      'document_title': documentTitle,
      'sender_name': senderName,
      'receiver_name': receiverName,
      'account_number': accountNumber,
      'branch': branch,
      'notes': notes,
      'employee_name': employeeName,
      'document_category': documentCategory,
      'detected_language': detectedLanguage,
      'dynamic_metadata': jsonEncode(dynamicMetadata),
      'table_columns': jsonEncode(tableColumns),
      'table_rows': jsonEncode(tableRows),
    };
  }

  /// Copy constructor helper
  InvoiceModel copyWith({
    String? id,
    String? storeName,
    String? invoiceNumber,
    String? date,
    String? time,
    String? currency,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    String? paymentMethod,
    String? imagePath,
    String? ocrEngine,
    double? ocrConfidence,
    String? rawText,
    String? createdAt,
    List<InvoiceItemModel>? items,
    String? documentType,
    String? documentTitle,
    String? senderName,
    String? receiverName,
    String? accountNumber,
    String? branch,
    String? notes,
    String? employeeName,
    String? documentCategory,
    String? detectedLanguage,
    List<Map<String, String>>? dynamicMetadata,
    List<String>? tableColumns,
    List<List<String>>? tableRows,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      time: time ?? this.time,
      currency: currency ?? this.currency,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      imagePath: imagePath ?? this.imagePath,
      ocrEngine: ocrEngine ?? this.ocrEngine,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
      rawText: rawText ?? this.rawText,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      documentType: documentType ?? this.documentType,
      documentTitle: documentTitle ?? this.documentTitle,
      senderName: senderName ?? this.senderName,
      receiverName: receiverName ?? this.receiverName,
      accountNumber: accountNumber ?? this.accountNumber,
      branch: branch ?? this.branch,
      notes: notes ?? this.notes,
      employeeName: employeeName ?? this.employeeName,
      documentCategory: documentCategory ?? this.documentCategory,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      dynamicMetadata: dynamicMetadata ?? this.dynamicMetadata,
      tableColumns: tableColumns ?? this.tableColumns,
      tableRows: tableRows ?? this.tableRows,
    );
  }
}
