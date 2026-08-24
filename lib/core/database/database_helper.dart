import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'migrations.dart';

/// DatabaseHelper manages opening, migrating, and query execution on SQLite database.
class DatabaseHelper {
  Database? _db;

  Database get db {
    if (_db == null) {
      throw StateError('Database has not been initialized. Call initDb() first.');
    }
    return _db!;
  }

  /// Initializes the SQLite database and runs migrations.
  Future<void> initDb() async {
    if (_db != null) return;

    final dbDirectory = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbDirectory.path, 'invoice_ocr_ai.db');
    
    _db = sqlite3.open(dbPath);
    
    // Enable Foreign Keys
    _db!.execute('PRAGMA foreign_keys = ON;');
    
    _runMigrations();
  }

  /// Internal migration manager checking user_version and applying scripts.
  void _runMigrations() {
    final userVersionResult = _db!.select('PRAGMA user_version;');
    int currentVersion = 0;
    if (userVersionResult.isNotEmpty) {
      currentVersion = userVersionResult.first['user_version'] as int;
    }

    final targetVersion = DatabaseMigrations.schemaVersion;
    if (currentVersion < targetVersion) {
      // Temporarily disable foreign keys outside the transaction to allow schema changes
      _db!.execute('PRAGMA foreign_keys = OFF;');

      try {
        for (int v = currentVersion + 1; v <= targetVersion; v++) {
          final queries = DatabaseMigrations.scripts[v];
          if (queries != null) {
            _db!.execute('BEGIN TRANSACTION;');
            try {
              for (final query in queries) {
                _db!.execute(query);
              }
              _db!.execute('PRAGMA user_version = $v;');
              _db!.execute('COMMIT;');
            } catch (e) {
              _db!.execute('ROLLBACK;');
              rethrow;
            }
          }
        }
      } finally {
        // Always re-enable foreign keys outside transaction
        _db!.execute('PRAGMA foreign_keys = ON;');
      }
    }
  }

  /// Closes database connection.
  void close() {
    _db?.dispose();
    _db = null;
  }

  /// Closes database, deletes the file, and resets state.
  Future<void> deleteDatabaseFile() async {
    close();
    final dbDirectory = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbDirectory.path, 'invoice_ocr_ai.db');
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Raw query executor wrapper
  void execute(String sql, [List<Object?> parameters = const []]) {
    db.execute(sql, parameters);
  }

  /// Raw select query runner
  ResultSet select(String sql, [List<Object?> parameters = const []]) {
    return db.select(sql, parameters);
  }
}
