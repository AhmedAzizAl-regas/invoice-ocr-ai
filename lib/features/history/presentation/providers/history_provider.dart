import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:invoice_ocr_ai/features/invoice/data/models/invoice_model.dart';
import 'package:invoice_ocr_ai/features/invoice/domain/repositories/invoice_repository.dart';

/// HistoryState holds query results and sorting options.
class HistoryState {
  final List<InvoiceModel> invoices;
  final String searchQuery;
  final String sortBy;
  final bool ascending;
  final bool isLoading;
  final String? errorMessage;

  HistoryState({
    required this.invoices,
    required this.searchQuery,
    required this.sortBy,
    required this.ascending,
    required this.isLoading,
    this.errorMessage,
  });

  factory HistoryState.initial() {
    return HistoryState(
      invoices: [],
      searchQuery: '',
      sortBy: 'created_at',
      ascending: false,
      isLoading: true,
    );
  }

  HistoryState copyWith({
    List<InvoiceModel>? invoices,
    String? searchQuery,
    String? sortBy,
    bool? ascending,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HistoryState(
      invoices: invoices ?? this.invoices,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// HistoryNotifier manages loading and filtering history lists.
class HistoryNotifier extends StateNotifier<HistoryState> {
  final InvoiceRepository _repository;

  HistoryNotifier(this._repository) : super(HistoryState.initial()) {
    loadInvoices();
  }

  /// Loads invoices matching parameters.
  Future<void> loadInvoices() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await _repository.getInvoices(
        query: state.searchQuery,
        sortBy: state.sortBy,
        ascending: state.ascending,
      );
      state = state.copyWith(invoices: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load invoice history: $e',
      );
    }
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
    loadInvoices();
  }

  void updateSorting(String sortBy, bool ascending) {
    state = state.copyWith(sortBy: sortBy, ascending: ascending);
    loadInvoices();
  }

  Future<void> deleteInvoice(String id) async {
    try {
      await _repository.deleteInvoice(id);
      loadInvoices();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Delete failed: $e');
    }
  }
}

/// Riverpod Provider for Invoice History
final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final repo = GetIt.I<InvoiceRepository>();
  return HistoryNotifier(repo);
});
