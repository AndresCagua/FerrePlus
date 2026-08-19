# Delta Specification: App móvil fixes + offline (Flutter)

**Change**: `app-movil-fixes-offline`  
**Scope**: `flutter/` only  
**Base spec**: `openspec/specs/app-movil-flutter/spec.md`  
**Approved proposal**: `openspec/changes/app-movil-fixes-offline/proposal.md`

## Purpose

This delta spec corrects four behavioral bugs and two UX problems, and introduces an offline-first layer for the four main commercial operations, without changing backend contracts, business logic, or the Angular web frontend. All changes apply to the existing Flutter application under `flutter/`.

---

## ADDED Requirements

### R66 [OFFLINE-QUEUE] Cola durable de operaciones offline

The system MUST persist every commercial write operation (sales, expenses, purchases, stock movements) and their voidings when the device is offline. Each queued operation MUST store the payload, target endpoint, HTTP method, user identifier, local idempotency key, creation timestamp, status, attempt count and a sanitized error message. The system MUST NOT discard queued operations when the app restarts or when the session is logged out.

#### Scenario: Crear una venta sin conectividad

- GIVEN a user completes a sale form while the device has no connectivity
- WHEN the user taps "Guardar"
- THEN the app stores the operation in a local durable queue with status `pending`
- AND the app shows a confirmation that the sale was registered locally

#### Scenario: Crear un gasto sin conectividad

- GIVEN a user completes an expense form while offline
- WHEN the user saves it
- THEN the operation is queued locally with method `POST`, endpoint `/api/gastos` and the full payload
- AND the expense appears in the local list immediately

#### Scenario: Anular una compra sin conectividad

- GIVEN a user with `COMPRAS_ELIMINAR` confirms the voiding of a purchase while offline
- WHEN the voiding is requested
- THEN the app queues a `PUT /api/compras/{id}/anular` operation
- AND the local list reflects the voided status

#### Scenario: La cola sobrevive al reinicio de la app

- GIVEN there are pending operations in the local queue
- WHEN the app is closed and reopened
- THEN all queued operations remain available with their original payload and status

#### Scenario: Operación online no deja registro pendiente innecesario

- GIVEN the device is online and the backend accepts the request
- WHEN a commercial operation is sent and confirmed
- THEN no duplicate pending record remains in the local queue

---

### R67 [OFFLINE-SYNC] Sincronización automática al recuperar la red

The system MUST listen to connectivity events and, when online, process pending operations in FIFO order. The sync SHOULD retry failed operations with bounded exponential backoff and jitter. After a configurable maximum number of attempts, the system MUST mark the operation as permanently failed and surface it through a local notification. The system MUST suppress duplicates using the local idempotency key and MUST update local records with the backend response (server ID, timestamps, final state).

#### Scenario: Sincronización al recuperar conectividad

- GIVEN there are pending operations and the device regains connectivity
- WHEN the sync worker runs
- THEN operations are sent to the backend in the same order they were queued
- AND successful operations are marked as `completed` locally

#### Scenario: Reintento con backoff ante error transitorio

- GIVEN a pending operation fails with a 5xx or timeout
- WHEN the sync worker retries
- THEN each retry waits longer than the previous attempt up to a maximum delay

#### Scenario: Máximo de intentos marca error terminal

- GIVEN a pending operation fails repeatedly
- WHEN the attempt count exceeds the configured maximum
- THEN the operation is marked as `error`
- AND a local notification informs the user that manual review is needed

#### Scenario: Idempotencia evita duplicados

- GIVEN a queued operation is retried after a network timeout
- WHEN the same local idempotency key reaches the backend twice
- THEN the operation is applied only once and the local state reflects the single server response

#### Scenario: Actualización del registro local con respuesta del servidor

- GIVEN a queued sale is synchronized successfully
- WHEN the backend returns the created sale with its server ID and timestamps
- THEN the local record is updated with those values
- AND the local list shows the sale as synchronized

---

### R68 [OFFLINE-AUTH] JWT expirado durante la sincronización

The system MUST detect an HTTP 401 response during synchronization and transition the queue to an `auth_required` state. While in this state the system MUST pause automatic retries, preserve all pending operations securely, and resume synchronization only after a valid session is restored. The system MUST NOT drop queued operations when the existing `AuthInterceptor` triggers a logout due to 401.

#### Scenario: 401 durante la sincronización pausa la cola

- GIVEN the auth token has expired while pending operations exist
- WHEN the sync worker receives HTTP 401 from the backend
- THEN the queue transitions to `auth_required`
- AND automatic retries are paused

#### Scenario: Logout por 401 conserva las operaciones pendientes

- GIVEN pending operations exist and the interceptor receives a 401
- WHEN the app clears the session and redirects to `/login`
- THEN the local queue remains intact and encrypted/minimally exposed

#### Scenario: Reanudación tras nuevo login

- GIVEN the queue is in `auth_required` state
- WHEN the user logs in again and obtains a valid token
- THEN the sync worker resumes automatically
- AND pending operations are sent in FIFO order

#### Scenario: Sin pérdida de datos tras días offline

- GIVEN the device has been offline for several days and the token has expired
- WHEN the user opens the app and logs in again
- THEN all queued operations are still present
- AND synchronization starts without requiring the user to recreate any operation

---

### R69 [OFFLINE-BATTERY] Eficiencia de batería y memoria

The system MUST NOT rely on aggressive polling to detect connectivity. It SHOULD listen to platform connectivity events with debouncing. Synchronization MUST process pending operations in small batches and MUST dispose of subscriptions when not needed. The system SHOULD prune completed operations older than a configurable retention window and SHOULD limit the total size of the local queue. Background sync via workmanager/background tasks MAY be used only if it provides measurable value and is configured with network and battery constraints.

#### Scenario: Sin polling continuo

- GIVEN the app is idle with no connectivity changes
- WHEN several minutes pass
- THEN no periodic timer is firing just to check connectivity

#### Scenario: Debounce de cambios de conectividad

- GIVEN the connectivity signal flaps rapidly between offline and online
- WHEN the signal stabilizes
- THEN synchronization runs only once, not on every fluctuation

#### Scenario: Procesamiento por lotes

- GIVEN there are many pending operations
- WHEN synchronization runs
- THEN the system sends operations in small batches
- AND it does not load the entire queue into memory at once

#### Scenario: Dispose de subscriptions

- GIVEN a sync listener is active
- WHEN the user logs out or the app lifecycle disposes the listener
- THEN all connectivity subscriptions are cancelled

#### Scenario: Limpieza de operaciones sincronizadas antiguas

- GIVEN completed operations older than the retention window exist
- WHEN the cleanup runs
- THEN those records are removed from the local store

#### Scenario: Background sync opcional con restricciones

- GIVEN background sync is enabled
- WHEN it is configured
- THEN it runs only under network and battery constraints that avoid aggressive wake-ups

---

### R70 [OFFLINE-CONFLICTS] Política de conflictos offline

The system MUST adopt a `last-write-wins` policy for local queued operations against cached server state. For inventory-affecting conflicts, the backend response MUST be treated as authoritative. HTTP 409/422 validation or conflict responses MUST NOT be retried indefinitely; the system MUST transition the operation to a terminal error state and present a clear, actionable message to the user.

#### Scenario: Last-write-wins para operación local

- GIVEN a local queued sale differs from the last known server state
- WHEN the operation synchronizes successfully
- THEN the server reflects the locally created payload
- AND the local record is updated accordingly

#### Scenario: Conflicto de stock no reintenta indefinidamente

- GIVEN a sale is rejected by the backend because of insufficient stock (409/422)
- WHEN the sync worker processes the response
- THEN the operation is marked as terminal error
- AND the user sees a message explaining the failure

#### Scenario: Idempotencia local previene duplicados

- GIVEN the same idempotency key is sent twice due to a retry
- WHEN the backend processes the request
- THEN only one resource is created
- AND the local state stores the single server response

---

### R71 [OFFLINE-SCHEMA] Esquema SQLite versionado

The system MUST use a versioned local SQLite schema with incremental migrations. The schema version MUST be encoded in the application code. Migrations MUST preserve queued operations and local cache data across app updates.

#### Scenario: Versión de esquema visible

- GIVEN the offline module is built
- WHEN a developer inspects the database configuration
- THEN a schema version greater than zero is defined

#### Scenario: Migración conserva datos

- GIVEN pending operations exist in schema version N
- WHEN the app updates to schema version N+1
- THEN the schema is migrated
- AND all queued operations and cached list data remain intact

---

### R72 [OFFLINE-NOTIFICATIONS] Notificaciones locales de sincronización

The system MUST display a grouped local notification when pending operations exist or when a terminal sync error occurs. Notifications MUST NOT include sensitive business data (customer names, amounts, product details) and MUST respect platform notification permissions. The system MUST degrade gracefully if permission is denied.

#### Scenario: Notificación de operaciones pendientes

- GIVEN there are pending operations
- WHEN the app is in foreground or background
- THEN a local notification shows the count and a generic message such as "Operaciones pendientes de sincronizar"

#### Scenario: Notificación de error terminal sin datos sensibles

- GIVEN an operation reaches the maximum retry count
- WHEN the terminal error is recorded
- THEN a local notification appears with a generic title like "Error de sincronización"
- AND it does not expose payload details

#### Scenario: Permiso denegado no crashea

- GIVEN the user denies notification permission
- WHEN the app attempts to show a notification
- THEN the app continues working without crashing
- AND the pending operations remain in the queue

---

### R73 [OFFLINE-LIST] Lectura offline de listados

The system SHOULD cache list data for the four commercial modules so that list screens can show the last known data when offline. When displaying cached data, the system MUST show a visible offline indicator. If no cache exists and the device is offline, the system MUST show an empty state with an offline-specific message.

#### Scenario: Listado de ventas desde caché offline

- GIVEN the sales list was previously loaded while online
- WHEN the user opens Ventas while offline
- THEN the last known list is displayed with an offline indicator

#### Scenario: Caché se invalida tras sincronización

- GIVEN cached list data exists
- WHEN new data is synchronized from the backend
- THEN the cache is refreshed with the latest server data

#### Scenario: Sin caché y sin red

- GIVEN the device is offline and no cached list data exists
- WHEN the user opens a commercial list
- THEN an empty state with an offline message is shown

---

## MODIFIED Requirements

### R-M1 [BASE R57] FAB de chat como toggle

The `ChatFloatingActionButton` requirement is MODIFIED: it MUST behave as a toggle. When the current route is not `/chat`, it MUST navigate to `/chat` and show a close icon with a "Cerrar chat" tooltip/semantics label. When the current route is `/chat`, it MUST close the chat and return to the previous branch when available, or to the dashboard as a safe fallback. The draggable behavior of `DraggableChatFab` MUST be preserved.

(Previously: the FAB always executed `context.go('/chat')` and always showed the chat outline icon and "Abrir chat" tooltip.)

#### Scenario: Abrir chat desde el dashboard

- GIVEN the user is on `/dashboard` and sees the chat FAB
- WHEN the user taps the FAB
- THEN the app navigates to `/chat`
- AND the FAB icon changes to `close` and the tooltip becomes "Cerrar chat"

#### Scenario: Cerrar chat vuelve a la rama anterior

- GIVEN the user opened `/chat` from the Ventas branch
- WHEN the user taps the FAB again
- THEN the app returns to `/ventas`
- AND the FAB icon changes back to `chat_bubble_outline`

#### Scenario: Cerrar chat sin rama anterior cae al dashboard

- GIVEN the user opened `/chat` directly via deep link with no previous branch
- WHEN the user taps the FAB to close
- THEN the app navigates to `/dashboard`

#### Scenario: Semántica y tooltip dinámicos

- GIVEN the current route is `/chat`
- WHEN a screen reader focuses the FAB
- THEN it announces "Cerrar chat"
- AND the tooltip matches the label

---

### R-M2 [BASE R6 / R8 / R55] Navegación del shell determinista

The shell navigation requirement is MODIFIED: `ShellScaffold` MUST use an explicit `branchIndex -> canonical initial route` map and navigate explicitly to the canonical route of the selected branch. Secondary routes such as `/gastos`, `/compras` and `/movimientos` MUST resolve correctly without relying on `StatefulShellRoute.indexedStack` heuristics. State per branch MUST continue to be preserved.

(Previously: `goBranch` used `initialLocation` based only on whether the selected index matched the current index, which caused routes like `/gastos` to get stuck inside branch 2.)

#### Scenario: Gastos -> Ventas navega correctamente

- GIVEN the user is on `/gastos` inside the Ventas branch
- WHEN the user taps the Ventas tab
- THEN the app navigates to `/ventas`

#### Scenario: Deep link a ruta secundaria selecciona la rama correcta

- GIVEN the app receives a deep link to `/compras`
- WHEN the shell renders
- THEN branch 2 is selected
- AND the `/compras` page is displayed

#### Scenario: Estado de la rama se preserva

- GIVEN the user scrolled the Productos list and then switched to Dashboard
- WHEN the user returns to Productos
- THEN the list remains at the same scroll position

#### Scenario: Cinco ramas/tabs se mantienen

- GIVEN the shell is rendered
- WHEN the bottom navigation bar is inspected
- THEN exactly five destinations are shown
- AND the branch mapping covers Dashboard, Productos, Ventas, Reportes and Más

---

### R-M3 [BASE R52] Gráfica del dashboard por periodo

The dashboard chart requirement is MODIFIED: the provider MUST compute the full date range for the selected period and guarantee data for every interval in that range. It MUST use `ventasPorDia` only when it covers the entire range; otherwise it MUST fall back to `reportSalesProvider(range)`. Week and month MUST be grouped by day; year MUST be grouped by month. The implementation MUST NOT modify the backend or the Angular web frontend.

(Previously: the provider prioritized `ventasPorDia` and only queried `reportSalesProvider` when the grouped result was empty, which could render a single day.)

#### Scenario: Semana con datos parciales usa el fallback

- GIVEN the dashboard `ventasPorDia` only contains today's data
- WHEN the user selects "Esta Semana"
- THEN the app queries `reportes/ventas` for the full week range
- AND the chart shows one bar per day from Monday to today

#### Scenario: Mes agrupado por día

- GIVEN `ventasPorDia` is empty for the current month
- WHEN the user selects "Este Mes"
- THEN the app uses the report endpoint
- AND the chart groups sales by day of the month

#### Scenario: Año agrupado por mes

- GIVEN the user selects "Este Año"
- WHEN the chart loads
- THEN the data is grouped by month
- AND the range covers January 1 to today

#### Scenario: Nunca muestra un solo día

- GIVEN any period selector is active
- WHEN the chart renders
- THEN all intervals in the computed range are represented, even if their value is zero

#### Scenario: Web y backend no se modifican

- GIVEN the change is applied only to `flutter/`
- WHEN the Angular web dashboard is inspected
- THEN its behavior and backend endpoints remain unchanged

---

### R-M4 [BASE R37 / R40] Rediseño del layout del Chat IA

The chat screen requirement is MODIFIED: the loading indicator MUST appear as an assistant bubble placed below the last user message. Message bubbles MUST use a relative width (approximately 85% of the available width) instead of a fixed 700 dp. The composer MUST respect `MediaQuery.viewInsets`, have a compact min/max height, support internal scrolling for long text, integrate the send button, and show a discreet `0/1000` character counter. The message list MUST scroll smoothly to the latest message on send/receive. The layout MUST NOT use absolute `Positioned` widgets, reduced fonts or `FittedBox` to solve layout. The chat logic, prompts, RAG and endpoints MUST remain unchanged.

(Previously: loading used a `ListTile` that compressed text, bubbles had a fixed `maxWidth: 700`, the composer did not consider `viewInsets`, there was no auto-scroll, and the counter occupied extra space.)

#### Scenario: Indicador de carga integrado al flujo

- GIVEN the user has just sent a question
- WHEN the assistant is generating the answer
- THEN a loading bubble appears directly below the last user message
- AND it shows an animated indicator

#### Scenario: Burbujas con ancho relativo

- GIVEN the app runs on a narrow phone
- WHEN a chat bubble is rendered
- THEN its width is approximately 85% of the available message list width
- AND it is not constrained to a fixed 700 dp

#### Scenario: Scroll automático suave

- GIVEN the message list is scrolled up
- WHEN a new user message is sent or an assistant response arrives
- THEN the list animates smoothly to the bottom

#### Scenario: Composer con teclado abierto

- GIVEN the software keyboard is visible
- WHEN the composer renders
- THEN it stays above the keyboard using `viewInsets`
- AND no content is hidden behind the keyboard

#### Scenario: Composer compacto con contador discreto

- GIVEN the user types a long question
- WHEN the text exceeds the composer height
- THEN the text field scrolls internally up to the maximum height
- AND a small `0/1000` counter remains visible

---

### R-M5 [BASE R11-R15 / R18 / R21 / R24-R25] Refactor de formularios con componentes compartidos

The form screens requirement is MODIFIED: the approximately ten form screens (Venta, Compra, Movimiento, Gasto, Producto, Categoría, Proveedor, Cliente, Usuario, Rol) MUST use shared components such as `AppFormField`, `AppDropdownField` and `AppFormSection` (or equivalent names). They MUST apply `AppSpacing` consistently, group related fields under section titles, keep the form scrollable, place buttons in the natural flow, and ensure labels remain legible without overlapping. Existing validations, business logic, permission checks, models and endpoints MUST remain unchanged.

(Previously: forms mixed inline fields without consistent spacing or grouping, causing overlap and poor rhythm on small screens.)

#### Scenario: Componentes compartidos en formularios

- GIVEN the form screens are inspected
- THEN they import and use shared field and section widgets
- AND they do not duplicate the same inline input styling

#### Scenario: Espaciado consistente

- GIVEN two different form screens
- WHEN their vertical spacing is compared
- THEN both use tokens from `AppSpacing`
- AND no magic spacing numbers remain

#### Scenario: Labels sin superposición

- GIVEN a text field contains a value
- WHEN the field is focused or unfocused
- THEN the label does not overlap the input text

#### Scenario: Formulario scrollable con botón alcanzable

- GIVEN the device is small or the keyboard is open
- WHEN the user reaches the bottom of the form
- THEN the submit button is reachable by scrolling
- AND it follows the natural reading flow

#### Scenario: Validaciones y lógica preservadas

- GIVEN a form with existing validation rules
- WHEN invalid data is submitted
- THEN the same validation messages appear
- AND the same backend endpoint is called on success

---

### R-M6 [README] Sección de la app Flutter en el README

The README requirement is MODIFIED: `README.md` MUST include a Flutter app section describing the mobile stack, the `flutter/` directory structure, how to run tests, common build commands, and a summary of the new UX/offline features.

(Previously: the README documented backend and web frontend but omitted the Flutter app.)

#### Scenario: Sección Flutter presente

- GIVEN the `README.md` file is opened
- WHEN the Flutter section is located
- THEN it explains the purpose of the `flutter/` directory

#### Scenario: Comandos documentados

- GIVEN the Flutter section
- WHEN the commands are read
- THEN `flutter pub get`, `flutter analyze`, `flutter test` and `flutter build apk` are listed with the required `--dart-define` example

#### Scenario: Offline y rediseños documentados

- GIVEN the Flutter section
- WHEN the features are read
- THEN it summarizes the offline queue/sync, local notifications, chat layout redesign and form refactor

---

### R-M7 [BASE R47 / R65] Verificación y tests actualizados

The testing requirement is MODIFIED: the existing 77 tests MUST remain green. New tests MUST cover the offline queue, retry/backoff, online/offline transitions, JWT expiration handling, FAB toggle, shell navigation, dashboard chart grouping, chat layout/composer and the shared form components. `flutter analyze` MUST remain clean.

(Previously: the base spec referenced 52 existing tests; the current baseline is 77.)

#### Scenario: Tests existentes permanecen verdes

- GIVEN the existing 77 tests
- WHEN `flutter test` runs
- THEN all 77 tests pass

#### Scenario: Nuevos tests de offline

- GIVEN the offline queue, sync worker and conflict handling
- WHEN their tests run
- THEN they verify persistence, FIFO sync, backoff and `auth_required` behavior

#### Scenario: Nuevos tests de navegación y FAB

- GIVEN the chat FAB and shell navigation
- WHEN their widget tests run
- THEN they verify open/close toggle, icon changes and branch navigation

#### Scenario: Nuevos tests de dashboard, chat y formularios

- GIVEN the dashboard chart, chat layout and shared form components
- WHEN their tests run
- THEN they verify period grouping, composer behavior and component reuse

---

## REMOVED Requirements

No requirements are removed in this change. Existing requirements R6, R8, R37, R40, R47, R52, R55 and R65 are updated through the MODIFIED section above.

---

## NOT Requirements / Out of Scope

- Changes to `backend/`, REST contracts, PostgreSQL schema or Angular web frontend.
- Firebase Cloud Messaging / push notifications.
- Offline support for chat, authentication, catalogs, reports or administration beyond the list cache required for local state visualization.
- Changes to chat prompts, RAG logic, endpoints or conversation handling.
- Background sync is optional; if implemented, it MUST use network and battery constraints.
- Destructive silent synchronization that deletes or overwrites server data outside the already supported operations.

---

## Summary

| ID | Requirement | Type | Scenarios |
|----|-------------|------|-----------|
| R66 | Cola durable offline | Added | 5 |
| R67 | Sincronización automática | Added | 5 |
| R68 | JWT expirado durante sync | Added | 4 |
| R69 | Eficiencia batería/memoria | Added | 6 |
| R70 | Política de conflictos | Added | 3 |
| R71 | Esquema SQLite versionado | Added | 2 |
| R72 | Notificaciones locales | Added | 3 |
| R73 | Lectura offline de listados | Added | 3 |
| R-M1 | FAB chat toggle | Modified | 4 |
| R-M2 | Navegación shell determinista | Modified | 4 |
| R-M3 | Dashboard gráfica periodo | Modified | 5 |
| R-M4 | Rediseño layout Chat IA | Modified | 5 |
| R-M5 | Refactor formularios compartidos | Modified | 5 |
| R-M6 | Sección Flutter en README | Modified | 3 |
| R-M7 | Tests actualizados | Modified | 4 |

**Total added requirements**: 8  
**Total modified requirements**: 7  
**Total removed requirements**: 0  
**Total scenarios**: 61

### Cobertura

- **Happy paths**: covered (offline creation, auto-sync, FAB toggle, shell navigation, dashboard periods, chat composer, form refactor, README).
- **Edge cases**: covered (JWT expiration, rapid connectivity flapping, max retries, deep link without previous branch, partial dashboard data, long composer text).
- **Error states**: covered (401 during sync, terminal sync errors, validation conflicts, notification permission denied, empty cache offline).
- **Riesgos obligatorios**: JWT expirado (R68), batería/memoria (R69), conflictos last-write-wins (R70), esquema versionado (R71), preservación de tests (R-M7).

### Open Decisions

1. Background sync via `workmanager` is optional and will be enabled only if measurable value is demonstrated with network/battery constraints.
2. The backend currently does not expose a refresh-token endpoint; therefore the spec defines `auth_required` state and re-login resume instead of automatic silent refresh.
