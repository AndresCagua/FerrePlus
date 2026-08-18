# Design: UI/UX de la app movil Flutter

## Technical Approach

La implementacion sera una evolucion exclusivamente de `flutter/`, sobre la
arquitectura existente `presentation -> domain <- data`. No se modificaran
contratos REST, modelos generados, reglas de negocio, backend ni frontend.
Riverpod continuara siendo la fuente de estado compartido y GoRouter mantendra
`StatefulShellRoute.indexedStack`, pero la shell tendra cinco ramas visibles:
Dashboard, Productos, Ventas, Reportes y Mas. Las rutas secundarias seguiran
siendo canonicas y protegidas por la tabla de permisos actual, aunque ya no
sean ramas del bottom navigation.

El trabajo se divide en cinco cortes compilables: (1) tokens, temas, selector,
marca y estados compartidos; (2) dashboard; (3) shell y Mas; (4) migracion
progresiva de pantallas a wrappers/tokens; (5) accesibilidad, responsive y
verificacion. Cada corte conserva los tests existentes y pasa `flutter analyze`.

### Mobile design checkpoint

- **Plataforma:** Android prioritaria; iOS secundaria, ambas consideradas.
- **Framework:** Flutter 3.38.1 / Dart 3.10.0.
- **Navegacion:** cinco tabs persistentes con `StatefulShellRoute`, pagina Mas
  para destinos secundarios y deep links intactos.
- **Offline:** fuera de alcance; se muestran estados de red claros sin cachear
  datos de negocio.
- **Dispositivos:** phones compactos, phones grandes, landscape y tablet.
- **Audiencia:** usuarios autenticados de negocio, con permisos y necesidades
  de legibilidad operativa.
- **MFRI:** moderado (la complejidad de routing y dashboard se compensa con
  accesibilidad explicitamente verificada); se exige profiling y validacion
  en ambos temas.

La firma visual sera un dashboard operativo sobrio: superficies neutrales,
azul FerrePlus para acciones primarias, coral como acento secundario y el
motivo `hardware` como unico gesto de marca destacado. Se evita convertir
cada KPI en una superficie saturada: el color de KPI se limita al icono o
badge, mientras el valor domina al label.

## Architecture Overview

```text
MaterialApp.router
  ├── ThemeModeController (Riverpod) ──> ThemePreferenceStore
  ├── AppTheme.light/dark
  │     ├── primitive tokens
  │     ├── semantic ThemeExtensions
  │     └── component ThemeExtensions
  └── GoRouter
        └── StatefulShellRoute (5 branches)
              └── ShellScaffold + contextual AppBar + chat FAB
                    ├── DashboardScreen
                    │     ├── dashboardProvider -> ReporteRepository
                    │     ├── period provider -> ventasPorDia/reportSalesProvider
                    │     └── shared Loading/Empty/Error/Permission widgets
                    └── feature screens / MasPage -> canonical routes
```

### Token layers

`presentation/theme/` sera la fuente unica:

1. **Primitive:** valores raw (`blue700`, escalas de spacing, tipos, radios,
   elevaciones, iconos y duraciones). Solo estos archivos contienen hex,
   tamanos numericos y elevaciones base.
2. **Semantic:** roles (`primary`, `surface`, `onSurface`, `textSecondary`,
   `success`, `warning`, `error`, `outline`, KPI colors), con variantes light y
   dark. El seed light sera `#1565C0` y el dark `#64B5F6`; las superficies y
   textos se validan con contraste WCAG AA.
3. **Component:** estilos de Button, Card, Input, AppBar, NavigationBar,
   Dialog, BottomSheet y SnackBar: alturas, padding, radios, estados, iconos,
   elevacion y colores semanticamente referenciados.

La definicion fuente sera de clases Dart const; el runtime se expondrá mediante
`ThemeExtension` (`AppSemanticColors` y `AppComponentTheme`) agregado a cada
`ThemeData`. Esto permite que un widget obtenga tokens desde `BuildContext`
sin globals ambiguos y que light/dark cambie con `ThemeMode`. Los primitives
siguen siendo clases directas para que sean auditables; ningun widget nuevo
podra usar hex o magic numbers.

### Dashboard

```text
DashboardScreen
├── PageScaffold/AppBarBuilder("Dashboard")
├── DashboardHeader
├── MetricsGrid
│   └── MetricCard x6 (tap -> ruta canonica)
├── SalesChart
│   ├── PeriodSelector (week/month/year)
│   └── Built-in bar renderer (CustomPaint o Row/Container)
├── QuickActions (PermissionVisibility por CREAR)
├── MonthSummary (solo campos existentes, si aplica)
└── DashboardEmpty / AppLoadingIndicator / AppErrorView
```

El periodo por defecto es mes. Se agrupan `ReporteDashboard.ventasPorDia`
por dia para semana/mes y por mes para año; si el payload no contiene puntos,
se consulta `ReporteRepository.ventas(desde, hasta)` mediante el provider
existente y se agrupan las ventas. El chart no usara `fl_chart`, pese a que ya
esta instalado: se dibujaran barras con widgets/`CustomPaint`, con labels,
tooltip/semantics y formatter monetario. No se fabrican ceros ni actividad.

El grid usa `LayoutBuilder`: dos columnas desde 360dp cuando las restricciones
permiten el gutter y una columna por debajo. Landscape/tablet aumenta gutters y
puede mantener dos o mas columnas sin scroll horizontal. Las listas largas de
features existentes permanecen lazy (`ListView.builder`).

### Navigation and permissions

Las cinco ramas se ordenan de forma estable para que el indice de
`StatefulNavigationShell` no dependa de permisos visibles. Dashboard es rama
0. Productos, Ventas y Reportes conservan sus rutas; la rama Mas contiene
`/mas` y solo sus accesos visuales. Las rutas de Compras, Categorias,
Proveedores, Clientes, Movimientos, Gastos, Precios, Usuarios, Roles, Logs y
Chat continuan declaradas en el router, agrupadas en ramas auxiliares solo si
GoRouter lo requiere para conservar deep links; la barra no las expone.

La tabla de tiles de Mas contiene label, icono, ruta y permiso `*_VER`, con
secciones OPERACIONES, CATALOGOS, ADMINISTRACION y SISTEMA. `PermissionVisibility`
consume el `Set<String>` efectivo de `authNotifierProvider`; no se infiere
autorizacion desde `rol`. El chat sigue siendo el FAB primario para cualquier
usuario autenticado; su tile en Mas es opcional y no sustituye el FAB.

### Progressive polish

No se reescribe la logica de negocio de cada feature. Cada pantalla se migra
con este orden: `PageScaffold`/`AppBarBuilder`, padding y estilos de tokens,
reemplazo de estados inline por shared views, luego labels/targets y finalmente
microinteracciones. Los providers, repositories, DTOs y payloads quedan sin
cambios salvo el provider de periodo del dashboard y el provider de tema.

## Architecture Decisions

### ADR-14: ThemeExtension como superficie runtime de tokens

**Choice:** clases Dart const para primitives y definiciones semantic/component,
expuestas en `ThemeData.extensions` mediante `AppSemanticColors` y
`AppComponentTheme`.

**Alternatives considered:** getters estaticos directos (`AppColors.primary`)
que no conocen el `BuildContext`, o pasar un objeto de tokens manualmente por
toda la jerarquia.

**Rationale:** ThemeExtension resuelve correctamente light/dark y permite
interpolacion/consumo idiomatico de Flutter sin acoplar widgets a hex. Las
clases const mantienen una fuente auditable para primitive y semantic tokens.

### ADR-15: `shared_preferences` para preferencia de tema

**Choice:** agregar `shared_preferences` como dependencia runtime y persistir
solo `light`, `dark` o `system` en un `ThemePreferenceStore` aislado.

**Alternatives considered:** `flutter_secure_storage` existente, o estado en
memoria.

**Rationale:** la eleccion de tema no es secreto ni credencial; preferences es
la abstraccion correcta, evita mezclarla con el borrado de sesion y sobrevive
a logout/reinicio. El store tendra fallback `system` si el valor es invalido
o la lectura falla. No se guardan datos de negocio.

### ADR-16: Selector de tema como `Notifier` global, UI local en Mas

**Choice:** `ThemeModeNotifier` inicializa async desde el store, publica
`ThemeMode.system` mientras carga y expone `setMode`; `FerrePlusApp` observa el
estado y `ThemeSelectorTile` lo modifica desde Mas > SISTEMA.

**Alternatives considered:** `setState` en Mas, `ChangeNotifier` separado o
leer storage desde `main` antes de `runApp`.

**Rationale:** ThemeMode afecta toda la app y debe ser testeable/sobrescribible
en ProviderScope. Mantener la UI del selector en Mas no limita el alcance del
estado.

### ADR-17: Chart de barras con Flutter built-in

**Choice:** `SalesChart` recibe puntos ya agrupados y pinta barras con
`CustomPaint`/widgets Flutter; el selector calcula un `DateRange` tipado.

**Alternatives considered:** usar `fl_chart` ya presente, añadir otra libreria,
o conservar el line chart actual.

**Rationale:** cumple la especificacion sin dependencia nueva, reduce peso y
mantiene control sobre semantica, empty state y responsive. La agrupacion se
prueba fuera del widget y el painter no realiza IO.

### ADR-18: Cinco ramas estables y Mas como indice secundario

**Choice:** reconfigurar `StatefulShellRoute` a cinco ramas visibles; Mas
centraliza los destinos secundarios filtrados por permisos, sin cambiar URLs.

**Alternatives considered:** conservar 15 tabs, drawer como navegacion
principal, o construir rutas nuevas bajo `/mas`.

**Rationale:** cinco destinos respetan Material y el uso con una mano; un
indice secundario reduce carga cognitiva sin romper deep links ni stacks
persistentes. Ramas/indices se mantienen estables aunque falte un permiso.

### ADR-19: Shared views como proyeccion de `AsyncValue`

**Choice:** `AppLoadingIndicator`, `AppEmptyState`, `AppErrorView` y
`PermissionVisibility` reciben datos/acciones por parametros y no conocen
repositories.

**Alternatives considered:** helpers globales con acceso a providers, o cada
feature implementando su propio spinner/error.

**Rationale:** la presentacion de estados es transversal y debe ser consistente;
la inyeccion de retry conserva la separacion de capas y facilita widget tests.

### ADR-20: Icono reproducible desde un asset fuente local

**Choice:** crear PNG cuadrado con el motivo vectorial `Icons.hardware` sobre
   fondo de marca, versionarlo como asset fuente, declarar
`flutter_launcher_icons` en dev_dependencies y generar Android/iOS; splash
usara la misma fuente. Si el generador falla, un script/documentacion genera
mipmaps desde ese mismo PNG.

**Alternatives considered:** logo Flutter recoloreado, icono Material runtime,
o mipmaps editados manualmente sin fuente comun.

**Rationale:** conserva identidad FerrePlus, evita rasterizar un glyph distinto
por densidad y hace el resultado reproducible. No agrega dependencia de chart ni
runtime para el icono.

### ADR-21: Accesibilidad y responsive como contratos de componente

**Choice:** tokens y shared widgets fijan targets minimo 48dp, labels Semantics,
contraste >=4.5:1, spacing 4/8 y soporte de `MediaQuery.textScaler`; cada
feature hereda estos contratos mediante wrappers.

**Alternatives considered:** auditoria manual final solamente, o estilos por
feature.

**Rationale:** los errores de accesibilidad se propagan si se dejan para el
final. Centralizar contratos reduce regresiones y permite validar 375dp,
landscape, tablet y escala maxima de texto.

## Data Flow

### Theme flow

```text
app start -> ThemePreferenceStore.read()
          -> ThemeModeNotifier.state
          -> FerrePlusApp.themeMode
          -> AppTheme.light/dark + ThemeExtensions
Mas/Sistema -> notifier.setMode(mode) -> store.write(mode) -> rebuild
```

### Dashboard flow

```text
DashboardScreen
  -> ref.watch(dashboardProvider)
  -> ReporteRepository.dashboard()
  -> ReporteDashboard (KPIs + ventasPorDia)
  -> MetricsGrid / MonthSummary / QuickActions

PeriodSelector
  -> DashboardPeriodNotifier
  -> DateRange (current Monday/today, month, Jan 1/today)
  -> ventasPorDia OR reportSalesProvider(DateRange)
  -> pure grouping by day/month
  -> SalesChart bars / AppEmptyState
```

### Navigation flow

```text
tap bottom destination -> navigationShell.goBranch(index)
                       -> preserved branch stack/state
tap Mas tile -> context.go(canonicalPath)
             -> router redirect + _permissionFor(path)
             -> screen OR _fallbackLocation
deep link -> same redirect/permission path (no visual menu dependency)
chat FAB -> /chat (authenticated gate only)
```

### Dashboard sequence with failure

```text
UI -> dashboardProvider: watch
Provider -> ReporteRepository: dashboard()
ReporteRepository --> Provider: ReporteDashboard | error
Provider --> UI: AsyncData | AsyncError
UI -> shared state: loading / error(retry) / empty / content
User -> retry: invalidate(dashboardProvider)
```

## File Changes

| Archivo | Action | Description |
|---|---|---|
| `flutter/lib/presentation/theme/app_colors.dart` | Create | Primitives y semantic light/dark; KPI roles y contraste documentado. |
| `flutter/lib/presentation/theme/app_typography.dart` | Create | Escala tipografica compatible con text scaling y pesos limitados. |
| `flutter/lib/presentation/theme/app_spacing.dart` | Create | Escala 4/8/12/16/24/32 y gutters responsive. |
| `flutter/lib/presentation/theme/app_radius.dart` | Create | Radios semanticos/componentes. |
| `flutter/lib/presentation/theme/app_elevation.dart` | Create | Elevaciones y sombras suaves por tema. |
| `flutter/lib/presentation/theme/app_components.dart` | Create | Component tokens/styles y `ThemeExtension` de componentes. |
| `flutter/lib/presentation/theme/app_theme.dart` | Modify | Material 3 light/dark, extensions, typography y component themes. |
| `flutter/lib/core/theme/theme_mode.dart` | Create | Enum/serializacion de claro, oscuro, sistema. |
| `flutter/lib/core/providers/theme_provider.dart` | Create | `ThemePreferenceStore` y `ThemeModeNotifier`. |
| `flutter/lib/data/services/theme_preference_store.dart` | Create | Adaptador `shared_preferences`, fallback seguro. |
| `flutter/lib/main.dart` | Modify | Observa `themeModeProvider` y configura `themeMode`. |
| `flutter/lib/presentation/shared/widgets/loading_view.dart` | Create | Skeleton variants y indicador accesible. |
| `flutter/lib/presentation/shared/widgets/empty_view.dart` | Create | Icono, titulo, subtitulo y CTA opcional. |
| `flutter/lib/presentation/shared/widgets/error_view.dart` | Create | Error con retry accesible. |
| `flutter/lib/presentation/shared/widgets/permission_visibility.dart` | Create/Modify | Filtrado por `Set<String>` efectivo. |
| `flutter/lib/presentation/shared/widgets/page_scaffold.dart` | Create | Safe area, padding, AppBarBuilder y content insets. |
| `flutter/lib/presentation/features/dashboard/dashboard_screen.dart` | Modify | Sustituye placeholder y compone el dashboard. |
| `flutter/lib/presentation/features/dashboard/dashboard_provider.dart` | Create/Modify | Periodo, agrupacion y estado de dashboard; reutiliza repository actual. |
| `flutter/lib/presentation/features/dashboard/widgets/dashboard_header.dart` | Create | Encabezado contextual. |
| `flutter/lib/presentation/features/dashboard/widgets/metric_card.dart` | Create | KPI reusable, semantics y navegacion. |
| `flutter/lib/presentation/features/dashboard/widgets/metrics_grid.dart` | Create | Grid responsive 2->1. |
| `flutter/lib/presentation/features/dashboard/widgets/sales_chart.dart` | Create | Barras built-in, selector y empty state. |
| `flutter/lib/presentation/features/dashboard/widgets/quick_actions.dart` | Create | Acciones por permisos CREAR. |
| `flutter/lib/presentation/features/dashboard/widgets/month_summary.dart` | Create | Solo campos existentes; empty si no hay contenido. |
| `flutter/lib/presentation/shell/shell_scaffold.dart` | Modify | Five destinations, contextual AppBar, FAB y safe areas. |
| `flutter/lib/presentation/features/mas/mas_page.dart` | Create | Secciones y tiles canonicales filtrados. |
| `flutter/lib/presentation/features/mas/theme_selector.dart` | Create | Claro/Oscuro/Seguir sistema. |
| `flutter/lib/core/routing/app_router.dart` | Modify | Five branches, `/mas`, guards y rutas secundarias preservadas. |
| `flutter/lib/presentation/features/admin_pages.dart` | Modify | Extrae dashboard y reemplaza estados inline de forma progresiva. |
| `flutter/pubspec.yaml` | Modify | `shared_preferences`, `flutter_launcher_icons` dev y configuracion de asset. |
| `flutter/assets/branding/ferreplus_hardware.png` | Create | Fuente versionada del icono/splash. |
| `flutter/flutter_launcher_icons.yaml` | Create | Configuracion reproducible de launcher. |
| `flutter/android/app/src/main/res/**` | Modify | Mipmaps/splash generados, sin logo Flutter. |
| `flutter/ios/Runner/Assets.xcassets/**` | Modify | Icon/splash iOS cuando el target sea generado en macOS. |
| `flutter/test/presentation/theme/**` | Create | Tokens, selector y persistencia. |
| `flutter/test/presentation/features/dashboard/**` | Create | KPI/chart/states/actions/responsive. |
| `flutter/test/presentation/features/mas/**` | Create | Categorias, permisos y tema. |
| `flutter/test/presentation/shell/**` | Create/Modify | Cinco tabs, FAB y estado por branch. |
| `flutter/test/core/routing/**` | Create/Modify | Deep links, guards y rutas canonicas. |
| `flutter/test/branding/**` | Create | Verificacion de configuracion y asset no Flutter. |
| `flutter/test/widgets/**` | Modify | Reemplazo progresivo de helpers inline por shared views. |

No se modificaran `backend/`, `frontend/`, DTOs generados ni contratos de
repository, salvo el consumo UI del repository de reportes ya existente.

## Interfaces / Contracts

```dart
enum AppThemeMode { system, light, dark }

abstract interface class ThemePreferenceStore {
  Future<AppThemeMode> read();
  Future<void> write(AppThemeMode mode);
}

final class DashboardPeriodState {
  const DashboardPeriodState({required this.period, required this.range});
  final DashboardPeriod period; // week, month, year
  final DateRange range;
}

class MetricCardData {
  const MetricCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorRole,
    required this.route,
    required this.permission,
  });
  final String label;
  final String value;
  final IconData icon;
  final KpiColorRole colorRole;
  final String route;
  final String permission;
}
```

`AppLoadingIndicator`, `AppEmptyState` y `AppErrorView` tendran constructores
inmutables, labels accesibles y callbacks explicitos. `MasItem` sera un valor
const con `section`, `label`, `icon`, `route`, `permission`; la pantalla no
duplicara la tabla de permisos del router, solo la consumira para visibilidad.
El agrupador de chart sera una funcion pura que recibe `Iterable<ChartPoint>` o
`Iterable<Venta>` y retorna puntos ordenados, sin IO ni dependencia Flutter.

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Unit | Tokens light/dark, contraste, serializacion del tema, fallback corrupto, date ranges y grouping diario/mensual | Dart tests puros; fake `ThemePreferenceStore` y fixtures de `ReporteDashboard`. |
| Unit | Mapeo de seis KPIs, permisos CREAR/VER y rutas | Tests de tablas const; verificar que no se derive permiso desde rol. |
| Widget | MetricCard, grid 2/1, chart con datos/vacio, QuickActions, shared loading/empty/error | `flutter_test`, `ProviderScope` overrides, `MediaQuery` 320/360/600dp, semantics. |
| Widget | Dashboard loading/error/retry/empty y tap de KPI/acciones | Repository/provider fake; `pump`, `pumpAndSettle`, finders semanticos y rutas observables. |
| Widget | Shell cinco tabs, estado preservado, FAB autenticado, Mas filtrado y selector de tema | Router de prueba con `StatefulShellRoute`, auth/theme providers overrideados. |
| Integration | Deep links, guards, back Android/iOS, seleccion de tema persistida y chat FAB | `integration_test` con backend fake o fixture; ejecutar en emulator y, cuando exista, dispositivo real. |
| Accessibility | targets >=48dp, labels icon-only, color no unico, texto grande/reduced motion | `SemanticsTester`, `MediaQuery.textScaler` maximo, contrast audit y revision manual TalkBack/VoiceOver. |
| Regression | 52 tests actuales y analyze limpio | `flutter analyze`, `flutter test`; no se aceptan warnings. |
| Build | launcher/splash no Flutter logo | Validar config/asset y `flutter build apk --debug`; inspeccion de mipmaps. |

Golden tests quedaran limitados a tokens/shell cuando el layout se estabilice;
no se usaran como unica prueba de accesibilidad. El chart se verificara por
semantica y valores, no por coordenadas internas del painter.

## Migration / Rollout

No hay migracion de datos ni cambios de backend. La entrega sera incremental y
reversible por fase: primero tokens/shared views, luego dashboard, luego
navegacion, despues polish y finalmente accesibilidad/build. Durante la
migracion, `DashboardAdminPage` se extraera hacia `DashboardScreen` sin cambiar
`dashboardProvider` ni `ReporteDashboard`; las pantallas restantes continuaran
funcionando con wrappers compatibles hasta ser migradas.

La preferencia de tema ausente se interpreta como `system`; valores invalidos
se reemplazan por `system`. La adicion de `shared_preferences` es la unica
dependencia runtime nueva. `flutter_launcher_icons` es solo herramienta de
desarrollo; si no puede ejecutarse, se conservan assets y mipmaps generados
desde la misma fuente. El rollback de navegacion restaura el mapping anterior
sin cambiar las URLs publicas ni datos locales de negocio.

## Open Questions

None. Las decisiones abiertas de la propuesta ya fueron resueltas por la
especificacion. La generacion iOS de assets queda condicionada al entorno
macOS indicado en `flutter/AGENTS.md`, pero no bloquea el objetivo Android.
