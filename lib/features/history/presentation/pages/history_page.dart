import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:invoice_ocr_ai/core/services/export_service.dart';
import 'package:invoice_ocr_ai/core/theme/app_colors.dart';
import 'package:invoice_ocr_ai/core/theme/app_theme.dart';
import 'package:invoice_ocr_ai/features/settings/presentation/providers/settings_provider.dart';
import 'package:invoice_ocr_ai/features/settings/presentation/providers/currencies_provider.dart';
import 'package:invoice_ocr_ai/features/invoice/data/models/currency_model.dart';
import 'package:invoice_ocr_ai/features/home/presentation/providers/home_provider.dart';
import 'package:invoice_ocr_ai/core/utils/currency_formatter.dart';
import 'package:invoice_ocr_ai/features/history/presentation/providers/history_provider.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  /// Opens export sharing sheet.
  void _shareInvoice(BuildContext context, WidgetRef ref, dynamic invoice) {
    final exporter = GetIt.I<ExportService>();
    final settings = ref.read(settingsProvider);
    final isAr = settings.language == 'ar';

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAr ? 'تصدير ومشاركة الفاتورة' : 'Export & Share Invoice',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: AppTheme.spaceM),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('PDF'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await exporter.exportToPdf(invoice, isArabic: isAr);
                  await exporter.shareFile(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('Excel (.xlsx)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await exporter.exportToExcel(invoice, isArabic: isAr);
                  await exporter.shareFile(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.article, color: Colors.teal),
                title: const Text('CSV (.csv)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await exporter.exportToCsv(invoice, isArabic: isAr);
                  await exporter.shareFile(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.article, color: Colors.blue),
                title: const Text('Word (.docx)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await exporter.exportToWord(invoice, isArabic: isAr);
                  await exporter.shareFile(file);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyProvider);
    final settings = ref.watch(settingsProvider);
    final currencies = ref.watch(currenciesProvider);
    final isAr = settings.language == 'ar';
    final theme = Theme.of(context);

    // Refresh history lists on screen view
    ref.read(historyProvider.notifier);

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
          title: Text(isAr ? 'أرشيف الفواتير' : 'Invoice History'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: handleBack,
          ),
        ),
        body: Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          children: [
            // Search & Filters panel
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: AppColors.secondaryRed),
                      hintText: isAr ? 'ابحث باسم المتجر أو محتوى الفاتورة...' : 'Search stores or items...',
                    ),
                    onChanged: (val) {
                      ref.read(historyProvider.notifier).search(val);
                    },
                  ),
                  const SizedBox(height: AppTheme.spaceM),

                  // Sorting parameters
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'ترتيب حسب:' : 'Sort By:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          _buildSortChip(
                            label: isAr ? 'التاريخ' : 'Date',
                            field: 'date',
                            ref: ref,
                            state: state,
                          ),
                          const SizedBox(width: AppTheme.spaceS),
                          _buildSortChip(
                            label: isAr ? 'المتجر' : 'Store',
                            field: 'store_name',
                            ref: ref,
                            state: state,
                          ),
                          const SizedBox(width: AppTheme.spaceS),
                          _buildSortChip(
                            label: isAr ? 'الإجمالي' : 'Total',
                            field: 'total',
                            ref: ref,
                            state: state,
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),

            // Invoices list builder
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
                  : state.invoices.isEmpty
                      ? Center(
                          child: Text(
                            isAr ? 'لم يتم العثور على فواتير تطابق البحث' : 'No invoices matched your query.',
                            style: TextStyle(color: theme.hintColor),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM),
                          itemCount: state.invoices.length,
                          itemBuilder: (ctx, index) {
                            final invoice = state.invoices[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.15),
                                  child: const Icon(Icons.description, color: AppColors.primaryYellow),
                                ),
                                title: Text(
                                  invoice.storeName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${invoice.date ?? ""} | ${invoice.invoiceNumber ?? ""}',
                                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Builder(
                                          builder: (context) {
                                            final currency = currencies.firstWhere(
                                              (c) => c.code.toUpperCase() == (invoice.currency ?? 'SAR').toUpperCase(),
                                              orElse: () => CurrencyModel(
                                                code: invoice.currency ?? 'SAR',
                                                nameEn: invoice.currency ?? 'SAR',
                                                nameAr: invoice.currency ?? 'SAR',
                                                symbolEn: invoice.currency ?? 'SAR',
                                                symbolAr: invoice.currency ?? 'SAR',
                                                exchangeRate: 1.0,
                                              ),
                                            );
                                            final symbol = isAr ? currency.symbolAr : currency.symbolEn;
                                            return Text(
                                              '${CurrencyFormatter.format(invoice.total)} $symbol',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.secondaryRed,
                                              ),
                                            );
                                          }
                                        ),
                                        Text(
                                          invoice.ocrEngine ?? '',
                                          style: TextStyle(fontSize: 10, color: theme.hintColor),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: AppTheme.spaceS),
                                    IconButton(
                                      icon: const Icon(Icons.share, color: Colors.blue),
                                      onPressed: () => _shareInvoice(context, ref, invoice),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.secondaryRed),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete Invoice'),
                                            content: const Text('Are you sure you want to delete this invoice?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.secondaryRed,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await ref.read(historyProvider.notifier).deleteInvoice(invoice.id);
                                          ref.read(homeDashboardProvider.notifier).loadDashboard();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () => context.go('/invoice/${invoice.id}'),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSortChip({
    required String label,
    required String field,
    required WidgetRef ref,
    required HistoryState state,
  }) {
    final isSelected = state.sortBy == field;
    final isAscending = state.ascending;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) {
        final nextAscending = isSelected ? !isAscending : false;
        ref.read(historyProvider.notifier).updateSorting(field, nextAscending);
      },
    );
  }
}
