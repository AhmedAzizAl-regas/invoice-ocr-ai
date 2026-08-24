import 'package:go_router/go_router.dart';

// Screens imports
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/scanner/presentation/pages/scanner_page.dart';
import '../../features/ocr/presentation/pages/ocr_page.dart';
import '../../features/invoice/presentation/pages/invoice_detail_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

/// AppRouter defines the central navigation layout for Invoice OCR AI.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return ScannerPage(imagePath: path);
        },
      ),
      GoRoute(
        path: '/ocr',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return OcrPage(imagePath: path);
        },
      ),
      GoRoute(
        path: '/invoice/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return InvoiceDetailPage(invoiceId: id);
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}
