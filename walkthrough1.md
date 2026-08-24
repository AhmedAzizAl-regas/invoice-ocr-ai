# Walkthrough - Invoice OCR AI Implementation

We have successfully built **Invoice OCR AI**, a production-ready, highly responsive Flutter application using Clean Architecture, a Feature-first structure, Riverpod for State Management, GoRouter for Routing, GetIt for Dependency Injection, and SQLite3 for local persistence.

---

## Architectural Layout

The application has been modularized according to the requested layout:

```
lib/
├── core/
│   ├── config/
│   │   ├── app_branding.dart          # Dynamic Logo CustomPainter and branding metadata
│   │   ├── app_config.dart            # API keys and threshold settings
│   │   └── dependency_injection.dart  # GetIt singletons registry (clients, database, repositories, services)
│   ├── database/
│   │   ├── database_helper.dart       # SQLite database helper wrapping connections and transactions
│   │   └── migrations.dart            # SQL DDL schemas for settings, invoices, logs, etc.
│   ├── network/
│   │   └── api_client.dart            # Base HTTP client with error handling
│   ├── router/
│   │   └── app_router.dart            # GoRouter configurations matching pages
│   ├── services/
│   │   ├── export_service.dart        # Excel, CSV, PDF, and OpenXML ZIP-based Docx generator
│   │   ├── image_processor_service.dart# Pure Dart OpenCV filters (noise, contrast, shadows, cropping)
│   │   ├── llm_service.dart           # Gemini & OpenAI JSON structurer API calls
│   │   └── ocr_service.dart           # Cascading local & cloud OCR manager
│   ├── theme/
│   │   ├── app_colors.dart            # Light/Dark HSL Yellow/Red palette colors
│   │   ├── app_text_styles.dart       # Responsive, scaling Arabic and English fonts
│   │   └── app_theme.dart             # Unified theme configuration (cards, dialogs, buttons, tables)
│   └── utils/
│       └── date_formatter.dart        # Dual Gregorian/Hijri converter and time formatter
└── features/
    ├── home/                          # Home dashboard analytics and scan buttons
    ├── history/                       # Invoices history database with search, sort, and deletion
    ├── scanner/                       # Image filter toggles and preview
    ├── ocr/                           # OCR progress detail logging
    ├── invoice/                       # Invoice reviewer edit form, calculations, and items table
    └── settings/                      # Preferences, localizations, database exports, and wipe data
```

---

## Technical Highlights

1. **Resilient Multi-Stage Cascading OCR Pipeline**:
   Coordinated inside [ocr_service.dart](file:///c:/laragon/www/invoice_ocr_ai/lib/core/services/ocr_service.dart). It runs local **Google ML Kit OCR**. If text confidence does not reach the specified threshold, it falls back to local **Tesseract OCR**. If confidence remains low, it calls the cloud **Google Vision Cloud API** or **Azure OCR API** in sequence. Finally, the extracted raw text is structured into a clean JSON invoice format using **Gemini or OpenAI APIs** inside [llm_service.dart](file:///c:/laragon/www/invoice_ocr_ai/lib/core/services/llm_service.dart).

2. **OpenCV-Style Processing**:
   Developed inside [image_processor_service.dart](file:///c:/laragon/www/invoice_ocr_ai/lib/core/services/image_processor_service.dart). It runs noise reduction, orientation alignment, background lighting subtraction (shadow removal), contrast adjustments, auto-cropping, and convolution sharpening using pure-Dart image filters executed in background isolates to ensure smooth performance across all mobile/desktop platforms without compiling CMake files.

3. **Premium Theming & Responsive Layouts**:
   Integrated HSL Yellow/Red/Black/White styling tokens within [app_theme.dart](file:///c:/laragon/www/invoice_ocr_ai/lib/core/theme/app_theme.dart) and [app_colors.dart](file:///c:/laragon/www/invoice_ocr_ai/lib/core/theme/app_colors.dart). All views adapt dynamically across standard Breakpoints (Phone <600, Tablet 600-1023, Desktop 1024+) in both Portrait and Landscape without Overflow errors.

4. **Multi-Format Document Exporter**:
   Implemented inside [export_service.dart](file:///c:/laragon/www/invoice_ocr_ai/lib/core/services/export_service.dart). It handles file exports to Excel (.xlsx), CSV, PDF, and creates Microsoft Word (.docx) documents manually via in-memory OpenXML ZIP archives.

---

## Validation Results

We wrote unit tests in [widget_test.dart](file:///c:/laragon/www/invoice_ocr_ai/test/widget_test.dart) to verify:
- Accurate Gregorian to Hijri calendar algorithms.
- Custom 12h/24h time formatting under English and Arabic locales.

All tests compile and pass successfully:
```
All tests passed!
```

---

## Latest Updates (Phase 2 & 3)

1. **Azure OCR Engine Deletion**:
   - Removed all references to Azure API key and endpoints from the configuration and UI.
   - Simplified the OCR cascade pipeline to rely on Google ML Kit -> Tesseract -> Google Vision -> LLM fallback.

2. **File Sharing & PDF Cache Resolution**:
   - Resolved the file lock/caching issue on share sheets by introducing millisecond timestamping to all exported files.
   - Configured document files to be dynamically named in the format: `[StoreName]_[Date]_[Timestamp].[extension]` for easier file identification and device savings.

3. **Dynamic Currency & Exchange Rate System**:
   - Upgraded database migration schemas to version 2, incorporating dual-language symbols and exchange rates.
   - Pre-populated the system with default currencies (SAR, YER, AED, KWD, USD, EUR) with exchange rates relative to the base currency **SAR** (Saudi Riyal).
   - Designed settings dropdowns and an **"Add Custom Currency"** bottom sheet form, allowing users to enter custom currencies (e.g., Yemeni Rial or others) with symbols in both English/Arabic and custom rates.
   - Modified statistical calculations to dynamically convert all invoice sums into the base currency (SAR) before summing, showing exact expenses localized dynamically (`ر.س` or `SAR`) according to the active language settings.

---

## Compilation Fixes Applied

We resolved all the compiler issues found by `flutter analyze`:
1. **Excel Cell Values**: Migrated `CellValue.value` calls to explicit sealed type subclasses (`TextCellValue` and `DoubleCellValue`) complying with the latest version of the `excel` package.
2. **Image Preprocessing Filters**: Fixed the sharpening function call from `img.convolve` to `img.convolution` matching the updated `image` package API.
3. **Card & Dialog Themes**: Adjusted theme argument types from `CardTheme` and `DialogTheme` to `CardThemeData` and `DialogThemeData` in `app_theme.dart`.
4. **Layout Parameter Correctness**: Repaired formatting errors inside `export_service.dart` by modifying `cross` and `main` parameters in row/column builders of the `pdf` package to `crossAxisAlignment` and `mainAxisAlignment`.
5. **Dynamic Imports Resolution**: Updated all invalid relative page imports with safe, clean, absolute package imports (e.g. `import 'package:invoice_ocr_ai/...'`).
6. **DI Package Links**: Added missing explicit direct dependencies for `google_mlkit_text_recognition`, `flutter_tesseract_ocr`, and `archive` packages in `pubspec.yaml` to ensure reliable builds.
