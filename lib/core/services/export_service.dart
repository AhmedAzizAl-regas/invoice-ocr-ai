import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/invoice/data/models/invoice_model.dart';
import '../utils/date_formatter.dart';
import '../utils/currency_formatter.dart';

/// ExportService creates Excel, CSV, Word, and PDF files from Invoices and handles share/print.
class ExportService {
  ExportService();

  /// Gets a standard output directory for storing exported invoices.
  Future<String> _getExportDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final exportPath = p.join(dir.path, 'exports');
    final directory = Directory(exportPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return exportPath;
  }

  /// Generates a clean, user-friendly filename based on the merchant name and date.
  String _buildFileName(InvoiceModel invoice, String extension) {
    final store =
        (invoice.storeName.isNotEmpty && invoice.storeName != 'Unknown Store')
        ? invoice.storeName
        : 'Invoice';
    final cleanStoreName = store.replaceAll(RegExp(r'[\\/:*?"<>|\s]'), '_');
    final cleanDate = (invoice.date ?? '').replaceAll(
      RegExp(r'[\\/:*?"<>|\s]'),
      '_',
    );
    return '${cleanStoreName}_${cleanDate}_${DateTime.now().millisecondsSinceEpoch}.$extension';
  }

  /// Validates whether a field value should be printed (filters out empty, null, N/A, A/N, Unknown).
  bool _isValidValue(String? val) {
    if (val == null) return false;
    final trimmed = val.trim().toLowerCase();
    if (trimmed.isEmpty) return false;
    if (trimmed == 'n/a' ||
        trimmed == 'a/n' ||
        trimmed == 'unknown' ||
        trimmed == 'unknown store' ||
        trimmed == 'null' ||
        trimmed == '-')
      return false;
    return true;
  }

  /// Gets context-specific clean label for document fields without bloated slashes.
  String _getFieldLabel(String fieldType, String category, bool isAr) {
    final cat = category.toLowerCase();

    switch (fieldType) {
      case 'institution':
        if (cat == 'bank_financial') return isAr ? 'البنك' : 'Bank';
        if (cat == 'medical') return isAr ? 'المستشفى' : 'Hospital';
        if (cat == 'pharmacy') return isAr ? 'الصيدلية' : 'Pharmacy';
        if (cat == 'education_tuition') return isAr ? 'الجامعة' : 'University';
        if (cat == 'hotel') return isAr ? 'الفندق' : 'Hotel';
        if (cat == 'real_estate_rent' || cat == 'real_estate_sale') return isAr ? 'المكتب العقاري' : 'Agency';
        if (cat == 'vehicle_sale') return isAr ? 'معرض السيارات' : 'Showroom';
        if (cat == 'utility') return isAr ? 'شركة المرافق' : 'Utility Provider';
        if (cat == 'logistics') return isAr ? 'شركة الشحن' : 'Carrier';
        return isAr ? 'الجهة' : 'Institution';

      case 'sender':
        if (cat == 'bank_financial') return isAr ? 'المودع' : 'Sender';
        if (cat == 'medical' || cat == 'pharmacy') return isAr ? 'اسم المريض' : 'Patient Name';
        if (cat == 'education_tuition') return isAr ? 'اسم الطالب' : 'Student Name';
        if (cat == 'hotel') return isAr ? 'اسم النزيل' : 'Guest Name';
        if (cat == 'logistics') return isAr ? 'اسم المرسل' : 'Shipper';
        if (cat == 'utility') return isAr ? 'اسم المشترك' : 'Subscriber';
        if (cat == 'real_estate_rent') return isAr ? 'اسم المستأجر' : 'Tenant';
        if (cat == 'real_estate_sale' || cat == 'vehicle_sale') return isAr ? 'اسم المشتري' : 'Buyer';
        if (cat == 'purchase_invoice') return isAr ? 'الجهة المشترية' : 'Buyer';
        if (cat == 'sales_invoice') return isAr ? 'اسم العميل' : 'Customer';
        return isAr ? 'العميل' : 'Customer';

      case 'receiver':
        if (cat == 'bank_financial') return isAr ? 'المستفيد' : 'Beneficiary';
        if (cat == 'medical') return isAr ? 'المستشفى' : 'Hospital';
        if (cat == 'pharmacy') return isAr ? 'الصيدلية' : 'Pharmacy';
        if (cat == 'education_tuition') return isAr ? 'الجامعة' : 'University';
        if (cat == 'hotel') return isAr ? 'الفندق' : 'Hotel';
        if (cat == 'logistics') return isAr ? 'اسم المرسل إليه' : 'Consignee';
        if (cat == 'real_estate_rent') return isAr ? 'اسم المؤجر' : 'Landlord';
        if (cat == 'real_estate_sale' || cat == 'vehicle_sale') return isAr ? 'اسم البائع' : 'Seller';
        if (cat == 'purchase_invoice') return isAr ? 'المورد' : 'Supplier';
        if (cat == 'sales_invoice') return isAr ? 'البائع' : 'Seller';
        return isAr ? 'المتجر' : 'Merchant';

      case 'account':
        if (cat == 'bank_financial') return isAr ? 'رقم الحساب' : 'Account No';
        if (cat == 'medical') return isAr ? 'رقم الملف الطبي' : 'Medical File No';
        if (cat == 'pharmacy') return isAr ? 'رقم الوصفة الطبية' : 'Prescription No';
        if (cat == 'education_tuition') return isAr ? 'الرقم الجامعي' : 'Student ID';
        if (cat == 'hotel') return isAr ? 'رقم الحجز' : 'Booking No';
        if (cat == 'logistics') return isAr ? 'رقم بوليصة الشحن' : 'Waybill No';
        if (cat == 'real_estate_rent') return isAr ? 'رقم العقد' : 'Contract No';
        if (cat == 'real_estate_sale') return isAr ? 'رقم الصك' : 'Deed No';
        if (cat == 'vehicle_sale') return isAr ? 'رقم الهيكل (VIN)' : 'Chassis No';
        if (cat == 'utility') return isAr ? 'رقم العداد' : 'Meter No';
        if (cat == 'purchase_invoice') return isAr ? 'رقم أمر الشراء' : 'PO No';
        if (cat == 'sales_invoice') return isAr ? 'رقم حساب العميل' : 'Customer Account No';
        return isAr ? 'رقم الحساب' : 'Account No';

      case 'employee':
        if (cat == 'bank_financial') return isAr ? 'الصراف' : 'Teller';
        if (cat == 'medical') return isAr ? 'الطبيب المعالج' : 'Doctor';
        if (cat == 'pharmacy') return isAr ? 'الصيدلي' : 'Pharmacist';
        if (cat == 'education_tuition') return isAr ? 'المحاسب' : 'Accountant';
        if (cat == 'hotel') return isAr ? 'موظف الاستقبال' : 'Receptionist';
        if (cat == 'logistics') return isAr ? 'المخلص الجمركي' : 'Dispatcher';
        if (cat == 'purchase_invoice') return isAr ? 'مسؤول المشتريات' : 'Purchasing Agent';
        if (cat == 'sales_invoice') return isAr ? 'ممثل المبيعات' : 'Sales Rep';
        return isAr ? 'الموظف' : 'Employee';

      case 'branch':
        if (cat == 'medical') return isAr ? 'العيادة' : 'Clinic';
        if (cat == 'education_tuition') return isAr ? 'الكلية' : 'Faculty';
        return isAr ? 'الفرع' : 'Branch';

      default:
        return fieldType;
    }
  }

  /// Exports an Invoice, Medical Bill, or Bank Slip to CSV.
  Future<File> exportToCsv(InvoiceModel invoice, {bool? isArabic}) async {
    final isAr =
        isArabic ??
        (invoice.detectedLanguage == 'ar' ||
            RegExp(r'[\u0600-\u06FF]').hasMatch(
              '${invoice.documentTitle} ${invoice.storeName} ${invoice.notes} ${invoice.senderName}',
            ));
    final isBankDoc = invoice.documentType != 'invoice';
    final cat = invoice.documentCategory;

    final List<List<dynamic>> csvData = [
      [isAr ? 'الحقل' : 'Field', isAr ? 'القيمة' : 'Value'],
    ];

    if (_isValidValue(invoice.documentTitle))
      csvData.add([isAr ? 'عنوان المستند' : 'Title', invoice.documentTitle!]);
    if (_isValidValue(invoice.storeName))
      csvData.add([
        _getFieldLabel('institution', cat, isAr),
        invoice.storeName,
      ]);
    if (_isValidValue(invoice.invoiceNumber))
      csvData.add([isAr ? 'رقم المرجع' : 'Ref #', invoice.invoiceNumber!]);
    if (_isValidValue(invoice.branch))
      csvData.add([_getFieldLabel('branch', cat, isAr), invoice.branch!]);
    if (_isValidValue(invoice.date))
      csvData.add([isAr ? 'التاريخ' : 'Date', invoice.date!]);
    if (_isValidValue(invoice.time))
      csvData.add([isAr ? 'الوقت' : 'Time', invoice.time!]);
    if (_isValidValue(invoice.currency))
      csvData.add([isAr ? 'العملة' : 'Currency', invoice.currency!]);
    if (_isValidValue(invoice.paymentMethod))
      csvData.add([
        isAr ? 'طريقة الدفع' : 'Payment Method',
        invoice.paymentMethod!,
      ]);

    if (_isValidValue(invoice.senderName))
      csvData.add([_getFieldLabel('sender', cat, isAr), invoice.senderName!]);
    if (_isValidValue(invoice.receiverName))
      csvData.add([
        _getFieldLabel('receiver', cat, isAr),
        invoice.receiverName!,
      ]);
    if (_isValidValue(invoice.accountNumber))
      csvData.add([
        _getFieldLabel('account', cat, isAr),
        invoice.accountNumber!,
      ]);
    if (_isValidValue(invoice.employeeName))
      csvData.add([
        _getFieldLabel('employee', cat, isAr),
        invoice.employeeName!,
      ]);
    if (_isValidValue(invoice.notes))
      csvData.add([isAr ? 'الملاحظات' : 'Notes', invoice.notes!]);

    // Dynamic Metadata Filtered
    final addedValues = <String>{
      if (invoice.accountNumber != null) invoice.accountNumber!,
      if (invoice.invoiceNumber != null) invoice.invoiceNumber!,
    };

    final validMetadata = invoice.dynamicMetadata.where((m) {
      final v = m['value'] ?? '';
      return _isValidValue(v) && !addedValues.contains(v);
    }).toList();

    if (validMetadata.isNotEmpty) {
      csvData.add([]);
      csvData.add([
        isAr ? '--- بيانات وحقول المستند ---' : '--- Dynamic Metadata ---',
        '',
      ]);
      for (final item in validMetadata) {
        csvData.add([item['label'] ?? '', item['value'] ?? '']);
      }
    }

    if (invoice.total > 0) {
      csvData.add([]);
      if (!isBankDoc && invoice.subtotal > 0)
        csvData.add([
          isAr ? 'الإجمالي قبل الضريبة' : 'Subtotal',
          CurrencyFormatter.format(invoice.subtotal),
        ]);
      if (!isBankDoc && invoice.tax > 0)
        csvData.add([isAr ? 'الضريبة' : 'Tax', CurrencyFormatter.format(invoice.tax)]);
      if (!isBankDoc && invoice.discount > 0)
        csvData.add([isAr ? 'الخصم' : 'Discount', CurrencyFormatter.format(invoice.discount)]);
      csvData.add([
        isAr ? 'المبلغ الإجمالي النهائي' : 'Total Amount',
        CurrencyFormatter.format(invoice.total),
      ]);
    }

    if (invoice.items.isNotEmpty) {
      csvData.add([]);
      csvData.add(
        isAr
            ? ['اسم المنتج / الخدمة', 'الكمية', 'سعر الوحدة', 'الإجمالي']
            : ['Product Name', 'Quantity', 'Unit Price', 'Total Price'],
      );
      csvData.addAll(
        invoice.items.map(
          (item) => [
            item.productName,
            item.quantity,
            CurrencyFormatter.format(item.unitPrice),
            CurrencyFormatter.format(item.totalPrice),
          ],
        ),
      );
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final exportDir = await _getExportDirectory();
    final fileName = _buildFileName(invoice, 'csv');
    final file = File(p.join(exportDir, fileName));
    await file.writeAsString(csvString, encoding: utf8);
    return file;
  }

  /// Exports an Invoice, Medical Bill, or Bank Slip to Excel (.xlsx).
  Future<File> exportToExcel(InvoiceModel invoice, {bool? isArabic}) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];
    final isAr =
        isArabic ??
        (invoice.detectedLanguage == 'ar' ||
            RegExp(r'[\u0600-\u06FF]').hasMatch(
              '${invoice.documentTitle} ${invoice.storeName} ${invoice.notes} ${invoice.senderName}',
            ));
    final isBankDoc = invoice.documentType != 'invoice';
    final cat = invoice.documentCategory;

    sheet.appendRow([
      TextCellValue(
        invoice.documentTitle ??
            (isBankDoc
                ? (isAr ? 'إشعار مالي / إيداع' : 'Bank Voucher')
                : (isAr ? 'تقرير فاتورة' : 'Document Report')),
      ),
    ]);
    sheet.appendRow([]);

    if (_isValidValue(invoice.storeName))
      sheet.appendRow([
        TextCellValue(_getFieldLabel('institution', cat, isAr) + ':'),
        TextCellValue(invoice.storeName),
      ]);
    if (_isValidValue(invoice.invoiceNumber))
      sheet.appendRow([
        TextCellValue((isAr ? 'رقم المرجع' : 'Ref #') + ':'),
        TextCellValue(invoice.invoiceNumber!),
      ]);
    if (_isValidValue(invoice.branch))
      sheet.appendRow([
        TextCellValue(_getFieldLabel('branch', cat, isAr) + ':'),
        TextCellValue(invoice.branch!),
      ]);
    if (_isValidValue(invoice.date))
      sheet.appendRow([
        TextCellValue((isAr ? 'التاريخ' : 'Date') + ':'),
        TextCellValue(invoice.date!),
      ]);
    if (_isValidValue(invoice.time))
      sheet.appendRow([
        TextCellValue((isAr ? 'الوقت' : 'Time') + ':'),
        TextCellValue(invoice.time!),
      ]);
    if (_isValidValue(invoice.currency))
      sheet.appendRow([
        TextCellValue((isAr ? 'العملة' : 'Currency') + ':'),
        TextCellValue(invoice.currency!),
      ]);

    if (_isValidValue(invoice.senderName))
      sheet.appendRow([
        TextCellValue(_getFieldLabel('sender', cat, isAr) + ':'),
        TextCellValue(invoice.senderName!),
      ]);
    if (_isValidValue(invoice.receiverName))
      sheet.appendRow([
        TextCellValue(_getFieldLabel('receiver', cat, isAr) + ':'),
        TextCellValue(invoice.receiverName!),
      ]);
    if (_isValidValue(invoice.accountNumber))
      sheet.appendRow([
        TextCellValue(_getFieldLabel('account', cat, isAr) + ':'),
        TextCellValue(invoice.accountNumber!),
      ]);
    if (_isValidValue(invoice.employeeName))
      sheet.appendRow([
        TextCellValue(_getFieldLabel('employee', cat, isAr) + ':'),
        TextCellValue(invoice.employeeName!),
      ]);
    if (_isValidValue(invoice.notes))
      sheet.appendRow([
        TextCellValue((isAr ? 'الملاحظات' : 'Notes') + ':'),
        TextCellValue(invoice.notes!),
      ]);

    final addedValues = <String>{
      if (invoice.accountNumber != null) invoice.accountNumber!,
      if (invoice.invoiceNumber != null) invoice.invoiceNumber!,
    };

    final validMetadata = invoice.dynamicMetadata.where((m) {
      final v = m['value'] ?? '';
      return _isValidValue(v) && !addedValues.contains(v);
    }).toList();

    if (validMetadata.isNotEmpty) {
      sheet.appendRow([]);
      sheet.appendRow([
        TextCellValue(
          isAr ? '--- بيانات وحقول المستند ---' : '--- Dynamic Metadata ---',
        ),
      ]);
      for (final meta in validMetadata) {
        sheet.appendRow([
          TextCellValue((meta['label'] ?? '') + ':'),
          TextCellValue(meta['value'] ?? ''),
        ]);
      }
    }

    if (invoice.items.isNotEmpty) {
      sheet.appendRow([]);
      sheet.appendRow(
        isAr
            ? [
                TextCellValue('اسم المنتج / الخدمة'),
                TextCellValue('الكمية'),
                TextCellValue('سعر الوحدة'),
                TextCellValue('الإجمالي'),
              ]
            : [
                TextCellValue('Product Name'),
                TextCellValue('Quantity'),
                TextCellValue('Unit Price'),
                TextCellValue('Total Price'),
              ],
      );

      for (final item in invoice.items) {
        sheet.appendRow([
          TextCellValue(item.productName),
          DoubleCellValue(item.quantity),
          DoubleCellValue(item.unitPrice),
          DoubleCellValue(item.totalPrice),
        ]);
      }
    }

    if (invoice.total > 0) {
      sheet.appendRow([]);
      if (!isBankDoc && invoice.subtotal > 0)
        sheet.appendRow([
          TextCellValue((isAr ? 'الإجمالي قبل الضريبة' : 'Subtotal') + ':'),
          DoubleCellValue(invoice.subtotal),
        ]);
      if (!isBankDoc && invoice.tax > 0)
        sheet.appendRow([
          TextCellValue((isAr ? 'الضريبة' : 'Tax') + ':'),
          DoubleCellValue(invoice.tax),
        ]);
      if (!isBankDoc && invoice.discount > 0)
        sheet.appendRow([
          TextCellValue((isAr ? 'الخصم' : 'Discount') + ':'),
          DoubleCellValue(invoice.discount),
        ]);
      sheet.appendRow([
        TextCellValue(
          (isAr ? 'المبلغ الإجمالي النهائي' : 'Total Amount') + ':',
        ),
        DoubleCellValue(invoice.total),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Failed to generate Excel bytes');

    final exportDir = await _getExportDirectory();
    final fileName = _buildFileName(invoice, 'xlsx');
    final file = File(p.join(exportDir, fileName));
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Exports an Invoice or Bank Slip to PDF with Arabic Cairo font and smart field hiding.
  Future<File> exportToPdf(InvoiceModel invoice, {bool? isArabic}) async {
    final pdf = pw.Document();

    pw.Font? cairoRegular;
    pw.Font? cairoBold;
    try {
      cairoRegular = await PdfGoogleFonts.cairoRegular();
      cairoBold = await PdfGoogleFonts.cairoBold();
    } catch (_) {}

    final isAr =
        isArabic ??
        (invoice.detectedLanguage == 'ar' ||
            RegExp(r'[\u0600-\u06FF]').hasMatch(
              '${invoice.documentTitle} ${invoice.storeName} ${invoice.notes} ${invoice.senderName}',
            ));
    final isBankDoc = invoice.documentType != 'invoice';
    final cat = invoice.documentCategory;

    final textStyle = pw.TextStyle(
      font: cairoRegular ?? pw.Font.helvetica(),
      fontSize: 11,
    );
    final boldStyle = pw.TextStyle(
      font: cairoBold ?? cairoRegular ?? pw.Font.helvetica(),
      fontWeight: pw.FontWeight.bold,
      fontSize: 12,
    );

    final addedValues = <String>{
      if (invoice.accountNumber != null) invoice.accountNumber!,
      if (invoice.invoiceNumber != null) invoice.invoiceNumber!,
    };

    final validMetadata = invoice.dynamicMetadata.where((m) {
      final v = m['value'] ?? '';
      return _isValidValue(v) && !addedValues.contains(v);
    }).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: cairoRegular ?? pw.Font.helvetica(),
          bold: cairoBold ?? cairoRegular ?? pw.Font.helvetica(),
        ),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Title
                  pw.Text(
                    invoice.documentTitle ??
                        (isBankDoc
                            ? (isAr
                                  ? 'إشعار مالي / إيداع بنكي'
                                  : 'Bank Voucher')
                            : (isAr ? 'تقرير الفاتورة' : 'DOCUMENT REPORT')),
                    style: boldStyle.copyWith(fontSize: 20),
                    textDirection: isAr
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr,
                  ),
                  pw.Divider(thickness: 1.5),
                  pw.SizedBox(height: 10),

                  // Header Info Row
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      if (_isValidValue(invoice.storeName))
                        pw.Text(
                          '${_getFieldLabel("institution", cat, isAr)}: ${invoice.storeName}',
                          style: textStyle,
                          textDirection: isAr
                              ? pw.TextDirection.rtl
                              : pw.TextDirection.ltr,
                        )
                      else
                        pw.SizedBox(),
                      if (_isValidValue(invoice.invoiceNumber))
                        pw.Text(
                          '${isAr ? "رقم المرجع" : "Ref #"}: ${invoice.invoiceNumber}',
                          style: textStyle,
                          textDirection: isAr
                              ? pw.TextDirection.rtl
                              : pw.TextDirection.ltr,
                        )
                      else
                        pw.SizedBox(),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      if (_isValidValue(invoice.branch))
                        pw.Text(
                          '${_getFieldLabel("branch", cat, isAr)}: ${invoice.branch}',
                          style: textStyle,
                          textDirection: isAr
                              ? pw.TextDirection.rtl
                              : pw.TextDirection.ltr,
                        )
                      else
                        pw.SizedBox(),
                      if (_isValidValue(invoice.date))
                        pw.Text(
                          '${isAr ? "التاريخ" : "Date"}: ${invoice.date} ${invoice.time ?? ""}',
                          style: textStyle,
                          textDirection: isAr
                              ? pw.TextDirection.rtl
                              : pw.TextDirection.ltr,
                        )
                      else
                        pw.SizedBox(),
                    ],
                  ),
                  pw.SizedBox(height: 15),

                  // Dynamic Metadata Box (Only valid fields)
                  if (validMetadata.isNotEmpty) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: validMetadata.map((meta) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 3),
                            child: pw.Text(
                              '${meta["label"]}: ${meta["value"]}',
                              style: textStyle,
                              textDirection: isAr
                                  ? pw.TextDirection.rtl
                                  : pw.TextDirection.ltr,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    pw.SizedBox(height: 15),
                  ],

                  // Main Parties & Account Box (Only valid fields)
                  if (_isValidValue(invoice.senderName) ||
                      _isValidValue(invoice.receiverName) ||
                      _isValidValue(invoice.accountNumber) ||
                      _isValidValue(invoice.employeeName) ||
                      _isValidValue(invoice.notes)) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (_isValidValue(invoice.senderName)) ...[
                            pw.Text(
                              '${_getFieldLabel("sender", cat, isAr)}: ${invoice.senderName}',
                              style: textStyle,
                              textDirection: isAr
                                  ? pw.TextDirection.rtl
                                  : pw.TextDirection.ltr,
                            ),
                            pw.SizedBox(height: 4),
                          ],
                          if (_isValidValue(invoice.receiverName)) ...[
                            pw.Text(
                              '${_getFieldLabel("receiver", cat, isAr)}: ${invoice.receiverName}',
                              style: textStyle,
                              textDirection: isAr
                                  ? pw.TextDirection.rtl
                                  : pw.TextDirection.ltr,
                            ),
                            pw.SizedBox(height: 4),
                          ],
                          if (_isValidValue(invoice.accountNumber)) ...[
                            pw.Text(
                              '${_getFieldLabel("account", cat, isAr)}: ${invoice.accountNumber}',
                              style: textStyle,
                              textDirection: isAr
                                  ? pw.TextDirection.rtl
                                  : pw.TextDirection.ltr,
                            ),
                            pw.SizedBox(height: 4),
                          ],
                          if (_isValidValue(invoice.employeeName)) ...[
                            pw.Text(
                              '${_getFieldLabel("employee", cat, isAr)}: ${invoice.employeeName}',
                              style: textStyle,
                              textDirection: isAr
                                  ? pw.TextDirection.rtl
                                  : pw.TextDirection.ltr,
                            ),
                            pw.SizedBox(height: 4),
                          ],
                          if (_isValidValue(invoice.notes)) ...[
                            pw.Text(
                              '${isAr ? "الملاحظات" : "Notes"}: ${invoice.notes}',
                              style: textStyle,
                              textDirection: isAr
                                  ? pw.TextDirection.rtl
                                  : pw.TextDirection.ltr,
                            ),
                          ],
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 15),
                  ],

                  // Items Table if present
                  if (invoice.tableColumns.isNotEmpty &&
                      invoice.tableRows.isNotEmpty) ...[
                    pw.TableHelper.fromTextArray(
                      headers: invoice.tableColumns,
                      data: invoice.tableRows,
                    ),
                    pw.SizedBox(height: 15),
                  ] else if (invoice.items.isNotEmpty) ...[
                    pw.TableHelper.fromTextArray(
                      headers: isAr
                          ? [
                              'اسم المنتج / الخدمة',
                              'الكمية',
                              'سعر الوحدة',
                              'الإجمالي',
                            ]
                          : ['Item / Service', 'Qty', 'Unit Price', 'Total'],
                      data: invoice.items
                          .map(
                            (item) => [
                              item.productName,
                              item.quantity.toString(),
                              CurrencyFormatter.format(item.unitPrice),
                              CurrencyFormatter.format(item.totalPrice),
                            ],
                          )
                          .toList(),
                    ),
                    pw.SizedBox(height: 15),
                  ],

                  // Total Amount Box
                  if (invoice.total > 0) ...[
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          isAr ? 'المبلغ الإجمالي النهائي:' : 'Total Amount:',
                          style: boldStyle.copyWith(fontSize: 15),
                          textDirection: isAr
                              ? pw.TextDirection.rtl
                              : pw.TextDirection.ltr,
                        ),
                        pw.Text(
                          '${CurrencyFormatter.format(invoice.total)} ${invoice.currency}',
                          style: boldStyle.copyWith(
                            fontSize: 17,
                            color: PdfColors.green800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );

    final exportDir = await _getExportDirectory();
    final fileName = _buildFileName(invoice, 'pdf');
    final file = File(p.join(exportDir, fileName));
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Exports an Invoice or Bank Slip to Word (.docx).
  Future<File> exportToWord(InvoiceModel invoice, {bool? isArabic}) async {
    final isAr =
        isArabic ??
        (invoice.detectedLanguage == 'ar' ||
            RegExp(r'[\u0600-\u06FF]').hasMatch(
              '${invoice.documentTitle} ${invoice.storeName} ${invoice.notes} ${invoice.senderName}',
            ));
    final archive = Archive();
    final isBankDoc = invoice.documentType != 'invoice';
    final cat = invoice.documentCategory;

    const contentTypesXml =
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';
    archive.addFile(
      ArchiveFile(
        '[Content_Types].xml',
        contentTypesXml.length,
        utf8.encode(contentTypesXml),
      ),
    );

    const relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    archive.addFile(
      ArchiveFile('_rels/.rels', relsXml.length, utf8.encode(relsXml)),
    );

    final StringBuffer docBuffer = StringBuffer();
    docBuffer.write('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:pPr><w:pStyle w:val="Heading1"/></w:pPr>
      <w:r><w:t>${invoice.documentTitle ?? (isBankDoc ? (isAr ? "إشعار مالي / إيداع" : "Bank Transfer") : (isAr ? "تقرير الفاتورة" : "Invoice Report"))}</w:t></w:r>
    </w:p>
''');

    if (_isValidValue(invoice.storeName))
      docBuffer.write(
        '<w:p><w:r><w:t>${_getFieldLabel("institution", cat, isAr)}: ${invoice.storeName}</w:t></w:r></w:p>',
      );
    if (_isValidValue(invoice.invoiceNumber))
      docBuffer.write(
        '<w:p><w:r><w:t>${isAr ? "رقم المرجع" : "Ref #"}: ${invoice.invoiceNumber}</w:t></w:r></w:p>',
      );
    if (_isValidValue(invoice.branch))
      docBuffer.write(
        '<w:p><w:r><w:t>${_getFieldLabel("branch", cat, isAr)}: ${invoice.branch}</w:t></w:r></w:p>',
      );
    if (_isValidValue(invoice.date))
      docBuffer.write(
        '<w:p><w:r><w:t>${isAr ? "التاريخ" : "Date"}: ${invoice.date} ${invoice.time ?? ""}</w:t></w:r></w:p>',
      );

    if (_isValidValue(invoice.senderName))
      docBuffer.write(
        '<w:p><w:r><w:t>${_getFieldLabel("sender", cat, isAr)}: ${invoice.senderName}</w:t></w:r></w:p>',
      );
    if (_isValidValue(invoice.receiverName))
      docBuffer.write(
        '<w:p><w:r><w:t>${_getFieldLabel("receiver", cat, isAr)}: ${invoice.receiverName}</w:t></w:r></w:p>',
      );
    if (_isValidValue(invoice.accountNumber))
      docBuffer.write(
        '<w:p><w:r><w:t>${_getFieldLabel("account", cat, isAr)}: ${invoice.accountNumber}</w:t></w:r></w:p>',
      );
    if (_isValidValue(invoice.employeeName))
      docBuffer.write(
        '<w:p><w:r><w:t>${_getFieldLabel("employee", cat, isAr)}: ${invoice.employeeName}</w:t></w:r></w:p>',
      );
    if (_isValidValue(invoice.notes))
      docBuffer.write(
        '<w:p><w:r><w:t>${isAr ? "الملاحظات" : "Notes"}: ${invoice.notes}</w:t></w:r></w:p>',
      );

    if (invoice.total > 0) {
      docBuffer.write(
        '<w:p><w:r><w:t>--------------------------------------------------</w:t></w:r></w:p>',
      );
      docBuffer.write(
        '<w:p><w:r><w:t>${isAr ? "المبلغ الإجمالي النهائي" : "Total Amount"}: ${invoice.total} ${invoice.currency}</w:t></w:r></w:p>',
      );
    }

    docBuffer.write('''
  </w:body>
</w:document>''');

    final documentXml = docBuffer.toString();
    archive.addFile(
      ArchiveFile(
        'word/document.xml',
        documentXml.length,
        utf8.encode(documentXml),
      ),
    );

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) throw Exception('Failed to generate Docx bytes');

    final exportDir = await _getExportDirectory();
    final fileName = _buildFileName(invoice, 'docx');
    final file = File(p.join(exportDir, fileName));
    await file.writeAsBytes(zipBytes);
    return file;
  }

  /// Triggers standard OS share panel for the file.
  Future<void> shareFile(File file, {String? text}) async {
    final xFile = XFile(file.path);
    await Share.shareXFiles([xFile], text: text);
  }

  /// Triggers standard OS document printing panel.
  Future<void> printPdf(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
  }
}
