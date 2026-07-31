# Online Integration & Backup Improvement Plan

## Current State

| Component | How It Works | Limitation |
|---|---|---|
| **Cloud backup** | Full `.isar` file upload/download to Appwrite Storage | Entire DB transferred every time; no incremental |
| **LAN sync** | Full DB replacement over HTTP (port 30000) | No merge; one device's data wipes the other |
| **Change tracking** | None | No way to know what changed since last sync |
| **Conflict resolution** | None | Last restore wins; data loss on concurrent edits |
| **Device identity** | Isar auto-increment IDs | IDs collide across devices |
| **Code duplication** | LAN sync in both `Lists` and `ShareProvider` | Maintenance burden |

## Data Model

5 Isar collections: `Product`, `Log`, `Loaner`, `Owner`, `Expense`

Cloud backend: Appwrite (Auth + Storage). No Appwrite Database currently used.

LAN sync: HTTP server on port 30000, full `backup.isar` transfer with SHA-256 verification.

---

## Phase 1 — Add `updatedAt` + UUID fields to all collections

**Why**: Cross-device sync needs stable entity identifiers (UUIDs) and timestamps for LWW conflict resolution.

### Changes

- Add `String uuid` (unique index) to `Product`, `Log`, `Loaner`, `Owner`, `Expense`
- Add `DateTime updatedAt` to `Product`, `Loaner`, `Owner`, `Expense`
  - `Log` already has `date` which serves as its timestamp
- Add `String deviceUuid` to each collection (identifies which device made the change)
- Generate a persistent device ID on first launch (stored in `SharedPreferences`)
- On first run after migration, backfill UUIDs for existing records using `uuid` package
- Run `build_runner` to regenerate Isar schemas

### Files Touched

- `lib/util/models/Product.dart`
- `lib/util/models/Log.dart`
- `lib/util/models/Loaner.dart`
- `lib/util/models/Owner.dart`
- `lib/util/models/Expense.dart`
- `lib/core/db.dart` (backfill logic on init)

### Notes

- Isar schema changes require a fresh install or a migration strategy. Since the app already backs up/restores, the migration can piggyback on the existing backup flow: backup old DB, open new schema, restore data.
- The `uuid` package is already in `pubspec.yaml`.

---

## Phase 2 — Create `SyncLog` Isar collection

**Why**: This is the change log that enables incremental sync.

### Schema

```dart
@collection
class SyncLog {
  Id id = Isar.autoIncrement;

  String entityType;    // "product", "log", "loaner", "owner", "expense"
  String entityUuid;    // UUID of the affected record
  String operation;     // "create", "update", "delete"
  DateTime timestamp;   // when the change happened
  String deviceUuid;    // which device made the change
  String? payload;      // JSON snapshot of the entity (null for deletes)
  bool synced;          // whether this entry has been uploaded to cloud
}
```

### Design

- Every write to Isar produces a corresponding `SyncLog` entry
- `synced` starts as `false`; set to `true` after successful cloud upload
- `payload` contains the full entity state as JSON (for creates/updates) — this allows the receiving device to apply the change without querying the sender
- Deletes store `null` payload; the receiver just needs the UUID and operation type
- SyncLog entries older than 30 days can be pruned (configurable)

### Files Touched

- New: `lib/util/models/SyncLog.dart`
- Modified: `lib/core/db.dart` (open SyncLog collection)

---

## Phase 3 — Sync-aware DB wrapper (`SyncDB`)

**Why**: Every write to Isar must also record a sync log entry.

### Changes

Create `lib/core/sync_db.dart` with a wrapper class that:

1. **Intercepts all write operations** — product CRUD, checkout, expense CRUD, loaner updates, owner updates, log creation
2. **After each successful `isar.writeTxn()`**, inserts a corresponding `SyncLog` entry with:
   - The entity's UUID
   - Operation type (`create` / `update` / `delete`)
   - Timestamp (`DateTime.now()`)
   - Device UUID
   - JSON payload snapshot (for creates/updates)
3. **`getChangesSince(DateTime since)`** — returns unsynced `SyncLog` entries (where `synced == false` or `timestamp > since`)
4. **`markSynced(List<int> syncLogIds)`** — marks entries as uploaded
5. **`applyRemoteChanges(List<SyncLog> entries)`** — applies changes from other devices using LWW logic:
   - For each incoming change, compare its `timestamp` against the local `updatedAt` of the same entity UUID
   - Apply if incoming is newer; skip if local is newer or same
   - For deletes: check if the entity still exists locally with a newer timestamp before deleting
6. **`getSyncCursor()` / `setSyncCursor(DateTime timestamp)`** — persist last sync timestamp

### LWW Conflict Resolution

```
if (incoming.timestamp > local.updatedAt) {
  apply(incoming);  // remote wins
} else {
  skip(incoming);   // local wins
}
```

Edge cases:
- Clock skew: devices on the same network typically have <1s skew. Acceptable for a single-shop app.
- Simultaneous edits with identical timestamps: device with lexicographically smaller `deviceUuid` wins (deterministic tiebreak).
- Delete vs update: if device A deletes and device B updates, the one with the later timestamp wins.

### Files Touched

- New: `lib/core/sync_db.dart`
- Modified: `lib/core/db.dart`
- Modified: Provider files that call DB directly (`list.dart`, `salesProvider.dart`, `expense_provider.dart`, `loan_provider.dart`, `owner_provider.dart`, `inventory_provider.dart`)

---

## Phase 4 — Appwrite sync service

**Why**: Upload/download only changed data instead of the full database file.

### Changes

Create `lib/services/appwrite_sync.dart`:

1. **`uploadChanges(userId)`**
   - Read unsynced `SyncLog` entries from Isar
   - Serialize them as a JSON bundle
   - Upload to Appwrite Storage as `sync_{userId}_{deviceId}_{timestamp}.json`
   - Update a metadata file `sync_cursor_{userId}_{deviceId}.json` with the last synced timestamp
   - Mark entries as `synced` in Isar

2. **`downloadChanges(userId, lastSyncTimestamp)`**
   - List all sync bundles in Appwrite Storage matching `sync_{userId}_*`
   - Download bundles newer than `lastSyncTimestamp`
   - Parse and return as a list of `SyncLog` entries

3. **`applyChanges(entries)`**
   - Call `SyncDB.applyRemoteChanges()` with LWW logic
   - Return count of applied vs skipped changes

4. **Keep existing full backup** as "disaster recovery" option (renamed to "full backup" in UI)

### Sync Flow

```
Device A (offline)          Cloud (Appwrite)         Device B (online)
    |                            |                        |
    |-- makes changes locally --|                        |
    |   (SyncLog entries created)|                        |
    |                            |                        |
    |--- uploadChanges() ------->|                        |
    |   (JSON sync bundles)      |                        |
    |                            |<--- downloadChanges() -|
    |                            |   (newer bundles)      |
    |                            |                        |
    |                            |   applyChanges() with  |
    |                            |   LWW conflict res.    |
```

### Files Touched

- New: `lib/services/appwrite_sync.dart`
- Modified: `lib/providers/sync_provider.dart`
- Modified: `lib/core/appwrite_config.dart` (add database ID config if using Appwrite Database for metadata)

---

## Phase 5 — Auto-sync + UI improvements

**Why**: Manual sync is unreliable; users forget to backup.

### Changes

1. **Auto-sync scheduler**
   - Use the existing `cron` package for periodic sync (default: every 30 minutes when online)
   - Also sync on app resume/foreground detection (`WidgetsBindingObserver.didChangeAppLifecycleState`)
   - Only sync when authenticated and online

2. **Sync status UI**
   - Add sync status indicator in the drawer:
     - Last sync time (e.g., "Last sync: 5 min ago")
     - Pending changes count (e.g., "3 changes waiting to sync")
     - Online/offline indicator
   - Add progress indicators for upload/download (not just snackbar)
   - Add "Sync Now" button in settings/drawer

3. **Code consolidation**
   - Migrate `Lists` LAN methods to `ShareProvider`
   - Remove duplicate LAN sync code from `Lists`
   - Update `main.dart` provider setup

4. **Conflict notification**
   - After sync, if any LWW overrides happened, show a subtle notification:
     "Sync complete. 2 remote changes applied."
   - Log conflict details for debugging

### Files Touched

- New: `lib/services/auto_sync.dart`
- Modified: `lib/providers/sync_provider.dart`
- Modified: `lib/util/drawer.dart`
- Modified: `lib/pages/settingsPage.dart`
- Modified: `lib/providers/list.dart` (remove LAN methods)
- Modified: `lib/main.dart`

---

## Phase 6 — Upgrade LAN sync to change-log protocol

**Why**: LAN sync should also support incremental sync, not just full replacement.

### Changes

1. **Extend LAN protocol** in `lib/core/lan_sync.dart`:
   - Add `/changes?since=<timestamp>` endpoint — returns JSON SyncLog entries
   - Add `/apply` POST endpoint — receives SyncLog entries from client
   - Keep existing endpoints (`/version`, `/hash`, `/backup.isar`, `/shutdown`) for backward compatibility

2. **Server-side changes**:
   - Serve only changes since the client's last sync timestamp
   - Accept and apply incoming changes from the client

3. **Client-side changes**:
   - Download changes, apply with LWW
   - Optionally send local changes back to server (bidirectional sync)

4. **UI changes** in `lib/util/share.dart`:
   - Add "Full replace" vs "Merge" option in the LAN sync UI
   - "Merge" uses the change-log protocol
   - "Full replace" keeps the existing behavior (for fresh installs)

5. **Version negotiation**:
   - Bump LAN sync version to `3.0`
   - Version `2.x` clients get full backup behavior
   - Version `3.x` clients get change-log sync behavior

### Files Touched

- Modified: `lib/core/lan_sync.dart`
- Modified: `lib/providers/share_provider.dart`
- Modified: `lib/util/share.dart`

---

## Key Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Conflict resolution | Last-write-wins (timestamp) | Simple, sufficient for single-shop use. Clock skew <1s on same network. |
| Entity identity | UUID strings | Stable across devices; Isar IDs are local only |
| Sync transport | Appwrite Storage (JSON bundles) | Works with existing setup; no new Appwrite services needed |
| Incremental granularity | Per-entity changes | Much smaller than full `.isar` file; still simple to implement |
| Auto-sync frequency | Every 30 min + on app resume | Balances freshness with battery/data usage |
| Disaster recovery | Keep full `.isar` backup alongside sync | Full backup for new device setup; sync for day-to-day |
| Delete handling | SyncLog entry with `operation=delete` and null payload | Receiver just needs UUID + timestamp to know what to delete |
| Tiebreak | Lexicographically smaller `deviceUuid` wins | Deterministic, no coordination needed |

---

## Complexity Estimate

| Phase | Effort | Risk | Dependencies |
|---|---|---|---|
| Phase 1 (UUIDs + timestamps) | Medium | Low | None |
| Phase 2 (SyncLog collection) | Low | Low | Phase 1 |
| Phase 3 (SyncDB wrapper) | High | Medium | Phase 1, 2 |
| Phase 4 (Appwrite sync service) | Medium | Low | Phase 2, 3 |
| Phase 5 (Auto-sync + UI) | Medium | Low | Phase 4 |
| Phase 6 (LAN sync upgrade) | Medium | Medium | Phase 2, 3 |

## Recommended Execution Order

1. **Phase 1 + Phase 2** — Foundation. Can be shipped independently. No impact on existing functionality.
2. **Phase 3** — Core sync logic. The most complex phase. Should be thoroughly tested.
3. **Phase 4** — Cloud sync. Builds on Phase 3.
4. **Phase 5** — UX improvements. Builds on Phase 4.
5. **Phase 6** — LAN sync upgrade. Can be done in parallel with Phase 4/5.

## Testing Strategy

- **Phase 1**: Unit tests for UUID generation and backfill logic
- **Phase 2**: Unit tests for SyncLog creation and queries
- **Phase 3**: Integration tests for sync-aware writes + LWW conflict resolution
- **Phase 4**: Integration tests for upload/download/apply cycle using mock Appwrite
- **Phase 5**: Widget tests for sync status UI
- **Phase 6**: Integration tests for LAN change-log protocol + backward compatibility
- **All phases**: Verify all existing 69+ tests still pass after each phase

## Migration Strategy

Since Isar schema changes (Phase 1) require a fresh database:

1. Before migration: auto-backup the current database
2. Open new schema (Isar will create a fresh DB)
3. Import data from backup using the existing `importData()` JSON path (needs to be expanded to cover all collections, not just logs)
4. Backfill UUIDs for all imported records
5. Delete old backup

This is a one-time migration. The existing full backup/restore mechanism provides a safety net.

---

## Open Questions

1. **Appwrite Storage limits**: Appwrite Cloud free tier has storage limits. How large can sync bundles grow before hitting limits? Mitigation: prune old SyncLog entries, compress JSON payloads.

2. **Concurrent uploads**: If two sync uploads happen simultaneously (e.g., auto-sync + manual), we need a mutex. The `cron` package and manual trigger should share a lock.

3. **First-time sync on new device**: A new device has no data. It should download the full backup first, then switch to incremental sync. The existing `downloadBackup()` flow handles this.

4. **Offline queue size**: If a device is offline for weeks, the SyncLog could grow large. Need a configurable max age or max count for pending entries.
