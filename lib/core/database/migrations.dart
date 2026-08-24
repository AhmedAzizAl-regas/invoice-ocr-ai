/// DatabaseMigrations manages schema upgrades for the SQLite database.
class DatabaseMigrations {
  DatabaseMigrations._();

  static const int schemaVersion = 4;

  static final Map<int, List<String>> scripts = {
    1: [
      // Settings Table
      '''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
      ''',
      
      // Currencies Table
      '''
      CREATE TABLE IF NOT EXISTS currencies (
        code TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        symbol TEXT NOT NULL
      );
      ''',

      // Invoices Table
      '''
      CREATE TABLE IF NOT EXISTS invoices (
        id TEXT PRIMARY KEY,
        store_name TEXT NOT NULL,
        invoice_number TEXT,
        date TEXT, -- Store in ISO8601
        time TEXT, -- Store in HH:mm
        currency TEXT,
        subtotal REAL DEFAULT 0.0,
        tax REAL DEFAULT 0.0,
        discount REAL DEFAULT 0.0,
        total REAL DEFAULT 0.0,
        payment_method TEXT,
        image_path TEXT,
        ocr_engine TEXT,
        ocr_confidence REAL DEFAULT 0.0,
        raw_text TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (currency) REFERENCES currencies (code)
      );
      ''',

      // Invoice Items Table
      '''
      CREATE TABLE IF NOT EXISTS invoice_items (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL DEFAULT 1.0,
        unit_price REAL DEFAULT 0.0,
        total_price REAL DEFAULT 0.0,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      );
      ''',

      // OCR Logs Table
      '''
      CREATE TABLE IF NOT EXISTS ocr_logs (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        file_path TEXT NOT NULL,
        engine TEXT NOT NULL,
        confidence REAL DEFAULT 0.0,
        raw_text TEXT,
        success INTEGER DEFAULT 1,
        error_details TEXT
      );
      ''',

      // Export Logs Table
      '''
      CREATE TABLE IF NOT EXISTS export_logs (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        file_path TEXT NOT NULL,
        format TEXT NOT NULL,
        status TEXT NOT NULL
      );
      ''',

      // Recent Files Table
      '''
      CREATE TABLE IF NOT EXISTS recent_files (
        id TEXT PRIMARY KEY,
        file_path TEXT NOT NULL,
        imported_at TEXT NOT NULL
      );
      ''',

      // Populating default currencies
      "INSERT OR IGNORE INTO currencies (code, name, symbol) VALUES ('SAR', 'Saudi Riyal', 'ر.س');",
      "INSERT OR IGNORE INTO currencies (code, name, symbol) VALUES ('AED', 'UAE Dirham', 'د.إ');",
      "INSERT OR IGNORE INTO currencies (code, name, symbol) VALUES ('KWD', 'Kuwaiti Dinar', 'د.ك');",
      "INSERT OR IGNORE INTO currencies (code, name, symbol) VALUES ('USD', 'US Dollar', '\$');",
      "INSERT OR IGNORE INTO currencies (code, name, symbol) VALUES ('EUR', 'Euro', '€');",
    ],
    2: [
      // Drop and recreate currencies table to support exchange_rate and dual language symbols
      "PRAGMA foreign_keys = OFF;",
      "DROP TABLE IF EXISTS currencies;",
      '''
      CREATE TABLE currencies (
        code TEXT PRIMARY KEY,
        name_en TEXT NOT NULL,
        name_ar TEXT NOT NULL,
        symbol_en TEXT NOT NULL,
        symbol_ar TEXT NOT NULL,
        exchange_rate REAL NOT NULL DEFAULT 1.0
      );
      ''',
      "INSERT OR IGNORE INTO currencies (code, name_en, name_ar, symbol_en, symbol_ar, exchange_rate) VALUES ('SAR', 'Saudi Riyal', 'ريال سعودي', 'SAR', 'ر.س', 1.0);",
      "INSERT OR IGNORE INTO currencies (code, name_en, name_ar, symbol_en, symbol_ar, exchange_rate) VALUES ('YER', 'Yemeni Rial', 'ريال يمني', 'YER', 'ر.ي', 0.015);",
      "INSERT OR IGNORE INTO currencies (code, name_en, name_ar, symbol_en, symbol_ar, exchange_rate) VALUES ('AED', 'UAE Dirham', 'درهم إماراتي', 'AED', 'د.إ', 1.02);",
      "INSERT OR IGNORE INTO currencies (code, name_en, name_ar, symbol_en, symbol_ar, exchange_rate) VALUES ('KWD', 'Kuwaiti Dinar', 'دينار كويتي', 'KWD', 'د.ك', 12.20);",
      "INSERT OR IGNORE INTO currencies (code, name_en, name_ar, symbol_en, symbol_ar, exchange_rate) VALUES ('USD', 'US Dollar', 'دولار أمريكي', '\$', '\$', 3.75);",
      "INSERT OR IGNORE INTO currencies (code, name_en, name_ar, symbol_en, symbol_ar, exchange_rate) VALUES ('EUR', 'Euro', 'يورو', '€', '€', 4.05);",
      "PRAGMA foreign_keys = ON;",
    ],
    3: [
      "ALTER TABLE invoices ADD COLUMN document_type TEXT DEFAULT 'invoice';",
      "ALTER TABLE invoices ADD COLUMN document_title TEXT;",
      "ALTER TABLE invoices ADD COLUMN sender_name TEXT;",
      "ALTER TABLE invoices ADD COLUMN receiver_name TEXT;",
      "ALTER TABLE invoices ADD COLUMN account_number TEXT;",
      "ALTER TABLE invoices ADD COLUMN branch TEXT;",
      "ALTER TABLE invoices ADD COLUMN notes TEXT;",
      "ALTER TABLE invoices ADD COLUMN employee_name TEXT;",
    ],
    4: [
      "ALTER TABLE invoices ADD COLUMN document_category TEXT DEFAULT 'general';",
      "ALTER TABLE invoices ADD COLUMN detected_language TEXT DEFAULT 'ar';",
      "ALTER TABLE invoices ADD COLUMN dynamic_metadata TEXT;",
      "ALTER TABLE invoices ADD COLUMN table_columns TEXT;",
      "ALTER TABLE invoices ADD COLUMN table_rows TEXT;",
    ],
  };
}
