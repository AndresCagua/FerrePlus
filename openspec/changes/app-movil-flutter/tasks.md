# Tasks: Aplicación móvil Flutter de Ferreplus

## Phase 0 — Environment bootstrap (one-time)

- [x] 0.1 Verificar entorno de desarrollo ejecutando `flutter --version`, `dart --version` y comprobando Android SDK / Xcode; documentar versiones mínimas en `flutter/AGENTS.md`. No instalar nada sin autorización explícita del usuario.
- [x] 0.2 Crear el proyecto Flutter en `flutter/` con el comando: `flutter create --org com.ferreplus --project-name ferreplus flutter`. Confirmar que existen `flutter/android`, `flutter/ios` y `flutter/lib`.
- [x] 0.3 Configurar `flutter/pubspec.yaml` con dependencias fijadas: `flutter_riverpod`, `go_router`, `dio`, `flutter_secure_storage`, `freezed_annotation`, `json_annotation`, `build_runner`, `freezed`, `json_serializable`, `flutter_markdown`, `intl`, `fl_chart`, `mocktail`, `flutter_lints`. Ejecutar `flutter pub get`.
- [x] 0.4 Crear `flutter/analysis_options.yaml` con `strict-casts: true`, `strict-raw-types: true`, `prefer_const_constructors`, `prefer_const_declarations`, `avoid_dynamic_calls` y lints de tipado explícito.
- [x] 0.5 Crear `flutter/.gitignore` excluyendo `build/`, `.dart_tool/`, `.idea/`, `*.iml`, `ios/Pods`, `ios/.symlinks`, `android/.gradle`, `android/app/*.keystore`, `.flutter-plugins`, `.flutter-plugins-dependencies`, `coverage/`.
- [x] 0.6 Configurar Android: agregar `<uses-permission android:name="android.permission.INTERNET" />` en `android/app/src/main/AndroidManifest.xml`; crear `android/app/src/main/res/xml/network_security_config.xml` con `cleartextTrafficPermitted` solo para debug; fijar `minSdk` 24+ y `applicationId com.ferreplus` en `android/app/build.gradle`.
- [x] 0.7 Configurar nombre visible de la app: `android:label="FerrePlus"` en `AndroidManifest.xml`; actualizar `pubspec.yaml` name; ajustar `ios/Runner/Info.plist` `CFBundleDisplayName`.
- [x] 0.8 Crear `flutter/AGENTS.md` con convenciones locales: estructura de capas, nombres de archivos, comandos de build/test, formato de commits del proyecto (asunto `YYYYMMDD`, cuerpo `tipo(scope):` bullets en español) y notas del emulador `10.0.2.2`.
- [x] 0.9 Ejecutar `flutter analyze` sobre el proyecto base y garantizar cero warnings antes de continuar.
- [x] 0.10 Ejecutar `flutter test` y dejar el test por defecto o reemplazarlo por un smoke mínimo que compile.

## Phase 1 — Slice S1: Scaffolding, configuración y autenticación (R1–R10, R44–R47 parcial)

- [ ] 1.1 Crear constantes de API en `flutter/lib/core/constants/api_paths.dart` con las rutas REST (`/api/auth/login`, `/api/usuarios/me`, etc.) y `flutter/lib/core/constants/permission_codes.dart` con las autoridades conocidas como constantes.
- [ ] 1.2 Crear `flutter/lib/core/config/api_config.dart` que lea `API_BASE_URL` exclusivamente mediante `String.fromEnvironment`, con valor por defecto de desarrollo `http://10.0.2.2:8080` para Android emulator; crear `flutter/lib/core/config/app_config.dart` para timeouts y flags. (R9)
- [ ] 1.3 Definir el modelo de dominio `AuthSession` en `flutter/lib/domain/models/auth_session.dart` y el DTO `AuthDto`/`UsuarioMeDto` en `flutter/lib/data/models/`, usando `freezed` + `json_serializable`. (R1, R4)
- [ ] 1.4 Crear la interfaz `SessionStorage` en `flutter/lib/domain/repositories/session_storage.dart` y la implementación `flutter/lib/data/services/session_storage_impl.dart` con `flutter_secure_storage`, claves `jwt_token`, `session_user`, `session_permissions` y limpieza ante lectura corrupta. (R2)
- [ ] 1.5 Crear `flutter/lib/core/errors/failure.dart` (unión de fallos de dominio) y `flutter/lib/core/errors/failure_mapper.dart` para traducir `DioException` y códigos HTTP a `Failure`. (R44)
- [ ] 1.6 Crear `flutter/lib/data/services/api_client.dart` como wrapper tipado de Dio; añadir `auth_interceptor.dart` para inyectar `Authorization: Bearer` y ejecutar logout idempotente ante 401; añadir `error_interceptor.dart` para log técnico controlado. (R1, R3)
- [ ] 1.7 Crear `flutter/lib/core/formatters/date_formatter.dart` y `currency_formatter.dart` para formato de UI (`dd/MM/yyyy HH:mm`) y serialización ISO; usar en toda la app. (R45)
- [ ] 1.8 Crear casos de uso `Login`, `RestoreSession` y `RefreshPermissions` en `flutter/lib/domain/use_cases/`; crear el repositorio `AuthRepository` e implementación que consuma `/api/auth/login` y `/api/usuarios/me`. (R1, R2, R4)
- [ ] 1.9 Crear `flutter/lib/core/providers/storage_provider.dart`, `api_client_provider.dart`; crear `AuthNotifier` como `AsyncNotifier<AuthState>` con estados `loading`, `unauthenticated`, `authenticated`, `failure`; crear `permissionSetProvider` derivado como `Set<String>` y helper `hasPermission`. (R1–R4, R46)
- [ ] 1.10 Configurar GoRouter en `flutter/lib/core/routing/app_router.dart` con `MaterialApp.router`, `StatefulShellRoute.indexedStack`, rutas `/login`, `/registro-inicial`, `/dashboard`, `/productos`, etc.; implementar `auth_redirect.dart` y `route_permissions.dart`. (R6, R7)
- [ ] 1.11 Crear `flutter/lib/presentation/shell/main_shell.dart` con `NavigationBar` / `NavigationDrawer` cuyos destinos se filtren por permisos efectivos. (R7, R8)
- [ ] 1.12 Crear `flutter/lib/presentation/features/auth/pages/login_page.dart` y widgets de formulario con validación de email/password; integrar `AuthNotifier`. (R1)
- [ ] 1.13 Crear `flutter/lib/presentation/features/auth/pages/initial_admin_page.dart` para el flujo de registro inicial condicional cuando el backend indique que no hay usuarios; redirigir a `/login` tras éxito. (R5)
- [ ] 1.14 Crear `flutter/lib/presentation/features/dashboard/pages/dashboard_page.dart` inicial y su provider básico. (R8)
- [ ] 1.15 Crear widgets compartidos en `flutter/lib/presentation/shared/widgets/`: `LoadingState`, `EmptyState`, `ErrorState` con reintentar, `PermissionGate`, `ConfirmDialog`. (R44, R46)
- [ ] 1.16 Suite de tests S1: unitarios de `ApiConfig`, mapeadores, storage corrupto, interceptor 401, failure mapper, `AuthNotifier`, guards de permisos; widget tests de login exitoso/fallido, shell filtrado, dashboard y logout. Ejecutar `flutter test`. (R10, R47)
- [ ] 1.17 Smoke check manual: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080` en emulator/dispositivo; verificar login, persistencia, redirección 401 y shell. (R1–R4)
- [ ] 1.18 Actualizar `README.md` raíz con sección de configuración de Flutter: prerequisitos, `flutter pub get`, comandos de run/build y nota de `10.0.2.2` / `--dart-define`.
- [ ] 1.19 Generar commits atómicos con formato de proyecto y detener la cadena para revisión del usuario antes de S2.

## Phase 2 — Slice S2: Catálogos y CRUD core (R11–R16)

- [x] 2.1 Crear modelos de dominio y DTOs `Producto`, `Categoria`, `Proveedor`, `Cliente` en `flutter/lib/domain/models/` y `flutter/lib/data/models/`, con enums tolerantes y converters de fechas; mapeadores DTO → dominio. (R11–R15)
- [x] 2.2 Crear interfaces de repositorio en `flutter/lib/domain/repositories/` e implementaciones en `flutter/lib/data/repositories/` para productos, categorías, proveedores y clientes (listar, crear, editar, eliminar, filtros de búsqueda). (R11–R15)
- [x] 2.3 Crear providers `productosProvider`, `categoriasProvider`, `proveedoresProvider`, `clientesProvider` como `AsyncNotifier` con estado de consulta (búsqueda, filtros) y métodos `reload()` / invalidación. (R11)
- [x] 2.4 Crear `flutter/lib/presentation/features/productos/pages/productos_list_page.dart` con búsqueda por nombre/código, filtros, `ListView.builder`, estados vacío/carga/error y navegación a detalle. (R11)
- [x] 2.5 Crear `flutter/lib/presentation/features/productos/pages/producto_form_page.dart` para alta/edición de productos con validaciones; ocultar acciones según `PRODUCTOS_CREAR` / `PRODUCTOS_EDITAR`. (R12)
- [x] 2.6 Crear pantallas list/form para categorías, proveedores y clientes reutilizando widgets comunes donde sea posible. (R13–R15)
- [x] 2.7 Crear widgets reutilizables `PermissionVisibility` / `PermissionButton` y aplicarlos a todos los catálogos para ocultar/deshabilitar crear, editar y eliminar sin permiso. (R16, R46)
- [x] 2.8 Suite de tests S2: unitarios de mapeadores, repositorios (URLs y payloads), filtros e invalidación de providers; widget tests de lista vacía/carga/error, búsqueda, formulario representativo y botones ocultos. Ejecutar `flutter test`. (R47)
- [ ] 2.9 Smoke check manual: ejecutar flujos de catálogos en emulator y verificar que las acciones de escritura se oculten sin permiso. (R11–R16)
- [ ] 2.10 Generar commits atómicos con formato de proyecto y detener la cadena para revisión del usuario antes de S3.

## Phase 3 — Slice S3: Operación comercial (R17–R26)

- [x] 3.1 Crear modelos de dominio y DTOs `Venta`, `DetalleVenta`, `Compra`, `DetalleCompra`, `MovimientoStock`, `Gasto`; enums con fallback `unknown` para `estado`, `tipo`, `metodoPago`; converters y mapeadores. (R17–R25)
- [x] 3.2 Crear repositorios e implementaciones para ventas, compras, movimientos de stock y gastos (listar, detalle, crear, editar, anulación). (R17–R25)
- [x] 3.3 Crear casos de uso `BuildSale` y `BuildPurchase` en `flutter/lib/domain/use_cases/` para calcular subtotal, descuento, IVA y total, y validar al menos un detalle, cantidades/positivos y stock insuficiente en ventas. (R18, R21)
- [x] 3.4 Crear providers: `ventasProvider` con filtros; `posNotifier` para el formulario POS; `comprasProvider` y notifier de formulario; `movimientosProvider`; `gastosProvider`. (R17–R25)
- [x] 3.5 Crear `flutter/lib/presentation/features/ventas/pages/ventas_list_page.dart` con filtros por fecha, estado y cliente; pantalla de detalle de venta. (R17)
- [x] 3.6 Crear `flutter/lib/presentation/features/ventas/pages/pos_page.dart` con selector de producto, cantidad, precio unitario, listado de líneas, cálculo de totales y botón guardar; mostrar errores de validación. (R18)
- [x] 3.7 Implementar anulación de ventas en detalle: diálogo de confirmación y llamada `PUT /api/ventas/{id}/anular`, actualizando el listado; ocultar si no hay `VENTAS_ELIMINAR`. (R19)
- [x] 3.8 Crear pantallas de listado y formulario de compras (crear/editar) y anulación con `COMPRAS_ELIMINAR`. (R21, R22)
- [x] 3.9 Crear pantalla de movimientos de stock con filtros y formulario de alta; implementar `POST /api/movimientos-stock`. (R24)
- [x] 3.10 Crear pantallas de listado y formulario de gastos con permisos correspondientes. (R25)
- [x] 3.11 Crear pantallas de reporte de ventas y reporte de compras por rango de fechas. (R20, R23)
- [x] 3.12 Suite de tests S3: unitarios de cálculos POS/compras, payloads exactos, validación de stock, anulación, mapeo de errores; widget tests del POS con dos líneas, formulario de compra, confirmación de anulación y mensaje 422. Ejecutar `flutter test`. (R47)
- [ ] 3.13 Smoke check manual: ejecutar venta POS, anulación, compra, movimiento de stock y gasto en emulator; validar permisos comerciales. (R17–R26)
- [ ] 3.14 Generar commits atómicos con formato de proyecto y detener la cadena para revisión del usuario antes de S4.

## Phase 4 — Slice S4: Administración, precios y analíticas (R27–R36)

- [x] 4.1 Crear modelos de dominio y DTOs `PrecioProducto`, `HistoricoPrecio`, `Usuario`, `Rol`, `Modulo`, `Permiso`, `Auditoria`, `ReporteDashboard`, `ReporteVentas`, `ReporteInventario`, `ReporteMovimientos`; mapeadores. (R27–R35)
- [x] 4.2 Crear repositorios e implementaciones para precios, usuarios, roles, catálogo de módulos/permisos, reportes y logs. (R27–R35)
- [x] 4.3 Crear caso de uso `UpdateSalePrice` que soporte actualización por `nuevoPrecio` o `margenPorcentaje`. (R28)
- [x] 4.4 Crear providers: precios, usuarios, roles, módulos/permisos, dashboard, reportes y logs paginados con estado de filtros. (R27–R35)
- [x] 4.5 Crear `flutter/lib/presentation/features/precios/pages/precios_list_page.dart` y `precio_historial_page.dart`; implementar acción de actualizar precio oculta sin `PRECIOS_EDITAR`. (R27, R28)
- [x] 4.6 Crear pantallas de usuarios: listado, formulario de creación/edición, cambio de contraseña y overrides de permisos; proteger con `USUARIOS_*`. (R29)
- [x] 4.7 Crear pantallas de roles: listado y formulario con matriz de permisos obtenida de `/api/modulos` y `/api/permisos`; proteger con `ROLES_*`. (R30, R31)
- [x] 4.8 Crear `flutter/lib/presentation/features/dashboard/pages/dashboard_page.dart` completo con KPIs y gráfica (`fl_chart`) desde `/api/reportes/dashboard`; manejar error con reintentar. (R32)
- [x] 4.9 Crear pantallas de reportes: ventas, inventario y movimientos, con filtros de fecha y totales. (R33)
- [x] 4.10 Crear `flutter/lib/presentation/features/logs/pages/logs_page.dart` con tabla paginada, filtros (fecha, usuario, entidad, acción) y borrado por rango con confirmación; proteger con `LOGS_VER` / `LOGS_ELIMINAR`. (R34, R35)
- [x] 4.11 Aplicar visibilidad por permisos en todas las rutas y acciones administrativas. (R36, R46)
- [x] 4.12 Suite de tests S4: unitarios de cálculo de margen, mapeo de matriz de roles, paginación/filtros de logs, mapeo de reportes; widget tests de tablas, KPIs/error-retry, matriz y acciones ocultas. Ejecutar `flutter test`. (R47)
- [ ] 4.13 Smoke check manual: ejecutar dashboard, precios, usuarios, roles, reportes y logs en emulator. (R27–R36)
- [ ] 4.14 Generar commits atómicos con formato de proyecto y detener la cadena para revisión del usuario antes de S5.

## Phase 5 — Slice S5: Chat y polish de entrega (R37–R43, cierre de R44–R47)

- [x] 5.1 Crear modelos de dominio y DTOs `ChatResponse`, `ChatSource`, `ChatMessage`; mapeadores. (R37, R39)
- [x] 5.2 Crear `ChatRepository` e implementación para `POST /api/chat`; crear casos de uso `SendChatMessage` y `RebuildChatIndex`. (R37, R41)
- [x] 5.3 Crear `ChatNotifier` con historial de mensajes, `conversationId`, `isSending`, `error`; garantizar que los errores no borren el historial. (R37, R40)
- [x] 5.4 Crear `flutter/lib/presentation/features/chat/pages/chat_page.dart` con burbujas de mensaje, campo de entrada y estados de carga/error. (R37)
- [x] 5.5 Implementar renderizado seguro de Markdown en `flutter/lib/presentation/features/chat/widgets/safe_markdown_renderer.dart`: escapar HTML, soportar listas, negritas, cursivas y párrafos; fallback ante Markdown malformado. Parser propio por seguridad. (R38)
- [x] 5.6 Crear widget `ChatSourcesAccordion` que muestre `sources[]` en un `ExpansionTile` y se oculte cuando la lista sea nula/vacía. (R39)
- [x] 5.7 Agregar acción de reconstrucción de índice en la pantalla de chat, visible solo con `CHAT_INDEX_REBUILD`, con diálogo de confirmación. (R41)
- [x] 5.8 Pasada de accesibilidad: agregar labels semánticos a iconos/botones, asegurar touch targets mínimo 48 dp y revisar contraste. (R42)
- [x] 5.9 Pasada de rendimiento: verificar `const` constructors y `ListView.builder`; sin `RepaintBoundary` adicional necesario en esta pantalla. (R42)
- [x] 5.10 Finalizar `flutter/lib/presentation/theme/app_theme.dart` con Material 3 y colores alineados al frontend; se conserva icono/splash base de Flutter ya configurado. (R43)
- [x] 5.11 Actualizar `flutter/README.md` con instrucciones de build, tests, arquitectura y troubleshooting de emulador/dispositivo. (docs)
- [ ] 5.12 Crear `flutter/integration_test/authenticated_smoke_test.dart` con flujo login → dashboard → catálogo representativo. (R47)
- [x] 5.13 Suite de tests S5: parser Markdown seguro, fuentes, preservación de `conversationId`, error sin pérdida de historial y acordeón. Ejecutar `flutter test`. (R38–R40, R47)
- [x] 5.14 Ejecutar `flutter analyze` y dejarlo limpio; ejecutar `flutter test` de todos los slices; ejecutar `flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080`. (R42, R47)
- [ ] 5.15 Smoke check manual: instalar APK release en emulator/dispositivo y verificar splash, ícono, login, chat y navegación general. (R42, R43)
- [ ] 5.16 Cierre cross-cutting: verificar que R44 (estados error/vacío/carga + reintentar), R45 (formato de fechas consistente), R46 (visibilidad por permisos en todos los botones/menús) y R47 (tests por slice) estén aplicados en toda la app.
- [ ] 5.17 Generar commits atómicos con formato de proyecto y finalizar la cadena S1–S5.

## Forecast

| Slice | Requisitos | Escenarios | Líneas estimadas (código + tests) | Riesgo |
|-------|------------|------------|-----------------------------------|--------|
| S1 | R1–R10 | 26 | 1.000 | Alto (entorno, arquitectura, emulador) |
| S2 | R11–R16 | 13 | 1.500 | Medio (contrato real de catálogos) |
| S3 | R17–R26 | 16 | 2.200 | Alto/Medio (cálculos POS/payloads) |
| S4 | R27–R36 | 18 | 1.800 | Medio (reportes, logs, matrices) |
| S5 | R37–R43 | 14 | 1.000 | Medio (Markdown seguro, release) |
| **Total código + tests** | 46 | 87 del slice + 9 cross-cutting | **~7.500** | |
| Archivos generados (`*.freezed.dart`, `*.g.dart`) estimados | | | **~3.000–4.000** | |
| **Total con generados** | | | **~11.000** | |

## Review Workload Forecast

- **Líneas estimadas totales (sin generados):** ~7.500.
- **Líneas estimadas totales (con freezed/json_serializable generados):** ~11.000.
- **¿Se excede el presupuesto de 400 líneas?** Sí.
- **¿Se excede el presupuesto de 800 líneas?** Sí.
- **Justificación:** El cambio es intencionalmente grande por decisión D3 (no-limit) del usuario; el alcance es una app Flutter completa.
- **¿PRs encadenados recomendados?** Sí — entrega forzada por slices S1–S5.
- **¿Decisión necesaria antes de continuar?** Sí — el usuario debe aprobar cada commit antes de avanzar al siguiente.
- **Bloqueador detectado:** Flutter SDK no está instalado en el entorno (`flutter --version` falla). Se requiere que el usuario instale Flutter, Android SDK y, opcionalmente, Xcode antes de ejecutar `flutter create`.
