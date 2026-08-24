import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:invoice_ocr_ai/features/invoice/domain/repositories/invoice_repository.dart';
import 'package:invoice_ocr_ai/features/settings/presentation/providers/settings_provider.dart';

/// HomeDashboardState holds dashboard analytic details.
class HomeDashboardState {
  final int invoiceCount;
  final double totalSpend;
  final List<dynamic> recentInvoices;
  final List<dynamic> recentExports;
  final bool isLoading;
  final String? errorMessage;

  HomeDashboardState({
    required this.invoiceCount,
    required this.totalSpend,
    required this.recentInvoices,
    required this.recentExports,
    required this.isLoading,
    this.errorMessage,
  });

  factory HomeDashboardState.initial() {
    return HomeDashboardState(
      invoiceCount: 0,
      totalSpend: 0.0,
      recentInvoices: [],
      recentExports: [],
      isLoading: true,
    );
  }

  HomeDashboardState copyWith({
    int? invoiceCount,
    double? totalSpend,
    List<dynamic>? recentInvoices,
    List<dynamic>? recentExports,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HomeDashboardState(
      invoiceCount: invoiceCount ?? this.invoiceCount,
      totalSpend: totalSpend ?? this.totalSpend,
      recentInvoices: recentInvoices ?? this.recentInvoices,
      recentExports: recentExports ?? this.recentExports,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// HomeDashboardNotifier loads statistics from SQLite using the InvoiceRepository.
class HomeDashboardNotifier extends StateNotifier<HomeDashboardState> {
  final InvoiceRepository _repository;
  final Ref _ref;

  HomeDashboardNotifier(this._repository, this._ref) : super(HomeDashboardState.initial()) {
    loadDashboard();
  }

  /// Reloads stats from Database.
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true);
    try {
      final settings = _ref.read(settingsProvider);
      final stats = await _repository.getStatistics(settings.defaultCurrency);
      state = HomeDashboardState(
        invoiceCount: stats['invoice_count'] as int,
        totalSpend: stats['total_spend'] as double,
        recentInvoices: stats['recent_invoices'] as List<dynamic>,
        recentExports: stats['recent_exports'] as List<dynamic>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error loading dashboard statistics: $e',
      );
    }
  }
}

/// Provider for Home Dashboard State
final homeDashboardProvider = StateNotifierProvider<HomeDashboardNotifier, HomeDashboardState>((ref) {
  final repo = GetIt.I<InvoiceRepository>();
  return HomeDashboardNotifier(repo, ref);
});
