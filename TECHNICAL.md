# Dukkan — Technical Reference

This document is the deep technical reference for feature agents working on Dukkan. It
describes the architecture, data layer, providers, pages, key business logic, testing,
and known code-level gotchas. It complements `AGENTS.md` (workflows and conventions).

> Developer docs are English-first. User-facing UI strings are Arabic-first (see
> README "Product Language"). Keep code comments minimal.

---

## 1. Project Overview

Dukkan (دكان) is a Flutter retail shop management app for sales, inventory, loans,
expenses, reporting, backups, and peer-to-peer LAN data sharing.

**Stack**

- Flutter (pinned `3.41.9` in CI) + Dart SDK `>=3.0.5 <4.0.0`
- `isar_community` (Isar DB, version 3.3.2) for local persistence
- `provider` (ChangeNotifier) for state management
- `isolate_pool_2` for heavy/background DB computations
- Appwrite Cloud backend for auth, user prefs, and file storage
- Optional Sentry crash reporting (`SENTRY_DSN` build define)
- `dio`, `crypto`, `screenshot`/`image`/`pdf`/`printing`, `mobile_scanner`, `qr_flutter`

**Platforms**

- Android (APK/AAB), Windows (Inno Setup installer), Linux (AppImage/.deb/tar.gz).
- iOS is not a current production target.

**Versioning**: `major.minor.patch+build` in `pubspec.yaml` (currently `2.4.18+1`).
Work happens on branch `hot`; PRs go `hot` → `master`.

### App entry flow (`lib/main.dart`)

1. `main()` → `AppLogger.bootstrap(...)` (initializes Sentry + global error handlers).
2. `DB.initialize()` — opens the local Isar database (singleton).
3. `runApp(MyApp)` → `MaterialApp` (brown Material 3 theme) → `AnimatedSplashScreen`.
4. Splash resolves to a `MultiProvider` tree registering **11 providers**:
   `AuthAPI`, `ExpenseProvider`, `SalesProvider`, `LoanProvider`, `StatsProvider`,
   `InventoryProvider`, `LogProvider`, `OwnerProvider`, `ShareProvider`, `SyncProvider`,
   and legacy `Lists` (kept "for backward compatibility during migration").
5. The `builder` is the **auth gate**: `AuthStatus.uninitialized` → spinner;
   `authenticated` → `LandingPage` if no weight precision is set, else `HomePage`;
   otherwise `LoginPage`.
6. `SalesProvider.onInventoryChanged` is wired to `Lists.clearAllCache` (any inventory
   write invalidates the legacy stats cache).

---

## 2. Architecture & Data Flow

### Layers

```
Pages (lib/pages/, lib/util/*.dart widgets)
   │  read/watch
   ▼
Providers (lib/providers/)  ── legacy Lists + focused providers
   │  delegate
   ▼
DB (lib/core/db.dart)  +  PooledJob (Cget*) classes scheduled on isolate_pool_2
   │
   ▼
Isar (isar_community)   ── 5 collections in a single file: isarInstance.isar
```

### The two provider generations (important!)

- **`Lists` (`lib/providers/list.dart`)** is the **legacy central provider**. It owns
  stats caching (`getCachedCalculation`, `cacheVersion`), checkout/cancel/edit of
  receipts, LAN sync (`runServer`/`client`/`cancelSync`), owners, low-stock, and stream
  helpers. **Most pages still consume `Lists`.**
- **Newer focused providers** exist and are registered in `main.dart`, but only
  `SalesProvider`, `ExpenseProvider`, `InventoryProvider`, and `AuthAPI` are actually
  consumed by pages today. `StatsProvider`, `LoanProvider`, `LogProvider`,
  `OwnerProvider`, `ShareProvider`, `SyncProvider` are registered (and used by tests)
  but have **no page consumers** — their logic is duplicated in `Lists` and
  `SalesProvider`. See §8 (Gotchas).

### Navigation idiom

`MultiProvider` only wraps the root widget. Every pushed route re-wraps its child with
`ChangeNotifierProvider.value(...)` to carry providers across `Navigator.push`. When
adding a page that needs providers, follow this pattern.

---

## 3. Data Layer (Isar)

### `DB` class (`lib/core/db.dart`, ~2265 lines)

Singleton (`DB.getInstance()`), lazy singleton init guarded against races. Holds the
live `Isar` instance named `isarInstance` in the app documents directory.

Key members:

- `createForTesting(directoryPath, name)` / `resetForTesting()` — `@visibleForTesting`,
  used by all tests.
- `_openIsar` / `openIsarSafely` — open with fallback to an existing instance; logs
  failures via `AppLogger`.
- Backup/restore: `createLocalBackup()` (copies live `.isar` file), `useLocalBacup()`,
  `windows()`, `_replaceLiveIsarWithFile` (verifies the incoming file, swaps with a
  `.bak` fallback), `_verifyIsarFile` (opens a temp copy to validate), `exportData` /
  `importData` (JSON logs).
- `closeAllIsarInstances` / `reOpenPool` — stop/restart the isolate pool (used during
  DB file replacement).
- Write helpers: `insertProducts`, `updateProducts`, `deleteProduct`, `checkOut`,
  `cancelReceiptAtomically`, `inboundReceipt`, loaner ops, expense ops.
- Stream/watch helpers: `getExpenses`, `watchExpense`, `watchLoaner`, `watchProduct`,
  `getTotalBuyPrice`, `getLoanersStream`, `getLogsStream`, `getPersonsLogs`,
  `getLogsChunk`.

### Collections (the 5 Isar schemas)

All `.g.dart` files are build_runner generated — regenerate with
`dart run build_runner build` after changing a model.

| Collection | File | Notes |
|---|---|---|
| `Product` | `lib/util/models/Product.dart` | catalog item + `hot` ad-hoc items |
| `Log` | `lib/util/models/Log.dart` | sale/inbound receipt |
| `Loaner` | `lib/util/models/Loaner.dart` | customer with balance |
| `Owner` | `lib/util/models/Owner.dart` | supplier/owner due money |
| `Expense` | `lib/util/models/Expense.dart` | fixed/recurring expense |

#### `Product`

- `id` auto-increment; `name` has a **unique** index (case-insensitive, value, replace).
- `buyprice`, `sellPrice`, `count` (indexed), `weightable`, `wholeUnit`, `offer`,
  `offerCount`, `offerPrice`, `endDate`, `hot`.
- `priceHistory` — `List<Emap>` (buy/sell/date snapshots, used for profit
  recalculation).
- `hot == true` means an **ad-hoc/quick-sale item not in the catalog** (no reliable buy
  price, no stock tracking). Hot items are excluded from profit math and stock updates.
- `validateForCreate()` — returns an Arabic error string or null.
- Constructors: `Product()` (empty), `Product.named(...)`, `Product.named2(...)`
  (with id; used in tests and cash logic). Prefer `Product.named2` when id matters.
- `toEmbedded()` snapshots a sale line into `EmbeddedProduct`; note it computes the
  sale price as `offerPrice` only when `offer && count % offerCount == 0`.

`@embedded EmbeddedProduct`: `name`, `productId`, `buyPrice`, `sellPrice`, `count`,
`hot`, `endDate` — the line items stored inside a `Log`.

#### `Log` (receipt)

- Unique indexed `date` — **a receipt's identity for editing is its timestamp.**
- `price`, `profit`, `discount`, `products` (`List<EmbeddedProduct>`), `loaned`,
  `loanerID`, `expense`, `expenseId`.
- `Log.named2(...)` used everywhere; `toMap`/`fromMap` used for JSON backup export.

#### `Loaner`

- `name` (indexed), `ID` (auto-increment), `phoneNumber`, `location`, `balance`
  (DB column `loanedAmount` via `@Name`), `zeroingDate`.
- `lastPayment` — `List<EmbeddedMap>` acting as a **payment/ledger history**.

`@Embedded EmbeddedMap`: `key` (ISO date string), `value` (amount string), `remaining`
(balance after), `type`, `notes`. `type` values: `sale`, `payment`, `withdraw`,
`reset`, `cancel`.

#### `Owner`

`ownerName` (indexed), `lastPaymentDate`, `lastPayment`, `totalPayed`, `dueMoney`.
Used to track money owed to suppliers/owners for consigned products. (Note: `Lists` /
`OwnerProvider` currently have no working `updateOwner`.)

#### `Expense`

`ID` (unique, replace), `name`, `amount`, `period` (30=monthly, 7=weekly, 1=daily,
0=unspecified), `payDate`, `fixed`, `lastCalculationDate`.

`@embedded Emap`: `buyPrice`, `sellPrice`, `date` — used inside `priceHistory`.

### The isolate pool pattern (`Cget*` jobs)

Heavy read-only computations run on a pool of background isolates
(`isolate_pool_2`), sized `(Platform.numberOfProcessors ~/ 2) - 1` (`Pool.init()` in
`lib/core/IsolatePool.dart`).

Every pooled job class (defined in `lib/core/db.dart`) follows this exact shape:

1. Constructor takes a `Map` where `map['1']` is the `RootIsolateToken` (passed from the
   provider) and `map['2']` is often a date/query param.
2. `job()` calls `BackgroundIsolateBinaryMessenger.ensureInitialized(map['1'])`.
3. It (re)opens the `isarInstance` database in the worker isolate
   (`Isar.open(...)` with a fallback to `DB.openIsarSafely` / existing instance).
4. Computes and returns; on failure logs `AppLogger.warning(...)` (area `stats.*`) and
   returns a sentinel (`-1`, `[]`, `0`).

Examples: `CgetYearlyTotals`, `CgetProfitOfTheMonth`, `CgetDailySales`,
`CgetMonthlyloans`, `getTotalExpenseNow`, `CgetSalesPerProduct` (has its own static
`_cachedStats`), `CgetLowStockItemsPerMonth`, `CgetLoanerComparison`.

### Profit model (`recalculateProfit`)

`recalculateProfit(logs, productMap)` in `db.dart`:

- Skips `hot` products (no reliable buy price).
- Resolves the historical buy price per sale line from the product's `priceHistory`:
  the nearest `Emap` entry with `date >= log.date`; else falls back to current
  `buyprice`, then `ep.buyPrice`.
- `profit += (sellPrice - buyPrice) * count` per line, then `total -= log.discount`.

`CgetYearlyTotals` also computes yearly inflation from `priceHistory` (average change
of buy price from start-of-year to current).

---

## 4. Providers

### `AuthAPI` — `lib/providers/onlineProvider.dart`

Appwrite auth + storage facade. `AuthStatus { uninitialized, authenticated,
unauthenticated }`.

- Auth: `createUser`, `sendVerification`, `confirmVerification`, `anonymosSignIn`,
  `createEmailSession`, `signInWithProvider` (google/github; desktop uses
  `FlutterWebAuth2` with callback `http://localhost:43871/oauth2`), `signOut`.
- **Offline sessions**: `checkOfflineSession()` reconstructs an in-memory `User` from
  `FlutterSecureStorage` within a 3-day window; a self-restarting 5-minute timer
  (`_startRevalidationTimer`) flips `isOffline` back off once `account.get()` succeeds.
- Preferences/subscription: `getUserPreferences`, `updatePreferences`,
  `setSubscriptionPlan(days)`, `getSubscriptionStatus` (Appwrite user prefs).
- Backup: `uploadBackup()` / `downloadBackup()` of the live `.isar` file to Appwrite
  Storage bucket (file id `backup_{userId}.isar`, delete-then-upload).
- `uploadPaymentReceipt(...)` is an **empty no-op stub** (see Gotchas).

Consumed by: auth gate in `main.dart`, `LoginPage`, `register_page`, `verifyPage`,
`landingPge`, `AccountPage`, `util/drawer.dart`.

### `SalesProvider` — `lib/providers/salesProvider.dart`

The workhorse provider (cart, inventory, loaners, parking, prefs). `with
ChangeNotifier, WidgetsBindingObserver`. Hooks `onInventoryChanged` → `Lists.clearAllCache`.

- **Cart**: `sellList` (sale cart), `inboundList` (inbound stock batch), `searchTemp`.
  `parkCurrentCart` / `restoreCart` / `deletePendingCart` (persist to SharedPreferences
  key `pendingCarts` as JSON, capped at `maxPendingCarts = 5`). The current `sellList`
  is persisted to prefs on app pause/detach.
- **Products**: `refreshProductsList`, `updateProduct`, `insertProducts`,
  `removeProduct`, `getProductCount(id)` (sync; returns `999` when missing),
  `isProductOutOFStock` (**inverted logic**), `isProductOutOfDate`.
- **Search**: `search(keyWord, sales, barcode)` — barcode-exact when `sales/barcode`
  set; name/barcode contains otherwise; sorting depends on context (fast sellers first
  for sales, low stock first for inventory).
- **Loaners**: `refreshLoanersList`, `addLoaner`, `deleteLoaner`, `getLoanerName`,
  `getLoanersStream`, `watchLoaner`, `watchProduct`, ledger ops
  `payLoaner(cash, ID)`, `withdrawFromBalance(cash, ID)`, `resetLoanerAcount(ID)`
  (append `EmbeddedMap` with type `payment`/`withdraw`/`reset`).
- **Prefs**: `get/setWeightPrececsion`, `get/setStoreName` (SharedPreferences).
- Weight unit maps: `kg`, `pound`, `toumna` (Arabic labels → grams).

Consumed by: `SellPage`, `homePage`, `CheckOutPage`, `InsertPage`, `inventoryPage`,
`searchPage`, `settingsPage`, `Logs`, `loans`, `paymentVerficaion`, and many `util/`
widgets.

### `ExpenseProvider` — `lib/providers/expense_provider.dart`

- `watchExpense(id)`, `getIndvidualExpenses({fixed})`, `addExpense(...)`,
  `deleteExpense(id)`.
- Pooled stats: `getProfitOfTheMonth`, `getLoansOfMonth` (`CgetMonthlyloans`),
  `getDailyLoans` (`CgetDailyloans`), `getTotalExpenses` (`getTotalExpenseNow`).
- `getRealProfit()` = monthly profit − monthly loans − total expenses.

Consumed by: `spendings`, `spending`, `addExpense`, `CheckOutPage`, `SellPage`,
`landingPge`, `paymentVerficaion`, `util/inboundReceipt.dart`, `util/drawer.dart`.

### `InventoryProvider` — `lib/providers/inventory_provider.dart`

`search`, `searchByBarcode`, `embeddedToProduct`, `getAllProducts`,
`watchProducts` (lazy watch), `getLowStockItems({thresholdPercent = 0.25})`.

Consumed by: `lowStockItemesPage`, `util/drawer.dart`.

### `Lists` (legacy central) — `lib/providers/list.dart`

`ChangeNotifier with LanSyncState`. Holds owners/logs lists, the stats `_cache`
(`getCachedCalculation` + `cacheVersion`), and LAN sync state.

- Stats (all pooled): `getYearlyTotals`, `getAllProfit`, `getAllSales`,
  `getAverageProfitPercent`, `getYearlyInflation`, `getProfitOfTheMonth`,
  `getSalesOfTheMonth`, `getDailySales`, `getDailyProfits`, `getNumberOfSalesForAproduct`,
  `getSaledProductsByDate`, `getSalesPerProduct`, `getLoanerComparison`,
  `getDailySalesOfTheMonth`, `getDailyProfitOfTheMonth`, `getMonthlySalesOfTheYear`,
  `getMonthlyProfitsOfTheYear`.
- Receipts: `checkOut(...)`, `cancelReceipt(date, log)` (atomic), `editReceipt(date, log)`,
  `getLogsStream`, `getLogsChunk`, `getPersonsLogs`.
- Products/owners: `getTotalBuyPrice`, `embeddedToProduct`, `getLowStockItems`,
  `addOwner`, `refreshListOfOwners`, `updateOwner` (**no-op**).
- LAN sync: `runServer()`, `client(input)`, `cancelSync()` (see §5 LAN sync).

Consumed by: `StatsPage`, `homePage`, `SellPage`, `CheckOutPage`, `InsertPage`,
`inventoryPage`, `Logs`, `loans`, `landingPge`, `paymentVerficaion`, `util/share.dart`.

### Registered-but-unused by pages

`StatsProvider`, `LoanProvider`, `LogProvider`, `OwnerProvider`, `ShareProvider`,
`SyncProvider` — registered in `main.dart` and used by tests, but no page consumes
them; their logic is duplicated in `Lists`/`SalesProvider`. Do not assume they are
"the" implementation for a feature — check where pages actually read state.

---

## 5. Pages & Key User Flows

| Page | File | Purpose |
|---|---|---|
| `LandingPage` | `pages/landingPge.dart` | First-run onboarding: store name, scale precision, subscription plan → `PaymentVerificationPage` |
| `HomePage` | `pages/homePage.dart` | Auth shell: TabBar (Sell + Stats), drawer, barcode/logs/inventory/share actions |
| `SellPage` | `pages/SellPage.dart` | Cart editor tab; grid/list, parking dialog, open invoice |
| `CheckOut` | `pages/CheckOutPage.dart` | Invoice confirmation; cash / debt (loaner) / expense payment; discount |
| `InPage` | `pages/InsertPage.dart` | Product create/edit form (whole-unit aware) |
| `InvPage` | `pages/inventoryPage.dart` | Inventory grid, capital total, add owner/product |
| `Loans` | `pages/loans.dart` | Debt overview + loaner list; FAB adds loaner |
| `Loan` | `util/loan.dart` | Loaner detail: balance card, deposit/withdraw, invoices |
| `BankStatementPage` | `pages/accountStatement.dart` | Per-loaner statement ledger + PDF/text export |
| `StatsPage` | `pages/StatsPage.dart` | KPI cards + charts dashboard |
| `Logs` | `pages/Logs.dart` | Invoice history with search/date/loaner filters, chunked infinite scroll |
| `Spendings` / `Spending` | `pages/spendings.dart` / `spending.dart` | Expenses dashboard + expense detail |
| `LowStockItemsPage` | `pages/lowStockItemesPage.dart` | Low-stock products with severity colors |
| `LoginPage` / `RegisterPage` / `VerficationPage` | `pages/*` | Appwrite auth screens |
| `PaymentVerificationPage` | `pages/paymentVerficaion.dart` | Subscription payment upload + PIN (partly stubbed) |
| `SearchPage` | `pages/searchPage.dart` | Product picker for sale/inbound; hot-item fallback |
| `SettingsPage` | `pages/settingsPage.dart` | Weight precision + store name |

### Sale flow (happy path)

`SellPage` cart (`sa.sellList`) → `SearchPage` adds products (count 1) → `CheckOut`
computes total → `db.checkOut(...)` writes one `Log`, decrements stock, bumps owner
`dueMoney`, applies discounts, updates loaner/expense → success clears cart and pops
back.

### Receipt cancel & edit

Both go through `db.cancelReceiptAtomically` (single write txn):
restore non-hot product counts, reverse loaner balance (with `cancel` ledger entry),
delete the `Log`. Edit (`Lists.editReceipt`) additionally rebuilds the product list and
reuses the original `Log.date` (unique) so re-checkout replaces the same receipt.

### Offer pricing formula

At checkout and display, a unit's effective price is:
`offer && count % offerCount == 0 ? offerPrice : sellPrice`.
In `db.checkOut`, bundle offer profit is computed as
`(offerPrice - buy) * offerCount * (count ~/ offerCount) + (sell - buy) * (count % offerCount)`.

### Whole-unit ↔ grams conversion

Weightable products store per-gram prices/counts internally; UI shows whole-unit prices.

- `getWholeUnitNumber`: كيلو=1000, رطل=450, تمنة=850, ''=1, else numeric parse.
- `padd` (grams → units) and `unPadd` (units → grams) live in `InsertPage.dart` and
  `inboundListItem.dart`.
- `MyListTile` lets the cashier pick weight fractions (نص/ربع) via the `kg`/`pound`/
  `toumna` gram maps and a multiplier; "وزن" mode converts a typed money amount into
  grams rounded up to scale precision.

### Low stock heuristic

`db.getLowStockProductsWithPercent` (30-day window) computes
`percentRemaining = currentStock / (currentStock + soldLast30Days)`; products below
`thresholdPercent` (0.25) are low stock. Severity: <10% critical, <25% low, else
normal.

### LAN sync protocol (`lib/core/lan_sync.dart`)

Peer-to-peer DB transfer over HTTP on port `30000`. Version-gated:
`LanSync.filesForVersion` requires major 2 + minor ≥ 3 → single `backup.isar`.

- Sender (`Lists.runServer` / `ShareProvider.runServer`): creates local backup, binds
  `HttpServer`, serves `version`, `hash` (sha256), and the backup file; sets
  `shareAddress = host:port` (the QR payload).
- Receiver (`Lists.client` / `syncFromServer`): parses endpoint, downloads via `dio`
  with progress, **verifies sha256** against `hash`, asks peer to `shutdown`, restores
  (desktop: `db.windows()` swaps in `.received`; mobile: `db.useLocalBacup()` +
  `Restart.restartApp()`).
- Server only serves the allow-listed segments (`version`, `hash`, `shutdown`,
  `backup.isar`). `SyncStatus` enum + `LanSyncState` mixin drive the UI.

---

## 6. Observability & Backend

### `lib/core/observability.dart`

- `ObservabilityConfig`: reads `SENTRY_DSN`, `SENTRY_ENVIRONMENT`, `SENTRY_RELEASE`
  from `String.fromEnvironment`. Crash reporting only when `SENTRY_DSN` non-empty.
- `AppLogger`: `debug/info/warning/captureException`. Local logging redacts emails,
  pairing addresses, `.isar` paths; release builds suppress non-error/warning logs.
  `sanitizeMap`/`sanitizeText` are `@visibleForTesting`.
- `UserSafeMessages`: Arabic user-safe error strings (never leak internals).

Always log through `AppLogger` (never raw `print`/`debugPrint`) with an `area` string.

### Appwrite config (`lib/core/appwrite_config.dart`)

Build defines with defaults: `APPWRITE_ENDPOINT` (default
`https://cloud.appwrite.io/v1`), `APPWRITE_PROJECT_ID`, `APPWRITE_BUCKET_ID`.
`isCloud` controls `client.setSelfSigned()` for self-hosted instances.

### `lib/core/postgres_connection.dart`

Optional local PostgreSQL mirror (`Connection.open` to `localhost`). `insertProduct`
inserts into a `products` table. Not part of the main product flow; used via
`DB.insertInPostgres` (currently only wired from a commented-out block in `SellPage`).

### `lib/firebase_options.dart`

Entirely commented out (legacy Firebase config, disabled after migration to Appwrite).
Do not re-enable.

---

## 7. Testing Guide

### Layout

- `test/unit/` — pure Dart unit tests: `loaner_comparison_test.dart`,
  `observability_test.dart`, `profit_recalculation_test.dart`.
- `test/widget/` — widget tests: `widgets_test.dart`, `real_widgets_test.dart`.
- `test/integration/` — tagged `@Tags(['integration'])`: auth, checkout, database,
  expenses/logs, file ops, file sharing, inbound/stats, inventory, loans, navigation,
  offline auth, product validation, real database, sell flow.
- `test/helpers/` — `test_app.dart` (full `MultiProvider` widget harness with
  `forTesting` providers), `test_db.dart` (`openTestDb()` creates a temp Isar DB),
  `fixtures.dart`, `mocks.dart`, `pump_utils.dart`.

### Testing patterns

- Open an isolated DB with `openTestDb()` (calls `Isar.initializeIsarCore(download: ...
  )` on first use and `DB.createForTesting`), close via `TestDbHandle.close()`.
- Providers expose `@visibleForTesting` constructors (`X.forTesting(db)`,
  `detachedForTesting(...)`) instead of hitting the isolate pool / network.
- `Lists.forTesting(db)` / `SalesProvider.detachedForTesting(pref, products)` bypass
  the real init path.
- Integration tests need Isar's native library; CI pre-downloads `libisar.so`.

### Commands

```bash
flutter analyze --no-fatal-infos --no-fatal-warnings   # mandatory before finishing
flutter test                                           # full suite
flutter test -j 1 --timeout 120s                       # when Isar native init is flaky
flutter test test/unit/profit_recalculation_test.dart  # single file
```

---

## 8. Known Bugs & Code Gotchas

These matter when touching code — verify before "fixing" and don't rely on broken paths.

**Provider duplication / migration state**

- `Lists`, `SalesProvider`, `StatsProvider`, `LoanProvider`, `LogProvider`,
  `OwnerProvider`, `ShareProvider`, `SyncProvider` all carry **overlapping logic**
  (loaner ledger, stats, LAN sync). Pages use `Lists` and `SalesProvider`; the newer
  providers are effectively dead in the UI. Don't "deduplicate" blindly — confirm what
  the pages actually call first.
- `Lists.updateOwner(...)` and `OwnerProvider.updateOwner(...)` are **empty no-ops**.
  The owners tile in `charts.dart` mutates `li.ownersList` in memory but never persists.
- `AuthAPI.uploadPaymentReceipt(...)` is an **empty stub** (called from
  `paymentVerficaion.dart`).
- `AccountPage` is **not referenced** by the navigation tree (dead-ish; the drawer has
  its own logout).

**Navigation / flow bugs**

- `PaymentVerificationPage._verifyPin` navigates **to itself** (should go to the app
  home). The subscription payment flow is incomplete.
- `util/inboundReceipt.dart` desktop branch uses `ValueKey(sa.sellList[index])` and
  mutates `sa.sellList` instead of `inboundList` (mobile branch is correct).
- `util/scanner.dart` `Scanner` snackbar prints an unset `ip` variable (cosmetic).

**Logic bugs**

- `SalesProvider.isProductOutOFStock` has **inverted logic** (returns `true` when
  `count != 0`). `SearchPage` relies on this to disable out-of-stock tiles — be careful
  if you "fix" it.
- `inboundListItem.dart` `unPadd` has an operator-precedence bug: the `?? 0` binds
  looser than `*`, so the fallback multiplies `0 * wholeUnit`.
- `MyListTile` unit-selection switch lacks `break` in several cases (falls through to
  `weight = 0`).
- `lowStockItemesPage.dart` displays price with the `₪` symbol while the rest of the
  app uses SDG/`ج` (inconsistency).

**Dead / deprecated code**

- `BcLog.dart` and `BC_product.dart` are fully commented out (legacy Hive-era).
- `lib/firebase_options.dart` is commented out (migrated to Appwrite).
- `ExpensesPieChart` in `charts.dart` is demo data and unused.
- `CgetLowStockItemsPerMonth` exists in `db.dart` but is not used by
  `InventoryProvider` (which uses `getLowStockProductsWithPercent`).
- `db.exportData` / `importData` (JSON logs) exist but are not surfaced in the UI.
- `PostgresConnection` / `insertInPostgres` are wired only to a commented-out block.

**Watch out when extending**

- `Log.date` is a **unique indexed field** — receipt identity = timestamp. Checkout of
  an edited receipt must reuse the original date (`li.logID`).
- `Product.name` is unique — adding a product with an existing name replaces it.
- Never schedule pooled `Cget*` jobs without passing a `RootIsolateToken` in `map['1']`.
- Pooled jobs re-open `isarInstance` in the worker; the worker must not use the main
  isolate's `db.isar` handle.
- When a page needs providers, wrap the pushed route with
  `ChangeNotifierProvider.value(...)` — the root `MultiProvider` does not extend into
  new routes.

---

## 9. Conventions Checklist

- **Naming**: camelCase Dart classes/methods; `Cget*` for pooled DB jobs; Arabic-first
  user-visible strings; English for code/docs.
- **Models**: use `Product.named2(...)` in tests and cash logic; `Emap` for embedded
  key-value snapshots; `.g.dart` files are generated — never hand-edit.
- **Logging**: `AppLogger.debug/info/warning/captureException` with an `area` string;
  never raw `print`. Surface user errors via `UserSafeMessages`.
- **State**: providers are `ChangeNotifier`; heavy reads go through the isolate pool
  via `pool.scheduleJob(Cget*(map: {...}))`; wrap expensive/repeated results in
  `getCachedCalculation`.
- **Quality gate**: always finish with
  `flutter analyze --no-fatal-infos --no-fatal-warnings` and fix findings.
- **Versioning**: bump patch only on push (see AGENTS.md); update `CHANGELOG.md`.
