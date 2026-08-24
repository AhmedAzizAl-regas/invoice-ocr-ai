import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import 'package:invoice_ocr_ai/features/invoice/data/models/invoice_model.dart';
import 'package:invoice_ocr_ai/features/invoice/data/models/invoice_item_model.dart';
import 'package:invoice_ocr_ai/features/invoice/domain/repositories/invoice_repository.dart';

/// State encapsulating current editing Invoice.
class InvoiceEditState {
  final InvoiceModel? invoice;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  InvoiceEditState({
    this.invoice,
    required this.isLoading,
    required this.isSaving,
    this.errorMessage,
  });

  factory InvoiceEditState.initial() => InvoiceEditState(isLoading: true, isSaving: false);

  InvoiceEditState copyWith({
    InvoiceModel? invoice,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return InvoiceEditState(
      invoice: invoice ?? this.invoice,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

/// InvoiceEditNotifier manages operations in the Review / Editor page.
class InvoiceEditNotifier extends FamilyNotifier<InvoiceEditState, String> {
  late final InvoiceRepository _repository;

  @override
  InvoiceEditState build(String arg) {
    _repository = GetIt.I<InvoiceRepository>();
    Future.microtask(() => loadInvoice(arg));
    return InvoiceEditState.initial();
  }

  /// Loads Invoice from repository.
  Future<void> loadInvoice(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final invoice = await _repository.getInvoiceById(id);
      if (invoice == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Invoice not found');
      } else {
        state = InvoiceEditState(invoice: invoice, isLoading: false, isSaving: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Load failed: $e');
    }
  }

  // --- Field Mutators ---
  
  void updateStoreName(String storeName) {
    final inv = state.invoice;
    if (inv == null) return;
    state = state.copyWith(invoice: inv.copyWith(storeName: storeName));
  }

  void updateInvoiceNumber(String num) {
    final inv = state.invoice;
    if (inv == null) return;
    state = state.copyWith(invoice: inv.copyWith(invoiceNumber: num));
  }

  void updateDate(String date) {
    final inv = state.invoice;
    if (inv == null) return;
    state = state.copyWith(invoice: inv.copyWith(date: date));
  }

  void updateTime(String time) {
    final inv = state.invoice;
    if (inv == null) return;
    state = state.copyWith(invoice: inv.copyWith(time: time));
  }

  void updateCurrency(String currency) {
    final inv = state.invoice;
    if (inv == null) return;
    state = state.copyWith(invoice: inv.copyWith(currency: currency));
  }

  void updatePaymentMethod(String method) {
    final inv = state.invoice;
    if (inv == null) return;
    state = state.copyWith(invoice: inv.copyWith(paymentMethod: method));
  }

  void updateDocumentType(String type) {
    final inv = state.invoice;
    if (inv == null) return;
    state = state.copyWith(invoice: inv.copyWith(documentType: type));
  }

  void updateDocumentTitle(String title) {
    final inv = state.invoice;
    if (inv == null) return;
    state = state.copyWith(invoice: inv.copyWith(documentTitle: title));
  }

  void updateSenderName(String sender) {
    final inv = state.invoice;
    if (inv == null) return;
    state = state.copyWith(invoice: inv.copyWith(senderName: sender));
  }

  void updateReceiverName(String receiver) {
    final inv = state.invoice;
    if (inv == null) return;
    state = state.copyWith(invoice: inv.copyWith(receiverName: receiver));
  }

  void updateAccountNumber(String acc) {
    final inv = state.invoice;
    if (inv == null) return;
    state = state.copyWith(invoice: inv.copyWith(accountNumber: acc));
  }

  void updateBranch(String branch) {
    final inv = state.invoice;
    if (inv == null) return;
    state = state.copyWith(invoice: inv.copyWith(branch: branch));
  }

  void updateNotes(String notes) {
    final inv = state.invoice;
    if (inv == null) return;
    state = state.copyWith(invoice: inv.copyWith(notes: notes));
  }

  void updateEmployeeName(String emp) {
    final inv = state.invoice;
    if (inv == null) return;
    state = state.copyWith(invoice: inv.copyWith(employeeName: emp));
  }

  void updateTotalDirectly(double total) {
    final inv = state.invoice;
    if (inv == null) return;
    state = state.copyWith(invoice: inv.copyWith(total: total, subtotal: total));
  }

  void updateDocumentCategory(String category) {
    final inv = state.invoice;
    if (inv == null) return;
    state = state.copyWith(invoice: inv.copyWith(documentCategory: category));
  }

  void updateDetectedLanguage(String lang) {
    final inv = state.invoice;
    if (inv == null) return;
    state = state.copyWith(invoice: inv.copyWith(detectedLanguage: lang));
  }

  void updateMetadataItem(int index, String label, String value) {
    final inv = state.invoice;
    if (inv == null || index < 0 || index >= inv.dynamicMetadata.length) return;
    final list = List<Map<String, String>>.from(inv.dynamicMetadata);
    list[index] = {'label': label, 'value': value};
    state = state.copyWith(invoice: inv.copyWith(dynamicMetadata: list));
  }

  void addMetadataItem(String label, String value) {
    final inv = state.invoice;
    if (inv == null) return;
    final list = List<Map<String, String>>.from(inv.dynamicMetadata);
    list.add({'label': label, 'value': value});
    state = state.copyWith(invoice: inv.copyWith(dynamicMetadata: list));
  }

  void deleteMetadataItem(int index) {
    final inv = state.invoice;
    if (inv == null || index < 0 || index >= inv.dynamicMetadata.length) return;
    final list = List<Map<String, String>>.from(inv.dynamicMetadata)..removeAt(index);
    state = state.copyWith(invoice: inv.copyWith(dynamicMetadata: list));
  }

  void updateTableCell(int rowIndex, int colIndex, String val) {
    final inv = state.invoice;
    if (inv == null || rowIndex < 0 || rowIndex >= inv.tableRows.length) return;
    final rows = List<List<String>>.from(inv.tableRows.map((r) => List<String>.from(r)));
    if (colIndex >= 0 && colIndex < rows[rowIndex].length) {
      rows[rowIndex][colIndex] = val;
      state = state.copyWith(invoice: inv.copyWith(tableRows: rows));
    }
  }

  // --- Line Items Mutators ---

  void addLineItem() {
    final inv = state.invoice;
    if (inv == null) return;

    final newItem = InvoiceItemModel(
      id: const Uuid().v4(),
      invoiceId: inv.id,
      productName: '',
      quantity: 1.0,
      unitPrice: 0.0,
      totalPrice: 0.0,
    );

    final updatedItems = List<InvoiceItemModel>.from(inv.items)..add(newItem);
    state = state.copyWith(invoice: inv.copyWith(items: updatedItems));
    recalculateTotals();
  }

  void updateLineItem(int index, {String? name, double? qty, double? price}) {
    final inv = state.invoice;
    if (inv == null || index < 0 || index >= inv.items.length) return;

    final item = inv.items[index];
    final updatedItem = item.copyWith(
      productName: name ?? item.productName,
      quantity: qty ?? item.quantity,
      unitPrice: price ?? item.unitPrice,
      totalPrice: (qty ?? item.quantity) * (price ?? item.unitPrice),
    );

    final updatedItems = List<InvoiceItemModel>.from(inv.items)..[index] = updatedItem;
    state = state.copyWith(invoice: inv.copyWith(items: updatedItems));
    recalculateTotals();
  }

  void deleteLineItem(int index) {
    final inv = state.invoice;
    if (inv == null || index < 0 || index >= inv.items.length) return;

    final updatedItems = List<InvoiceItemModel>.from(inv.items)..removeAt(index);
    state = state.copyWith(invoice: inv.copyWith(items: updatedItems));
    recalculateTotals();
  }

  /// Automatically updates subtotal and final total from items.
  void recalculateTotals() {
    final inv = state.invoice;
    if (inv == null) return;

    double subtotal = 0.0;
    for (final item in inv.items) {
      subtotal += item.totalPrice;
    }

    final total = subtotal + inv.tax - inv.discount;
    state = state.copyWith(
      invoice: inv.copyWith(
        subtotal: subtotal,
        total: total,
      ),
    );
  }

  void updateTax(double tax) {
    final inv = state.invoice;
    if (inv == null) return;
    final total = inv.subtotal + tax - inv.discount;
    state = state.copyWith(invoice: inv.copyWith(tax: tax, total: total));
  }

  void updateDiscount(double disc) {
    final inv = state.invoice;
    if (inv == null) return;
    final total = inv.subtotal + inv.tax - disc;
    state = state.copyWith(invoice: inv.copyWith(discount: disc, total: total));
  }

  /// Persists modified invoice changes to local DB.
  Future<bool> saveInvoice() async {
    final inv = state.invoice;
    if (inv == null) return false;

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repository.updateInvoice(inv);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Save failed: $e');
      return false;
    }
  }

  /// Delete current invoice from database.
  Future<bool> deleteInvoice() async {
    final inv = state.invoice;
    if (inv == null) return false;

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repository.deleteInvoice(inv.id);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Delete failed: $e');
      return false;
    }
  }
}

/// Riverpod family provider for editing a specific invoice
final invoiceEditProvider = NotifierProviderFamily<InvoiceEditNotifier, InvoiceEditState, String>(() {
  return InvoiceEditNotifier();
});
