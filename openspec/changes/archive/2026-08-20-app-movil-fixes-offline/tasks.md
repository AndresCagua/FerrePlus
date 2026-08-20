# Tasks: App movil fixes offline

**Change**: `app-movil-fixes-offline`  
**Scope**: `flutter/` only — no backend/frontend Angular changes.  
**Baseline**: 77 green tests, `flutter analyze` clean, Flutter 3.38.1 / Dart 3.10.0.  
**Architecture target**: Clean Architecture (`presentation → domain ← data`), Riverpod, GoRouter `StatefulShellRoute`, Drift SQLite.

---

## Phase 0: Infraestructura offline base

> Objetivo: dependencias, base SQLite versionada, modelos de dominio, DAOs tipados y providers Riverpod que el resto del change consume sin tocar UI.  
> Reqs cubiertos: **R66, R69, R71**.  
> Estimación: ~900 líneas nuevas (pubspec + schema + tablas + DAOs + modelos + providers + tests unitarios).

- [ ] **0.1** Actualizar `flutter/pubspec.yaml` con dependencias fijas compatibles Flutter 3.38.1 / Dart 3.10: `drift`, `sqlite3_flutter_libs`, `connectivity_plus`, `flutter_local_notifications`, `cryptography`, `drift_dev`, `build_runner`; revalidar versiones de Dio/Riverpod/GoRouter existentes.
  - *Done*: `flutter pub get` resuelve sin conflictos; `flutter analyze` sigue limpio; lockfile actualizado.
  - *Tests*: ninguno nuevo; no debe romper 77 tests existentes.

- [ ] **0.2** Crear `flutter/lib/domain/models/offline_models.dart` con: `OfflineOperationType` enum (`sale`, `expense`, `purchase`, `movement`, `saleVoid`, `purchaseVoid`), `PendingOperationStatus` enum (`pending`, `syncing`, `completed`, `authRequired`, `failed`), clase `PendingOperation`, `OfflineList<T>` y `OfflineSyncResult`.
  - *Req*: R66, R71.
  - *Done*: tipado explícito, `const` factories donde aplique, documentación de cada campo.
  - *Tests*: `test/domain/offline_models_test.dart` — serialización de enums y valores de `PendingOperation`.

- [ ] **0.3** Crear `flutter/lib/data/local/tables/pending_operations_table.dart` y `flutter/lib/data/local/tables/cached_*_tables.dart` (ventas, gastos, compras, movimientos) usando Drift DSL; definir `schemaVersion = 1` y migración identidad en `flutter/lib/data/local/app_database.dart`.
  - *Req*: R66, R71.
  - *Done*: columnas requeridas: `id`, `operation_type`, `endpoint`, `http_method`, `user_id`, `idempotency_key`, `payload_json`, `created_at`, `status`, `attempt_count`, `next_retry_at`, `last_error`, `response_json`, `local_record_key`; índices por `user_id + status + created_at` y `idempotency_key` único.
  - *Tests*: `test/data/local/app_database_test.dart` — apertura, versión de esquema > 0, migración 1→1 idempotente.

- [ ] **0.4** Crear DAOs: `flutter/lib/data/local/daos/pending_operations_dao.dart` y `flutter/lib/data/local/daos/cached_*_dao.dart` con queries FIFO, watch de conteos, batch de 10, upsert de cache y cleanup por edad/estado.
  - *Req*: R66, R69, R71.
  - *Done*: métodos `enqueue`, `nextBatch(limit: 10)`, `markSyncing`, `markCompleted`, `markAuthRequired`, `markFailed`, `watchPendingCount`, `cleanupCompleted(olderThan: Duration(days: 7))`, `countAll` y `totalPayloadSize`.
  - *Tests*: `test/data/local/daos/pending_operations_dao_test.dart` — FIFO, estados, retención de `completed`, conteo, límite de batch.

- [ ] **0.5** Crear `flutter/lib/data/offline/payload_codec.dart` con JSON canónico, cifrado AES-GCM con clave por instalación desde `flutter_secure_storage`, y sanitizador de errores que elimina body/headers/tokens/datos sensibles.
  - *Req*: R66, R68, R69, R70.
  - *Done*: funciones puras `encryptPayload`, `decryptPayload`, `sanitizeError`, `canonicalizeJson`; manejo de `SecureStorage` no disponible (bloquea creación offline, no pierde datos).
  - *Tests*: `test/data/offline/payload_codec_test.dart` — redondeo de JSON, cifrado reversible, sanitización de token y body.

- [ ] **0.6** Crear contratos de dominio: `flutter/lib/domain/repositories/offline_repository.dart` con interfaces `OfflineQueue`, `OfflineCache<T>` y `ConnectivityMonitor` (más adelante se agrega `SyncEngine`).
  - *Req*: R66, R67.
  - *Done*: interfaces abstractas sin imports de Drift ni UI; contratos de `enqueue`, `nextBatch`, `mark*`, `watchPendingCount`, `stabilizedOnline`.

- [ ] **0.7** Crear providers base en `flutter/lib/core/providers/offline_providers.dart`: `appDatabaseProvider`, `pendingOperationsDaoProvider`, `cached*DaoProvider`, `payloadCodecProvider`, `offlineQueueProvider`.
  - *Req*: R66, R71.
  - *Done*: todos `autoDispose` o `Provider` según lifecycle; `ref.onDispose` cierra DB cuando corresponda; en Web se provee implementación remota sin DB persistente.
  - *Tests*: `test/core/offline_providers_test.dart` — overrides con DB temporal; verificar dispose.

- [ ] **0.8** Actualizar `flutter/android/app/src/main/AndroidManifest.xml` con permiso `POST_NOTIFICATIONS` (Android 13+) y configuración de canales de `flutter_local_notifications`; dejar comentario de instrucciones para iOS en `flutter/ios/Runner/Info.plist` sin editar en este entorno.
  - *Req*: R72.
  - *Done*: build Android debug exitoso; manifest sin warnings de lint.

---

## Phase 1: Decorators offline de repositorios comerciales

> Objetivo: envolver `VentaRepository`, `CompraRepository`, `MovimientoRepository` y `GastoRepository` para que escrituras y listados soporten cache/fallback y cola offline.  
> Reqs cubiertos: **R66, R67, R70, R73**.  
> Estimación: ~1.200 líneas (4 decorators + adaptadores + providers + tests repository).

- [ ] **1.1** Crear adaptadores puros `flutter/lib/data/offline/adapters/sale_offline_adapter.dart`, `purchase_offline_adapter.dart`, `expense_offline_adapter.dart`, `movement_offline_adapter.dart` con funciones `toCacheJson`, `fromCacheJson`, `toOperation`, `voidOperation`.
  - *Req*: R66, R70.
  - *Done*: reutilizan `_saleRequest`, `_purchaseRequest`, etc., de `commercial_repositories_impl.dart` sin mover reglas de negocio; generan `idempotency_key` local.
  - *Tests*: `test/data/offline/adapters/*_adapter_test.dart` — payload/void para cada operación.

- [ ] **1.2** Crear `flutter/lib/data/offline/offline_venta_repository.dart` decorando `VentaRepository`: `list()` remote-first con fallback a cache + banner offline; `create`, `anular` online-first, ante timeout/connection encolan operación optimista.
  - *Req*: R66, R67, R70, R73.
  - *Done*: errores 4xx de validación no se convierten en offline; devuelve entidad local con `syncState`.
  - *Tests*: `test/data/offline/offline_venta_repository_test.dart` — online OK no deja pendiente, offline encola, fallback cache, 4xx no encola.

- [ ] **1.3** Crear `flutter/lib/data/offline/offline_compra_repository.dart` con mismo patrón y anulación (`PUT /api/compras/{id}/anular`).
  - *Req*: R66, R67, R70, R73.
  - *Tests*: `test/data/offline/offline_compra_repository_test.dart`.

- [ ] **1.4** Crear `flutter/lib/data/offline/offline_gasto_repository.dart`.
  - *Req*: R66, R67, R70, R73.
  - *Tests*: `test/data/offline/offline_gasto_repository_test.dart`.

- [ ] **1.5** Crear `flutter/lib/data/offline/offline_movimiento_repository.dart`.
  - *Req*: R66, R67, R70, R73.
  - *Tests*: `test/data/offline/offline_movimiento_repository_test.dart`.

- [ ] **1.6** Modificar `flutter/lib/presentation/features/commercial_providers.dart` para inyectar los decorators como implementaciones de los repositorios existentes; mantener APIs públicas.
  - *Req*: R66, R67, R73.
  - *Done*: providers actuales resuelven a `Offline*Repository` con repositorio remoto inyectado; sin cambios en notifiers.
  - *Tests*: ejecutar 77 tests; ninguno debe fallar por cambio de provider.

- [ ] **1.7** Crear `flutter/lib/presentation/shared/widgets/offline_banner.dart` con `OfflineBanner` (indicador visible cuando se muestra cache offline) y `OfflineEmptyState` (sin cache y sin red).
  - *Req*: R73.
  - *Done*: banner genérico, no expone datos sensibles; empty state con mensaje offline.
  - *Tests*: `test/presentation/shared/offline_banner_test.dart`.

---

## Phase 2: SyncEngine y monitor de conectividad

> Objetivo: orquestar la sincronización FIFO, backoff, 401, conflictos, cleanup y lifecycle sin polling.  
> Reqs cubiertos: **R67, R68, R69, R70, R71**.  
> Estimación: ~1.000 líneas (monitor + engine + coordinator + tests sync).

- [ ] **2.1** Crear `flutter/lib/data/services/connectivity_monitor.dart`: escucha `connectivity_plus`, debounce 750 ms, emite `stabilizedOnline`; suscripción cancelable en `dispose`.
  - *Req*: R69.
  - *Done*: no usa timers de polling; maneja flapping; dispose en `ref.onDispose`.
  - *Tests*: `test/data/services/connectivity_monitor_test.dart` — debounce, dispose sin fugas.

- [ ] **2.2** Crear `flutter/lib/data/services/sync_engine.dart` con mutex, batch de 10, FIFO, backoff exponencial `min(30s * 2^(attempt-1) + jitter, 30min)`, máximo 5 intentos, 401→`authRequired`, 409/422→terminal `failed`, y cleanup post-sync.
  - *Req*: R67, R68, R69, R70, R71.
  - *Done*: envía `X-Idempotency-Key`; actualiza cache con respuesta; no duplica `completed`; limita cola a 500 ops / 20 MB.
  - *Tests*: `test/data/services/sync_engine_test.dart` — FIFO, backoff determinista con reloj fake, 401 pausa, 409 terminal, límite de cola.

- [ ] **2.3** Crear `flutter/lib/data/services/sync_notification_service.dart`: canal Android `sync_status`, permisos, notificación agrupada por count pending/syncing/auth_required y notificación de error/auth genérica sin datos sensibles.
  - *Req*: R72.
  - *Done*: permiso denegado no crashea; textos genéricos; grupo `ferreplus_sync`.
  - *Tests*: `test/data/services/sync_notification_service_test.dart` con fake plugin.

- [ ] **2.4** Crear `flutter/lib/data/services/offline_coordinator.dart` que conecta monitor → engine → notificaciones; expone `offlineSyncEnabledProvider` de emergencia.
  - *Req*: R67, R69, R72.
  - *Done*: dispara `syncNow()` al online estabilizado y `resumeAfterLogin()` tras autenticación; mutex global.

- [ ] **2.5** Modificar `flutter/lib/data/interceptors/auth_interceptor.dart` para notificar al coordinador antes del logout por 401.
  - *Req*: R68.
  - *Done*: interceptor llama `coordinator.onUnauthorized()`; no limpia cola ni clave de cifrado.
  - *Tests*: `test/data/interceptors/auth_interceptor_test.dart` (nuevo/actualizar) — 401 marca `authRequired`.

- [ ] **2.6** Modificar `flutter/lib/core/providers/auth_providers.dart`: tras login exitoso llamar `resumeAfterLogin()`; asegurar que logout no borre cola ni clave de cifrado.
  - *Req*: R68.
  - *Done*: login → resume; logout → cola intacta.
  - *Tests*: `test/core/auth_providers_test.dart` (actualizar/crear) — cola sobrevive logout.

- [ ] **2.7** Integrar providers en `flutter/lib/core/providers/offline_providers.dart`: `connectivityMonitorProvider`, `syncEngineProvider`, `syncNotificationServiceProvider`, `offlineCoordinatorProvider`.
  - *Req*: R67, R69.
  - *Done*: providers con `ref.onDispose` y overrides posibles.

---

## Phase 3: Notificaciones locales y banners

> Objetivo: exponer UI de estado offline/notificaciones y validar permisos.  
> Reqs cubiertos: **R72, R73**.  
> Estimación: ~250 líneas (widgets + tests).

- [ ] **3.1** Crear `flutter/lib/presentation/shared/widgets/sync_status_chip.dart` que muestre count de pendientes/error/auth de forma genérica en listados comerciales.
  - *Req*: R72, R73.
  - *Done*: widget sin datos sensibles; tap opcional para explicación.
  - *Tests*: `test/presentation/shared/sync_status_chip_test.dart`.

- [ ] **3.2** Agregar banner/offline indicator a las cuatro pantallas de listado comercial usando `OfflineBanner`/`OfflineEmptyState`.
  - *Req*: R73.
  - *Done*: Ventas, Gastos, Compras, Movimientos muestran estado offline/cache.
  - *Tests*: widget tests por pantalla (pueden agruparse en `commercial_list_offline_test.dart`).

---

## Phase 4: Navegación del shell y FAB chat toggle

> Objetivo: corregir `ShellScaffold` y `ChatFloatingActionButton` con mapa canónico y toggle basado en ruta actual.  
> Reqs cubiertos: **R-M1, R-M2**.  
> Estimación: ~400 líneas (router + shell + FAB + tests widget).

- [ ] **4.1** Modificar `flutter/lib/core/routing/app_router.dart`: agregar `branchInitialRoutes` map inmutable (`0→/`, `1→/productos`, `2→/ventas`, `3→/reportes`, `4→/mas`) y provider `chatPreviousLocationProvider`.
  - *Req*: R-M1, R-M2.
  - *Done*: mapa centralizado; deep link a rutas secundarias selecciona rama correcta.
  - *Tests*: `test/core/routing/app_router_test.dart` — branch mapping y deep links.

- [ ] **4.2** Modificar `flutter/lib/presentation/shell/shell_scaffold.dart`: usar `branchIndex → canonical initial route`; navegación explícita a ruta canónica; `goBranch` solo para cambio de rama; preservar estado.
  - *Req*: R-M2.
  - *Done*: Gastos → Ventas navega a `/ventas`; 5 tabs intactas; estado por rama preservado.
  - *Tests*: `test/presentation/shell/shell_scaffold_test.dart` — cambios de rama, rutas secundarias, 5 destinos.

- [ ] **4.3** Modificar `flutter/lib/presentation/shell/chat_floating_action_button.dart`: leer ruta actual; fuera de `/chat` guarda ruta previa y navega a `/chat`; en `/chat` muestra close y vuelve a ruta previa o `/`; preservar drag.
  - *Req*: R-M1.
  - *Done*: icono/tooltip/semantics dinámicos; accesible; no rompe `DraggableChatFab`.
  - *Tests*: `test/presentation/shell/chat_floating_action_button_test.dart` — open/close, icono, tooltip, deep link fallback.

---

## Phase 5: Dashboard por periodo

> Objetivo: garantizar que la gráfica cubra todo el rango seleccionado sin modificar backend.  
> Reqs cubiertos: **R-M3**.  
> Estimación: ~250 líneas (provider + tests).

- [ ] **5.1** Modificar `flutter/lib/presentation/features/dashboard/dashboard_provider.dart`: calcular `DateRange` por periodo; usar `ventasPorDia` solo si cubre todo el rango; fallback a `reportSalesProvider(range)`; agrupar semana/mes por día y año por mes; rellenar intervalos con cero.
  - *Req*: R-M3.
  - *Done*: no modifica backend/web; cubre semana/mes/año/vacío/error/cambio de periodo.
  - *Tests*: `test/presentation/features/dashboard/dashboard_provider_test.dart` — datos parciales usan fallback, año agrupado por mes, nunca un solo día.

---

## Phase 6: Rediseño del layout del Chat IA

> Objetivo: layout responsive, composer con teclado, scroll automático e indicador integrado sin cambiar lógica IA.  
> Reqs cubiertos: **R-M4**.  
> Estimación: ~600 líneas (página + widgets + tests widget).

- [ ] **6.1** Crear `flutter/lib/presentation/features/chat/widgets/chat_assistant_loading_bubble.dart`: burbuja assistant debajo del último mensaje del usuario, animación de 3 puntos, soporte `AnimationController` con dispose y reduced motion.
  - *Req*: R-M4.
  - *Done*: ancho relativo 85 %; no usa `ListTile`; accesible.
  - *Tests*: `test/presentation/features/chat/chat_assistant_loading_bubble_test.dart`.

- [ ] **6.2** Crear `flutter/lib/presentation/features/chat/widgets/chat_composer.dart`: `SafeArea` + `Padding(bottom: MediaQuery.viewInsetsOf(context).bottom)`, altura min/max, `TextField` multilinea con scroll interno, botón send integrado, contador discreto `0/1000`.
  - *Req*: R-M4.
  - *Done*: no `Positioned`; const donde sea posible.
  - *Tests*: `test/presentation/features/chat/chat_composer_test.dart` — insets, scroll interno, contador, altura.

- [ ] **6.3** Refactorizar `flutter/lib/presentation/features/chat/pages/chat_page.dart`: separar lista en widget interno, burbujas con `FractionallySizedBox(widthFactor: .85)`, `ScrollController` con dispose, autoscroll animado al enviar/recibir.
  - *Req*: R-M4.
  - *Done*: conserva `ChatState`, provider, markdown, fuentes y `conversationId`; no altera prompts/RAG/endpoints.
  - *Tests*: `test/presentation/features/chat/chat_page_test.dart` — scroll automático, ancho burbuja, composer con teclado.

---

## Phase 7: Componentes de formulario y refactor de ~10 pantallas

> Objetivo: crear widgets compartidos y migrar mecánicamente Venta, Compra, Movimiento, Gasto, Producto, Categoría, Proveedor, Cliente, Usuario, Rol.  
> Reqs cubiertos: **R-M5**.  
> Estimación: ~1.800 líneas (3 shared widgets + 10 pantallas + tests widget).

- [ ] **7.1** Crear `flutter/lib/presentation/shared/widgets/app_form_field.dart`: wrapper tipado de `TextFormField` con API compatible (`controller`, `initialValue`, `keyboardType`, `enabled`, `obscureText`, `validator`, `onChanged`, `decoration`), `AppSpacing`, label no superpuesto, target táctil ≥48 dp.
  - *Req*: R-M5.
  - *Done*: reutilizable; no duplica lógica de validación.
  - *Tests*: `test/presentation/shared/form_widgets_test.dart` — AppFormField.

- [ ] **7.2** Crear `flutter/lib/presentation/shared/widgets/app_dropdown_field.dart`: wrapper de dropdown con `validator`, `decoration`, `AppSpacing` y API compatible con dropdowns existentes.
  - *Req*: R-M5.
  - *Tests*: `test/presentation/shared/form_widgets_test.dart` — AppDropdownField.

- [ ] **7.3** Crear `flutter/lib/presentation/shared/widgets/app_form_section.dart`: título, semantics, spacing `AppSpacing`, children.
  - *Req*: R-M5.
  - *Tests*: `test/presentation/shared/form_widgets_test.dart` — AppFormSection.

- [ ] **7.4** Refactorizar formularios comerciales en `flutter/lib/presentation/features/commercial_pages.dart` (Venta, Compra, Movimiento, Gasto): secciones, scroll, spacing, shared fields, botones en flujo natural; conservar validaciones/permisos/endpoints.
  - *Req*: R-M5.
  - *Done*: sin magic numbers; labels legibles; form scrollable.
  - *Tests*: widget tests por formulario o agrupados en `commercial_forms_test.dart`.

- [ ] **7.5** Refactorizar `flutter/lib/presentation/features/productos/productos_pages.dart`.
  - *Req*: R-M5.
  - *Tests*: widget test correspondiente.

- [ ] **7.6** Refactorizar `flutter/lib/presentation/features/categorias/categorias_pages.dart`, `catalog_pages.dart` (Proveedor, Cliente) y `admin_pages.dart` (Usuario, Rol).
  - *Req*: R-M5.
  - *Done*: Categoría, Proveedor, Cliente, Usuario, Rol usan shared widgets.
  - *Tests*: `test/presentation/features/catalog_forms_test.dart`, `admin_forms_test.dart`.

- [ ] **7.7** Ejecutar `flutter analyze` y corregir warnings tras refactor de formularios.
  - *Done*: `flutter analyze` limpio.

---

## Phase 8: README, build, regresión y verificación final

> Objetivo: documentar Flutter/offline, garantizar 77 tests verdes, analizar limpio y build Android.  
> Reqs cubiertos: **R-M6, R-M7**.  
> Estimación: ~300 líneas (README + integration test + ajustes finales).

- [ ] **8.1** Actualizar `README.md` con sección Flutter: stack, estructura `presentation/domain/data`, comandos (`flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk` con `--dart-define` ejemplo), resumen de offline queue/sync, notificaciones locales, rediseño chat/formularios.
  - *Req*: R-M6.
  - *Done*: sección clara, comandos copiables, no toca backend/web docs.

- [ ] **8.2** Crear `flutter/integration_test/offline_sync_test.dart`: flujo completo — guardar venta offline, matar/reabrir app, recuperar red, login tras 401, verificar sync y lectura cache.
  - *Req*: R66, R67, R68, R73.
  - *Done*: usa fake API/DB temporal; Android target primario.

- [ ] **8.3** Ejecutar suite completa: `flutter test`, `flutter analyze`, `flutter build apk --debug`; verificar 77 tests existentes + nuevos verdes.
  - *Req*: R-M7.
  - *Done*: todos los tests pasan; analizador limpio; build exitoso.

- [ ] **8.4** Auditar memoria/batería: validar `dispose` de subscriptions, `ScrollController`, notificaciones agrupadas; documentar hallazgos en bitácora o comentario de `README.md`.
  - *Req*: R69, R72.
  - *Done*: sin polling, debounce 750 ms, batches de 10, cleanup programado.

---

## Review Workload Forecast

| Fase | Estimación líneas cambiadas | Riesgo de regresión | Observaciones |
|------|----------------------------|---------------------|---------------|
| 0 — Infra offline base | ~900 | Medio | Nuevos archivos; no toca UI existente. |
| 1 — Decorators repositories | ~1.200 | Alto | Cambia providers comerciales; posible impacto en 77 tests. |
| 2 — SyncEngine + monitor | ~1.000 | Alto | Lógica crítica de auth, retry, conflictos. |
| 3 — Notificaciones/banners | ~250 | Bajo | UI accesoria. |
| 4 — Navegación shell + FAB | ~400 | Medio | Router sensible; deep links. |
| 5 — Dashboard periodo | ~250 | Bajo | Provider aislado. |
| 6 — Chat layout | ~600 | Medio | UI con teclado/scroll; no lógica IA. |
| 7 — Formularios refactor | ~1.800 | **Muy Alto** | ~10 pantallas; mayor riesgo de romper validaciones/flujo. |
| 8 — README + verificación | ~300 | Bajo | Documentación + build. |
| **Total** | **~5.700 líneas** | | |

### ¿Chained PRs recommended?

**Sí.** El change supera ampliamente 800 líneas y tiene múltiples frentes de alto riesgo. Se proponen **4 PRs encadenados**:

1. **Slice 1 — Offline core** (Fases 0–2): Drift, DAOs, codec, decorators, SyncEngine, auth, notificaciones. Mayor riesgo técnico; se revisa primero.
2. **Slice 2 — Navegación y shell** (Fase 4): router canónico, `ShellScaffold`, FAB toggle. Aisla regresiones de routing.
3. **Slice 3 — Dashboard y Chat** (Fases 5–6): provider de dashboard y rediseño de chat. UI/UX puro.
4. **Slice 4 — Formularios y docs** (Fases 7–8): refactor de formularios, README, suite final. El más grande en líneas, pero depende solo de shared widgets.

### 400-line budget risk

**High.** Solo la Fase 7 ya estima ~1.800 líneas; todo el change ronda las 5.700. Es imperativo cortar en slices.

### Decision needed before apply

**Yes.** Decidir:
1. ¿Se acepta Drift como motor SQLite (ADR-22) o se prefiere reevaluar `sqflite`?
2. ¿Se aprueba NO incluir `workmanager` en esta entrega (ADR-27) y depender de foreground/resume/connectivity?
3. ¿Se confirma que el backend NO tiene refresh token (especificación asume re-login)?
4. ¿Se acepta el corte de 4 chained PRs o se prefiere otro orden?

---

## skill_resolution

- **Stack detectado**: Flutter/Dart (pubspec.yaml con flutter dependency, Clean Architecture, Riverpod, GoRouter).
- **Specialist consultado**: `especialista_flutter.md`.
- **Skills aplicables para sdd-apply**: `flutter-expert`, `flutter-apply-architecture-best-practices`, `flutter-add-widget-test`, `flutter-add-integration-test`, `flutter-setup-declarative-routing`, `clean-code`.
- **Convenciones aplicadas**: capas `presentation/domain/data`, Riverpod providers con `autoDispose`, `const` constructors, tipado explícito, `AppSpacing`, widgets compuestos, declarative routing con GoRouter, tests unit/widget/integration.
