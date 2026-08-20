# Verify Report: app-movil-fixes-offline

**Date**: 2026-08-19
**Branch**: feature/app-movil-fixes-offline
**Commits**: 49a647b, 96560b9, 44e92e5, 6c96df4

## Technical Results

- **flutter analyze**: 0 issues ✅
- **flutter test**: 88 tests passed ✅
- **flutter build apk --debug**: OK ✅

## Task Completeness (42 tareas, 9 fases)

All 42 tasks marked [x] (done) in tasks.md. No incomplete tasks found.

## Requirements Verification

### R66 [OFFLINE-QUEUE] — PASS
- `PendingOperation` model with all required fields (offline_models.dart:48-106)
- `PendingOperations` table with all columns + idempotency_key unique (offline_tables.dart:7-25)
- FIFO queries with status filter (pending_operations_dao.dart:38-53)
- Queue persists across restart (Drift persistent database, app_database.dart:24-32)
- Adapter generates operations with idempotency_key (commercial_offline_adapter.dart:5-21)

### R67 [OFFLINE-SYNC] — PARTIAL
- SyncEngine FIFO batches of 10 (sync_engine.dart:52)
- Mark completed with response (sync_engine.dart:60)
- Retry with backoff (sync_engine.dart:105-117)
- **GAP**: No jitter in backoff calculation (sync_engine.dart:107: `30 * (1 << (attempt-1))` — no random jitter)
- **GAP**: 401/409/422 handled but max attempts check uses `attemptCount + 1` instead of incrementing atomically before check

### R68 [OFFLINE-AUTH] — PASS
- 401 pauses engine (sync_engine.dart:63-69)
- `onUnauthorized()` called before logout (auth_providers.dart:21)
- Queue preserved on logout (auth_providers.dart:94-97 — no queue cleanup)
- Resume after login (auth_providers.dart:79)

### R69 [OFFLINE-BATTERY] — PARTIAL
- No polling, debounce 750ms (connectivity_monitor.dart:16)
- Batch of 10 (sync_engine.dart:52)
- Dispose subscriptions (connectivity_monitor.dart:28-31, offline_providers.dart:44)
- Cleanup completed 7 days (pending_operations_dao.dart:132-143)
- **GAP**: Cache is in-memory only (MemoryOfflineCache), not persisted in Drift — lost on restart
- **GAP**: No queue limit enforcement (500 ops / 20 MB) at write time

### R70 [OFFLINE-CONFLICTS] — PASS
- 409/422 marks terminal failed (sync_engine.dart:71-73)
- User notification on failure (sync_engine.dart:77)
- Last-write-wins via server response authoritative (design says backend is authority)

### R71 [OFFLINE-SCHEMA] — PASS
- schemaVersion = 1 (app_database.dart:42)
- Migration strategy defined (app_database.dart:45-48)
- Drift generated code handles versioning

### R72 [OFFLINE-NOTIFICATIONS] — PARTIAL
- Generic messages: "Operaciones pendientes de sincronizar", "Error de sincronizacion" (sync_notification_service.dart:19-50)
- Group key `ferreplus_sync` (sync_notification_service.dart:8)
- Android channel `sync_status` (sync_notification_service.dart:7)
- **GAP**: No `OfflineBanner` widget file exists — `flutter/lib/presentation/shared/widgets/offline_banner.dart` is MISSING
- **GAP**: No `SyncStatusChip` widget exists

### R73 [OFFLINE-LIST] — PARTIAL
- Cache via decorators (offline_venta_repository.dart:25-37)
- Fallback to cache on NetworkFailure (offline_venta_repository.dart:34-36)
- **GAP**: Cache is `MemoryOfflineCache` — data lost on app restart, violates "last known data when offline"
- **GAP**: No `OfflineBanner` or `OfflineEmptyState` widgets exist in codebase

### R-M1 [FAB Toggle] — PASS
- Reads current path (chat_floating_action_button.dart:82-83)
- Saves previous location on open (chat_floating_action_button.dart:104)
- Returns to previous or `/` fallback (chat_floating_action_button.dart:109-112)
- Dynamic icon: close vs chat_bubble_outline (chat_floating_action_button.dart:92)
- Dynamic tooltip/semantics (chat_floating_action_button.dart:84-88)
- Draggable preserved (DraggableChatFab, chat_floating_action_button.dart:16-66)

### R-M2 [Shell Navigation] — PASS
- `branchInitialRoutes` map immutable (app_router.dart:22-28)
- `goBranch` with `initialLocation: false` for branch changes (shell_scaffold.dart:63)
- `context.go(canonicalRoute)` for same-branch (shell_scaffold.dart:59)
- 5 destinations verified (shell_scaffold_test.dart:72)
- State preserved via StatefulShellRoute.indexedStack

### R-M3 [Dashboard Period] — PASS
- `dashboardDateRange` computes full range (dashboard_period.dart:18-31)
- `chartCoversRange` detects partial data (dashboard_period.dart:81-98)
- Fallback to `reportSalesProvider(range)` (dashboard_provider.dart:30-38)
- `completeChartPoints` fills zeros (dashboard_period.dart:58-79)
- Year grouped by month (dashboard_period.dart:43-45)

### R-M4 [Chat Layout] — PASS
- Loading bubble as assistant (chat_assistant_loading_bubble.dart:49-50, FractionallySizedBox 0.85)
- Reduced motion support (chat_assistant_loading_bubble.dart:30, 46, 62)
- Composer with viewInsets (chat_composer.dart:20)
- min/max height 56/144 (chat_composer.dart:31)
- Scroll counter 0/1000 (chat_composer.dart:47-48, 59)
- Auto-scroll on send/receive (chat_page.dart:41-43, 49-53, 169-177)
- Bubbles 85% width via FractionallySizedBox (chat_page.dart:134)

### R-M5 [Form Refactor] — PASS
- `AppFormField`, `AppDropdownField`, `AppFormSection` exist (forms/ directory)
- Used in admin_pages.dart, commercial_pages.dart, productos_pages.dart, catalog_pages.dart
- AppSpacing used consistently
- Labels with FloatingLabelBehavior.always
- Forms scrollable, buttons in flow

### R-M6 [README] — PASS
- Flutter section present (README.md:57-106)
- Stack, architecture, structure documented
- Commands: pub get, analyze, test, build apk with --dart-define
- Offline features summarized

### R-M7 [Tests] — PASS
- 88 tests pass (was 77 baseline — 11 new tests added)
- Tests cover: offline_core_test, form_widgets_test, chat_floating_action_button_test, shell_scaffold_test, chat_test (loading bubble, composer), dashboard_period_test, app_router_test
- flutter analyze clean

## Issues

### CRITICAL
- **Cache is in-memory only (MemoryOfflineCache)** — violates R73 "last known data when offline" and R69 "dispose subscriptions". Data lost on app restart. Should use Drift cache tables (`CachedSales`, etc.) or at minimum persist in SharedPreferences. (offline_providers.dart:29-40)

### WARNING
- **No jitter in SyncEngine backoff** — spec says "bounded exponential backoff and jitter" (R67). Current impl: `min(30s * 2^(attempt-1), 30min)` with no random jitter, risking thundering herd. (sync_engine.dart:107)
- **Missing OfflineBanner/OfflineEmptyState widgets** — spec R73 requires visible offline indicator and empty state. No such widgets exist. (task 1.7, 3.1, 3.2 not implemented)
- **No queue limits enforced at write time** — spec R71/R69 says limit 500 ops / 20 MB. `totalPayloadSize` exists in DAO but no check before enqueue. (pending_operations_dao.dart)
- **SyncEngine singleton race condition** — `_running` flag is not atomic; concurrent calls possible if `syncNow()` called from both `resumeAfterLogin()` and `coordinator.syncNow()`. Mitigated by `Provider` (singleton) but not by design. (sync_engine.dart:41)

### SUGGESTION
- **Missing integration test for offline flow** — `offline_sync_test.dart` exists but was not verified running (requires device). Spec task 8.2 expected it.
- **DropdownButtonFormField uses `initialValue` instead of `value`** — verify this compiles correctly across Flutter versions. (app_dropdown_field.dart:39)

## Coverage Summary

| Requirement | Status | Scenarios Covered |
|-------------|--------|-------------------|
| R66 | PASS | 5/5 |
| R67 | PARTIAL | 4/5 (missing jitter) |
| R68 | PASS | 4/4 |
| R69 | PARTIAL | 4/6 (missing persistence, limits) |
| R70 | PASS | 3/3 |
| R71 | PASS | 2/2 |
| R72 | PARTIAL | 2/3 (missing banner widget) |
| R73 | PARTIAL | 1/3 (cache not persisted, no banner) |
| R-M1 | PASS | 4/4 |
| R-M2 | PASS | 4/4 |
| R-M3 | PASS | 5/5 |
| R-M4 | PASS | 5/5 |
| R-M5 | PASS | 5/5 |
| R-M6 | PASS | 3/3 |
| R-M7 | PASS | 4/4 |

**Total**: 10 PASS, 4 PARTIAL, 0 FAIL
**Scenarios**: 55/61 fully covered, 6 partially covered
