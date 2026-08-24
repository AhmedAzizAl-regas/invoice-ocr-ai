import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import 'package:invoice_ocr_ai/core/services/ocr_service.dart';
import 'package:invoice_ocr_ai/core/services/llm_service.dart';
import 'package:invoice_ocr_ai/features/invoice/data/models/invoice_model.dart';
import 'package:invoice_ocr_ai/features/invoice/data/models/invoice_item_model.dart';
import 'package:invoice_ocr_ai/features/invoice/domain/repositories/invoice_repository.dart';

/// OcrPipelineState encapsulates the pipeline logs, current engine, text, and parsed invoice.
class OcrPipelineState {
  final String status; // 'idle', 'ocr_processing', 'llm_structuring', 'success', 'error'
  final String currentEngine;
  final double confidence;
  final String rawText;
  final InvoiceModel? parsedInvoice;
  final String? errorMessage;

  OcrPipelineState({
    required this.status,
    required this.currentEngine,
    required this.confidence,
    required this.rawText,
    this.parsedInvoice,
    this.errorMessage,
  });

  factory OcrPipelineState.initial() {
    return OcrPipelineState(
      status: 'idle',
      currentEngine: 'None',
      confidence: 0.0,
      rawText: '',
    );
  }

  OcrPipelineState copyWith({
    String? status,
    String? currentEngine,
    double? confidence,
    String? rawText,
    InvoiceModel? parsedInvoice,
    String? errorMessage,
  }) {
    return OcrPipelineState(
      status: status ?? this.status,
      currentEngine: currentEngine ?? this.currentEngine,
      confidence: confidence ?? this.confidence,
      rawText: rawText ?? this.rawText,
      parsedInvoice: parsedInvoice ?? this.parsedInvoice,
      errorMessage: errorMessage,
    );
  }
}

/// OcrPipelineNotifier executes the cascading OCR steps and sends the text to LLM parser.
class OcrPipelineNotifier extends StateNotifier<OcrPipelineState> {
  final OcrService _ocrService;
  final LlmService _llmService;
  final InvoiceRepository _invoiceRepository;

  OcrPipelineNotifier(this._ocrService, this._llmService, this._invoiceRepository)
      : super(OcrPipelineState.initial());

  /// Runs the full cascade OCR + LLM structure extraction.
  Future<void> runPipeline(File imageFile, {
    required bool isOnline,
    required String googleVisionKey,
    required String llmEngine, // 'openai' or 'gemini'
    required String llmApiKey,
  }) async {
    state = state.copyWith(status: 'ocr_processing', currentEngine: 'Google ML Kit', errorMessage: null);

    OcrResult? ocrResult;

    try {
      // 1. Run Cascading OCR
      ocrResult = await _ocrService.executePipeline(
        imageFile,
        isOnline: isOnline,
        googleVisionKey: googleVisionKey,
      );

      // Log OCR result to DB
      await _invoiceRepository.logOcr(
        filePath: imageFile.path,
        engine: ocrResult.engineUsed,
        confidence: ocrResult.confidence,
        rawText: ocrResult.text,
        success: ocrResult.success,
        errorDetails: ocrResult.errorMessage,
      );

      if (!ocrResult.success || ocrResult.text.trim().isEmpty) {
        state = state.copyWith(
          status: 'error',
          errorMessage: ocrResult.errorMessage ?? 'OCR could not extract any text from the invoice image.',
        );
        return;
      }

      state = state.copyWith(
        status: 'llm_structuring',
        currentEngine: ocrResult.engineUsed,
        confidence: ocrResult.confidence,
        rawText: ocrResult.text,
      );

      // 2. Structuring unstructured text via OpenAI or Gemini
      final jsonResponse = await _llmService.parseInvoiceText(
        rawText: ocrResult.text,
        engine: llmEngine,
        apiKey: llmApiKey,
      );

      // 3. Map JSON response into InvoiceModel
      final invoiceId = const Uuid().v4();
      final List<dynamic> itemsJson = jsonResponse['items'] as List? ?? [];
      
      final items = itemsJson.map((itemMap) {
        return InvoiceItemModel(
          id: const Uuid().v4(),
          invoiceId: invoiceId,
          productName: itemMap['product_name'] as String? ?? 'Unknown Product',
          quantity: (itemMap['quantity'] as num?)?.toDouble() ?? 1.0,
          unitPrice: (itemMap['unit_price'] as num?)?.toDouble() ?? 0.0,
          totalPrice: (itemMap['total_price'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      final invoice = InvoiceModel(
        id: invoiceId,
        storeName: jsonResponse['store_name'] as String? ?? 'Unknown Store',
        invoiceNumber: jsonResponse['invoice_number'] as String?,
        date: jsonResponse['date'] as String? ?? DateTime.now().toIso8601String().substring(0, 10),
        time: jsonResponse['time'] as String?,
        currency: jsonResponse['currency'] as String? ?? 'SAR',
        subtotal: (jsonResponse['subtotal'] as num?)?.toDouble() ?? 0.0,
        tax: (jsonResponse['tax'] as num?)?.toDouble() ?? 0.0,
        discount: (jsonResponse['discount'] as num?)?.toDouble() ?? 0.0,
        total: (jsonResponse['total'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: jsonResponse['payment_method'] as String?,
        imagePath: imageFile.path,
        ocrEngine: ocrResult.engineUsed,
        ocrConfidence: ocrResult.confidence,
        rawText: ocrResult.text,
        createdAt: DateTime.now().toIso8601String(),
        items: items,
        documentType: jsonResponse['document_type'] as String? ?? 'invoice',
        documentTitle: jsonResponse['document_title'] as String?,
        senderName: jsonResponse['sender_name'] as String?,
        receiverName: jsonResponse['receiver_name'] as String?,
        accountNumber: jsonResponse['account_number'] as String?,
        branch: jsonResponse['branch'] as String?,
        notes: jsonResponse['notes'] as String?,
        employeeName: jsonResponse['employee_name'] as String?,
        documentCategory: jsonResponse['document_category'] as String? ?? 'general',
        detectedLanguage: jsonResponse['detected_language'] as String? ?? (RegExp(r'[\u0600-\u06FF]').hasMatch(ocrResult.text) ? 'ar' : 'en'),
        dynamicMetadata: (jsonResponse['dynamic_metadata'] as List? ?? []).map((e) {
          if (e is Map) {
            return {
              'label': e['label']?.toString() ?? '',
              'value': e['value']?.toString() ?? '',
            };
          }
          return <String, String>{};
        }).where((m) => m.isNotEmpty).toList(),
        tableColumns: (jsonResponse['table_columns'] as List? ?? []).map((e) => e.toString()).toList(),
        tableRows: (jsonResponse['table_rows'] as List? ?? []).map((row) {
          if (row is List) {
            return row.map((cell) => cell.toString()).toList();
          }
          return <String>[];
        }).toList(),
      );

      // Record invoice into DB and add to recent files
      await _invoiceRepository.saveInvoice(invoice);
      await _invoiceRepository.addRecentFile(imageFile.path);

      state = state.copyWith(status: 'success', parsedInvoice: invoice);
    } catch (e) {
      state = state.copyWith(
        status: 'error',
        errorMessage: 'Structured Parsing Error: $e. Raw text extracted: ${ocrResult?.text ?? ""}',
      );
    }
  }

  void reset() {
    state = OcrPipelineState.initial();
  }
}

/// Riverpod Provider for OCR Pipeline state notifier
final ocrPipelineProvider = StateNotifierProvider<OcrPipelineNotifier, OcrPipelineState>((ref) {
  final ocr = GetIt.I<OcrService>();
  final llm = GetIt.I<LlmService>();
  final repo = GetIt.I<InvoiceRepository>();
  return OcrPipelineNotifier(ocr, llm, repo);
});
