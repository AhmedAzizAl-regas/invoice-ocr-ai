import 'package:invoice_ocr_ai/features/invoice/data/models/currency_model.dart';
import '../../data/models/invoice_model.dart';

/// InvoiceRepository specifies database persistence queries for invoice management,
/// analytics logs, exported logs, and recent files.
abstract class InvoiceRepository {
  /// Fetches all invoices supporting sorting, searching, and filtering.
  Future<List<InvoiceModel>> getInvoices({
    String? query,
    String? sortBy,
    bool ascending = false,
  });

  /// Fetches a single invoice containing all its items.
  Future<InvoiceModel?> getInvoiceById(String id);

  /// Saves a newly scanned invoice and its items in a transaction.
  Future<void> saveInvoice(InvoiceModel invoice);

  /// Updates modified invoice details and updates items list.
  Future<void> updateInvoice(InvoiceModel invoice);

  /// Removes an invoice from SQLite (cascading deletes its items).
  Future<void> deleteInvoice(String id);

  /// Calculates Home dashboard metrics (counts, subtotals, currencies, recent activities) in base currency.
  Future<Map<String, dynamic>> getStatistics(String baseCurrencyCode);

  /// Logs details of an OCR operation run.
  Future<void> logOcr({
    required String filePath,
    required String engine,
    required double confidence,
    String? rawText,
    required bool success,
    String? errorDetails,
  });

  /// Logs details of a file export run.
  Future<void> logExport({
    required String filePath,
    required String format,
    required String status,
  });

  /// Adds a file path to the recent files table.
  Future<void> addRecentFile(String filePath);

  /// Gets the list of recently processed files.
  Future<List<String>> getRecentFiles();

  /// Clears the entire database (except defaults).
  Future<void> clearAllData();

  /// Fetches all currencies supported by the system.
  Future<List<CurrencyModel>> getCurrencies();

  /// Saves or updates a currency config (symbols, rate).
  Future<void> saveCurrency(CurrencyModel currency);

  /// Deletes a currency config.
  Future<void> deleteCurrency(String code);
}
