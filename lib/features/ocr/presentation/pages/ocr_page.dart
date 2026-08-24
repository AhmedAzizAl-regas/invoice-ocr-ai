import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:get_it/get_it.dart';
import 'package:invoice_ocr_ai/core/config/app_config.dart';
import 'package:invoice_ocr_ai/core/services/export_service.dart';
import 'package:invoice_ocr_ai/core/theme/app_colors.dart';
import 'package:invoice_ocr_ai/core/theme/app_theme.dart';
import 'package:invoice_ocr_ai/features/settings/presentation/providers/settings_provider.dart';
import 'package:invoice_ocr_ai/features/ocr/presentation/providers/ocr_pipeline_provider.dart';

class OcrPage extends ConsumerStatefulWidget {
  final String imagePath;

  const OcrPage({super.key, required this.imagePath});

  @override
  ConsumerState<OcrPage> createState() => _OcrPageState();
}

class _OcrPageState extends ConsumerState<OcrPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startOcrPipeline();
    });
  }

  void _startOcrPipeline() {
    // Collect settings and keys to pass to the pipeline
    final settings = ref.read(settingsProvider);
    
    // We get api keys from environment variables or custom configs
    // Let's pass empty strings or env values; we catch missing keys in the notifier
    ref.read(ocrPipelineProvider.notifier).runPipeline(
          File(widget.imagePath),
          isOnline: true, // Assuming internet is available
          googleVisionKey: AppConfig.googleVisionApiKey,
          llmEngine: 'gemini', // Using Gemini by default for low cost/free tier
          llmApiKey: AppConfig.geminiApiKey,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ocrPipelineProvider);
    final settings = ref.watch(settingsProvider);
    final isAr = settings.language == 'ar';
    final theme = Theme.of(context);

    final bool isProcessing = state.status == 'ocr_processing' || state.status == 'llm_structuring';

    void handleBack() {
      ref.read(ocrPipelineProvider.notifier).reset();
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'نتائج المسح الضوئي' : 'OCR & AI Analysis'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: handleBack,
          ),
        ),
        body: Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceM),
            child: isProcessing
                ? _buildLoadingWidget(state.status, isAr, theme)
                : state.status == 'error'
                    ? _buildErrorWidget(state.errorMessage ?? '', isAr, theme)
                    : _buildSuccessWidget(state, isAr, context, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(String status, bool isAr, ThemeData theme) {
    final message = status == 'ocr_processing'
        ? (isAr ? 'جاري تشغيل محركات المسح الضوئي المتعاقبة...' : 'Running cascading OCR engines...')
        : (isAr ? 'جاري تنظيم النص المستخرج باستخدام الذكاء الاصطناعي...' : 'Structuring text via Gemini AI...');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryYellow, strokeWidth: 5),
          const SizedBox(height: AppTheme.spaceL),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            isAr
                ? 'قد يستغرق هذا بضع ثوانٍ للحصول على أفضل دقة'
                : 'This may take a few seconds to extract the finest details.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error, bool isAr, ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.secondaryRed, size: 64),
            const SizedBox(height: AppTheme.spaceM),
            Text(
              isAr ? 'عذراً، حدث خطأ أثناء المعالجة' : 'Processing Failed',
              style: theme.textTheme.titleMedium?.copyWith(color: AppColors.secondaryRed, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spaceS),
            Card(
              color: AppColors.secondaryRed.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceM),
                child: Text(
                  error,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceL),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryYellow, foregroundColor: Colors.black),
              onPressed: _startOcrPipeline,
              icon: const Icon(Icons.refresh),
              label: Text(isAr ? 'إعادة المحاولة' : 'Retry Analysis'),
            ),
            const SizedBox(height: AppTheme.spaceS),
            OutlinedButton(
              onPressed: () => context.go('/'),
              child: Text(isAr ? 'العودة للرئيسية' : 'Go Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessWidget(OcrPipelineState state, bool isAr, BuildContext context, ThemeData theme) {
    final invoice = state.parsedInvoice;
    if (invoice == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Confidence Indicator Card
        Card(
          color: AppColors.primaryYellow.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceM),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'نسبة دقة القراءة:' : 'OCR Confidence:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(state.confidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondaryRed),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceS),
                LinearProgressIndicator(
                  value: state.confidence,
                  backgroundColor: theme.dividerColor,
                  color: AppColors.primaryYellow,
                ),
                const SizedBox(height: AppTheme.spaceM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'المحرك المستخدم:' : 'Engine Used:',
                      style: theme.textTheme.bodySmall,
                    ),
                    Chip(
                      label: Text(
                        state.currentEngine,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: theme.dividerColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceM),

        // Raw OCR text preview
        Text(
          isAr ? 'النص الخام المستخرج:' : 'Raw OCR Text Extracted:',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.spaceS),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              child: SingleChildScrollView(
                child: Text(
                  state.rawText,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ),
          ),
        ),
        // Quick Export Row
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceS),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickExportButton(
                  icon: Icons.table_chart,
                  label: 'Excel',
                  color: Colors.green,
                  onTap: () async {
                    final file = await GetIt.I<ExportService>().exportToExcel(invoice, isArabic: isAr);
                    await GetIt.I<ExportService>().shareFile(file);
                  },
                ),
                _buildQuickExportButton(
                  icon: Icons.article,
                  label: 'CSV',
                  color: Colors.teal,
                  onTap: () async {
                    final file = await GetIt.I<ExportService>().exportToCsv(invoice, isArabic: isAr);
                    await GetIt.I<ExportService>().shareFile(file);
                  },
                ),
                _buildQuickExportButton(
                  icon: Icons.picture_as_pdf,
                  label: 'PDF',
                  color: Colors.red,
                  onTap: () async {
                    final file = await GetIt.I<ExportService>().exportToPdf(invoice, isArabic: isAr);
                    await GetIt.I<ExportService>().shareFile(file);
                  },
                ),
                _buildQuickExportButton(
                  icon: Icons.description,
                  label: 'Word',
                  color: Colors.blue,
                  onTap: () async {
                    final file = await GetIt.I<ExportService>().exportToWord(invoice, isArabic: isAr);
                    await GetIt.I<ExportService>().shareFile(file);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceM),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _startOcrPipeline,
                icon: const Icon(Icons.refresh),
                label: Text(isAr ? 'إعادة التحليل' : 'Re-Analyze'),
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.pureBlack,
                ),
                onPressed: () => context.go('/invoice/${invoice.id}'),
                icon: const Icon(Icons.edit_note),
                label: Text(isAr ? 'مراجعة وتعديل البيانات' : 'Review & Edit'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickExportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM, vertical: AppTheme.spaceXS),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppTheme.spaceXS),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
