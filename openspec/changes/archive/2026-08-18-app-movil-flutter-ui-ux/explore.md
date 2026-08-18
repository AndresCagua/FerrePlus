# Exploration: UI/UX Redesign — app-movil-flutter-ui-ux

## Current State

La app Flutter funciona correctamente (51 tests green) pero tiene estética de prototipo funcional, no de app profesional. El tema se limita a `ColorScheme.fromSeed` sin tipografía, spacing ni componentes definidos. Cada pantalla hardcodea estilos inline.

## 1. Problemas de UI/UX encontrados

### Navegación saturada (CRÍTICO)
- `shell_scaffold.dart:17-122` — **15 destinations** en el `NavigationBar`. Material Design recomienda máximo 5. Labels se envuelven en múltiples líneas, iconos se pisan, OverflowError en pantallas angostas.
- No hay separación primario/secundario: Dashboard, Productos, Categorías, Proveedores, Clientes, Ventas, Compras, Movimientos, Gastos, Usuarios, Precios, Roles, Reportes, Logs, Chat — todos compiten en la misma barra.

### Dashboard mínimo
- `admin_pages.dart:1021-1043` — `DashboardAdminPage` es un `ListView` con 5 `_metric` cards y un gráfico `LineChart`.
- `admin_pages.dart:1045-1067` — `_kpiGrid` usa `Wrap` + `SizedBox(width: 170)` + `Card(child: ListTile)` — sin iconos, sin color semántico, sin jerarquía visual.
- `admin_pages.dart:1068-1091` — `_salesChart` sin labels de eje, sin tooltip, sin formato de fecha.
- No hay acciones rápidas, no hay actividad reciente, no hay empty state diseñado.
- Datos disponibles en `ReporteDashboard` pero subutilizados: `ventasHoy`, `ventasMes`, `totalComprasMes`, `totalGastosMes`, `productosStockBajo`, `ventasPorDia`, `totalClientes`, `totalProveedores`, `saldoPendienteClientes`.

### Sin Design System
- `app_theme.dart:1-24` — Solo `ColorScheme.fromSeed` + `useMaterial3: true`. Sin tipografía, sin spacing tokens, sin border radius, sin elevation, sin estilos de componentes.
- Colores hardcodeados: `Colors.green.withValues(alpha: .15)` (`admin_pages.dart:281`), `Colors.red.withValues(alpha: .15)` (`admin_pages.dart:282`), `Colors.orange` (`productos_pages.dart:98`).
- Padding inconsistente: 8, 12, 16, 24 usado arbitrariamente en diferentes pantallas.
- `TextStyle(fontWeight: FontWeight.bold, fontSize: 18)` hardcodeado en `_metric` (`admin_pages.dart:1062`).

### AppBar genérica
- Todas las pantallas usan `AppBar(title: const Text(...))` sin personalización — solo texto plano, sin leading actions, sin elevation consistente.

### Estados vacíos/loading/error deficientes
- `CatalogStateView` (`catalog_state_view.dart:1-20`) — minimalista: `CircularProgressIndicator()` para loading, `Text(error!)` para error, `Text('No hay registros')` para vacío.
- `errorView` (`admin_pages.dart:22-32`) — icono `cloud_off` genérico + texto crudo.
- Sin skeleton loading, sinempty state con icono/acción, sin retry visual consistente.

### Touch targets y accesibilidad
- Varios `IconButton` sin tooltip o label semántico.
- `Checkbox` en `_overrideRow` (`admin_pages.dart:530`) sin label accesible.
- Chips de estado sin contraste suficiente en dark mode.

## 2. Causa exacta del FAB del chat no visible

**Código correcto. Es un problema de PERMISOS, no de bug.**

`chat_floating_action_button.dart:13-18`:
```dart
final bool canAccessChat = ref.watch(
  authNotifierProvider.select(
    (auth) => auth.permisos.contains(PermissionCodes.chat),
  ),
);
if (!canAccessChat) return const SizedBox.shrink();
```

El FAB se renderiza en `shell_scaffold.dart:136` como `floatingActionButton` del `Scaffold` del shell. La lógica es correcta: si el usuario no tiene `CHAT_VER`, retorna `SizedBox.shrink()` (invisible).

**Causa probable**: El rol del usuario autenticado no incluye la autoridad `CHAT_VER`. Esto es configurable en el backend, no un bug de código.

**Propuesta de solución UX**: En lugar de ocultar completamente, mostrar el FAB siempre pero con estado deshabilitado y tooltip "Chat no disponible para tu rol". Alternativamente, agregar un badge indicativo o mover el chat al menú "Más" con acceso condicional.

## 3. Propuesta de Design System

### Tokens de 3 capas

**Primitive tokens** (valores crudos):
```dart
// Colors
static const Color blue700 = Color(0xFF1565C0);
static const Color blue200 = Color(0xFF64B5F6);
static const Color orange400 = Color(0xFFFF7043);
static const Color orange200 = Color(0xFFFF8A65);
static const Color gray50 = Color(0xFFF5F5F5);
static const Color gray900 = Color(0xFF1A1A1A);
static const Color white = Color(0xFFFFFFFF);
static const Color green500 = Color(0xFF4CAF50);
static const Color coral500 = Color(0xFFFF7043);
static const Color amber500 = Color(0xFFFFC107);

// Spacing
static const double space4 = 4;
static const double space8 = 8;
static const double space12 = 12;
static const double space16 = 16;
static const double space24 = 24;
static const double space32 = 32;

// Border Radius
static const double radiusS = 8;
static const double radiusM = 12;
static const double radiusL = 16;
static const double radiusXL = 24;

// Typography sizes
static const double textXS = 12;
static const double textS = 13;
static const double textM = 14;
static const double textL = 16;
static const double textXL = 18;
static const double text2XL = 20;
static const double text3XL = 22;
static const double text4XL = 24;
static const double text5XL = 30;
```

**Semantic tokens** (significado):
```dart
// Light
static const Color primary = blue700;
static const Color onPrimary = white;
static const Color secondary = orange400;
static const Color surface = white;
static const Color surfaceVariant = gray50;
static const Color onSurface = gray900;
static const Color error = Color(0xFFB00020);

// KPI semantic colors
static const Color kpiVentas = green500;
static const Color kpiCompras = blue700;
static const Color kpiGastos = coral500;
static const Color kpiStockBajo = amber500;

// Dark
static const Color darkPrimary = blue200;
static const Color darkSurface = Color(0xFF1E1E1E);
static const Color darkSurfaceVariant = Color(0xFF2A2A2A);
```

**Component tokens** (reutilizables):
```dart
// Card
static const EdgeInsets cardPadding = EdgeInsets.all(space16);
static const double cardRadius = radiusM;
static const double cardElevation = 1;

// AppBar
static const double appBarElevation = 0;
static const FontWeight appBarTitleWeight = FontWeight.w600;
static const double appBarTitleSize = textXL;

// NavigationBar
static const double navBarHeight = 80;

// KPI Card
static const double kpiIconSize = 24;
static const double kpiValueSize = text5XL;
static const double kpiLabelSize = textS;

// Button
static const double buttonHeight = 48;
static const double buttonRadius = radiusS;

// Input
static const double inputHeight = 56;
```

### ColorScheme Light/Dark
- **Light**: `ColorScheme.fromSeed(seedColor: blue700, primary: blue700, secondary: orange400, surface: white, error: red700)`
- **Dark**: `ColorScheme.fromSeed(seedColor: blue200, brightness: Brightness.dark, secondary: orange200)`

### Typography Scale
- Screen title: 22-24sp, FontWeight.w600
- Section title: 18-20sp, FontWeight.w600
- KPI value: 24-30sp, FontWeight.w700
- KPI label: 13-15sp, FontWeight.w500
- Body: 14-16sp, FontWeight.w400
- Caption: 12-14sp, FontWeight.w400

### Componentes
- **KPI Card**: Card con Container decorado, icono + label + value con color semántico
- **AppBar**: Elevated AppBar con leading icono de marca, actions condicionales
- **Bottom Navigation**: Max 5 items, iconos de 24px, labels de 12sp
- **Empty State**: Icono grande + título + subtítulo + acción opcional
- **Loading**: Shimmer skeleton para listas, `CircularProgressIndicator` inline
- **Error State**: Icono + mensaje + retry button
- **Dialog**: AlertDialog con padding consistente, botones alineados a la derecha
- **SnackBar**: Auto-dismiss 3s, acción de retry opcional

## 4. Propuesta de Navegación

### 4 items principales + "Más"

```
┌─────────────────────────────────────────┐
│  📊 Dashboard  │  📦 Productos  │  💰 Ventas  │  📈 Reportes  │  ⋯ Más  │
└─────────────────────────────────────────┘
```

**Rutas por tab:**

| Tab | Ruta principal | Branch index |
|-----|---------------|-------------|
| Dashboard | `/` | 0 |
| Productos | `/productos` | 1 |
| Ventas | `/ventas` | 2 |
| Reportes | `/reportes` | 3 |
| Más | `/mas` (nueva) | 4 |

**Pantalla "Más"** — ListView agrupado por categoría:

**OPERACIONES**
- Compras (`/compras`) — `COMPRAS_VER`
- Movimientos (`/movimientos`) — `MOVIMIENTOS_VER`
- Gastos (`/gastos`) — `GASTOS_VER`

**CATÁLOGOS**
- Categorías (`/categorias`) — `CATEGORIAS_VER`
- Proveedores (`/proveedores`) — `PROVEEDORES_VER`
- Clientes (`/clientes`) — `CLIENTES_VER`
- Precios (`/gestion-precios`) — `PRECIOS_VER`

**ADMINISTRACIÓN**
- Usuarios (`/usuarios`) — `USUARIOS_VER`
- Roles (`/roles`) — `ROLES_VER`

**SISTEMA**
- Logs (`/logs`) — `LOGS_VER`
- Chat (`/chat`) — `CHAT_VER`

**Mapeo de StatefulShellRoute:**
- Reducir de 15 branches a 5 branches
- Branch 0: Dashboard `/`
- Branch 1: Productos `/productos` (+ categorías, proveedores como subrutas anidadas)
- Branch 2: Ventas `/ventas` (+ compras, movimientos, gastos)
- Branch 3: Reportes `/reportes` (+ logs como subruta)
- Branch 4: Más `/mas` (página dedicada con ListView categorizado)

**Accesibilidad**: Todos los ítems del menú "Más" siguen siendo navegables vía deep link y GoRouter redirect con permisos.

## 5. Propuesta de Dashboard

### Datos disponibles de `/api/reportes/dashboard`:
```dart
class ReporteDashboard {
  ventasHoy, totalVentasHoy, ventasMes, totalVentasMes,
  totalComprasMes, totalGastosMes, productosStockBajo,
  totalProductos, totalClientes, totalProveedores, totalUsuarios,
  saldoPendienteClientes, ventasPorDia (List<ChartPoint>),
  productosStockBajoList (List<Map>)
}
```

### Layout propuesto:

```
┌─────────────────────────────────┐
│  AppBar: "FerrePlus" + avatar   │
├─────────────────────────────────┤
│  KPI Grid (2 columnas)          │
│  ┌──────────┐ ┌──────────┐     │
│  │🟢 Ventas │ │🔵 Compras│     │
│  │  $12,500 │ │  $8,200  │     │
│  │  Hoy     │ │  Mes     │     │
│  └──────────┘ └──────────┘     │
│  ┌──────────┐ ┌──────────┐     │
│  │🔴 Gastos │ │⚠ Stock   │     │
│  │  $3,100  │ │  5 items │     │
│  │  Mes     │ │  bajo    │     │
│  └──────────┘ └──────────┘     │
├─────────────────────────────────┤
│  Ventas últimos 7 días          │
│  ┌─────────────────────────┐   │
│  │  █ █ █ █ █ █ █           │   │
│  │  L M M J V S D           │   │
│  └─────────────────────────┘   │
├─────────────────────────────────┤
│  Acciones Rápidas (2x2 grid)   │
│  ┌────────┐ ┌────────┐        │
│  │+ Venta │ │+ Producto│       │
│  └────────┘ └────────┘        │
│  ┌────────┐ ┌────────┐        │
│  │+ Gasto │ │+ Compra │       │
│  └────────┘ └────────┘        │
└─────────────────────────────────┘
```

### KPI Cards (por permiso):
- **Ventas hoy**: icon `point_of_sale`, color `kpiVentas`, value `money(r.ventasHoy)`
- **Compras mes**: icon `shopping_cart`, color `kpiCompras`, value `money(r.totalComprasMes)`
- **Gastos mes**: icon `money_off`, color `kpiGastos`, value `money(r.totalGastosMes)`
- **Stock bajo**: icon `warning_amber`, color `kpiStockBajo`, value `'${r.productosStockBajo}'`

### Chart 7 días (sin deps nuevas):
- Barras simples con `CustomPaint` o `Row` de `Container` con `FractionallySizedBox`
- Labels de día de semana (L, M, M, J, V, S, D)
- Valores formateados con `money()`
- Empty state: "Sin ventas registradas en los últimos 7 días"

### Acciones Rápidas (gated por permisos):
- `+ Nueva venta` → `/ventas/nuevo` (si `VENTAS_CREAR`)
- `+ Nuevo producto` → `/productos/nuevo` (si `PRODUCTOS_CREAR`)
- `Registrar gasto` → `/gastos/nuevo` (si `GASTOS_CREAR`)
- `Registrar compra` → `/compras/nuevo` (si `COMPRAS_CREAR`)

### Empty State (sin datos):
- Icono `dashboard` grande
- Título "Bienvenido a FerrePlus"
- Subtítulo "Los datos de tu negocio aparecerán aquí"
- Botón "Configurar datos iniciales" (gated)

## 6. Plan de fases

### FASE 1 — Design System (Theme)
**Archivos a crear/modificar:**
- `flutter/lib/presentation/theme/app_theme.dart` — Reescribir con tokens completos
- `flutter/lib/presentation/theme/app_colors.dart` — Primitive + semantic + component tokens
- `flutter/lib/presentation/theme/app_typography.dart` — Scale completa
- `flutter/lib/presentation/theme/app_spacing.dart` — Spacing + radius + elevation
- `flutter/lib/presentation/theme/app_components.dart` — Estilos de Card, AppBar, Button, Input, NavigationBar

### FASE 2 — Dashboard
**Archivos a crear/modificar:**
- `flutter/lib/presentation/features/dashboard/dashboard_screen.dart` — Reescribir (actualmente es placeholder)
- `flutter/lib/presentation/features/dashboard/widgets/kpi_card.dart` — Nuevo
- `flutter/lib/presentation/features/dashboard/widgets/sales_chart.dart` — Nuevo
- `flutter/lib/presentation/features/dashboard/widgets/quick_actions.dart` — Nuevo
- `flutter/lib/presentation/features/dashboard/widgets/dashboard_empty.dart` — Nuevo
- `flutter/lib/presentation/features/admin_pages.dart` — Mover `DashboardAdminPage` a `dashboard/dashboard_screen.dart`, actualizar import en `app_router.dart`

### FASE 3 — Navegación
**Archivos a crear/modificar:**
- `flutter/lib/presentation/shell/shell_scaffold.dart` — Reescribir: 5 tabs + menú Más
- `flutter/lib/presentation/shell/chat_floating_action_button.dart` — Evaluar: mover a Más o mantener FAB
- `flutter/lib/presentation/features/mas/mas_page.dart` — Nuevo: ListView categorizado
- `flutter/lib/core/routing/app_router.dart` — Reducir branches de 15 a 5, agregar branch Más
- `flutter/lib/presentation/shared/widgets/catalog_state_view.dart` — No cambia

### FASE 4 — Resto de pantallas (progresivo)
**Archivos a modificar:**
- Todas las páginas de features: aplicar Design System (tipografía, spacing, colores)
- `flutter/lib/presentation/shared/widgets/` — Crear `app_empty_state.dart`, `app_error_view.dart`, `app_loading_skeleton.dart`
- Reemplazar `errorView()` inline por widget compartido
- Reemplazar `CircularProgressIndicator()` por skeleton consistente
- Agregar `AppBar` personalizada a cada pantalla

### FASE 5 — Pulido
- Dark mode testing y ajustes
- Accesibilidad: semantic labels en todos los botones, contraste verificado
- Touch targets ≥ 48dp verificados
- `flutter analyze` limpio

## 7. Riesgos y decisiones abiertas

### Riesgos
- **GoRouter refactor**: Reducir branches de 15 a 5 requiere reestructurar `StatefulShellRoute.indexedStack`. Las pantallas de sub-categorías (Categorías, Proveedores, Clientes) deben moverse como subrutas dentro del branch de Productos o tener su propio manejo.
- **Tests existentes**: 51 tests pueden romperse al cambiar la estructura de navegación y el tema. Necesitan actualización coordinada.
- **Empty state sin backend**: El componente debe estar listo para recibir datos pero no inventar endpoints.

### Decisiones abiertas
1. **¿Más como page o drawer?** — Page es más mobile-first; drawer es más web-like. Recomendación: page con `ListView` categorizado.
2. **¿Chat como FAB o como item en Más?** — FAB es más discoverable pero compite con acciones de pantalla. Recomendación: FAB siempre visible (aunque disabled sin permiso) + acceso en Más.
3. **¿CustomPaint para chart o Row de Container?** — CustomPaint es más performante; Container es más simple. Para barras simples, Container con `FractionallySizedBox` es suficiente.
4. **¿Dark mode en fase 1 o fase 5?** — Recomendación: definir tokens dark en fase 1, pero testing completo en fase 5.
5. **¿Shimmer skeleton o solo CircularProgressIndicator?** — Shimmer es más profesional pero agrega dependencia. Recomendación: empezar con `CircularProgressIndicator` consistente, agregar shimmer como mejora futura.

## skill_resolution

- **ui-ux-pro-max**: Cargado. Proporcionó guidelines de navegación (max 5 items), touch targets (44-48px), tipografía (base 16px, line-height 1.5), y anti-patterns (labels wrapping, overloaded nav).
- **mobile-design**: Cargado. Proporcionó Fitts' Law, thumb zone considerations, touch-first philosophy, y mandatory checkpoint.
- **flutter-expert**: Cargado. Proporcionó patterns de Riverpod, const constructors, widget composition, y performance guidelines.
- **clean-code**: Cargado (referenciado por especialista_flutter). DRY, KISS, Separation of Concerns aplicados al refactoring.
- **design-system-patterns**: Cargado. Proporcionó 3-layer token architecture (primitive → semantic → component).
- **frontend-design**: Cargado. Proporcionó guidance para visual identity distinct from default Material.
- **mobile-app-ui-design**: Cargado. Proporcionó patterns de mobile navigation, bottom sheets, y mobile-first layout.

## Recommended Approach

**Phased incremental delivery** starting with Design System (FASE 1) as foundation, then Dashboard (FASE 2) as visible proof of concept, then Navigation (FASE 3) as UX improvement, then progressive polish (FASE 4-5). Each phase independently deployable and testable.
