import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../../invoice/data/models/currency_model.dart';
import '../../../invoice/domain/repositories/invoice_repository.dart';

/// CurrenciesNotifier manages loading, caching, and writing currencies.
class CurrenciesNotifier extends StateNotifier<List<CurrencyModel>> {
  final InvoiceRepository _repository;

  CurrenciesNotifier(this._repository) : super([]) {
    loadCurrencies();
  }

  /// Fetches currencies from database.
  Future<void> loadCurrencies() async {
    try {
      final list = await _repository.getCurrencies();
      state = list;
    } catch (_) {
      // Keep existing state on failure
    }
  }

  /// Inserts or updates a currency and reloads.
  Future<void> addCurrency(CurrencyModel currency) async {
    await _repository.saveCurrency(currency);
    await loadCurrencies();
  }

  /// Deletes a currency and reloads.
  Future<void> deleteCurrency(String code) async {
    await _repository.deleteCurrency(code);
    await loadCurrencies();
  }
}

/// Global provider for managing currencies state
final currenciesProvider = StateNotifierProvider<CurrenciesNotifier, List<CurrencyModel>>((ref) {
  final repo = GetIt.I<InvoiceRepository>();
  return CurrenciesNotifier(repo);
});
