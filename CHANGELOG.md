# Changelog

All notable production-readiness changes are tracked here.

## 2.4.19

- Fixed missing-provider crashes on checkout, receipts, and expenses by bootstrapping all root providers in `main()` before `runApp` (providers are now injected via `ChangeNotifierProvider.value` with memoized `init()`).
- Migrated navigation from provider re-wraps to go_router.
- Reorganized `lib` into feature folders; moved data models to `lib/models`.
- Replaced the legacy `Lists` provider with dedicated `LogProvider`, `OwnerProvider`, and `ShareProvider`; removed duplicate/dead providers (`LoanProvider`, `StatsProvider`, `SyncProvider`).
- Extracted stats cache, stats pooled jobs, and backup/restore into `data/stats` and `data/backup` services.
- Removed dead code: Postgres sync client, legacy Hive-era models, unused provider members, dead DB methods, and unused dependencies (`percent_indicator`, `postgres`).

## 2.4.18

- Inventory page now refreshes deterministically after editing a product: the DB write is awaited before listeners are notified, removing the intermittent stale-tile race.
- New products added from the inventory page now appear in the grid immediately (insert also notifies inventory listeners after persisting).

## 2.4.17

- Loaner debt window now counts hot products at sell price (`logLoanedValue`), so the window/current value step correctly.
- Replaced the loaner comparison chart with a diverging profit/loss chart (green = loaner still owes tracked value, red = loaner overpaid).
- Fixed null-offer crash when editing a receipt that contains hot products.
- Fixed buy/sell mismatch: editing or canceling a receipt now subtracts hot products at sell price, matching checkout.
- Sell page now refreshes immediately after a receipt edit restores products to the cart.

## 2.4.16

- Fixed monthly loans calculation: credit sales no longer double-counted as payments in `_calculateTotalPayments`.
- Fixed account statement same filtering bug.
- Relabeled monthly loans to "صافي ديون هذا الشهر" to clarify negative = net repayment.
- Added AGENTS.md with standardized commit/push/release workflows for agents.
- Pre-download Isar native library in CI to fix integration test failures.
- Tagged all integration tests with `@Tags(['integration'])`.

## 2.4.15

- Added priceHistory-based profit recalculation: each sale now uses the next restock's buy price instead of the current product buyprice.
- Added LoanerComparison chart on StatsPage showing original sell price vs current buy price per loaner.
- Added yearly inflation rate (نسبة تغير أسعار الشراء) to StatsPage.
- Consolidated yearly profit, sales, and inflation into a single `CgetYearlyTotals` pooled job.
- Added `verify_profit.dart` CLI script for manual profit trace verification against the live database.
- Updated all profit pooled jobs (monthly, daily, daily-of-month, monthly-of-year) to use priceHistory.
- Unit tests added for `recalculateProfit()` covering empty logs, priceHistory lookups, hot skip, discount, and fallback scenarios.

## 2.4.7

- Added production GitHub release builds for Android, Windows, and Linux.
- Added Android release signing through GitHub secrets.
- Added Windows Inno Setup installer with `Golden` as publisher.
- Added Linux AppImage, `.deb`, and `tar.gz` release outputs.
- Hardened Appwrite configuration by moving production values to build-time defines.
- Reworked auth to avoid plaintext offline credentials and support intentional offline login.
- Hardened database initialization, checkout failures, validation, and backup restore safety.
- Hardened LAN sync with pairing codes, file allowlisting, transfer timeouts, and hash verification.
- Added real tests for checkout, inventory, loans, expenses, backup/restore, auth policy, widgets, and smoke integration.
- Started Phase 11 documentation, Arabic-first copy, accessibility, and icon polish.
- Added disabled-by-default Sentry observability hooks, redacted app logging, and safer user-facing error messages.

## Earlier Releases

- Initial Flutter implementation for shop sales, inventory, expenses, loans, reports, backups, and sync.
