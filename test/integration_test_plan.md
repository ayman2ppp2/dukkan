# Integration Test Coverage Plan — دكان (Dukkan)

## Current State

**Existing test files:** 12 across `test/` (unit/integration/widget) and `integration_test/`

| Directory | Files | Quality |
|-----------|-------|---------|
| `test/unit/` | 1 | Minimal |
| `test/widget/` | 2 | Mostly placeholders |
| `test/integration/` | 6 | Basic logic tests |
| `test/helpers/` | 2 (fixtures, test_db) | Functional |
| `integration_test/` | 1 | Real smoke test |

**Testability:** Excellent — most providers have `@visibleForTesting` constructors, `DB.createForTesting()` opens temp Isar databases, `SharedPreferences.setMockInitialValues()` available, `mocktail` v1.0.4 ready.

**Gaps to fill:** No `dart_test.yaml`, no reusable test app wrapper, 5 providers lack `forTesting` constructors, no CI test workflow, no Dio/HTTP mocks for LAN sync.

---

## Infrastructure to Build

### 1. `test/helpers/test_app.dart` — Reusable Test App

A `TestApp` widget that wraps `MaterialApp` with all providers injected via their `forTesting` constructors, accepting an optional `DB` instance and mock `SharedPreferences`.

```dart
class TestApp extends StatelessWidget {
  final DB? db;
  final Widget? home;
  final Map<String, dynamic>? prefs;
  // ...
}
```

Automatically provides:
- `SalesProvider.forTesting()` or `.detachedForTesting()`
- `Lists.forTesting(db)` or `.detachedForTesting()`
- `ExpenseProvider.forTesting(db)` or `.detachedForTesting()`
- `LoanProvider.forTesting(db)`
- `InventoryProvider.forTesting(db)`
- `AuthAPI.forTesting()`
- Remaining providers with new `forTesting` constructors

### 2. `test/helpers/mocks.dart` — Shared Mock Instances

Mocktail mocks for:
- `SharedPreferences`
- `FlutterSecureStorage`
- `Dio`/HTTP client (for LAN sync tests)
- `network_info_plus` (for wifi detection)

### 3. `test/helpers/pump_utils.dart` — Pump Helpers

- `pumpUntilFound(tester, finder, {timeout})` — pumps until widget appears or timeout
- `pumpUntilIdle(tester)` — pumps with small increments until no more frames

### 4. `dart_test.yaml` — Test Configuration

```yaml
timeout: 60s
concurrency: 1
tags:
  integration:
    timeout: 120s
```

### 5. `forTesting` Constructors (5 providers)

| Provider | Current | Needed |
|----------|---------|--------|
| `SyncProvider` | Hardcodes `Client()` | `SyncProvider.forTesting(DB db)` |
| `StatsProvider` | Hardcodes `DB.getInstance()` | `StatsProvider.forTesting(DB db)` |
| `LogProvider` | Hardcodes `DB.getInstance()` | `LogProvider.forTesting(DB db)` |
| `OwnerProvider` | Hardcodes `DB.getInstance()` | `OwnerProvider.forTesting(DB db)` |
| `ShareProvider` | Hardcodes `DB.getInstance()` | `ShareProvider.forTesting(DB db)` |

### 6. `.github/workflows/test.yml` — CI Pipeline

```yaml
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
      - run: flutter test integration_test/
```

---

## Integration Test Files — 8 Flows

### 1. `auth_flow_test.dart` — Auth & Onboarding

| Test | Assertions |
|------|-----------|
| Login page renders all controls | Email, password fields; login, register, OAuth buttons |
| Empty field validation | Tap login with empty fields → stays on page |
| Register page navigation | Tap "إنشاء حساب" → RegisterPage with correct fields |
| Landing page store setup | Store name field, weight dropdown, subscription plans render |
| Subscription plan selection | Tap plan → "متابعة" button present |

### 2. `sell_flow_test.dart` — Core Sell Flow (Highest Priority)

| Test | Assertions |
|------|-----------|
| SellPage renders with empty cart | No product items, total is 0 |
| Add product via SearchPage | Search → tap → cart has 1 item, total updates |
| Park current cart | Tap park → dialog shows current cart → park → pending cart appears |
| Restore parked cart | Tap restore → current cart populated with saved products |
| Delete parked cart | Tap delete → confirmation → cart removed from list |
| Max 5 carts enforcement | Park 6 carts → snackbar "لا يمكن ركن أكثر من 5 فواتير" |
| Empty parked carts state | "لا توجد فواتير معلقة" visible when list empty |
| Dismiss item from cart | Swipe → item removed, total recalculated |
| Current cart summary updates | Add/remove items → count and total reflect changes |

### 3. `checkout_flow_test.dart` — Checkout & Payment

| Test | Assertions |
|------|-----------|
| Checkout page renders | Products listed, total shown, payment methods available |
| Discount dialog | Open → enter value → total updated with discount |
| Cash payment checkout | Confirm → success dialog → sale persisted to DB |
| Debt payment flow | Select loaner dropdown → confirm → log created with loaner ID |
| Expense payment flow | Select expense dropdown → confirm → log created with expense ID |
| Cancel confirmation | Tap "لا" → returns to checkout, no sale recorded |
| Empty cart prevents checkout | No products → snackbar "يجب تحديد منتجات أولاً" |
| Product count decreases after sale | Verify DB product count decreases by sold amount |
| Sale log created | Verify log entry in DB with correct total, discount, products |

### 4. `inventory_flow_test.dart` — Product CRUD

| Test | Assertions |
|------|-----------|
| InvPage renders product grid | Product fixtures appear in grid |
| Search filters products | Type name → only matching products shown |
| Add new product | FAB → fill InPage fields → submit → product appears in grid |
| Edit existing product | Tap edit icon → modify fields → save → changes persisted in DB |
| Delete product | Tap delete → confirm → removed from grid and DB |
| Add owner | AddOwner dialog → submit → owner available in dropdown |
| Empty inventory state | No products → appropriate empty message |

### 5. `loans_flow_test.dart` — Loans & Payments

| Test | Assertions |
|------|-----------|
| LoansPage renders | Loaner list, summary cards present |
| Add loaner | Dialog → name, phone, location → loaner appears in list |
| Loaner detail page | Tap loaner → balance, info, actions render |
| Deposit flow | Enter amount → confirm → ConfirmationPage with receipt |
| Withdraw flow | When balance negative → enter amount → confirm → receipt |
| Reset account | Enter "Reset" → confirm → balance zeroed |
| Delete loaner | Only when balance == 0 → confirmation → removed |
| Payment history | Long-press balance → history dialog with entries |
| Account statement | "كشف حساب" → BankStatementPage with filters |

### 6. `expenses_logs_flow_test.dart` — Expenses & Receipts

| Test | Assertions |
|------|-----------|
| SpendingsPage renders | Summary cards (profit, loans, remaining) present |
| Add expense category | FAB → name + amount → category appears in list |
| Expense detail | Tap expense → detail page with ID, amount, period |
| Delete expense | Tap delete → confirmation → removed |
| LogsPage renders | Sale logs listed, filter controls present |
| Receipt expand/collapse | Tap receipt → products list shown/hidden |
| Receipt cancel flow | Cancel → confirmation → log marked as cancelled in DB |
| Receipt edit flow | Edit → confirmation → products restored to sellList |
| Date range filter | Set start/end dates → logs filtered |
| Loaner filter | Select loaner → only that loaner's logs shown |

### 7. `inbound_stats_flow_test.dart` — Inbound & Reports

| Test | Assertions |
|------|-----------|
| InboundReceipt renders | Similar to sell page, but inbound mode |
| Add product inbound | Search (inbound mode) → product added to inboundList |
| Checkout inbound | Confirm → product count increases in DB |
| StatsPage renders | All stat cards: total, daily, monthly, avg |
| Charts render | Circular chart, bar chart, line chart, monthly chart visible |
| Low stock items | Products below 25% stock appear in low stock page |
| Low stock colors | Red < 10%, orange < 25%, green >= 25% |

### 8. `navigation_flow_test.dart` — Navigation & Drawer

| Test | Assertions |
|------|-----------|
| HomePage 2 tabs | Tab bar with "البيع" and "الإحصائيات" |
| Tab switching | Tap each tab → correct page content visible |
| AppBar actions render | 4 action icons present (scanner, logs, inventory, share) |
| Drawer opens | Swipe or menu → all drawer items listed |
| Drawer navigation | Tap each item → correct page opens |
| Back navigation | Push page → pop → returns to home |
| Logout flow | Drawer → "تسجيل الخروج" → returns to login |
| Barcode scanner dialog | Tap scanner icon → dialog opens with camera preview |

---

## Edge Cases & Error States

| Category | Cases |
|----------|-------|
| **Empty states** | Empty cart, empty inventory, no parked carts, no logs, no loaners, no expenses, empty search results, empty low stock |
| **Limits** | Max 5 parked carts, product count cannot go negative, stock depletion on checkout, discount cannot exceed total |
| **Validation** | Empty product name/barcode/price in InPage, empty login fields, invalid discount format, negative loan payment |
| **Error states** | DB write failure, auth failure (wrong password), offline during backup, scanner permission denied |
| **Concurrent state** | Park cart while cart empty (button disabled), restore cart while current cart non-empty (confirmation dialog), delete while confirm dialog open |

---

## Implementation Order

```
Phase 1 — Infrastructure
  ├── dart_test.yaml
  ├── test/helpers/test_app.dart
  ├── test/helpers/mocks.dart
  ├── test/helpers/pump_utils.dart
  └── forTesting constructors (5 providers)

Phase 2 — Core Flows
  ├── test/integration/sell_flow_test.dart
  └── test/integration/checkout_flow_test.dart

Phase 3 — Secondary Flows
  ├── test/integration/inventory_flow_test.dart
  ├── test/integration/loans_flow_test.dart
  └── test/integration/expenses_logs_flow_test.dart

Phase 4 — Remaining Flows
  ├── test/integration/inbound_stats_flow_test.dart
  ├── test/integration/navigation_flow_test.dart
  └── test/integration/auth_flow_test.dart

Phase 5 — CI & Final
  └── .github/workflows/test.yml
```

---

## Test Pattern

```dart
testWidgets('sell: parking a cart creates pending cart', (tester) async {
  final handle = await openTestDb();
  addTearDown(handle.close);

  // Seed data
  final product = productFixture(count: 10);
  await handle.db.insertProducts(products: [product]);

  // Render app with test DB
  await tester.pumpWidget(TestApp(db: handle.db));
  await tester.pumpAndSettle();

  // Add product to cart
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'Sugar');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sugar'));
  await tester.pumpAndSettle();

  // Park the cart
  await tester.tap(find.byIcon(Icons.pause_circle_outline));
  await tester.pumpAndSettle();
  await tester.tap(find.text('ركن الفاتورة'));
  await tester.pumpAndSettle();

  // Assert
  expect(find.textContaining('فاتورة'), findsOneWidget);

  // Verify DB state
  final sa = tester.state<SalesProvider>(find.byType(SalesProvider));
  expect(sa.pendingCarts, hasLength(1));
});
```

---

## Success Criteria

| Metric | Target |
|--------|--------|
| Total test files | 20 (8 new + 12 existing) |
| Total test cases | 80+ |
| Flow coverage | All 8 flows |
| Edge case coverage | Empty states, limits, validation, errors |
| CI passes | `flutter test` + `integration_test/` |
| DB-backed tests | Each test uses real Isar temp DB |
| Time per flow file | < 60s in CI |
