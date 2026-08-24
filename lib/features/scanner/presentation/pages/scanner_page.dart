import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:invoice_ocr_ai/core/theme/app_colors.dart';
import 'package:invoice_ocr_ai/core/theme/app_theme.dart';
import 'package:invoice_ocr_ai/features/settings/presentation/providers/settings_provider.dart';
import 'package:invoice_ocr_ai/features/scanner/presentation/providers/scanner_provider.dart';

class ScannerPage extends ConsumerStatefulWidget {
  final String imagePath;

  const ScannerPage({super.key, required this.imagePath});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scannerProvider.notifier).setImage(File(widget.imagePath));
    });
  }

  Future<void> _processAndProceed(BuildContext context) async {
    final processedFile = await ref.read(scannerProvider.notifier).runPreprocessing();
    if (processedFile != null && context.mounted) {
      // Go to OCR Pipeline Screen
      final encodedPath = Uri.encodeComponent(processedFile.path);
      context.go('/ocr?path=$encodedPath');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerProvider);
    final settings = ref.watch(settingsProvider);
    final isAr = settings.language == 'ar';
    final theme = Theme.of(context);

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final screenWidth = mediaQuery.size.width;

    final imageWidget = scannerState.originalImage != null
        ? Image.file(
            scannerState.originalImage!,
            fit: BoxFit.contain,
          )
        : const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow));

    void handleBack() {
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
          title: Text(isAr ? 'معالجة الصورة' : 'Image Preprocessing'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: handleBack,
          ),
        ),
        body: Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: scannerState.isProcessing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryYellow),
                    SizedBox(height: AppTheme.spaceM),
                    Text(
                      'Preprocessing image via OpenCV filters...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            : isLandscape
                ? Row(
                    children: [
                      // Left pane: Image preview
                      Expanded(
                        flex: 5,
                        child: Container(
                          color: Colors.black12,
                          padding: const EdgeInsets.all(AppTheme.spaceM),
                          child: imageWidget,
                        ),
                      ),
                      // Right pane: Controls
                      Expanded(
                        flex: 4,
                        child: _buildControlsPane(isAr, theme),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      // Top pane: Image preview
                      Expanded(
                        flex: 6,
                        child: Container(
                          color: Colors.black12,
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppTheme.spaceM),
                          child: imageWidget,
                        ),
                      ),
                      // Bottom pane: Controls
                      Expanded(
                        flex: 5,
                        child: _buildControlsPane(isAr, theme),
                      ),
                    ],
                  ),
      ),
    ),
  );
}

  Widget _buildControlsPane(bool isAr, ThemeData theme) {
    final scannerState = ref.watch(scannerProvider);
    final notifier = ref.read(scannerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAr ? 'خيارات تحسين الفاتورة' : 'Invoice Preprocessing Options',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildFilterSwitch(
                  title: isAr ? 'إزالة الضوضاء' : 'Denoise / Remove Noise',
                  value: scannerState.removeNoise,
                  onChanged: (_) => notifier.toggleNoise(),
                ),
                _buildFilterSwitch(
                  title: isAr ? 'تصحيح الميل' : 'Deskew / Align Orientation',
                  value: scannerState.deskew,
                  onChanged: (_) => notifier.toggleDeskew(),
                ),
                _buildFilterSwitch(
                  title: isAr ? 'إزالة الظلال' : 'Remove Shadows',
                  value: scannerState.removeShadows,
                  onChanged: (_) => notifier.toggleShadows(),
                ),
                _buildFilterSwitch(
                  title: isAr ? 'تحسين التباين' : 'Enhance Contrast',
                  value: scannerState.enhanceContrast,
                  onChanged: (_) => notifier.toggleContrast(),
                ),
                _buildFilterSwitch(
                  title: isAr ? 'قص الفاتورة تلقائياً' : 'Auto Crop Receipt',
                  value: scannerState.autoCrop,
                  onChanged: (_) => notifier.toggleAutoCrop(),
                ),
                _buildFilterSwitch(
                  title: isAr ? 'تحسين جودة الخط' : 'Enhance Text Quality',
                  value: scannerState.enhanceQuality,
                  onChanged: (_) => notifier.toggleQuality(),
                ),
              ],
            ),
          ),
          if (scannerState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
              child: Text(
                scannerState.errorMessage!,
                style: const TextStyle(color: AppColors.secondaryRed, fontSize: 12),
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceM),
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.pureBlack,
            ),
            onPressed: () => _processAndProceed(context),
            child: Text(
              isAr ? 'تطبيق الفلاتر والبدء في استخراج البيانات' : 'Apply Filters & Start OCR',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceXS),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        value: value,
        dense: true,
        activeColor: AppColors.primaryYellow,
        onChanged: onChanged,
      ),
    );
  }
}
