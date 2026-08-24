import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../models/invoice_item_model.dart';
import '../models/invoice_model.dart';
import '../models/currency_model.dart';

/// InvoiceLocalSource handles direct execution of raw SQL on SQLite3 database.
class InvoiceLocalSource {
  final DatabaseHelper _dbHelper;

  InvoiceLocalSource(this._dbHelper);

  /// Fetches items for a specific invoice.
  List<InvoiceItemModel> getItemsForInvoice(String invoiceId) {
    final results = _dbHelper.select(
      'SELECT * FROM invoice_items WHERE invoice_id = ?;',
      [invoiceId],
    );
    return results.map((row) => InvoiceItemModel.fromMap(row)).toList();
  }

  /// Lists all invoices matching filter parameters.
  List<InvoiceModel> getInvoices({
    String? query,
    String? sortBy,
    bool ascending = false,
  }) {
    final buffer = StringBuffer('SELECT * FROM invoices');
    final List<Object?> params = [];

    if (query != null && query.isNotEmpty) {
      buffer.write(' WHERE store_name LIKE ? OR raw_text LIKE ? OR invoice_number LIKE ?');
      final likePattern = '%$query%';
      params.addAll([likePattern, likePattern, likePattern]);
    }

    if (sortBy != null && sortBy.isNotEmpty) {
      buffer.write(' ORDER BY $sortBy ${ascending ? "ASC" : "DESC"}');
    } else {
      buffer.write(' ORDER BY created_at DESC');
    }

    final results = _dbHelper.select(buffer.toString(), params);
    
    return results.map((row) {
      final id = row['id'] as String;
      final items = getItemsForInvoice(id);
      return InvoiceModel.fromMap(row, items: items);
    }).toList();
  }

  /// Fetches a single invoice.
  InvoiceModel? getInvoiceById(String id) {
    final results = _dbHelper.select('SELECT * FROM invoices WHERE id = ?;', [id]);
    if (results.isEmpty) return null;
    
    final items = getItemsForInvoice(id);
    return InvoiceModel.fromMap(results.first, items: items);
  }

  /// Saves invoice and items in a transaction.
  void saveInvoice(InvoiceModel invoice) {
    _dbHelper.execute('BEGIN TRANSACTION;');
    try {
      _dbHelper.execute(
        '''
        INSERT INTO invoices (
          id, store_name, invoice_number, date, time, currency, 
          subtotal, tax, discount, total, payment_method, 
          image_path, ocr_engine, ocr_confidence, raw_text, created_at,
          document_type, document_title, sender_name, receiver_name,
          account_number, branch, notes, employee_name,
          document_category, detected_language, dynamic_metadata, table_columns, table_rows
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        ''',
        [
          invoice.id,
          invoice.storeName,
          invoice.invoiceNumber,
          invoice.date,
          invoice.time,
          invoice.currency,
          invoice.subtotal,
          invoice.tax,
          invoice.discount,
          invoice.total,
          invoice.paymentMethod,
          invoice.imagePath,
          invoice.ocrEngine,
          invoice.ocrConfidence,
          invoice.rawText,
          invoice.createdAt,
          invoice.documentType,
          invoice.documentTitle,
          invoice.senderName,
          invoice.receiverName,
          invoice.accountNumber,
          invoice.branch,
          invoice.notes,
          invoice.employeeName,
          invoice.documentCategory,
          invoice.detectedLanguage,
          invoice.toMap()['dynamic_metadata'],
          invoice.toMap()['table_columns'],
          invoice.toMap()['table_rows'],
        ],
      );

      for (final item in invoice.items) {
        _dbHelper.execute(
          '''
          INSERT INTO invoice_items (
            id, invoice_id, product_name, quantity, unit_price, total_price
          ) VALUES (?, ?, ?, ?, ?, ?);
          ''',
          [
            item.id,
            invoice.id,
            item.productName,
            item.quantity,
            item.unitPrice,
            item.totalPrice,
          ],
        );
      }

      _dbHelper.execute('COMMIT;');
    } catch (e) {
      _dbHelper.execute('ROLLBACK;');
      rethrow;
    }
  }

  /// Updates invoice details and replaces items.
  void updateInvoice(InvoiceModel invoice) {
    _dbHelper.execute('BEGIN TRANSACTION;');
    try {
      _dbHelper.execute(
        '''
        UPDATE invoices SET
          store_name = ?,
          invoice_number = ?,
          date = ?,
          time = ?,
          currency = ?,
          subtotal = ?,
          tax = ?,
          discount = ?,
          total = ?,
          payment_method = ?,
          image_path = ?,
          ocr_engine = ?,
          ocr_confidence = ?,
          raw_text = ?,
          document_type = ?,
          document_title = ?,
          sender_name = ?,
          receiver_name = ?,
          account_number = ?,
          branch = ?,
          notes = ?,
          employee_name = ?,
          document_category = ?,
          detected_language = ?,
          dynamic_metadata = ?,
          table_columns = ?,
          table_rows = ?
        WHERE id = ?;
        ''',
        [
          invoice.storeName,
          invoice.invoiceNumber,
          invoice.date,
          invoice.time,
          invoice.currency,
          invoice.subtotal,
          invoice.tax,
          invoice.discount,
          invoice.total,
          invoice.paymentMethod,
          invoice.imagePath,
          invoice.ocrEngine,
          invoice.ocrConfidence,
          invoice.rawText,
          invoice.documentType,
          invoice.documentTitle,
          invoice.senderName,
          invoice.receiverName,
          invoice.accountNumber,
          invoice.branch,
          invoice.notes,
          invoice.employeeName,
          invoice.documentCategory,
          invoice.detectedLanguage,
          invoice.toMap()['dynamic_metadata'],
          invoice.toMap()['table_columns'],
          invoice.toMap()['table_rows'],
          invoice.id,
        ],
      );

      // Recreate items
      _dbHelper.execute('DELETE FROM invoice_items WHERE invoice_id = ?;', [invoice.id]);
      
      for (final item in invoice.items) {
        _dbHelper.execute(
          '''
          INSERT INTO invoice_items (
            id, invoice_id, product_name, quantity, unit_price, total_price
          ) VALUES (?, ?, ?, ?, ?, ?);
          ''',
          [
            item.id,
            invoice.id,
            item.productName,
            item.quantity,
            item.unitPrice,
            item.totalPrice,
          ],
        );
      }

      _dbHelper.execute('COMMIT;');
    } catch (e) {
      _dbHelper.execute('ROLLBACK;');
      rethrow;
    }
  }

  /// Deletes invoice.
  void deleteInvoice(String id) {
    _dbHelper.execute('BEGIN TRANSACTION;');
    try {
      _dbHelper.execute('DELETE FROM invoice_items WHERE invoice_id = ?;', [id]);
      _dbHelper.execute('DELETE FROM invoices WHERE id = ?;', [id]);
      _dbHelper.execute('COMMIT;');
    } catch (e) {
      _dbHelper.execute('ROLLBACK;');
      rethrow;
    }
  }

  /// Aggregates database statistics converting totals into the specified base currency.
  Map<String, dynamic> getStatistics(String baseCurrencyCode) {
    final countResult = _dbHelper.select('SELECT COUNT(*) as cnt FROM invoices;');
    final int count = countResult.isEmpty ? 0 : countResult.first['cnt'] as int;

    // Get the exchange rate of the target base currency
    final baseRateResult = _dbHelper.select('SELECT exchange_rate FROM currencies WHERE code = ?;', [baseCurrencyCode]);
    final double baseRate = (baseRateResult.isEmpty || baseRateResult.first['exchange_rate'] == null)
        ? 1.0
        : (baseRateResult.first['exchange_rate'] as num).toDouble();

    // Query to sum up converted values: total * (invoice_currency_rate / base_rate)
    final sumResult = _dbHelper.select('''
      SELECT SUM(i.total * COALESCE(c.exchange_rate, 1.0) / ?) as total_sum 
      FROM invoices i
      LEFT JOIN currencies c ON i.currency = c.code;
    ''', [baseRate]);
    final double totalSum = (sumResult.isEmpty || sumResult.first['total_sum'] == null)
        ? 0.0
        : (sumResult.first['total_sum'] as num).toDouble();

    final recentResult = _dbHelper.select('SELECT * FROM invoices ORDER BY created_at DESC LIMIT 5;');
    final recentInvoices = recentResult.map((row) {
      final id = row['id'] as String;
      return InvoiceModel.fromMap(row, items: getItemsForInvoice(id));
    }).toList();

    final exportLogsResult = _dbHelper.select('SELECT * FROM export_logs ORDER BY timestamp DESC LIMIT 5;');
    final recentExports = exportLogsResult.map((row) => Map<String, dynamic>.from(row)).toList();

    return {
      'invoice_count': count,
      'total_spend': totalSum,
      'recent_invoices': recentInvoices,
      'recent_exports': recentExports,
    };
  }

  /// Fetches all currencies supported by the system.
  List<CurrencyModel> getCurrencies() {
    final results = _dbHelper.select('SELECT * FROM currencies ORDER BY code ASC;');
    return results.map((row) => CurrencyModel.fromMap(row)).toList();
  }

  /// Saves or updates a currency configuration in SQLite.
  void saveCurrency(CurrencyModel currency) {
    _dbHelper.execute(
      '''
      INSERT OR REPLACE INTO currencies (code, name_en, name_ar, symbol_en, symbol_ar, exchange_rate)
      VALUES (?, ?, ?, ?, ?, ?);
      ''',
      [
        currency.code,
        currency.nameEn,
        currency.nameAr,
        currency.symbolEn,
        currency.symbolAr,
        currency.exchangeRate,
      ],
    );
  }

  /// Deletes a currency configuration from SQLite database.
  void deleteCurrency(String code) {
    _dbHelper.execute('DELETE FROM currencies WHERE code = ?;', [code]);
  }

  /// Logs details of an OCR operation run.
  void logOcr({
    required String filePath,
    required String engine,
    required double confidence,
    String? rawText,
    required bool success,
    String? errorDetails,
  }) {
    _dbHelper.execute(
      '''
      INSERT INTO ocr_logs (id, timestamp, file_path, engine, confidence, raw_text, success, error_details)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        const Uuid().v4(),
        DateTime.now().toIso8601String(),
        filePath,
        engine,
        confidence,
        rawText,
        success ? 1 : 0,
        errorDetails,
      ],
    );
  }

  /// Logs details of a file export run.
  void logExport({
    required String filePath,
    required String format,
    required String status,
  }) {
    _dbHelper.execute(
      '''
      INSERT INTO export_logs (id, timestamp, file_path, format, status)
      VALUES (?, ?, ?, ?, ?);
      ''',
      [
        const Uuid().v4(),
        DateTime.now().toIso8601String(),
        filePath,
        format,
        status,
      ],
    );
  }

  /// Adds a file path to the recent files table.
  void addRecentFile(String filePath) {
    _dbHelper.execute(
      '''
      INSERT OR REPLACE INTO recent_files (id, file_path, imported_at)
      VALUES (?, ?, ?);
      ''',
      [
        const Uuid().v4(),
        filePath,
        DateTime.now().toIso8601String(),
      ],
    );
  }

  /// Gets the list of recently processed files.
  List<String> getRecentFiles() {
    final results = _dbHelper.select('SELECT file_path FROM recent_files ORDER BY imported_at DESC LIMIT 10;');
    return results.map((row) => row['file_path'] as String).toList();
  }

  /// Clears the entire database (except defaults).
  void clearAllData() {
    _dbHelper.execute('BEGIN TRANSACTION;');
    try {
      _dbHelper.execute('DELETE FROM invoice_items;');
      _dbHelper.execute('DELETE FROM invoices;');
      _dbHelper.execute('DELETE FROM ocr_logs;');
      _dbHelper.execute('DELETE FROM export_logs;');
      _dbHelper.execute('DELETE FROM recent_files;');
      _dbHelper.execute('DELETE FROM settings;');
      _dbHelper.execute('COMMIT;');
    } catch (e) {
      _dbHelper.execute('ROLLBACK;');
      rethrow;
    }
  }
}
