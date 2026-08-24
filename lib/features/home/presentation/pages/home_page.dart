import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import 'package:invoice_ocr_ai/core/config/app_branding.dart';
import 'package:invoice_ocr_ai/core/theme/app_colors.dart';
import 'package:invoice_ocr_ai/core/theme/app_theme.dart';
import 'package:invoice_ocr_ai/core/utils/date_formatter.dart';
import 'package:invoice_ocr_ai/core/utils/currency_formatter.dart';
import 'package:invoice_ocr_ai/features/settings/presentation/providers/settings_provider.dart';
import 'package:invoice_ocr_ai/features/settings/presentation/providers/currencies_provider.dart';
import 'package:invoice_ocr_ai/features/invoice/data/models/invoice_model.dart';
import 'package:invoice_ocr_ai/features/invoice/data/models/currency_model.dart';
import 'package:invoice_ocr_ai/features/home/presentation/providers/home_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// Picker action helper
  Future<void> _handleImageSelection(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(source: source);
      if (image != null && context.mounted) {
        context.go('/scanner?path=${Uri.encodeComponent(image.path)}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isAr = settings.language == 'ar';
    final dashboard = ref.watch(homeDashboardProvider);
    final currencies = ref.watch(currenciesProvider);
    final theme = Theme.of(context);

    final activeCurrency = currencies.firstWhere(
      (c) => c.code.toUpperCase() == settings.defaultCurrency.toUpperCase(),
      orElse: () => CurrencyModel(
        code: settings.defaultCurrency,
        nameEn: settings.defaultCurrency,
        nameAr: settings.defaultCurrency,
        symbolEn: settings.defaultCurrency,
        symbolAr: settings.defaultCurrency,
        exchangeRate: 1.0,
      ),
    );
    final activeCurrencySymbol = isAr ? activeCurrency.symbolAr : activeCurrency.symbolEn;

    // Responsive measurements
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    // Refresh metrics on resume/start
    ref.read(homeDashboardProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandingLogoWidget(size: 32),
            const SizedBox(width: AppTheme.spaceS),
            Text(
              isAr ? 'فاتورة ذكية' : 'Invoice OCR AI',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.secondaryRed),
            onPressed: () => context.go('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.secondaryRed),
            onPressed: () => context.go('/history'),
          ),
        ],
      ),
      body: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: RefreshIndicator(
          onRefresh: () => ref.read(homeDashboardProvider.notifier).loadDashboard(),
          child: dashboard.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Widget
                      _buildWelcomeHeader(isAr, theme),
                      const SizedBox(height: AppTheme.spaceM),

                      // Statistics Row (Responsive grid layout)
                      _buildStatsGrid(dashboard, activeCurrencySymbol, isAr, screenWidth, isTablet, isDesktop, theme),
                      const SizedBox(height: AppTheme.spaceL),

                      // Document Scan Action Buttons
                      _buildActionButtons(context, isAr, theme),
                      const SizedBox(height: AppTheme.spaceL),

                      // Recent Invoices section
                      _buildRecentInvoices(dashboard.recentInvoices, isAr, context, ref, theme),
                      const SizedBox(height: AppTheme.spaceL),

                      // Recent Exports section
                      _buildRecentExports(dashboard.recentExports, isAr, theme),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(bool isAr, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'أهلاً بك في الفاتورة الذكية 👋' : 'Welcome to Invoice OCR AI 👋',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          isAr
              ? 'امسح فواتيرك ضوئياً وحولها لجداول منظمة فوراً'
              : 'Scan your invoices and transform them into structured reports.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    HomeDashboardState state,
    String currencySymbol,
    bool isAr,
    double screenWidth,
    bool isTablet,
    bool isDesktop,
    ThemeData theme,
  ) {
    final double cardWidth = (isDesktop)
        ? (screenWidth - AppTheme.spaceM * 3) / 3
        : (isTablet)
            ? (screenWidth - AppTheme.spaceM * 2) / 2
            : screenWidth;

    final stats = [
      _StatItem(
        title: isAr ? 'إجمالي الفواتير' : 'Total Invoices',
        value: state.invoiceCount.toString(),
        icon: Icons.receipt_long,
        color: AppColors.primaryYellow,
      ),
      _StatItem(
        title: isAr ? 'إجمالي المصروفات' : 'Total Spent',
        value: '${CurrencyFormatter.format(state.totalSpend)} $currencySymbol',
        icon: Icons.monetization_on,
        color: AppColors.secondaryRed,
      ),
    ];

    if (isTablet || isDesktop) {
      return Wrap(
        spacing: AppTheme.spaceM,
        runSpacing: AppTheme.spaceM,
        children: stats
            .map((stat) => SizedBox(
                  width: cardWidth,
                  child: _buildStatCard(stat, theme),
                ))
            .toList(),
      );
    }

    return Column(
      children: stats.map((stat) => _buildStatCard(stat, theme)).toList(),
    );
  }

  Widget _buildStatCard(_StatItem item, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: item.color.withValues(alpha: 0.15),
              child: Icon(item.icon, color: item.color),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                Text(
                  item.value,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isAr, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.pureBlack,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceM),
            ),
            onPressed: () => _handleImageSelection(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: Text(isAr ? 'التقاط فاتورة' : 'Take Photo'),
          ),
        ),
        const SizedBox(width: AppTheme.spaceM),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.secondaryRed, width: 2),
              foregroundColor: AppColors.secondaryRed,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceM),
            ),
            onPressed: () => _handleImageSelection(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: Text(isAr ? 'معرض الصور' : 'Pick Image'),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentInvoices(List<dynamic> invoices, bool isAr, BuildContext context, WidgetRef ref, ThemeData theme) {
    final currencies = ref.watch(currenciesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(isAr ? 'آخر الفواتير المضافة' : 'Recent Invoices', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => context.go('/history'),
              child: Text(isAr ? 'عرض الكل' : 'View All'),
            )
          ],
        ),
        if (invoices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceM),
            child: Center(
              child: Text(
                isAr ? 'لا يوجد فواتير مضافة بعد' : 'No invoices added yet.',
                style: TextStyle(color: theme.hintColor),
              ),
            ),
          )
        else
          ...invoices.map((inv) {
            final invoice = inv as InvoiceModel;
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

            return Card(
              margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.15),
                  child: const Icon(Icons.description, color: AppColors.primaryYellow),
                ),
                title: Text(invoice.storeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${invoice.date ?? ""} | ${invoice.items.length} ${isAr ? "منتجات" : "items"}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${CurrencyFormatter.format(invoice.total)} $symbol',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondaryRed),
                    ),
                    Text(
                      invoice.ocrEngine ?? '',
                      style: TextStyle(fontSize: 10, color: theme.hintColor),
                    ),
                  ],
                ),
                onTap: () => context.go('/invoice/${invoice.id}'),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRecentExports(List<dynamic> exports, bool isAr, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isAr ? 'آخر عمليات التصدير' : 'Recent Exports', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppTheme.spaceS),
        if (exports.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceM),
            child: Center(
              child: Text(
                isAr ? 'لا يوجد عمليات تصدير بعد' : 'No exported files yet.',
                style: TextStyle(color: theme.hintColor),
              ),
            ),
          )
        else
          ...exports.map((log) {
            final path = log['file_path'] as String;
            final fileName = p.basename(path);
            final format = log['format'] as String;
            final dateStr = log['timestamp'] as String;

            return Card(
              margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.secondaryRed.withValues(alpha: 0.15),
                  child: Icon(
                    format == 'pdf'
                        ? Icons.picture_as_pdf
                        : format == 'xlsx'
                            ? Icons.table_chart
                            : Icons.file_present,
                    color: AppColors.secondaryRed,
                  ),
                ),
                title: Text(fileName, overflow: TextOverflow.ellipsis),
                subtitle: Text('$format | $dateStr'),
                trailing: Chip(
                  label: Text(
                    log['status'] as String,
                    style: const TextStyle(color: Colors.green, fontSize: 10),
                  ),
                  backgroundColor: Colors.green.withValues(alpha: 0.15),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
