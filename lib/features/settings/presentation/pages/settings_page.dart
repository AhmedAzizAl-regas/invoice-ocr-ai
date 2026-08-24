import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

import 'package:invoice_ocr_ai/core/config/app_config.dart';
import 'package:invoice_ocr_ai/core/database/database_helper.dart';
import 'package:invoice_ocr_ai/core/theme/app_colors.dart';
import 'package:invoice_ocr_ai/core/theme/app_theme.dart';
import 'package:invoice_ocr_ai/features/settings/presentation/providers/settings_provider.dart';
import 'package:invoice_ocr_ai/features/settings/presentation/providers/currencies_provider.dart';
import 'package:invoice_ocr_ai/features/invoice/data/models/currency_model.dart';
import 'package:invoice_ocr_ai/features/home/presentation/providers/home_provider.dart';
import 'package:invoice_ocr_ai/features/history/presentation/providers/history_provider.dart';

// تعليق 1: هذا الملف يحتوي على واجهة إعدادات التطبيق وإدارة النسخ الاحتياطية.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  /// Returns Google Play compliant backup folder path (e.g. Download/Invoice_OCR_Backups or Documents/Backups).
  Future<Directory> _getBackupDirectory() async {
    try {
      Directory targetDir;
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          targetDir = Directory(p.join(downloadsDir.path, 'Invoice_OCR_Backups'));
        } else {
          final docs = await getApplicationDocumentsDirectory();
          targetDir = Directory(p.join(docs.path, 'Backups'));
        }
      } else {
        final docs = await getApplicationDocumentsDirectory();
        targetDir = Directory(p.join(docs.path, 'Backups'));
      }
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      return targetDir;
    } catch (e) {
      // Fallback to application documents directory in case of any permission or IO errors.
      final docs = await getApplicationDocumentsDirectory();
      final fallback = Directory(p.join(docs.path, 'Backups'));
      if (!await fallback.exists()) {
        await fallback.create(recursive: true);
      }
      return fallback;
    }

    /// Safe wrapper with timeout to avoid UI hanging when platform channel fails.
    Future<Directory?> _fetchBackupDirectorySafe({Duration timeout = const Duration(seconds: 5)}) async {
      try {
        return await _getBackupDirectory().timeout(timeout);
      } catch (_) {
        try {
          final docs = await getApplicationDocumentsDirectory();
          final fallback = Directory(p.join(docs.path, 'Backups'));
          if (!await fallback.exists()) {
            await fallback.create(recursive: true);
          }
          return fallback;
        } catch (_) {
          return null;
        }
      }
    }
  }

  /// Opens options sheet for Exporting Database Backup (Share or Save to Storage).
  Future<void> _showExportDatabaseSheet(BuildContext context, bool isAr) async {
    final dbDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbDir.path, 'invoice_ocr_ai.db');
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'ملف قاعدة البيانات غير موجود بعد'
                  : 'Database file does not exist yet.',
            ),
          ),
        );
      }
      return;
    }

    final backupDir = await _getBackupDirectory();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr
                  ? 'تصدير نسخة احتياطية من قاعدة البيانات'
                  : 'Export Database Backup',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: AppTheme.spaceS),
            Text(
              isAr
                  ? 'المسار الافتراضي للحفظ في الهاتف:\n${backupDir.path}'
                  : 'Default device save path:\n${backupDir.path}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: AppTheme.spaceM),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: Text(
                isAr ? 'مشاركة عبر التطبيقات' : 'Share via App Picker',
              ),
              subtitle: Text(
                isAr
                    ? 'مشاركة ملف .db إلى أي تطبيق آخر'
                    : 'Share .db backup to other apps',
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final xFile = XFile(
                  dbFile.path,
                  mimeType: 'application/x-sqlite3',
                );
                await Share.shareXFiles([
                  xFile,
                ], text: 'Invoice OCR AI Database Backup');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.save_alt, color: Colors.green),
              title: Text(
                isAr
                    ? 'حفظ مباشرة في ذاكرة الهاتف'
                    : 'Save directly to Phone Storage',
              ),
              subtitle: Text(
                isAr
                    ? 'نسخ الملف إلى مجلد التحميلات/المستندات'
                    : 'Copy file to Downloads/Documents backup folder',
              ),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final timestamp = DateTime.now()
                      .toString()
                      .replaceAll(':', '-')
                      .split('.')[0]
                      .replaceAll(' ', '_');
                  final targetFileName = 'invoice_ocr_ai_backup_$timestamp.db';
                  final savedFile = await dbFile.copy(
                    p.join(backupDir.path, targetFileName),
                  );
                  // Also update default latest backup file
                  await dbFile.copy(
                    p.join(backupDir.path, 'invoice_ocr_ai.db'),
                  );

                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(isAr ? 'تم الحفظ بنجاح' : 'Backup Saved'),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? 'تم حفظ النسخة الاحتياطية بنجاح في المسار التالي:'
                                  : 'Backup saved successfully to:',
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              savedFile.path,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: Text(isAr ? 'حسناً' : 'OK'),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isAr ? 'خطأ أثناء الحفظ: $e' : 'Save error: $e',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: AppTheme.spaceS),
          ],
        ),
      ),
    );
  }

  /// Opens sheet for Importing Database Backup.
  Future<void> _showImportDatabaseSheet(
    BuildContext context,
    WidgetRef ref,
    bool isAr,
  ) async {
    final backupDir = await _getBackupDirectory();
    List<FileSystemEntity> backupFiles = [];
    if (await backupDir.exists()) {
      backupFiles = backupDir
          .listSync()
          .where((f) => f.path.endsWith('.db'))
          .toList();
      backupFiles.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'استيراد قاعدة البيانات' : 'Import Database Backup',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppTheme.spaceS),
              Text(
                isAr
                    ? 'المسار الافتراضي للبحث في الهاتف:\n${backupDir.path}'
                    : 'Default search path on phone:\n${backupDir.path}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: AppTheme.spaceM),
              if (backupFiles.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  child: Center(
                    child: Text(
                      isAr
                          ? 'لم يتم العثور على نسخ احتياطية (.db) في المسار الافتراضي'
                          : 'No backup (.db) files found in default directory.',
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  isAr
                      ? 'اختر ملف نسخة احتياطية للاسترجاع:'
                      : 'Select a backup file to restore:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppTheme.spaceS),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: backupFiles.length,
                  itemBuilder: (listCtx, index) {
                    final file = backupFiles[index] as File;
                    final fileName = p.basename(file.path);
                    final stat = file.statSync();
                    final dateStr = stat.modified.toString().split('.')[0];
                    final sizeKb = (stat.size / 1024).toStringAsFixed(1);

                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.storage,
                          color: AppColors.primaryYellow,
                        ),
                        title: Text(
                          fileName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text('$dateStr | $sizeKb KB'),
                        trailing: const Icon(
                          Icons.download_sharp,
                          color: Colors.green,
                        ),
                        onTap: () =>
                            _confirmRestoreDatabase(context, ref, isAr, file),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: AppTheme.spaceM),
            ],
          ),
        ),
      ),
    );
  }

  /// Confirms and replaces current database with picked backup file.
  void _confirmRestoreDatabase(
    BuildContext context,
    WidgetRef ref,
    bool isAr,
    File backupFile,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isAr ? 'تأكيد استيراد قاعدة البيانات' : 'Confirm Database Import',
        ),
        content: Text(
          isAr
              ? 'هل أنت متأكد من استبدال قاعدة البيانات الحالية بالنسخة الاحتياطية (${p.basename(backupFile.path)})؟ سيتم استرجاع كافة السجلات السابقة.'
              : 'Are you sure you want to replace current data with (${p.basename(backupFile.path)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }

              try {
                final dbHelper = GetIt.I<DatabaseHelper>();
                dbHelper.close();

                final activeDbDir = await getApplicationDocumentsDirectory();
                final activeDbPath = p.join(
                  activeDbDir.path,
                  'invoice_ocr_ai.db',
                );
                await backupFile.copy(activeDbPath);

                await dbHelper.initDb();

                ref.read(settingsProvider.notifier).loadSettings();
                await ref.read(currenciesProvider.notifier).loadCurrencies();
                ref.read(homeDashboardProvider.notifier).loadDashboard();
                ref.read(historyProvider.notifier).loadInvoices();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'تمت استعادة واستيراد قاعدة البيانات بنجاح! 🎉'
                            : 'Database backup imported successfully! 🎉',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr ? 'خطأ أثناء الاستيراد: $e' : 'Import error: $e',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(isAr ? 'استيراد' : 'Import'),
          ),
        ],
      ),
    );
  }

  /// Triggers full data wipe.
  void _confirmDeleteAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          ref.watch(settingsProvider).language == 'ar'
              ? 'حذف جميع البيانات'
              : 'Delete All Data',
          style: const TextStyle(color: AppColors.secondaryRed),
        ),
        content: Text(
          ref.watch(settingsProvider).language == 'ar'
              ? 'هل أنت متأكد من رغبتك في حذف جميع الفواتير والإعدادات؟ لا يمكن التراجع عن هذا الإجراء.'
              : 'Are you sure you want to delete all invoices and settings? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              ref.watch(settingsProvider).language == 'ar' ? 'إلغاء' : 'Cancel',
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              ref.read(settingsProvider.notifier).clearAllData();
              final dbHelper = GetIt.I<DatabaseHelper>();
              await dbHelper.deleteDatabaseFile();
              await dbHelper.initDb();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ref.read(settingsProvider).language == 'ar'
                          ? 'تم مسح جميع البيانات بنجاح'
                          : 'All data deleted successfully',
                    ),
                  ),
                );
              }
            },
            child: Text(
              ref.watch(settingsProvider).language == 'ar' ? 'حذف' : 'Delete',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isAr = settings.language == 'ar';
    final theme = Theme.of(context);

    final baseCurrency = ref
        .watch(currenciesProvider)
        .firstWhere(
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
    final baseCurrencyName = isAr ? baseCurrency.nameAr : baseCurrency.nameEn;
    final baseCurrencySymbol = isAr
        ? baseCurrency.symbolAr
        : baseCurrency.symbolEn;

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
          title: Text(isAr ? 'الإعدادات' : 'Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: handleBack,
          ),
        ),
        body: Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spaceM),
            children: [
              // Section 1: Localization & App Design
              _buildSectionHeader(
                isAr ? 'المظهر واللغة' : 'Appearance & Language',
                theme,
              ),

              // Language Selection
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.language,
                    color: AppColors.secondaryRed,
                  ),
                  title: Text(isAr ? 'لغة التطبيق' : 'Application Language'),
                  subtitle: Text(isAr ? 'العربية' : 'English'),
                  trailing: DropdownButton<String>(
                    value: ['ar', 'en'].contains(settings.language)
                        ? settings.language
                        : 'ar',
                    underline: const SizedBox(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(settingsProvider.notifier).changeLanguage(val);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                  ),
                ),
              ),

              // Theme Mode
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.dark_mode,
                    color: AppColors.secondaryRed,
                  ),
                  title: Text(isAr ? 'وضع المظهر' : 'Theme Mode'),
                  subtitle: Text(
                    settings.themeMode == 'dark'
                        ? (isAr ? 'داكن' : 'Dark')
                        : settings.themeMode == 'light'
                        ? (isAr ? 'فاتح' : 'Light')
                        : (isAr ? 'تلقائي حسب النظام' : 'System default'),
                  ),
                  trailing: DropdownButton<String>(
                    value: ['light', 'dark', 'system'].contains(settings.themeMode)
                        ? settings.themeMode
                        : 'system',
                    underline: const SizedBox(),
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .changeThemeMode(val);
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'light',
                        child: Text(isAr ? 'فاتح' : 'Light'),
                      ),
                      DropdownMenuItem(
                        value: 'dark',
                        child: Text(isAr ? 'داكن' : 'Dark'),
                      ),
                      DropdownMenuItem(
                        value: 'system',
                        child: Text(isAr ? 'تلقائي' : 'System'),
                      ),
                    ],
                  ),
                ),
              ),

              // Choose App Font Family
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.font_download,
                    color: AppColors.secondaryRed,
                  ),
                  title: Text(isAr ? 'نوع الخط' : 'Font Type'),
                  subtitle: Text(settings.fontFamily),
                  trailing: DropdownButton<String>(
                    value: ['Cairo', 'Tajawal', 'Inter', 'Outfit'].contains(settings.fontFamily)
                        ? settings.fontFamily
                        : 'Cairo',
                    underline: const SizedBox(),
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .changeFontFamily(val);
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'Cairo',
                        child: Text('Cairo (كايرو)'),
                      ),
                      DropdownMenuItem(
                        value: 'Tajawal',
                        child: Text('Tajawal (تجوال)'),
                      ),
                      DropdownMenuItem(
                        value: 'Inter',
                        child: Text('Inter (إنتر)'),
                      ),
                      DropdownMenuItem(
                        value: 'Outfit',
                        child: Text('Outfit (أوتفت)'),
                      ),
                    ],
                  ),
                ),
              ),

              // FontSize Zoom Slider
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spaceS,
                    horizontal: AppTheme.spaceM,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.text_fields,
                                color: AppColors.secondaryRed,
                              ),
                              const SizedBox(width: AppTheme.spaceM),
                              Text(isAr ? 'تكبير الخط' : 'Font Size Zoom'),
                            ],
                          ),
                          Text(
                            'x${settings.fontSizeFactor.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                      Slider(
                        value: settings.fontSizeFactor,
                        min: 0.8,
                        max: 1.4,
                        divisions: 6,
                        activeColor: AppColors.primaryYellow,
                        onChanged: (val) {
                          ref
                              .read(settingsProvider.notifier)
                              .changeFontSizeFactor(val);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spaceM),

              // Section 2: Calendar & Time
              _buildSectionHeader(
                isAr ? 'التقويم والوقت' : 'Calendar & Time',
                theme,
              ),

              // Date Format Selection
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.calendar_month,
                    color: AppColors.secondaryRed,
                  ),
                  title: Text(isAr ? 'صيغة التاريخ' : 'Date Format'),
                  subtitle: Text(
                    settings.dateFormat == 'gregorian'
                        ? (isAr ? 'ميلادي فقط' : 'Gregorian only')
                        : settings.dateFormat == 'hijri'
                        ? (isAr ? 'هجري فقط' : 'Hijri only')
                        : (isAr
                              ? 'الميلادي والهجري معاً'
                              : 'Gregorian & Hijri'),
                  ),
                  trailing: DropdownButton<String>(
                    value: settings.dateFormat,
                    underline: const SizedBox(),
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .changeDateFormat(val);
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'gregorian',
                        child: Text(isAr ? 'ميلادي' : 'Gregorian'),
                      ),
                      DropdownMenuItem(
                        value: 'hijri',
                        child: Text(isAr ? 'هجري' : 'Hijri'),
                      ),
                      DropdownMenuItem(
                        value: 'both',
                        child: Text(isAr ? 'كلاهما' : 'Both'),
                      ),
                    ],
                  ),
                ),
              ),

              // Time Format Selection
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.access_time,
                    color: AppColors.secondaryRed,
                  ),
                  title: Text(isAr ? 'صيغة الوقت' : 'Time Format'),
                  subtitle: Text(
                    settings.timeFormat == '12h'
                        ? (isAr ? '12 ساعة' : '12-hour (AM/PM)')
                        : (isAr ? '24 ساعة' : '24-hour'),
                  ),
                  trailing: DropdownButton<String>(
                    value: settings.timeFormat,
                    underline: const SizedBox(),
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .changeTimeFormat(val);
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: '12h',
                        child: Text(isAr ? '12 ساعة' : '12-hour'),
                      ),
                      DropdownMenuItem(
                        value: '24h',
                        child: Text(isAr ? '24 ساعة' : '24-hour'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spaceM),

              // Section 3: Currency & Financials
              _buildSectionHeader(
                isAr ? 'العملة والمالية' : 'Currency & Financials',
                theme,
              ),

              // Default Currency Selection
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.monetization_on,
                    color: AppColors.secondaryRed,
                  ),
                  title: Text(isAr ? 'العملة الافتراضية' : 'Default Currency'),
                  subtitle: Text(settings.defaultCurrency),
                  trailing: DropdownButton<String>(
                    value:
                        ref
                            .watch(currenciesProvider)
                            .any((c) => c.code == settings.defaultCurrency)
                        ? settings.defaultCurrency
                        : 'SAR',
                    underline: const SizedBox(),
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .changeDefaultCurrency(val);
                      }
                    },
                    items: ref.watch(currenciesProvider).map((c) {
                      return DropdownMenuItem(
                        value: c.code,
                        child: Text(
                          '${c.code} (${c.getSymbol(settings.language)})',
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Add Custom Currency
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.add_card,
                    color: AppColors.secondaryRed,
                  ),
                  title: Text(
                    isAr ? 'إضافة عملة مخصصة' : 'Add Custom Currency',
                  ),
                  subtitle: Text(
                    isAr
                        ? 'إدخال عملة جديدة وسعر صرفها مقابل $baseCurrencyName ($baseCurrencySymbol)'
                        : 'Add new currency with rate relative to $baseCurrencyName ($baseCurrencySymbol)',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAddCurrencySheet(
                    context,
                    ref,
                    isAr,
                    baseCurrency: baseCurrency,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spaceM),

              // Section: Currencies List
              _buildSectionHeader(
                isAr
                    ? 'قائمة العملات وأسعار الصرف'
                    : 'Registered Currencies & Exchange Rates',
                theme,
              ),
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ref.watch(currenciesProvider).length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final currency = ref.watch(currenciesProvider)[index];
                    final isDefault = currency.code == settings.defaultCurrency;
                    final targetSymbol = isAr
                        ? currency.symbolAr
                        : currency.symbolEn;

                    return ListTile(
                      title: Text(
                        '${currency.code} - ${currency.getName(settings.language)}',
                        style: TextStyle(
                          fontWeight: isDefault
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        isAr
                            ? 'الرمز: $targetSymbol | الصرف: 1 $targetSymbol = ${currency.exchangeRate} $baseCurrencySymbol'
                            : 'Symbol: $targetSymbol | Rate: 1 ${currency.code} = ${currency.exchangeRate} $baseCurrencySymbol',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDefault)
                            Chip(
                              label: Text(
                                isAr ? 'الأساسية' : 'Base',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              backgroundColor: Colors.green.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showAddCurrencySheet(
                              context,
                              ref,
                              isAr,
                              currency: currency,
                              baseCurrency: baseCurrency,
                            ),
                          ),
                          if (!isDefault)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.secondaryRed,
                              ),
                              onPressed: () => _confirmDeleteCurrency(
                                context,
                                ref,
                                isAr,
                                currency,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppTheme.spaceM),

              // Section 4: Data Safety & Backups
              _buildSectionHeader(
                isAr
                    ? 'إدارة البيانات والنسخ الاحتياطي'
                    : 'Database & Backup Operations',
                theme,
              ),

              // Default Backup Location Card
              FutureBuilder<Directory?>(
                future: _fetchBackupDirectorySafe(),
                builder: (context, snapshot) {
                  Widget subtitleWidget;
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    subtitleWidget = Row(
                      children: [
                        Text(isAr ? 'جاري التحميل...' : 'Loading...'),
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    subtitleWidget = Text(
                      isAr ? 'خطأ في الحصول على المسار' : 'Error retrieving path',
                      style: const TextStyle(fontSize: 11, color: Colors.red),
                    );
                  } else if (snapshot.hasData && snapshot.data != null) {
                    final path = snapshot.data!.path;
                    subtitleWidget = Text(
                      path,
                      style: const TextStyle(fontSize: 11),
                    );
                  } else if (snapshot.hasError || snapshot.data == null) {
                    subtitleWidget = Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAr ? 'غير متوفر' : 'Unavailable',
                          style: const TextStyle(fontSize: 11, color: Colors.red),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            // Trigger rebuild to retry
                            (context as Element).markNeedsBuild();
                          },
                        )
                      ],
                    );
                  } else {
                    final path = isAr ? 'غير متوفر' : 'Unavailable';
                    subtitleWidget = Text(
                      path,
                      style: const TextStyle(fontSize: 11),
                    );
                  }

                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.folder_special,
                        color: AppColors.primaryYellow,
                      ),
                      title: Text(
                        isAr
                            ? 'مسار النسخ الاحتياطي في الهاتف'
                            : 'Default Device Backup Directory',
                      ),
                      subtitle: subtitleWidget,
                    ),
                  );
                },
              ),

              // Export DB File (Share or Save to Storage)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.upload_file, color: Colors.blue),
                  title: Text(
                    isAr ? 'تصدير نسخة احتياطية' : 'Export Database Backup',
                  ),
                  subtitle: Text(
                    isAr
                        ? 'مشاركة ملف قاعدة البيانات أو حفظه مباشرة في الهاتف'
                        : 'Share or save database backup to storage',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async => await _showExportDatabaseSheet(context, isAr),
                ),
              ),

              // Import DB File
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.download_for_offline,
                    color: Colors.green,
                  ),
                  title: Text(
                    isAr ? 'استيراد قاعدة البيانات' : 'Import Database Backup',
                  ),
                  subtitle: Text(
                    isAr
                        ? 'استرجاع البيانات من نسخة احتياطية محفوظة بالهاتف'
                        : 'Restore data from a saved backup file',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async => await _showImportDatabaseSheet(context, ref, isAr),
                ),
              ),

              // Reset Database
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    color: AppColors.secondaryRed,
                  ),
                  title: Text(
                    isAr ? 'حذف جميع البيانات' : 'Delete All Data',
                    style: const TextStyle(
                      color: AppColors.secondaryRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    isAr
                        ? 'إعادة تعيين التطبيق وحذف السجلات'
                        : 'Wipe all database records and cache',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.secondaryRed,
                  ),
                  onTap: () => _confirmDeleteAll(context, ref),
                ),
              ),

              const SizedBox(height: AppTheme.spaceM),

              // Section 4: Information & Contact
              _buildSectionHeader(
                isAr ? 'حول التطبيق' : 'About & Support',
                theme,
              ),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.info,
                        color: AppColors.secondaryRed,
                      ),
                      title: Text(isAr ? 'إصدار التطبيق' : 'App Version'),
                      subtitle: const Text('1.0.0 (Production Ready)'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.privacy_tip,
                        color: AppColors.secondaryRed,
                      ),
                      title: Text(isAr ? 'سياسة الخصوصية' : 'Privacy Policy'),
                      subtitle: Text(
                        isAr
                            ? 'بياناتك تحفظ محلياً على جهازك'
                            : 'All invoice files and logs stay local to your device',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.contact_mail,
                        color: AppColors.secondaryRed,
                      ),
                      title: Text(isAr ? 'تواصل معنا' : 'Contact Support'),
                      subtitle: const Text('support@example.com'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppTheme.spaceS,
        left: AppTheme.spaceS,
        right: AppTheme.spaceS,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showAddCurrencySheet(
    BuildContext context,
    WidgetRef ref,
    bool isAr, {
    CurrencyModel? currency,
    required CurrencyModel baseCurrency,
  }) {
    final baseSymbol = isAr ? baseCurrency.symbolAr : baseCurrency.symbolEn;
    final baseName = isAr ? baseCurrency.nameAr : baseCurrency.nameEn;

    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController(text: currency?.code ?? '');
    final nameEnController = TextEditingController(
      text: currency?.nameEn ?? '',
    );
    final nameArController = TextEditingController(
      text: currency?.nameAr ?? '',
    );
    final symbolEnController = TextEditingController(
      text: currency?.symbolEn ?? '',
    );
    final symbolArController = TextEditingController(
      text: currency?.symbolAr ?? '',
    );
    final rateController = TextEditingController(
      text: currency?.exchangeRate.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: AppTheme.spaceM,
          right: AppTheme.spaceM,
          top: AppTheme.spaceM,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  currency != null
                      ? (isAr ? 'تعديل العملة' : 'Edit Currency')
                      : (isAr ? 'إضافة عملة جديدة' : 'Add New Currency'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceM),
                TextFormField(
                  controller: codeController,
                  enabled: currency == null,
                  decoration: InputDecoration(
                    labelText: isAr
                        ? 'رمز العملة (مثال: OMR)'
                        : 'Currency Code (e.g. OMR)',
                    helperText: currency != null
                        ? (isAr
                              ? 'رمز العملة الأساسي لا يمكن تعديله'
                              : 'Currency code primary key is read-only')
                        : null,
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? (isAr ? 'مطلوب' : 'Required')
                      : null,
                ),
                const SizedBox(height: AppTheme.spaceS),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: nameArController,
                        decoration: InputDecoration(
                          labelText: isAr ? 'الاسم بالعربية' : 'Name (Arabic)',
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? (isAr ? 'مطلوب' : 'Required')
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceS),
                    Expanded(
                      child: TextFormField(
                        controller: nameEnController,
                        decoration: InputDecoration(
                          labelText: isAr
                              ? 'الاسم بالإنجليزية'
                              : 'Name (English)',
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? (isAr ? 'مطلوب' : 'Required')
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceS),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: symbolArController,
                        decoration: InputDecoration(
                          labelText: isAr
                              ? 'الرمز بالعربية'
                              : 'Symbol (Arabic)',
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? (isAr ? 'مطلوب' : 'Required')
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceS),
                    Expanded(
                      child: TextFormField(
                        controller: symbolEnController,
                        decoration: InputDecoration(
                          labelText: isAr
                              ? 'الرمز بالإنجليزية'
                              : 'Symbol (English)',
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? (isAr ? 'مطلوب' : 'Required')
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceS),
                TextFormField(
                  controller: rateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: isAr
                        ? 'سعر الصرف مقابل $baseName (1 عملة = X $baseSymbol)'
                        : 'Exchange Rate to $baseName (1 unit = X $baseSymbol)',
                    hintText: 'e.g. 3.75',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return (isAr ? 'مطلوب' : 'Required');
                    if (double.tryParse(v) == null)
                      return (isAr ? 'رقم غير صحيح' : 'Invalid number');
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spaceM),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final newCurrency = CurrencyModel(
                      code: codeController.text.trim().toUpperCase(),
                      nameEn: nameEnController.text.trim(),
                      nameAr: nameArController.text.trim(),
                      symbolEn: symbolEnController.text.trim(),
                      symbolAr: symbolArController.text.trim(),
                      exchangeRate: double.parse(rateController.text),
                    );

                    await ref
                        .read(currenciesProvider.notifier)
                        .addCurrency(newCurrency);
                    ref.read(homeDashboardProvider.notifier).loadDashboard();

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            currency != null
                                ? (isAr
                                      ? 'تم تعديل العملة بنجاح'
                                      : 'Currency updated successfully')
                                : (isAr
                                      ? 'تمت إضافة العملة بنجاح'
                                      : 'Currency added successfully'),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    currency != null
                        ? (isAr ? 'حفظ التعديلات' : 'Save Changes')
                        : (isAr ? 'حفظ العملة' : 'Save Currency'),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceM),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteCurrency(
    BuildContext context,
    WidgetRef ref,
    bool isAr,
    CurrencyModel currency,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'حذف العملة' : 'Delete Currency'),
        content: Text(
          isAr
              ? 'هل أنت متأكد من حذف العملة ${currency.code}؟ سيتم استخدام معدل الصرف الافتراضي 1.0 للفواتير المرتبطة بها.'
              : 'Are you sure you want to delete ${currency.code}? Associated invoices will default to an exchange rate of 1.0.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(currenciesProvider.notifier)
                  .deleteCurrency(currency.code);
              ref.read(homeDashboardProvider.notifier).loadDashboard();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isAr
                          ? 'تم حذف العملة بنجاح'
                          : 'Currency deleted successfully',
                    ),
                  ),
                );
              }
            },
            child: Text(isAr ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }
}
