import 'package:invoice_ocr_ai/features/invoice/data/models/currency_model.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/invoice_local_source.dart';
import '../models/invoice_model.dart';

/// InvoiceRepositoryImpl wraps local SQLite source methods in async futures.
class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceLocalSource _localSource;

  InvoiceRepositoryImpl(this._localSource);

  @override
  Future<List<InvoiceModel>> getInvoices({
    String? query,
    String? sortBy,
    bool ascending = false,
  }) async {
    return _localSource.getInvoices(
      query: query,
      sortBy: sortBy,
      ascending: ascending,
    );
  }

  @override
  Future<InvoiceModel?> getInvoiceById(String id) async {
    return _localSource.getInvoiceById(id);
  }

  @override
  Future<void> saveInvoice(InvoiceModel invoice) async {
    _localSource.saveInvoice(invoice);
  }

  @override
  Future<void> updateInvoice(InvoiceModel invoice) async {
    _localSource.updateInvoice(invoice);
  }

  @override
  Future<void> deleteInvoice(String id) async {
    _localSource.deleteInvoice(id);
  }

  @override
  Future<Map<String, dynamic>> getStatistics(String baseCurrencyCode) async {
    return _localSource.getStatistics(baseCurrencyCode);
  }

  @override
  Future<void> logOcr({
    required String filePath,
    required String engine,
    required double confidence,
    String? rawText,
    required bool success,
    String? errorDetails,
  }) async {
    _localSource.logOcr(
      filePath: filePath,
      engine: engine,
      confidence: confidence,
      rawText: rawText,
      success: success,
      errorDetails: errorDetails,
    );
  }

  @override
  Future<void> logExport({
    required String filePath,
    required String format,
    required String status,
  }) async {
    _localSource.logExport(
      filePath: filePath,
      format: format,
      status: status,
    );
  }

  @override
  Future<void> addRecentFile(String filePath) async {
    _localSource.addRecentFile(filePath);
  }

  @override
  Future<List<String>> getRecentFiles() async {
    return _localSource.getRecentFiles();
  }

  @override
  Future<void> clearAllData() async {
    _localSource.clearAllData();
  }

  @override
  Future<List<CurrencyModel>> getCurrencies() async {
    return _localSource.getCurrencies();
  }

  @override
  Future<void> saveCurrency(CurrencyModel currency) async {
    _localSource.saveCurrency(currency);
  }

  @override
  Future<void> deleteCurrency(String code) async {
    _localSource.deleteCurrency(code);
  }
}
