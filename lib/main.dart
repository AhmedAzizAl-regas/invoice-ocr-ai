import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/dependency_injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Run Dependency Injection Container Init (which opens DB, reads shared prefs cache, and boots services)
  await initDependencies();

  runApp(const ProviderScope(child: InvoiceOcrAiApp()));
}

class InvoiceOcrAiApp extends ConsumerWidget {
  const InvoiceOcrAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch settings provider for runtime updates (language, theme mode, font family, scaling factors)
    final settings = ref.watch(settingsProvider);

    final isDark =
        settings.themeMode == 'dark' ||
        (settings.themeMode == 'system' &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    // Dynamic localization configurations
    final locale = Locale(settings.language);

    return MaterialApp.router(
      title: 'Invoice OCR AI',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,

      // Theme settings
      themeMode: settings.themeMode == 'dark'
          ? ThemeMode.dark
          : settings.themeMode == 'light'
          ? ThemeMode.light
          : ThemeMode.system,

      theme: AppTheme.buildTheme(
        isDark: false,
        locale: settings.language,
        fontSizeFactor: settings.fontSizeFactor,
        customFont: settings.fontFamily,
      ),

      darkTheme: AppTheme.buildTheme(
        isDark: true,
        locale: settings.language,
        fontSizeFactor: settings.fontSizeFactor,
        customFont: settings.fontFamily,
      ),

      // Localization delegates
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
