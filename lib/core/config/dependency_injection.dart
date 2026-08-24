import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';
import '../network/api_client.dart';
import '../storage/shared_prefs.dart';
import '../services/image_processor_service.dart';
import '../services/ocr_service.dart';
import '../services/llm_service.dart';
import '../services/export_service.dart';

// Features Imports
import '../../features/invoice/data/datasources/invoice_local_source.dart';
import '../../features/invoice/data/repositories/invoice_repository_impl.dart';
import '../../features/invoice/domain/repositories/invoice_repository.dart';
import '../../features/settings/data/datasources/settings_local_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';

final GetIt sl = GetIt.instance;

/// Sets up and registers all app dependencies.
Future<void> initDependencies() async {
  // 1. Core Utilities & Clients
  final sharedPrefs = await SharedPrefs.init();
  sl.registerSingleton<SharedPrefs>(sharedPrefs);

  final dbHelper = DatabaseHelper();
  await dbHelper.initDb();
  sl.registerSingleton<DatabaseHelper>(dbHelper);

  final httpClient = http.Client();
  sl.registerSingleton<http.Client>(httpClient);

  final apiClient = ApiClient(httpClient);
  sl.registerSingleton<ApiClient>(apiClient);

  // 2. Services
  sl.registerLazySingleton<ImageProcessorService>(() => ImageProcessorService());
  sl.registerLazySingleton<OcrService>(() => OcrService(sl<ApiClient>()));
  sl.registerLazySingleton<LlmService>(() => LlmService(sl<ApiClient>()));
  sl.registerLazySingleton<ExportService>(() => ExportService());

  // 3. Data Sources
  sl.registerLazySingleton<InvoiceLocalSource>(() => InvoiceLocalSource(sl<DatabaseHelper>()));
  sl.registerLazySingleton<SettingsLocalSource>(() => SettingsLocalSource(sl<DatabaseHelper>(), sl<SharedPrefs>()));

  // 4. Repositories
  sl.registerLazySingleton<InvoiceRepository>(() => InvoiceRepositoryImpl(sl<InvoiceLocalSource>()));
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(sl<SettingsLocalSource>()));
}
