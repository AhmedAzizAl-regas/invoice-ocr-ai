# Implementation Plan - Fully Dynamic Base Currency & Exchange Rate Management

We will expand the currency system to allow full user control:
1. **Dynamic Base Currency**: The user can set any currency as the default base currency. Total spend calculations on the dashboard will automatically convert all invoice totals to the selected base currency dynamically.
2. **Pre-populated Currencies**: Ensure SAR, AED, KWD, USD, EUR, and YER are pre-populated with default exchange rates.
3. **Currency Editing**: Allow users to edit currency names, symbols, and exchange rates.
4. **Currency Deletion**: Allow users to delete custom or default currencies (except the currently selected default base currency).

## User Review Required
> [!IMPORTANT]
> - Deleting a currency that is currently referenced by existing invoices will prevent foreign-key constraints from failing by setting a default fallback or restricting deletion. We will add a warning dialog if the currency is used.
> - Calculations will convert via a common anchor (relative rates) so that the user does not have to re-enter all exchange rates when changing the default currency.

---

## Proposed Changes

### Repository & Datasources

#### [MODIFY] [invoice_local_source.dart](file:///c:/laragon/www/invoice_ocr_ai/lib/features/invoice/data/datasources/invoice_local_source.dart)
- Update `getStatistics(String baseCurrencyCode)` to accept the target base currency code.
- Implement currency deletion `deleteCurrency(String code)`.

#### [MODIFY] [invoice_repository.dart](file:///c:/laragon/www/invoice_ocr_ai/lib/features/invoice/domain/repositories/invoice_repository.dart)
- Update signature: `Future<Map<String, dynamic>> getStatistics(String baseCurrencyCode)`.
- Add declaration: `Future<void> deleteCurrency(String code)`.

#### [MODIFY] [invoice_repository_impl.dart](file:///c:/laragon/www/invoice_ocr_ai/lib/features/invoice/data/repositories/invoice_repository_impl.dart)
- Update implementations matching repository changes.

### State Providers

#### [MODIFY] [currencies_provider.dart](file:///c:/laragon/www/invoice_ocr_ai/lib/features/settings/presentation/providers/currencies_provider.dart)
- Add `deleteCurrency(String code)` method.
- Add `editCurrency(CurrencyModel)` method.

#### [MODIFY] [home_provider.dart](file:///c:/laragon/www/invoice_ocr_ai/lib/features/home/presentation/providers/home_provider.dart)
- Pass `settings.defaultCurrency` to `getStatistics()` during loading.

### Presentation UI

#### [MODIFY] [settings_page.dart](file:///c:/laragon/www/invoice_ocr_ai/lib/features/settings/presentation/pages/settings_page.dart)
- Build a currency management list inside settings showing all registered currencies.
- Provide inline actions to:
  - **Edit** (edit symbol, rate, names via bottom sheet).
  - **Delete** (delete currency, checking that it is not the active default base currency).
- Display rates and symbols dynamically in list tiles.
