# Proposal: UI/UX de la app movil Flutter

## Intent

Transformar la app Flutter de un prototipo funcional a una experiencia movil profesional, consistente y accesible, sin modificar el contrato REST ni la logica de negocio. El cambio resolvera la navegacion saturada, dara jerarquia al dashboard y establecera una identidad visual FerrePlus reutilizable en toda la app.

El alcance se limita estrictamente a `flutter/`. Se conservaran Clean Architecture, Riverpod, GoRouter con `StatefulShellRoute` (ADR-3), permisos efectivos como `Set<String>` y el manejo tipado de fechas/converters (ADR-9). El comportamiento actual del chat ya corregido no se reabrira: el chat se accede mediante el **FAB flotante** (icono de chat) que al pulsarlo abre la pantalla de chat, igual que en la web (boton flotante que abre el panel). El FAB queda visible para cualquier usuario autenticado, tal como ya fue corregido. Opcionalmente, Chat puede aparecer tambien como acceso secundario en **Mas > SISTEMA**, pero la via principal es siempre el FAB flotante.

## Scope

### In Scope

- Design System de tres capas (primitive, semantic, component) en Material 3, con temas claro/oscuro, tipografia, spacing 4/8/12/16/24/32, radios, elevacion, iconografia Material y estilos centralizados para componentes.
- Reemplazo del icono Flutter por un icono propio FerrePlus basado en `Icons.hardware`, coherente con `brand-icon` del sidebar y `login-logo` del frontend. Se creara un asset fuente y se generaran los mipmaps Android mediante `flutter_launcher_icons` (o equivalente reproducible si la compatibilidad local lo exige), incluyendo su uso en splash.
- Rediseño del dashboard: KPI cards con color semantico solo en icono/badge, layout responsive 2 columnas a 1, grafica simple de ventas de 7 dias sin dependencias nuevas, resumen/actividad, acciones rapidas condicionadas por permisos y estados vacio/loading/error sin inventar datos.
- Reestructuracion de navegacion a cinco destinos maximos: Dashboard, Productos, Ventas, Reportes y Mas. `Mas` sera una pagina categorizada con OPERACIONES, CATALOGOS, ADMINISTRACION y SISTEMA; todas las rutas y deep links existentes continuaran disponibles y protegidos.
- AppBar contextual, componentes reutilizables (`MetricCard`, `SalesChart`, `QuickActions`, estados compartidos), responsive layout sin overflow, microinteracciones discretas y estados de feedback consistentes.
- Aplicacion progresiva del sistema visual al resto de pantallas Flutter, incluyendo contraste minimo 4.5:1, targets de 48dp, semantic labels, soporte para escala de texto y verificacion de dark mode.
- Verificacion por fase manteniendo verdes los 52 tests existentes, ademas de tests widget focalizados para componentes, dashboard, navegacion y estados nuevos.

### Out of Scope

- Cambios en `backend/`, `frontend/`, base de datos, endpoints, DTOs de negocio, repositories o reglas de negocio, salvo ajustes estrictamente necesarios para presentar UI existente.
- Nuevas funcionalidades comerciales, nuevos datos para dashboard, cache/offline sync, notificaciones push o rediseño del contrato de autenticacion.
- Reabrir o reproponer el bug historico del FAB de chat; su correccion ya fue aplicada fuera de banda. El chat mantiene el FAB flotante como via principal de acceso (comportamiento ya corregido: visible para cualquier usuario autenticado).
- Cambiar ADR-3 (GoRouter + `StatefulShellRoute`) ni ADR-9 (fechas como `DateTime` con converters ISO); tampoco se alteraran archivos generados de freezed/json_serializable.
- Incorporar una libreria de graficas: el chart de 7 dias usara `CustomPaint` o widgets Flutter existentes, aunque `fl_chart` ya exista en el proyecto.

## Approach

La implementacion sera incremental y comprobable, siguiendo las convenciones de `flutter/AGENTS.md`: widgets pequenos e inmutables, composicion, constructores `const`, Riverpod para estado compartido, `ListView.builder` para listas y separacion `presentation -> domain <- data`. Cada fase debera compilar, analizarse y conservar los tests antes de iniciar la siguiente.

### FASE 1 — Design System, tema e identidad de marca

- Reorganizar `presentation/theme/` en tokens de primitives, semantic y component; centralizar `ColorScheme` claro/oscuro con azul `#1565C0` / `#64B5F6`, superficies oscuras, acento coral y colores KPI.
- Definir escala tipografica, espaciado, radios, elevacion, tamaños de icono, estados y estilos de Card, AppBar, Button, Input, NavigationBar, Dialog, BottomSheet y SnackBar.
- Crear el asset vectorial/ fuente del icono `hardware`, generar iconos Android por densidad y actualizar splash; validar que no quede el logo default de Flutter.
- Crear primitives compartidos para loading, empty y error/retry sin acoplarlos a repositories.
- Validar `flutter analyze`, tests actuales y contraste en ambos temas.

### FASE 2 — Dashboard como prueba visible del sistema

- Extraer `DashboardAdminPage` de `admin_pages.dart` hacia la feature dashboard y conservar el provider/modelo `ReporteDashboard` existente.
- Componer `MetricCard`, `SalesChart`, `QuickActions`, resumen/actividad y `DashboardEmpty`; renderizar solamente datos recibidos del backend.
- Usar `LayoutBuilder`/`MediaQuery` para 2 columnas en ancho disponible y 1 columna en telefonos estrechos; evitar `RenderFlex` overflow y respetar escala de texto.
- Cubrir datos, ausencia de datos, error con retry, loading y visibilidad de acciones por permiso mediante tests widget.

### FASE 3 — Navegacion y acceso a todas las rutas

- Reducir `StatefulShellRoute.indexedStack` a cinco branches, preservando el ADR-3, el estado por tab, redirects, guards y deep links.
- Reescribir `shell_scaffold.dart` con `NavigationBar` de maximo cinco items y `mas_page.dart` con secciones y destinos filtrados por permisos.
- Mantener las rutas canonicas de cada feature; el agrupamiento visual no debe convertir rutas existentes en endpoints nuevos ni romper back navigation.
- Colocar Chat como destino principal de navegacion (no lo es): el chat se abre mediante el FAB flotante, no desde la barra de navegacion. Si aparece en `Mas > SISTEMA`, es solo un acceso secundario redundante.
- Probar navegación entre branches, deep links protegidos, rutas sin permiso y layouts compactos.

### FASE 4 — Pulido progresivo de features

- Migrar AppBars, paddings, colores y componentes de las pantallas existentes a los tokens; reemplazar errores inline y estados vacios/carga por widgets compartidos.
- Aplicar iconografia consistente, feedback de tap, transiciones sutiles y confirmaciones sin animaciones pesadas.
- Verificar listas lazy, selectores Riverpod y ausencia de cambios de negocio o requests adicionales.

### FASE 5 — Dark mode, accesibilidad y cierre

- Ajustar contraste independiente en light/dark, semantic labels, orden de foco, touch targets >=48dp, color no exclusivo como indicador y soporte de texto grande.
- Validar 375dp, orientacion horizontal, telefonos grandes/tablet, safe areas y reduced motion; ejecutar pruebas manuales con TalkBack/VoiceOver cuando el entorno lo permita.
- Ejecutar `flutter analyze`, `flutter test` (baseline de 52 tests), pruebas widget de componentes y build Android de validacion.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `flutter/lib/presentation/theme/` | Modified/New | Tokens, temas light/dark y estilos centralizados de componentes. |
| `flutter/lib/presentation/features/dashboard/` | Modified/New | Dashboard responsive y widgets KPI/chart/acciones/estados. |
| `flutter/lib/presentation/shell/shell_scaffold.dart` | Modified | NavigationBar de cinco destinos y AppBar/shell consistente. |
| `flutter/lib/presentation/features/mas/mas_page.dart` | New | Pagina categorizada para operaciones, catalogos, administracion y sistema. |
| `flutter/lib/core/routing/app_router.dart` | Modified | Cinco branches, subrutas, deep links y guards preservados. |
| `flutter/lib/presentation/shared/widgets/` | Modified/New | Estados loading, empty y error/retry reutilizables. |
| `flutter/android/app/src/main/res/` | Modified | Mipmaps y splash del icono hardware FerrePlus generado. |
| `flutter/pubspec.yaml` | Modified | Solo si se requiere declarar la herramienta reproducible de generacion de iconos. |
| `flutter/test/` | Modified/New | Tests widget y de routing; los 52 tests existentes deben permanecer verdes. |
| `backend/`, `frontend/` | Unchanged | Fuera del alcance. |

## Key Decisions

- **Material 3 como base, no como identidad final:** se centraliza Material 3 pero se personalizan tokens, jerarquia y componentes para evitar el aspecto default.
- **Tres capas de tokens:** los widgets consumen tokens semanticos/componentes, nunca hex ni colores ad hoc; esto permite dark mode sin duplicacion.
- **Cinco destinos y pagina Mas:** se prioriza descubribilidad movil y se conserva el acceso a los 15 modulos mediante categorias y deep links, en lugar de una barra saturada o un drawer como patron principal.
- **Chart sin dependencia nueva:** barras simples con `CustomPaint` o containers reducen peso y riesgo; no se inventan datos ni endpoints.
- **Icono de marca `hardware`:** el motivo herramienta/martillo es la unica firma visual destacada y mantiene continuidad con web; no se usaran emojis ni un logo Flutter recoloreado.
- **Fechas y permisos intactos:** la capa UI usara los `DateTime` y converters existentes y filtrara por permisos efectivos; no se inferira autorizacion desde `rol`.
- **Dark tokens primero, validacion completa despues:** se definen ambos temas en FASE 1 y se prueba exhaustivamente en FASE 5.

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Reorganizar `StatefulShellRoute` rompe estado, redirects o deep links. | High | Mantener ADR-3, probar cada ruta canonica y migrar branches sin cambiar URLs publicas. |
| Un AppBar/spacing global causa overflow en telefonos estrechos o con texto grande. | Medium | `LayoutBuilder`, constraints explicitas, prueba a 375dp/landscape y escala de texto antes de cerrar cada fase. |
| El dashboard muestra KPIs o acciones a usuarios sin permiso o inventa contenido cuando la respuesta esta vacia. | Medium | Selectores de permisos, estados vacios explicitos y fixtures basados solo en `ReporteDashboard`. |
| El icono generado pierde legibilidad en densidades pequenas o no se aplica al splash. | Medium | Asset fuente vectorial, generacion por densidad, inspeccion de mipmaps y build Android instalable en FASE 1. |
| Actualizar tema rompe snapshots/widgets existentes o introduce regresiones visuales silenciosas. | Medium | Tests por componente, migracion por fases y baseline de 52 tests despues de cada fase. |
| Agregar la herramienta de iconos aumenta dependencias o no es compatible con el entorno. | Low | Mantenerla como dev dependency reproducible; si falla, generar mipmaps desde el mismo asset sin tocar runtime ni contrato. |

## Rollback Plan

El cambio se entregara por fases independientes. Si una fase rompe tests, analyze, rutas o build, se detiene la siguiente y se revierte unicamente esa fase a su estado anterior; el backend y los datos no requieren rollback. La navegacion puede restaurarse al scaffold/branch mapping previo manteniendo las rutas canonicas. Si el generador de iconos falla, se conservan los assets fuente y se vuelve temporalmente a mipmaps versionados generados manualmente desde el mismo motivo `hardware`. No se ejecutaran comandos Git de modificacion durante esta propuesta.

## Dependencies

- Flutter 3.38.1 / Dart 3.10.0, Riverpod 3.0.3, GoRouter 16.2.4 y Material 3 ya presentes en `flutter/pubspec.yaml`.
- Contrato existente de `ReporteDashboard` y permisos ya expuestos por la app; no se requieren endpoints nuevos.
- Asset de marca basado en `hardware`; se puede derivar como vector local de Material Icons, sin depender del frontend en tiempo de ejecucion.
- Herramienta de generacion de launcher icon opcional (`flutter_launcher_icons`) o equivalente manual reproducible.

## Open Questions — RESUELTAS (decisiones del usuario)

- **Icono**: se usa el método más simple y reproducible (`flutter_launcher_icons` con un PNG fuente derivado del motivo `hardware`; si falla localmente, se generan los mipmaps manualmente desde el mismo asset).
- **Tema**: la app debe exponer un **selector de tema visible** (claro / oscuro / seguir sistema) dentro de `Mas > SISTEMA`, además de respetar la preferencia del sistema por defecto.
- **Dashboard**: debe mostrar **la misma data que el dashboard web** — 6 KPIs (Total Productos, Stock Bajo, Ventas Hoy, Ventas del Mes, Total Clientes, Proveedores) con navegación al pulsar, y gráfico de ventas por período (semana/mes/año) con selector de período. Sin datos inventados: se usan los campos existentes de `ReporteDashboard`; el bloque de actividad/reciente se limita a lo que el contrato ya entrega (o se omite con empty state).
- **Validación accesibilidad**: se valida en emulador y herramientas disponibles; dispositivo físico queda como paso opcional del usuario.

## Success Criteria

- [ ] `flutter/` contiene el Design System de tres capas y ningun widget nuevo depende de colores, spacing o estilos hardcodeados.
- [ ] El dashboard presenta KPIs, chart de 7 dias, resumen/actividad, acciones permitidas y estados loading/empty/error sin datos inventados ni overflow.
- [ ] La barra movil tiene como maximo cinco destinos y `Mas` hace accesibles todas las secciones, con permisos y deep links funcionando.
- [ ] El icono instalado y el splash muestran el motivo `hardware` FerrePlus, no el logo default de Flutter.
- [ ] Se mantienen ADR-3 y ADR-9, no se agregan endpoints ni cambios en `backend/`/`frontend/`, y la logica de negocio permanece intacta.
- [ ] Cada fase pasa `flutter analyze`; `flutter test` conserva verdes los 52 tests existentes y agrega cobertura widget/routing relevante.
- [ ] Light/dark, 375dp, landscape/tablet, texto ampliado, semantic labels, contraste >=4.5:1 y targets >=48dp son verificados antes del cierre.
