# Tasks: UI/UX de la app movil Flutter

**Change**: `app-movil-flutter-ui-ux`  
**Scope**: `flutter/` only  
**Branch**: `feature/app-movil-flutter`  
**Estrategia de entrega**: PRs encadenados por fase; cada commit es una unidad de trabajo revisable aprobada por el usuario (asunto `YYYYMMDD`, cuerpo `tipo(scope):` bullets en espanol).

---

## FASE 1 — Design System / Theme / Icon

Objetivo: establecer la unica fuente de verdad visual (tokens de tres capas), el tema claro/oscuro con persistencia, los estados compartidos y la identidad de marca FerrePlus. Ningun widget nuevo podra usar colores, spacing o estilos hardcodeados despues de esta fase.

- [ ] **1.1 Crear tokens primitivos en `lib/presentation/theme/`**
  - **What + Where**: Crear `app_colors.dart`, `app_spacing.dart`, `app_typography.dart`, `app_radius.dart`, `app_elevation.dart` y `app_durations.dart` con los valores raw (hex, escalas 4/8/12/16/24/32, pesos tipograficos, radios, elevaciones, duraciones, tamanos de icono). Solo estos archivos contienen literales numericos/colores.
  - **Acceptance criteria**:
    - `flutter analyze` limpio.
    - Los tokens son `const` y referenciables (ej. `AppColors.blue700`, `AppSpacing.space16`).
    - Ningun otro archivo de la fase usa valores raw.

- [ ] **1.2 Crear tokens semanticos como `ThemeExtension`**
  - **What + Where**: Crear `lib/presentation/theme/app_semantic_colors.dart` con `AppSemanticColors` (primary, surface, onSurface, textSecondary, success, warning, error, outline, KPI colors) y variantes light/dark. Documentar contraste minimo 4.5:1. Registrar la extension en `app_theme.dart`.
  - **Acceptance criteria**:
    - Light seed `#1565C0`, dark seed `#64B5F6`.
    - Los colores semanticos se resuelven via `Theme.of(context).extension<AppSemanticColors>()`.
    - Tests puros verifican que light y dark difieren en `surface`/`onSurface`.

- [ ] **1.3 Crear tokens de componente como `ThemeExtension`**
  - **What + Where**: Crear `lib/presentation/theme/app_component_theme.dart` con estilos centralizados de Card, AppBar, Button, Input, NavigationBar, Dialog, BottomSheet, SnackBar (padding, altura, radio, elevacion, colores semanticos). Registrar en `app_theme.dart`.
  - **Acceptance criteria**:
    - Ningun widget de componente accede a `AppColors` directamente; usa `AppComponentTheme` o tokens semanticos.
    - `flutter analyze` limpio.

- [ ] **1.4 Actualizar `lib/presentation/theme/app_theme.dart` a Material 3 completo**
  - **What + Where**: Ensamblar `ColorScheme` light/dark, `Typography`, `ThemeData` con `useMaterial3: true` y ambas `ThemeExtension`. Reemplazar la implementacion actual de 24 lineas.
  - **Acceptance criteria**:
    - `AppTheme.light` y `AppTheme.dark` son temas validos y completos.
    - `flutter analyze` sin warnings.

- [ ] **1.5 Agregar `shared_preferences` y crear `ThemePreferenceStore`**
  - **What + Where**: Agregar `shared_preferences` a `pubspec.yaml`. Crear `lib/data/services/theme_preference_store.dart` implementando la interfaz `ThemePreferenceStore` con lectura/escritura de `light|dark|system` y fallback a `system` si el valor es corrupto.
  - **Acceptance criteria**:
    - `flutter pub get` exitoso.
    - Tests con store fake verifican persistencia y fallback.

- [ ] **1.6 Crear enumeracion de modo de tema y `ThemeModeNotifier`**
  - **What + Where**: Crear `lib/core/theme/theme_mode.dart` con `AppThemeMode { system, light, dark }` y serializacion. Crear `lib/core/providers/theme_provider.dart` con `ThemeModeNotifier` (AsyncNotifier/StateNotifier) que inicializa desde el store, publica `ThemeMode.system` mientras carga y expone `setMode(AppThemeMode)`.
  - **Acceptance criteria**:
    - Tests verifican: valor default system, set light/dark/system, persistencia.
    - `flutter analyze` limpio.

- [ ] **1.7 Conectar tema en `lib/main.dart`**
  - **What + Where**: Modificar `FerrePlusApp` para observar `themeModeProvider` y asignar `themeMode` a `MaterialApp.router`.
  - **Acceptance criteria**:
    - Cambiar el provider de tema provoca rebuild del `MaterialApp`.
    - `flutter test` smoke verde.

- [ ] **1.8 Crear widgets de estado compartido**
  - **What + Where**: Crear `lib/presentation/shared/widgets/app_loading_indicator.dart` (skeleton + CircularProgressIndicator accesible), `app_empty_state.dart` (icono, titulo, subtitulo, CTA opcional) y `app_error_view.dart` (icono, mensaje, boton "Intentar nuevamente" accesible).
  - **Acceptance criteria**:
    - Cada widget tiene constructor `const`, parametros explicitos y `Semantics` donde aplica.
    - Tests widget verifican renderizado y tap de retry.

- [ ] **1.9 Crear `PageScaffold` y `AppBarBuilder` compartidos**
  - **What + Where**: Crear `lib/presentation/shared/widgets/page_scaffold.dart` con `PageScaffold` que envuelve SafeArea, padding de tokens, AppBar contextual con titulo y acciones; `AppBarBuilder` recibe titulo y acciones opcionales.
  - **Acceptance criteria**:
    - AppBar respeta safe area y usa tokens de componente.
    - Tests widget verifican titulo y altura.

- [ ] **1.10 Crear asset fuente del icono FerrePlus `hardware`**
  - **What + Where**: Crear `flutter/assets/branding/ferreplus_hardware.png` (motivo martillo/herramienta sobre fondo de marca, cuadrado, alta resolucion). Crear `flutter/flutter_launcher_icons.yaml` apuntando al asset.
  - **Acceptance criteria**:
    - El asset no es el logo Flutter.
    - La configuracion es reproducible.

- [ ] **1.11 Generar iconos launcher y splash Android**
  - **What + Where**: Ejecutar `flutter_launcher_icons` para generar mipmaps en `android/app/src/main/res/`. Asegurar que el splash nativo use el mismo asset. Si el generador falla, documentar/generar manualmente desde el mismo PNG.
  - **Acceptance criteria**:
    - `flutter build apk --debug` compila.
    - Inspeccion visual de mipmaps: motivo `hardware`, sin logo Flutter.

- [ ] **1.12 Migrar `shell_scaffold.dart` y chrome a tokens**
  - **What + Where**: Actualizar `shell_scaffold.dart`, `chat_floating_action_button.dart` y `_NoPermissionPage` para usar tokens semanticos/componente y el nuevo `PageScaffold`. No cambiar logica de negocio ni permisos.
  - **Acceptance criteria**:
    - Ningun color/spacing hardcodeado queda en estos archivos.
    - `flutter analyze` limpio; tests existentes siguen verdes.

- [ ] **1.13 Verificacion de FASE 1**
  - **What + Where**: Ejecutar `flutter analyze`, `flutter test` (52 tests base), tests nuevos de tokens/tema, y `flutter build apk --debug`.
  - **Acceptance criteria**:
    - `flutter analyze` 0 issues.
    - 52 tests base verdes + nuevos tests de FASE 1.
    - APK debug compila.

---

## FASE 2 — Dashboard

Objetivo: transformar el dashboard de placeholder a una pantalla operativa con 6 KPIs, grafico de ventas por periodo, acciones rapidas filtradas por permiso y estados loading/empty/error reutilizables.

- [ ] **2.1 Crear utilidades de periodo y agrupacion de ventas**
  - **What + Where**: Crear `lib/presentation/features/dashboard/dashboard_period.dart` con `DashboardPeriod` enum, `DateRange` y funciones puras para calcular rango de semana (lunes-hoy), mes (1-hoy) y ano (1 ene-hoy). Crear funcion pura de agrupacion diaria/mensual de `Venta`/`ChartPoint`.
  - **Acceptance criteria**:
    - Tests puros verifican los 3 rangos y agrupaciones.
    - Sin dependencia Flutter ni IO.

- [ ] **2.2 Crear/ajustar providers del dashboard**
  - **What + Where**: Crear/modificar `lib/presentation/features/dashboard/dashboard_provider.dart` para exponer `dashboardProvider` (reutiliza `ReporteRepository.dashboard()`), `dashboardPeriodProvider` (notifier) y `dashboardSalesProvider` (ventas por periodo, fallback a `ventasPorDia` o `reportSalesProvider`).
  - **Acceptance criteria**:
    - Providers reutilizan repositories existentes.
    - Tests de providers con repositories fake pasan.

- [ ] **2.3 Crear widget `MetricCard`**
  - **What + Where**: Crear `lib/presentation/features/dashboard/widgets/metric_card.dart` con icono, label, valor, color semantico solo en icono/badge, tap que navega a la ruta canonica, `Semantics` y touch target minimo 48dp.
  - **Acceptance criteria**:
    - Valor tiene mayor peso visual que label.
    - Tap navega a la ruta correspondiente.
    - Tests widget verifican renderizado y navegacion.

- [ ] **2.4 Crear widget `MetricsGrid` responsive**
  - **What + Where**: Crear `lib/presentation/features/dashboard/widgets/metrics_grid.dart` con `LayoutBuilder`: 2 columnas si ancho >= 360dp, 1 columna si es menor. Componer 6 `MetricCard` con la tabla de KPIs del spec (iconos, colores, rutas).
  - **Acceptance criteria**:
    - Tests con `MediaQuery` de 320dp y 400dp verifican 1 y 2 columnas.
    - Sin overflow horizontal.

- [ ] **2.5 Crear widget `SalesChart` con widgets nativos**
  - **What + Where**: Crear `lib/presentation/features/dashboard/widgets/sales_chart.dart` que reciba puntos agrupados y dibuje barras con `CustomPaint` o `Row` de `Container`, selector de periodo week/month/year, labels de eje X, formato de moneda y `AppEmptyState` cuando no hay datos.
  - **Acceptance criteria**:
    - No se agrega dependencia de graficos.
    - Tests verifican renderizado con datos, vacio y cambio de periodo.

- [ ] **2.6 Crear widget `QuickActions`**
  - **What + Where**: Crear `lib/presentation/features/dashboard/widgets/quick_actions.dart` con hasta 4 acciones (Nueva venta, Nuevo producto, Registrar gasto, Registrar compra), cada una visible solo si el usuario tiene el permiso `*_CREAR` correspondiente.
  - **Acceptance criteria**:
    - Tests verifican visibilidad por permisos y navegacion al tocar.

- [ ] **2.7 Crear widgets `DashboardHeader`, `MonthSummary` y `DashboardEmpty`**
  - **What + Where**: Crear `dashboard_header.dart`, `month_summary.dart` y `dashboard_empty.dart` bajo `lib/presentation/features/dashboard/widgets/`. Usar solo datos existentes de `ReporteDashboard`; `DashboardEmpty` muestra mensaje de bienvenida sin inventar datos.
  - **Acceptance criteria**:
    - Cada widget es <300 lineas.
    - `DashboardEmpty` no muestra KPIs falsos.

- [ ] **2.8 Reconstruir `DashboardScreen`**
  - **What + Where**: Reescribir `lib/presentation/features/dashboard/dashboard_screen.dart` para componer AppBar, header, `MetricsGrid`, `SalesChart`, `QuickActions`, `MonthSummary` y los estados compartidos loading/empty/error.
  - **Acceptance criteria**:
    - Pantalla usa `AppLoadingIndicator`, `AppEmptyState`, `AppErrorView`.
    - Sin logica de negocio nueva; solo presentacion.

- [ ] **2.9 Ajustar ruta del dashboard en `admin_pages.dart`/`app_router.dart`**
  - **What + Where**: Asegurar que `/` y `/dashboard` apunten al nuevo `DashboardScreen` (o renombrar/mantener `DashboardAdminPage` si se decide conservar el nombre). Actualizar imports en `app_router.dart` si cambia la ruta del archivo.
  - **Acceptance criteria**:
    - Deep links a `/` y `/dashboard` renderizan el nuevo dashboard.
    - No se rompen permisos.

- [ ] **2.10 Tests widget del dashboard**
  - **What + Where**: Crear `test/presentation/features/dashboard/dashboard_screen_test.dart` y tests para cada sub-widget. Cubrir: 6 KPIs, colores contenidos, navegacion de KPI, grafico por periodo, empty/error/loading, acciones por permiso, responsive 1/2 columnas.
  - **Acceptance criteria**:
    - Todos los tests nuevos pasan.
    - 52 tests base siguen verdes.

- [ ] **2.11 Verificacion de FASE 2**
  - **What + Where**: Ejecutar `flutter analyze`, `flutter test`, inspeccion visual del dashboard en emulador/dispositivo con datos de fixture.
  - **Acceptance criteria**:
    - `flutter analyze` 0 issues.
    - Todos los tests verdes.
    - No overflow en 360dp y 320dp.

---

## FASE 3 — Navegacion

Objetivo: reducir el `NavigationBar` a 5 destinos estables, crear la pagina `Mas` categorizada, preservar deep links/permisos y mantener el FAB de chat como acceso principal.

- [ ] **3.1 Reconfigurar `StatefulShellRoute` a 5 branches en `app_router.dart`**
  - **What + Where**: Modificar `lib/core/routing/app_router.dart` para que `StatefulShellRoute.indexedStack` tenga exactamente 5 branches: Dashboard (0), Productos (1), Ventas (2), Reportes (3), Mas (4). Las rutas secundarias se anidan como sub-rutas dentro de la branch mas cercana o se agrupan bajo Mas segun convenga para deep links.
  - **Acceptance criteria**:
    - `navigationShell.goBranch(0..4)` funciona.
    - `flutter analyze` limpio.
    - Los 52 tests base se adaptan o siguen verdes.

- [ ] **3.2 Preservar rutas canonicas y deep links secundarios**
  - **What + Where**: Verificar que `/categorias`, `/proveedores`, `/clientes`, `/compras`, `/movimientos`, `/gastos`, `/gestion-precios`, `/usuarios`, `/roles`, `/logs`, `/chat` siguen declaradas y protegidas por `_permissionFor`. No cambiar URLs publicas.
  - **Acceptance criteria**:
    - Tests de routing verifican deep links a `/compras`, `/logs`, `/chat`.
    - Guards rechazan rutas sin permiso.

- [ ] **3.3 Crear `MasPage` con secciones categorizadas**
  - **What + Where**: Crear `lib/presentation/features/mas/mas_page.dart` con secciones OPERACIONES (Compras, Movimientos, Gastos), CATALOGOS (Categorias, Proveedores, Clientes, Precios), ADMINISTRACION (Usuarios, Roles), SISTEMA (Logs, Chat). Cada item filtrado por permiso `*_VER`.
  - **Acceptance criteria**:
    - Items ocultos cuando falta permiso; seccion vacia oculta o muestra mensaje.
    - Tap navega a la ruta canonica via `context.go`.

- [ ] **3.4 Crear selector de tema en `Mas > SISTEMA`**
  - **What + Where**: Crear `lib/presentation/features/mas/theme_selector.dart` con opciones Claro, Oscuro, Seguir sistema. Integrar en `MasPage` bajo SISTEMA. Conectar con `ThemeModeNotifier`.
  - **Acceptance criteria**:
    - Seleccion cambia el tema inmediatamente.
    - Persistencia se verifica en tests.
    - Default es "Seguir sistema".

- [ ] **3.5 Reescribir `shell_scaffold.dart` para 5 destinos + AppBar contextual**
  - **What + Where**: Reemplazar la lista de 15 destinos por 5 fijos. Incluir AppBar contextual con titulo de la rama actual usando `PageScaffold`/`AppBarBuilder`. Mantener `ChatFloatingActionButton`.
  - **Acceptance criteria**:
    - Exactamente 5 `NavigationDestination` visibles.
    - El indice seleccionado refleja la rama actual.
    - Estado por rama se preserva.

- [ ] **3.6 Ajustar `chat_floating_action_button.dart` y consideraciones de FAB**
  - **What + Where**: Verificar que el FAB solo se muestra para usuarios autenticados, navega a `/chat` y tiene semantic label. No debe aparecer en login.
  - **Acceptance criteria**:
    - Tests verifican FAB visible autenticado, oculto en login, navega a `/chat`.

- [ ] **3.7 Tests de navegacion y routing**
  - **What + Where**: Crear/actualizar `test/presentation/shell/shell_scaffold_test.dart`, `test/presentation/features/mas/mas_page_test.dart` y `test/core/routing/app_router_test.dart`. Cubrir: 5 tabs, Mas items filtrados por permiso, selector de tema, deep links, guards, estado preservado por branch.
  - **Acceptance criteria**:
    - Todos los tests de navegacion pasan.
    - 52 tests base verdes.

- [ ] **3.8 Verificacion de FASE 3**
  - **What + Where**: Ejecutar `flutter analyze`, `flutter test`, navegacion manual entre tabs y deep links en emulador.
  - **Acceptance criteria**:
    - 0 issues en analyze.
    - Todos los tests verdes.
    - Navegacion de 5 tabs funciona; deep links a rutas secundarias funcionan.

---

## FASE 4 — Pulido progresivo

Objetivo: aplicar el Design System a las pantallas restantes sin cambiar logica de negocio, reemplazando colores/spacing hardcodeados, estados inline y AppBars ad-hoc por tokens y shared views.

- [ ] **4.1 Pulir pantallas de autenticacion**
  - **What + Where**: Aplicar tokens y `PageScaffold` a `lib/presentation/features/auth/login_screen.dart` y `lib/presentation/features/auth/initial_admin_page.dart`; reemplazar estados inline por `AppLoadingIndicator`/`AppErrorView` si aplica.
  - **Acceptance criteria**:
    - Sin colores/spacing hardcodeados.
    - `flutter analyze` limpio; tests existentes verdes.

- [ ] **4.2 Pulir catalogos (productos, categorias, proveedores, clientes)**
  - **What + Where**: Aplicar tokens a pantallas/listas/formularios en `lib/presentation/features/productos/`, `categorias/`, `proveedores/`, `clientes/`; reemplazar `CatalogStateView` por `AppLoadingIndicator`/`AppEmptyState`/`AppErrorView` donde sea apropiado.
  - **Acceptance criteria**:
    - Consistencia visual con el Design System.
    - Tests existentes verdes.

- [ ] **4.3 Pulir operaciones comerciales (ventas, compras, movimientos, gastos)**
  - **What + Where**: Aplicar tokens a pantallas en `lib/presentation/features/ventas/`, `compras/`, `movimientos/`, `gastos/`; usar `PageScaffold`, tokens de input/button/card.
  - **Acceptance criteria**:
    - Sin logica de negocio modificada.
    - `flutter analyze` limpio.

- [ ] **4.4 Pulir administracion (precios, usuarios, roles, reportes, logs)**
  - **What + Where**: Aplicar tokens a `admin_pages.dart`, `lib/presentation/features/precios/`, `usuarios/`, `roles/`, `reportes/`, `logs/`. Reemplazar `errorView` inline por `AppErrorView` compartido.
  - **Acceptance criteria**:
    - `errorView` inline eliminado de `admin_pages.dart`.
    - Consistencia visual; tests verdes.

- [ ] **4.5 Pulir pantalla de chat**
  - **What + Where**: Aplicar tokens a `lib/presentation/features/chat/pages/chat_page.dart` y sus widgets; asegurar AppBar contextual y estados compartidos.
  - **Acceptance criteria**:
    - Sin colores hardcodeados.
    - Tests existentes de chat verdes.

- [ ] **4.6 Centralizar uso de estados compartidos en feature screens**
  - **What + Where**: Reemplazar todos los `CircularProgressIndicator` y mensajes de empty/error inline por `AppLoadingIndicator`, `AppEmptyState` y `AppErrorView`. Actualizar `catalog_state_view.dart` si se conserva como wrapper legacy.
  - **Acceptance criteria**:
    - `grep` no encuentra `CircularProgressIndicator` inline en feature screens (salvo dentro de shared widgets).
    - `flutter analyze` limpio.

- [ ] **4.7 Agregar semantic labels y touch targets >=48dp a controles existentes**
  - **What + Where**: Revisar todos los `IconButton`, `InkWell`, chips y tiles de feature screens; agregar `tooltip`/`Semantics` y asegurar `minimumSize` o padding para targets.
  - **Acceptance criteria**:
    - Auditoria manual: todos los icon-only buttons tienen label.
    - No hay errores de `flutter analyze`.

- [ ] **4.8 Verificacion de FASE 4**
  - **What + Where**: Ejecutar `flutter analyze`, `flutter test` y revision visual rapida de las pantallas pulidas.
  - **Acceptance criteria**:
    - 0 issues.
    - Todos los tests verdes.
    - Ninguna pantalla muestra colores/spacing claramente inconsistentes.

---

## FASE 5 — Dark mode + A11y cierre

Objetivo: verificar que ambos temas funcionan en todas las pantallas, cumplir contraste, touch targets, semantic labels, soporte de escala de texto y responsive; cerrar con analyze, tests y build.

- [ ] **5.1 Verificacion manual de dark mode en todas las pantallas**
  - **What + Where**: Navegar manualmente (o con smoke test) por auth, dashboard, productos, ventas, compras, movimientos, gastos, categorias, proveedores, clientes, precios, usuarios, roles, reportes, logs, chat y Mas en dark mode.
  - **Acceptance criteria**:
    - No hay textos ilegibles, superficies sin contraste ni colores perdidos.
    - Issues documentados y corregidos.

- [ ] **5.2 Verificar contraste >=4.5:1**
  - **What + Where**: Auditar pares de color text/icon vs background en light y dark usando herramienta de contraste (ej. plugin, script o inspeccion de valores). Documentar resultados.
  - **Acceptance criteria**:
    - Todos los pares de texto/icono cumplen WCAG AA (4.5:1).
    - Ajustes de tokens si se detectan incumplimientos.

- [ ] **5.3 Verificar touch targets >=48dp**
  - **What + Where**: Revisar todos los controles interactivos en las pantallas pulidas; ajustar padding o `ConstrainedBox`/`minimumSize` donde sea necesario.
  - **Acceptance criteria**:
    - Todos los botones, icon buttons, chips y tiles tienen area de toque minima 48x48dp.

- [ ] **5.4 Verificar semantic labels y orden de foco**
  - **What + Where**: Activar TalkBack/VoiceOver (o `SemanticsTester`) y navegar por dashboard, Mas y feature screens. Asegurar que icon-only buttons, FAB y acciones rapidas anuncian su proposito.
  - **Acceptance criteria**:
    - Ningun icon-only button sin label.
    - Orden de foco logico.

- [ ] **5.5 Verificar soporte de escala de texto**
  - **What + Where**: Ejecutar la app con `MediaQuery.textScaler` al maximo (o configuracion de accesibilidad del SO). Verificar que no hay overflow ni texto cortado en dashboard, Mas y feature screens.
  - **Acceptance criteria**:
    - Texto se envuelve o scrolla verticalmente; no hay `RenderFlex` overflow.

- [ ] **5.6 Verificar responsive landscape/tablet**
  - **What + Where**: Probar orientacion horizontal y resoluciones de tablet. Verificar que `MetricsGrid`, listas, formularios y Mas se ven correctos sin scroll horizontal.
  - **Acceptance criteria**:
    - Sin overflow en landscape.
    - Layouts usables en tablet.

- [ ] **5.7 Aplicar correcciones de a11y/responsive encontradas**
  - **What + Where**: Implementar ajustes minimos en tokens o widgets para resolver issues detectados en 5.1-5.6. No agregar features nuevas.
  - **Acceptance criteria**:
    - `flutter analyze` y `flutter test` siguen limpios despues de los ajustes.

- [ ] **5.8 Ejecutar suite de tests completa y `flutter analyze` final**
  - **What + Where**: Desde `flutter/`, correr `flutter analyze` y `flutter test`. Asegurar que los 52 tests base y todos los nuevos pasan.
  - **Acceptance criteria**:
    - 0 errores/warnings.
    - 100% de tests verdes.

- [ ] **5.9 Build de validacion y verificacion de assets de marca**
  - **What + Where**: Ejecutar `flutter build apk --debug` y verificar que los assets generados no contienen logo Flutter. Inspeccionar mipmaps y splash.
  - **Acceptance criteria**:
    - Build exitoso.
    - Icono instalado muestra motivo `hardware`.

- [ ] **5.10 Verificacion de cierre de FASE 5**
  - **What + Where**: Revisar checklist final: design system completo, dashboard con 6 KPIs + chart, 5 tabs + Mas, icono/splash FerrePlus, 52 tests base + nuevos verdes, analyze limpio, build OK, a11y validada.
  - **Acceptance criteria**:
    - Todo el checklist aprobado.
    - Listo para entrega/PR final encadenado.

---

## Review Workload Forecast

### Estimacion por fase (codigo + tests)

| Fase | Requisitos principales | Escenarios cubiertos | Lineas estimadas (codigo + tests) | Riesgo |
|------|------------------------|----------------------|-----------------------------------|--------|
| FASE 1 — Design System / Theme / Icon | R1, R2, R3, R11, R12, R13, R14 | 19 | ~1.500 | Medio (tokens, icon generation) |
| FASE 2 — Dashboard | R4, R5, R6, R7, R15, R17 | 19 | ~1.800 | Medio/Alto (chart, responsive, estados) |
| FASE 3 — Navegacion | R8, R9, R10, R2 (selector), R11 | 16 | ~1.200 | Alto (router restructure, deep links) |
| FASE 4 — Pulido progresivo | R11, R12, R13, R14, R15, R16 parcial | ~8 | ~2.000 | Medio (muchas pantallas, sin logica nueva) |
| FASE 5 — Dark mode + A11y cierre | R16, R18, R-M1, R-M2, R-M3 | ~11 | ~700 | Medio/Alto (validacion manual, contraste) |
| **Total codigo + tests** | 18 nuevos + 3 modificados + 2 removidos | 65 | **~7.200** | |
| Archivos generados (`*.freezed.dart`, `*.g.dart`) estimados | — | — | **~0** (sin nuevos modelos) | |
| **Total estimado** | — | — | **~7.200** | |

### Recomendacion de entrega

- **¿Se excede el presupuesto de 400 lineas por PR?** Si, en todas las fases.
- **¿Se excede el presupuesto de 800 lineas por PR?** Si, en FASE 1, 2, 3 y 4.
- **PRs encadenados recomendados**: **Si, obligatorio** — un PR por fase (FASE 1 → FASE 2 → FASE 3 → FASE 4 → FASE 5). Cada PR contiene los commits atomicos de sus tareas.
- **Decision necesaria antes de continuar**: El usuario debe aprobar cada commit/PR antes de avanzar a la siguiente fase.
- **Riesgo general**: **Alto/Medio**. El riesgo mas alto esta en FASE 3 (reestructuracion de `StatefulShellRoute` y deep links) y FASE 2 (chart responsive y estados). FASE 1 tiene riesgo medio por generacion de iconos. FASE 5 depende de validacion manual de accesibilidad.

### Mitigaciones clave

1. Mantener ADR-3 (GoRouter `StatefulShellRoute`) y no cambiar URLs publicas en FASE 3.
2. No agregar logica de negocio ni endpoints nuevos en ninguna fase.
3. Ejecutar `flutter analyze` y `flutter test` al final de cada fase antes de iniciar la siguiente.
4. Conservar los 52 tests base como guardrail de regresion.
5. Documentar fallas del generador de iconos y mantener el asset fuente como fallback.

### Open items

- Ninguno. Todas las decisiones abiertas de la propuesta fueron resueltas en la especificacion.
- La generacion de assets iOS queda condicionada a un entorno macOS, pero no bloquea el objetivo Android prioritario.
