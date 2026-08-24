import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:invoice_ocr_ai/core/services/export_service.dart';
import 'package:invoice_ocr_ai/core/theme/app_colors.dart';
import 'package:invoice_ocr_ai/core/theme/app_theme.dart';
import 'package:invoice_ocr_ai/core/utils/currency_formatter.dart';
import 'package:invoice_ocr_ai/features/settings/presentation/providers/settings_provider.dart';
import 'package:invoice_ocr_ai/features/home/presentation/providers/home_provider.dart';
import 'package:invoice_ocr_ai/features/invoice/presentation/providers/invoice_provider.dart';
import 'package:invoice_ocr_ai/features/settings/presentation/providers/currencies_provider.dart';
import 'package:invoice_ocr_ai/features/invoice/data/models/invoice_model.dart';

class InvoiceDetailPage extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoiceDetailPage({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends ConsumerState<InvoiceDetailPage> {
  final _formKey = GlobalKey<FormState>();

  // Header controllers
  late final TextEditingController _storeNameController;
  late final TextEditingController _invNumberController;
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  late final TextEditingController _taxController;
  late final TextEditingController _discountController;

  // Financial & Bank transfer controllers
  late final TextEditingController _docTitleController;
  late final TextEditingController _senderController;
  late final TextEditingController _receiverController;
  late final TextEditingController _accountController;
  late final TextEditingController _branchController;
  late final TextEditingController _notesController;
  late final TextEditingController _employeeController;
  late final TextEditingController _totalAmountController;

  bool _controllersInitialized = false;

  @override
  void dispose() {
    if (_controllersInitialized) {
      _storeNameController.dispose();
      _invNumberController.dispose();
      _dateController.dispose();
      _timeController.dispose();
      _taxController.dispose();
      _discountController.dispose();
      _docTitleController.dispose();
      _senderController.dispose();
      _receiverController.dispose();
      _accountController.dispose();
      _branchController.dispose();
      _notesController.dispose();
      _employeeController.dispose();
      _totalAmountController.dispose();
    }
    super.dispose();
  }

  void _initControllers(dynamic invoice) {
    if (_controllersInitialized) return;
    _storeNameController = TextEditingController(text: invoice.storeName);
    _invNumberController = TextEditingController(text: invoice.invoiceNumber ?? '');
    _dateController = TextEditingController(text: invoice.date ?? '');
    _timeController = TextEditingController(text: invoice.time ?? '');
    _taxController = TextEditingController(text: CurrencyFormatter.format(invoice.tax));
    _discountController = TextEditingController(text: CurrencyFormatter.format(invoice.discount));

    _docTitleController = TextEditingController(text: invoice.documentTitle ?? '');
    _senderController = TextEditingController(text: invoice.senderName ?? '');
    _receiverController = TextEditingController(text: invoice.receiverName ?? '');
    _accountController = TextEditingController(text: invoice.accountNumber ?? '');
    _branchController = TextEditingController(text: invoice.branch ?? '');
    _notesController = TextEditingController(text: invoice.notes ?? '');
    _employeeController = TextEditingController(text: invoice.employeeName ?? '');
    _totalAmountController = TextEditingController(text: CurrencyFormatter.format(invoice.total));

    _controllersInitialized = true;
  }

  Future<void> _saveInvoice(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    
    final notifier = ref.read(invoiceEditProvider(widget.invoiceId).notifier);
    final success = await notifier.saveInvoice();

    if (success && context.mounted) {
      // Reload Home stats
      ref.read(homeDashboardProvider.notifier).loadDashboard();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document saved successfully')),
      );
      context.go('/history');
    }
  }

  Future<void> _deleteInvoice(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref.read(invoiceEditProvider(widget.invoiceId).notifier).deleteInvoice();
      if (success && context.mounted) {
        ref.read(homeDashboardProvider.notifier).loadDashboard();
        context.go('/history');
      }
    }
  }

  /// Triggers exporting options sheet
  void _showExportOptions(BuildContext context, dynamic invoice) {
    final exporter = GetIt.I<ExportService>();
    final settings = ref.read(settingsProvider);
    final isAr = settings.language == 'ar' || invoice.detectedLanguage == 'ar';

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isAr ? 'تصدير المستند كـ' : 'Export Document As',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceM),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildExportOptionCard(
                    icon: Icons.table_chart,
                    label: 'Excel',
                    color: Colors.green,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final file = await exporter.exportToExcel(invoice, isArabic: isAr);
                      await exporter.shareFile(file, text: 'Document Excel Export');
                    },
                  ),
                  _buildExportOptionCard(
                    icon: Icons.article,
                    label: 'CSV',
                    color: Colors.teal,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final file = await exporter.exportToCsv(invoice, isArabic: isAr);
                      await exporter.shareFile(file, text: 'Document CSV Export');
                    },
                  ),
                  _buildExportOptionCard(
                    icon: Icons.picture_as_pdf,
                    label: 'PDF',
                    color: Colors.red,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final file = await exporter.exportToPdf(invoice, isArabic: isAr);
                      await exporter.shareFile(file, text: 'Document PDF Export');
                    },
                  ),
                  _buildExportOptionCard(
                    icon: Icons.wordpress, // Represent docx
                    label: 'Word',
                    color: Colors.blue,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final file = await exporter.exportToWord(invoice, isArabic: isAr);
                      await exporter.shareFile(file, text: 'Document Word Export');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportOptionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceS),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: AppTheme.spaceXS),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceEditProvider(widget.invoiceId));
    final settings = ref.watch(settingsProvider);
    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)));
    }

    if (state.invoice == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(state.errorMessage ?? 'Error loading document')),
      );
    }

    final invoice = state.invoice!;
    _initControllers(invoice);

    final isAr = invoice.detectedLanguage == 'ar' || settings.language == 'ar';
    final theme = Theme.of(context);

    final isBankDoc = invoice.documentType == 'bank_transfer' || invoice.documentType == 'receipt_voucher';

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final isTablet = mediaQuery.size.width >= 720;

    final formWidget = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Universal Category & Language Selector
          _buildCategorySelectorCard(isAr, invoice, theme),
          const SizedBox(height: AppTheme.spaceM),

          // Header Card
          _buildFormCard(isAr, invoice, theme),
          const SizedBox(height: AppTheme.spaceM),

          // Dynamic Metadata Card (Patient, Doctor, Room #, Meter #, Account #, Policy #, Expiry)
          if (invoice.dynamicMetadata.isNotEmpty) ...[
            _buildDynamicMetadataCard(isAr, invoice, theme),
            const SizedBox(height: AppTheme.spaceM),
          ],

          // Financial & Bank Details Card
          if (isBankDoc || invoice.senderName != null || invoice.accountNumber != null) ...[
            _buildBankDetailsCard(isAr, invoice, theme),
            const SizedBox(height: AppTheme.spaceM),
          ],

          // Universal Dynamic Multi-Column Table (if present)
          if (invoice.tableColumns.isNotEmpty && invoice.tableRows.isNotEmpty) ...[
            _buildDynamicTable(isAr, invoice, theme),
            const SizedBox(height: AppTheme.spaceM),
          ],

          // Standard Line Items Table (if invoice or if items exist)
          if (!isBankDoc || invoice.items.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? 'المنتجات / الخدمات' : 'Line Items & Services',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () {
                    ref.read(invoiceEditProvider(widget.invoiceId).notifier).addLineItem();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXS),
            _buildItemsList(invoice.items, isAr, theme),
            const SizedBox(height: AppTheme.spaceM),
          ],

          // Totals / Amount Summary
          _buildTotalsCard(invoice, isAr, theme, isBankDoc),
          const SizedBox(height: AppTheme.spaceL),

          // Save / Delete Buttons
          _buildActionsRow(context, invoice, isAr),
        ],
      ),
    );

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/history');
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
          title: Text(isAr ? 'مراجعة المستند' : 'Review Document'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: handleBack,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: AppColors.secondaryRed),
              onPressed: () => _showExportOptions(context, invoice),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.secondaryRed),
              onPressed: () => _deleteInvoice(context),
            ),
          ],
        ),
      body: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: isTablet || isLandscape
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spaceM),
                      child: formWidget,
                    ),
                  ),
                  if (invoice.imagePath != null)
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: double.infinity,
                        color: Colors.black12,
                        padding: const EdgeInsets.all(AppTheme.spaceM),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          child: Image.file(
                            File(invoice.imagePath!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spaceM),
                child: formWidget,
              ),
        ),
      ),
    );
  }

  Widget _buildCategorySelectorCard(bool isAr, dynamic invoice, ThemeData theme) {
    final notifier = ref.read(invoiceEditProvider(widget.invoiceId).notifier);

    const allowedCategories = {
      'general',
      'education_tuition',
      'real_estate_rent',
      'real_estate_sale',
      'vehicle_sale',
      'utility',
      'medical',
      'pharmacy',
      'hotel',
      'purchase_invoice',
      'sales_invoice',
      'logistics',
      'bank_financial',
      'retail_invoice',
    };

    final currentCategory = allowedCategories.contains(invoice.documentCategory)
        ? invoice.documentCategory
        : 'general';

    IconData getCategoryIcon(String cat) {
      switch (cat) {
        case 'medical':
          return Icons.local_hospital;
        case 'pharmacy':
          return Icons.medication;
        case 'hotel':
          return Icons.hotel;
        case 'utility':
          return Icons.water_drop;
        case 'education_tuition':
          return Icons.school;
        case 'real_estate_rent':
          return Icons.real_estate_agent;
        case 'real_estate_sale':
          return Icons.home_work;
        case 'vehicle_sale':
          return Icons.directions_car;
        case 'purchase_invoice':
          return Icons.shopping_cart_checkout;
        case 'sales_invoice':
          return Icons.sell;
        case 'logistics':
          return Icons.local_shipping;
        case 'bank_financial':
          return Icons.account_balance;
        case 'retail_invoice':
          return Icons.shopping_bag;
        default:
          return Icons.description;
      }
    }

    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM, vertical: AppTheme.spaceS),
        child: Row(
          children: [
            Icon(getCategoryIcon(currentCategory), color: AppColors.primaryYellow),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: currentCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: isAr ? 'تصنيف الفاتورة / القطاع' : 'Category / Sector',
                  border: InputBorder.none,
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(value: 'general', child: Text(isAr ? 'مستند عام' : 'General Document', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'education_tuition', child: Text(isAr ? 'فواتير مدارس وجامعات ودراسات عليا' : 'School & University Tuition', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'real_estate_rent', child: Text(isAr ? 'إيجارات عقارات ومحلات وشقق' : 'Property & Shop Rent', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'real_estate_sale', child: Text(isAr ? 'عقود بيع وشراء عقارات وأراضي' : 'Real Estate Purchase & Sale', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'vehicle_sale', child: Text(isAr ? 'مبايعة وبيع وشراء سيارات والمركبات' : 'Vehicle Purchase & Sale', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'utility', child: Text(isAr ? 'فواتير كهرباء وماء ومرافق' : 'Water, Electricity & Utilities', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'medical', child: Text(isAr ? 'فواتير مستشفيات وعيادات' : 'Hospital & Medical Bill', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'pharmacy', child: Text(isAr ? 'فواتير صيدليات وأدوية' : 'Pharmacy Receipt', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'hotel', child: Text(isAr ? 'فواتير فنادق وضيافة' : 'Hotel & Hospitality', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'purchase_invoice', child: Text(isAr ? 'فواتير مشتريات بكافة أنواعها' : 'Purchase Invoices', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'sales_invoice', child: Text(isAr ? 'فواتير مبيعات بكافة أنواعها' : 'Sales Invoices', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'logistics', child: Text(isAr ? 'فواتير شحن وتخليص جمركي' : 'Shipping & Customs', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'bank_financial', child: Text(isAr ? 'إشعارات وإيداعات بنكية' : 'Bank Deposit / Transfer', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'retail_invoice', child: Text(isAr ? 'فواتير تجارية وتجزئة' : 'Retail Invoice', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (val) {
                  if (val != null) notifier.updateDocumentCategory(val);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicMetadataCard(bool isAr, dynamic invoice, ThemeData theme) {
    final notifier = ref.read(invoiceEditProvider(widget.invoiceId).notifier);
    final List<Map<String, String>> metadata = invoice.dynamicMetadata;

    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, color: AppColors.primaryYellow),
                    const SizedBox(width: AppTheme.spaceS),
                    Text(
                      isAr ? 'بيانات وحقول الفاتورة المستخرجة' : 'Extracted Document Metadata',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                  onPressed: () {
                    notifier.addMetadataItem(isAr ? 'حقل جديد' : 'New Field', '');
                  },
                ),
              ],
            ),
            const Divider(height: AppTheme.spaceM),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metadata.length,
              itemBuilder: (ctx, index) {
                final item = metadata[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          initialValue: item['label'],
                          decoration: InputDecoration(
                            labelText: isAr ? 'اسم الحقل' : 'Label',
                            isDense: true,
                          ),
                          onChanged: (val) => notifier.updateMetadataItem(index, val, item['value'] ?? ''),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceS),
                      Expanded(
                        flex: 6,
                        child: TextFormField(
                          initialValue: item['value'],
                          decoration: InputDecoration(
                            labelText: isAr ? 'القيمة' : 'Value',
                            isDense: true,
                          ),
                          onChanged: (val) => notifier.updateMetadataItem(index, item['label'] ?? '', val),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.secondaryRed),
                        onPressed: () => notifier.deleteMetadataItem(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicTable(bool isAr, dynamic invoice, ThemeData theme) {
    final notifier = ref.read(invoiceEditProvider(widget.invoiceId).notifier);
    final List<String> cols = invoice.tableColumns;
    final List<List<String>> rows = invoice.tableRows;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'جدول الفاتورة الأصلي المستخرج' : 'Extracted Document Table',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spaceS),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: cols.map((col) => DataColumn(label: Text(col, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                rows: rows.asMap().entries.map((entry) {
                  final rowIndex = entry.key;
                  final rowCells = entry.value;
                  return DataRow(
                    cells: cols.asMap().entries.map((colEntry) {
                      final colIndex = colEntry.key;
                      final cellVal = colIndex < rowCells.length ? rowCells[colIndex] : '';
                      return DataCell(
                        TextFormField(
                          initialValue: cellVal,
                          decoration: const InputDecoration(border: InputBorder.none),
                          onChanged: (val) => notifier.updateTableCell(rowIndex, colIndex, val),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(bool isAr, dynamic invoice, ThemeData theme) {
    final notifier = ref.read(invoiceEditProvider(widget.invoiceId).notifier);
    final isBankDoc = invoice.documentType != 'invoice';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _storeNameController,
                    decoration: InputDecoration(
                      labelText: isAr
                          ? (isBankDoc ? 'اسم البنك / الجهة' : 'اسم المتجر')
                          : (isBankDoc ? 'Bank / Institution Name' : 'Store Name'),
                      isDense: true,
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Name required' : null,
                    onChanged: (val) => notifier.updateStoreName(val),
                  ),
                ),
                if (isBankDoc) ...[
                  const SizedBox(width: AppTheme.spaceM),
                  Expanded(
                    child: TextFormField(
                      controller: _docTitleController,
                      decoration: InputDecoration(
                        labelText: isAr ? 'نوع السند / الإشعار' : 'Voucher Title',
                        isDense: true,
                      ),
                      onChanged: (val) => notifier.updateDocumentTitle(val),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppTheme.spaceM),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _invNumberController,
                    decoration: InputDecoration(
                      labelText: isAr
                          ? (isBankDoc ? 'رقم العملية / المرجع' : 'رقم الفاتورة')
                          : (isBankDoc ? 'Transaction / Ref #' : 'Invoice Number'),
                      isDense: true,
                    ),
                    onChanged: (val) => notifier.updateInvoiceNumber(val),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: TextFormField(
                    controller: _branchController,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الفرع' : 'Branch',
                      isDense: true,
                    ),
                    onChanged: (val) => notifier.updateBranch(val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceM),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: isAr ? 'التاريخ' : 'Date',
                      isDense: true,
                      suffixIcon: const Icon(Icons.calendar_today, size: 16, color: AppColors.primaryYellow),
                    ),
                    onTap: () async {
                      final DateTime initial = DateTime.tryParse(_dateController.text) ?? DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        _dateController.text = formatted;
                        notifier.updateDate(formatted);
                      }
                    },
                    onChanged: (val) => notifier.updateDate(val),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceS),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _timeController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الوقت' : 'Time',
                      isDense: true,
                      suffixIcon: const Icon(Icons.access_time, size: 16, color: AppColors.primaryYellow),
                    ),
                    onTap: () async {
                      TimeOfDay initial = TimeOfDay.now();
                      if (_timeController.text.contains(':')) {
                        final parts = _timeController.text.split(':');
                        if (parts.length >= 2) {
                          final h = int.tryParse(parts[0].trim());
                          final m = int.tryParse(parts[1].trim());
                          if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
                            initial = TimeOfDay(hour: h, minute: m);
                          }
                        }
                      }
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: initial,
                      );
                      if (picked != null) {
                        final formatted = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                        _timeController.text = formatted;
                        notifier.updateTime(formatted);
                      }
                    },
                    onChanged: (val) => notifier.updateTime(val),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceS),
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<String>(
                    value: ref.watch(currenciesProvider).any((c) => c.code == (invoice.currency ?? 'SAR')) ? (invoice.currency ?? 'SAR') : 'SAR',
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: isAr ? 'العملة' : 'Currency',
                      isDense: true,
                    ),
                    items: ref.watch(currenciesProvider).map((c) {
                      return DropdownMenuItem(
                        value: c.code,
                        child: Text(
                          '${c.code} (${c.getSymbol(isAr ? "ar" : "en")})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.updateCurrency(val);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _getCategoryCardLabels(String category, bool isAr) {
    final cat = category.toLowerCase();
    switch (cat) {
      case 'medical':
        return {
          'title': isAr ? 'تفاصيل الخدمة الطبية' : 'Medical Details',
          'sender': isAr ? 'اسم المريض' : 'Patient Name',
          'receiver': isAr ? 'المستشفى' : 'Hospital',
          'account': isAr ? 'رقم الملف الطبي' : 'Medical File No',
          'employee': isAr ? 'الطبيب المعالج' : 'Doctor',
        };
      case 'education_tuition':
        return {
          'title': isAr ? 'تفاصيل الرسوم الدراسية' : 'Tuition Details',
          'sender': isAr ? 'اسم الطالب' : 'Student Name',
          'receiver': isAr ? 'الجامعة' : 'University',
          'account': isAr ? 'الرقم الجامعي' : 'Student ID',
          'employee': isAr ? 'المحاسب' : 'Accountant',
        };
      case 'real_estate_rent':
        return {
          'title': isAr ? 'تفاصيل عقد الإيجار' : 'Lease Details',
          'sender': isAr ? 'اسم المستأجر' : 'Tenant Name',
          'receiver': isAr ? 'اسم المؤجر' : 'Landlord Name',
          'account': isAr ? 'رقم العقد' : 'Contract No',
          'employee': isAr ? 'المكتب العقاري' : 'Agency',
        };
      case 'real_estate_sale':
        return {
          'title': isAr ? 'تفاصيل بيع العقار' : 'Real Estate Purchase Details',
          'sender': isAr ? 'اسم المشتري' : 'Buyer Name',
          'receiver': isAr ? 'اسم البائع' : 'Seller Name',
          'account': isAr ? 'رقم الصك' : 'Deed No',
          'employee': isAr ? 'الموثق' : 'Notary',
        };
      case 'vehicle_sale':
        return {
          'title': isAr ? 'تفاصيل مبايعة المركبة' : 'Vehicle Sale Details',
          'sender': isAr ? 'اسم المشتري' : 'Buyer Name',
          'receiver': isAr ? 'اسم البائع' : 'Seller Name',
          'account': isAr ? 'رقم الهيكل (VIN)' : 'Chassis No',
          'employee': isAr ? 'معرض السيارات' : 'Showroom',
        };
      case 'utility':
        return {
          'title': isAr ? 'تفاصيل فاتورة المرافق' : 'Utility Bill Details',
          'sender': isAr ? 'اسم المشترك' : 'Subscriber Name',
          'receiver': isAr ? 'شركة المرافق' : 'Utility Provider',
          'account': isAr ? 'رقم العداد' : 'Meter No',
          'employee': isAr ? 'المفتش' : 'Inspector',
        };
      case 'purchase_invoice':
        return {
          'title': isAr ? 'تفاصيل فاتورة المشتريات' : 'Purchase Order Details',
          'sender': isAr ? 'الجهة المشترية' : 'Buyer',
          'receiver': isAr ? 'المورد' : 'Supplier',
          'account': isAr ? 'رقم أمر الشراء' : 'PO No',
          'employee': isAr ? 'مسؤول المشتريات' : 'Purchasing Agent',
        };
      case 'sales_invoice':
        return {
          'title': isAr ? 'تفاصيل فاتورة المبيعات' : 'Sales Receipt Details',
          'sender': isAr ? 'اسم العميل' : 'Customer Name',
          'receiver': isAr ? 'البائع' : 'Seller',
          'account': isAr ? 'رقم حساب العميل' : 'Customer Account No',
          'employee': isAr ? 'ممثل المبيعات' : 'Sales Rep',
        };
      case 'pharmacy':
        return {
          'title': isAr ? 'تفاصيل فاتورة الصيدلية' : 'Pharmacy Details',
          'sender': isAr ? 'اسم المريض' : 'Patient Name',
          'receiver': isAr ? 'الصيدلية' : 'Pharmacy',
          'account': isAr ? 'رقم الوصفة الطبية' : 'Prescription No',
          'employee': isAr ? 'الصيدلي' : 'Pharmacist',
        };
      case 'hotel':
        return {
          'title': isAr ? 'تفاصيل فاتورة الفندق' : 'Hotel Booking Details',
          'sender': isAr ? 'اسم النزيل' : 'Guest Name',
          'receiver': isAr ? 'الفندق' : 'Hotel',
          'account': isAr ? 'رقم الحجز' : 'Booking No',
          'employee': isAr ? 'موظف الاستقبال' : 'Receptionist',
        };
      case 'logistics':
        return {
          'title': isAr ? 'تفاصيل فاتورة الشحن' : 'Shipping Details',
          'sender': isAr ? 'اسم المرسل' : 'Shipper Name',
          'receiver': isAr ? 'اسم المرسل إليه' : 'Consignee Name',
          'account': isAr ? 'رقم بوليصة الشحن' : 'Waybill No',
          'employee': isAr ? 'المخلص الجمركي' : 'Dispatcher',
        };
      case 'bank_financial':
      default:
        return {
          'title': isAr ? 'تفاصيل الإيداع والحوالة البنكية' : 'Bank Transfer Details',
          'sender': isAr ? 'المودع' : 'Sender',
          'receiver': isAr ? 'المستفيد' : 'Beneficiary',
          'account': isAr ? 'رقم الحساب' : 'Account No',
          'employee': isAr ? 'الصراف' : 'Teller',
        };
    }
  }

  Widget _buildBankDetailsCard(bool isAr, dynamic invoice, ThemeData theme) {
    final notifier = ref.read(invoiceEditProvider(widget.invoiceId).notifier);
    final cardLabels = _getCategoryCardLabels(invoice.documentCategory, isAr);

    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz, color: AppColors.primaryYellow),
                const SizedBox(width: AppTheme.spaceS),
                Expanded(
                  child: Text(
                    cardLabels['title']!,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: AppTheme.spaceM),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _senderController,
                    decoration: InputDecoration(
                      labelText: cardLabels['sender'],
                      isDense: true,
                    ),
                    onChanged: (val) => notifier.updateSenderName(val),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: TextFormField(
                    controller: _receiverController,
                    decoration: InputDecoration(
                      labelText: cardLabels['receiver'],
                      isDense: true,
                    ),
                    onChanged: (val) => notifier.updateReceiverName(val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceM),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _accountController,
                    decoration: InputDecoration(
                      labelText: cardLabels['account'],
                      isDense: true,
                    ),
                    onChanged: (val) => notifier.updateAccountNumber(val),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: TextFormField(
                    controller: _employeeController,
                    decoration: InputDecoration(
                      labelText: isAr ? 'المستخدم / الموظف' : 'Teller / Employee',
                    ),
                    onChanged: (val) => notifier.updateEmployeeName(val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceM),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: isAr ? 'الملاحظات / المبلغ كتابة' : 'Notes / Written Amount',
                hintText: isAr ? 'مثال: مائة دولار فقط لا غير' : 'Remarks',
              ),
              onChanged: (val) => notifier.updateNotes(val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(List<dynamic> items, bool isAr, ThemeData theme) {
    final notifier = ref.read(invoiceEditProvider(widget.invoiceId).notifier);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceS),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: TextFormField(
                    initialValue: item.productName,
                    decoration: InputDecoration(
                      labelText: isAr ? 'المنتج' : 'Product',
                      hintText: isAr ? 'اسم السلعة' : 'Product name',
                      isDense: true,
                    ),
                    onChanged: (val) => notifier.updateLineItem(index, name: val),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceS),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: item.quantity.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isAr ? 'الكمية' : 'Qty',
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final double? qty = double.tryParse(val);
                      if (qty != null) notifier.updateLineItem(index, qty: qty);
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spaceS),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: item.unitPrice.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isAr ? 'السعر' : 'Price',
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final double? price = double.tryParse(val);
                      if (price != null) notifier.updateLineItem(index, price: price);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.secondaryRed),
                  onPressed: () => notifier.deleteLineItem(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalsCard(dynamic invoice, bool isAr, ThemeData theme, bool isBankDoc) {
    final notifier = ref.read(invoiceEditProvider(widget.invoiceId).notifier);

    if (isBankDoc) {
      return Card(
        color: AppColors.primaryYellow.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'المبلغ المقبوض / المودع:' : 'Deposited Amount:',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: _totalAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                          textAlign: TextAlign.end,
                          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8)),
                          onChanged: (val) {
                            final double? tot = double.tryParse(val);
                            if (tot != null) notifier.updateTotalDirectly(tot);
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceS),
                      Text(
                        invoice.currency ?? 'SAR',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceS),
                Align(
                  alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    '${isAr ? "مبلغ وقدره:" : "In words:"} ${invoice.notes}',
                    style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isAr ? 'الإجمالي قبل الضريبة:' : 'Subtotal:'),
                Text('${CurrencyFormatter.format(invoice.subtotal)} ${invoice.currency}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppTheme.spaceM),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _taxController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: isAr ? 'الضريبة (+)' : 'Tax (+)'),
                    onChanged: (val) {
                      final double? tax = double.tryParse(val.replaceAll(',', ''));
                      if (tax != null) notifier.updateTax(tax);
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: isAr ? 'الخصم (-)' : 'Discount (-)'),
                    onChanged: (val) {
                      final double? disc = double.tryParse(val.replaceAll(',', ''));
                      if (disc != null) notifier.updateDiscount(disc);
                    },
                  ),
                ),
              ],
            ),
            const Divider(height: AppTheme.spaceXL),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? 'الإجمالي النهائي:' : 'Final Total:',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${CurrencyFormatter.format(invoice.total)} ${invoice.currency}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsRow(BuildContext context, dynamic invoice, bool isAr) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceM),
            ),
            onPressed: () => context.go('/history'),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
        ),
        const SizedBox(width: AppTheme.spaceM),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.pureBlack,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceM),
            ),
            onPressed: () => _saveInvoice(context),
            child: Text(
              isAr ? 'حفظ المستند' : 'Save Document',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
