# Design: Aplicacion movil Flutter de FerrePlus

## Technical Approach

Se creara una aplicacion Flutter independiente en `flutter/`, con Android como plataforma de entrega prioritaria e iOS como objetivo secundario. La aplicacion sera un cliente del backend existente: no reproducira reglas de persistencia ni autorizacion del servidor y no modificara `backend/` ni `frontend/`.

La solucion seguira Clean Architecture con dependencia hacia el dominio: `presentation -> domain <- data`. Las pantallas se agruparan por feature, mientras que los modelos de dominio, contratos de repositorio, cliente HTTP y almacenamiento permaneceran en sus capas respectivas. Riverpod sera tanto el contenedor de dependencias como el mecanismo de estado; GoRouter resolvera autenticacion, permisos y deep links; Dio centralizara JWT y errores; `freezed` + `json_serializable` mantendran DTOs y estados inmutables.

Los CRUD simples iran directamente de provider a repositorio. Auth, POS, compras, permisos, reportes y chat tendran casos de uso cuando coordinen varios repositorios o necesiten reglas de presentacion no triviales. Las autoridades se trataran siempre como `Set<String>`; el campo `rol` solo se mostrara como dato informativo.

## Architecture Overview

```text
MaterialApp.router
        |
     GoRouter ---- AuthNotifier/PermissionGuard
        |
 StatefulShellRoute -> feature pages -> Riverpod providers
                                      |
                              use cases (cuando aplica)
                                      |
                         domain repository interfaces
                                      |
             repository implementations -> Dio ApiClient
                                      |             |
                          secure session storage   backend REST
```

Una peticion autenticada sigue este flujo:

```text
Page -> provider/notifier -> use case -> repository -> Dio interceptor
                                                               |
                                                   401 -> logout -> /login
```

## Project Structure

La siguiente es la estructura objetivo. Los archivos `*.g.dart` y `*.freezed.dart` son generados y no se editan manualmente.

```text
flutter/
├── pubspec.yaml                         # Dependencias y scripts del proyecto
├── analysis_options.yaml                # strict-casts, strict-raw-types y lints
├── AGENTS.md                            # Convenciones, comandos y limites locales
├── .gitignore                            # build, .dart_tool, secretos y archivos locales
├── lib/
│   ├── main.dart                         # Bootstrap: ProviderScope y MaterialApp.router
│   ├── core/
│   │   ├── config/
│   │   │   ├── api_config.dart            # API_BASE_URL y configuracion de entorno
│   │   │   └── app_config.dart            # Nombre, timeouts y flags de build
│   │   ├── constants/
│   │   │   ├── api_paths.dart             # Rutas REST, sin URLs completas
│   │   │   ├── permission_codes.dart      # Autoridades conocidas como constantes
│   │   │   └── app_constants.dart         # Limites, formatos y textos tecnicos
│   │   ├── errors/
│   │   │   ├── failure.dart               # Union de errores de dominio
│   │   │   └── failure_mapper.dart        # DioException -> Failure
│   │   ├── routing/
│   │   │   ├── app_router.dart            # GoRouter y StatefulShellRoute
│   │   │   ├── route_permissions.dart     # Ruta -> permiso de lectura
│   │   │   └── auth_redirect.dart          # Redirect auth/permission/error
│   │   ├── formatters/
│   │   │   ├── currency_formatter.dart    # Moneda y redondeo visual
│   │   │   └── date_formatter.dart        # UI dd/MM/yyyy HH:mm e ISO de API
│   │   └── providers/
│   │       ├── api_client_provider.dart   # Dio y ciclo de vida
│   │       ├── storage_provider.dart      # Secure storage
│   │       └── router_provider.dart       # Router reactivo a AuthNotifier
│   ├── domain/
│   │   ├── models/                        # Entidades inmutables sin Dio ni Flutter
│   │   │   ├── auth_session.dart
│   │   │   ├── producto.dart, categoria.dart, proveedor.dart, cliente.dart
│   │   │   ├── venta.dart, detalle_venta.dart, compra.dart, detalle_compra.dart
│   │   │   ├── movimiento_stock.dart, gasto.dart
│   │   │   ├── usuario.dart, rol.dart, modulo.dart, permiso.dart
│   │   │   ├── auditoria.dart, precio_producto.dart, historico_precio.dart
│   │   │   ├── reporte_dashboard.dart, reporte_ventas.dart
│   │   │   ├── reporte_inventario.dart, reporte_movimientos.dart
│   │   │   └── chat_message.dart, chat_response.dart, chat_source.dart
│   │   ├── repositories/                  # Interfaces consumidas por presentation
│   │   │   ├── auth_repository.dart
│   │   │   ├── producto_repository.dart, categoria_repository.dart
│   │   │   ├── proveedor_repository.dart, cliente_repository.dart
│   │   │   ├── venta_repository.dart, compra_repository.dart
│   │   │   ├── movimiento_stock_repository.dart, gasto_repository.dart
│   │   │   ├── usuario_repository.dart, rol_repository.dart
│   │   │   ├── catalogo_repository.dart, precio_repository.dart
│   │   │   ├── reporte_repository.dart, log_repository.dart, chat_repository.dart
│   │   │   └── session_storage.dart
│   │   └── use_cases/
│   │       ├── restore_session.dart, login.dart, refresh_permissions.dart
│   │       ├── build_sale.dart, build_purchase.dart
│   │       ├── update_sale_price.dart, send_chat_message.dart
│   │       └── rebuild_chat_index.dart
│   ├── data/
│   │   ├── models/                        # DTOs freezed/json_serializable y converters
│   │   │   ├── auth_dto.dart, producto_dto.dart, categoria_dto.dart
│   │   │   ├── proveedor_dto.dart, cliente_dto.dart, venta_dto.dart
│   │   │   ├── compra_dto.dart, movimiento_stock_dto.dart, gasto_dto.dart
│   │   │   ├── usuario_dto.dart, rol_dto.dart, modulo_dto.dart, permiso_dto.dart
│   │   │   ├── auditoria_dto.dart, precio_producto_dto.dart, historico_precio_dto.dart
│   │   │   ├── reporte_dto.dart, reporte_ventas_dto.dart, reporte_inventario_dto.dart
│   │   │   ├── reporte_movimientos_dto.dart, chat_response_dto.dart, chat_source_dto.dart
│   │   │   └── date_time_converters.dart
│   │   ├── repositories/                   # Implementaciones y mapeo DTO -> dominio
│   │   │   ├── auth_repository_impl.dart
│   │   │   ├── producto_repository_impl.dart, categoria_repository_impl.dart
│   │   │   ├── proveedor_repository_impl.dart, cliente_repository_impl.dart
│   │   │   ├── venta_repository_impl.dart, compra_repository_impl.dart
│   │   │   ├── movimiento_stock_repository_impl.dart, gasto_repository_impl.dart
│   │   │   ├── usuario_repository_impl.dart, rol_repository_impl.dart
│   │   │   ├── catalogo_repository_impl.dart, precio_repository_impl.dart
│   │   │   ├── reporte_repository_impl.dart, log_repository_impl.dart
│   │   │   └── chat_repository_impl.dart
│   │   ├── services/
│   │   │   ├── api_client.dart             # Wrapper tipado sobre Dio
│   │   │   └── session_storage_impl.dart   # flutter_secure_storage
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart       # Bearer y 401
│   │       └── error_interceptor.dart      # Log tecnico controlado
│   └── presentation/
│       ├── shared/widgets/                 # Loading, empty, error, permission, confirm
│       ├── shared/forms/                   # campos, selectores, date range, money
│       ├── theme/app_theme.dart            # Material 3 claro/oscuro
│       ├── shell/main_shell.dart           # NavigationBar/drawer filtrado
│       └── features/
│           ├── auth/{providers,pages,widgets}/
│           ├── dashboard/{providers,pages,widgets}/
│           ├── productos/{providers,pages,widgets}/
│           ├── categorias/{providers,pages,widgets}/
│           ├── proveedores/{providers,pages,widgets}/
│           ├── clientes/{providers,pages,widgets}/
│           ├── ventas/{providers,pages,widgets}/
│           ├── compras/{providers,pages,widgets}/
│           ├── movimientos/{providers,pages,widgets}/
│           ├── gastos/{providers,pages,widgets}/
│           ├── precios/{providers,pages,widgets}/
│           ├── usuarios/{providers,pages,widgets}/
│           ├── roles/{providers,pages,widgets}/
│           ├── reportes/{providers,pages,widgets}/
│           ├── logs/{providers,pages,widgets}/
│           └── chat/{providers,pages,widgets}/
├── test/
│   ├── core/, data/, domain/
│   └── presentation/features/{auth,productos,ventas,chat,...}/
└── integration_test/
    └── authenticated_smoke_test.dart     # Smoke Android contra backend de prueba
```

Cada feature mantendra `page` como composicion de widgets pequenos y `provider` como unico lugar de estado/presentacion. Ningun repositorio importara `material.dart` ni una pantalla.

## State Management: Riverpod

Se usara Riverpod con providers generados o declarativos consistentes con la version fijada en S1. La jerarquia sera:

```text
storageProvider
  -> apiClientProvider (Dio + tokenReader + onUnauthorized)
      -> *RepositoryProvider
          -> *Provider / *Notifier
```

- `sessionStorageProvider`: interfaz `read/write/clear` de token, usuario y permisos.
- `apiClientProvider`: instancia unica de Dio por `ProviderScope`; se dispone al cerrar el scope.
- `authNotifierProvider`: `AsyncNotifier<AuthState>` con estados `loading`, `unauthenticated`, `authenticated`, `failure`. Expone `restore`, `login`, `logout`, `refreshMe` y `hasPermission`.
- `permissionSetProvider`: derivado de AuthState; usa `Set<String>`, nunca `rol`.
- Catalogos (`productosProvider`, `categoriasProvider`, `proveedoresProvider`, `clientesProvider`, `gastosProvider`): `AsyncNotifier<List<T>>`, con filtros en un `QueryState` inmutable y `reload()` explicito.
- Detalles: `FutureProvider.family<T, int>` invalidable al guardar/anular.
- Formularios/POS/compras: `Notifier<FormState>` o `StateNotifier` cuando haya comandos y lista mutable de detalles; el estado expuesto siempre sera inmutable.
- Dashboard/reportes: `AsyncNotifier` con parametros de rango; logs: `AsyncNotifier<Paginated<Auditoria>>` con cursor/pagina y filtros.
- Chat: `AsyncNotifier<ChatState>`; el historial, `conversationId` y errores forman parte del estado para no perder mensajes ante fallos.
- No se usara `StreamProvider` hasta que exista un endpoint de streaming/WebSocket; el backend actual es request/response.

La recuperacion de sesion se ejecuta una sola vez en bootstrap. Si hay token valido se llama a `/api/usuarios/me`, se reemplaza el conjunto local de permisos y se persiste la sesion actualizada. Al volver a una ruta protegida despues de una pausa prolongada se permite un refresh deduplicado, no uno por cada rebuild. Tras una mutacion exitosa se invalida el provider de listado correspondiente; no se mantienen caches offline.

Los providers `autoDispose` se usaran para detalles, formularios y consultas con parametros. Los providers de sesion, cliente, repositorios y router viven mientras viva el `ProviderScope`. Antes de una nueva peticion se cancelan consultas Dio asociadas a la pantalla; un `logout` invalida providers autenticados y borra almacenamiento.

## Routing and Screen Contract

Se usara `MaterialApp.router` con `StatefulShellRoute.indexedStack`, pues conserva el estado de cada rama. En telefono se mostrara `NavigationBar` con destinos permitidos; en ancho mayor se usara `NavigationDrawer`. El menu y el guard consumen la misma tabla de permisos.

| Ruta | Pantalla | Permiso de entrada | Acciones principales |
|---|---|---|---|
| `/login` | LoginPage | publica | login |
| `/registro-inicial` | InitialAdminPage | publica y solo backend sin usuarios | registro |
| `/dashboard` | DashboardPage | `DASHBOARD_VER` (o permiso definido por backend) | refrescar |
| `/productos`, `/productos/:id` | ProductList/DetailPage | `PRODUCTOS_VER` | crear/editar/eliminar por `PRODUCTOS_CREAR/EDITAR/ELIMINAR` |
| `/categorias` | CategoryList/FormPage | `CATEGORIAS_VER` | CRUD por autoridad correspondiente |
| `/proveedores` | SupplierList/FormPage | `PROVEEDORES_VER` | CRUD por autoridad correspondiente |
| `/clientes` | CustomerList/FormPage | `CLIENTES_VER` | CRUD por autoridad correspondiente |
| `/ventas`, `/ventas/nueva`, `/ventas/:id` | SaleList/POS/DetailPage | `VENTAS_VER` / `VENTAS_CREAR` | anular con `VENTAS_ELIMINAR` |
| `/compras`, `/compras/nueva`, `/compras/:id` | PurchaseList/Form/DetailPage | `COMPRAS_VER` / `COMPRAS_CREAR` | editar/anular por autoridad |
| `/movimientos` | StockMovementPage | `MOVIMIENTOS_VER` | crear con `MOVIMIENTOS_CREAR` |
| `/gastos` | ExpenseList/FormPage | `GASTOS_VER` | CRUD por autoridad correspondiente |
| `/precios`, `/precios/:id/historial` | PriceList/HistoryPage | `PRECIOS_VER` | actualizar con `PRECIOS_EDITAR` |
| `/usuarios`, `/usuarios/:id` | UserList/FormPage | `USUARIOS_VER` | CRUD/password por autoridad |
| `/roles`, `/roles/:id` | RoleList/FormPage | `ROLES_VER` | matriz por autoridad |
| `/reportes/ventas`, `/reportes/inventario`, `/reportes/movimientos` | Report pages | `REPORTES_VER` | filtros y reintento |
| `/logs` | AuditLogPage | `LOGS_VER` | borrar rango con `LOGS_ELIMINAR` |
| `/chat` | ChatPage | `CHAT_VER` o autoridad efectiva del endpoint | rebuild con `CHAT_INDEX_REBUILD` |

`/` redirige a `/dashboard`. El redirect primero espera la restauracion de auth; luego envia no autenticados a `/login`, autenticados fuera de `/login` y sin permiso a `/dashboard` (o a la primera ruta permitida). Un deep link conserva la ubicacion solicitada en `from` solo para usuarios que finalmente tengan permiso. Un 401 no intenta reintentar: el interceptor ejecuta logout idempotente y el router redirige a `/login`; un 403 se convierte en `Failure.forbidden` y mantiene la pantalla con mensaje controlado.

## Networking: Dio

`ApiConfig` lee exclusivamente `const String.fromEnvironment('API_BASE_URL')`. S1 definira un valor de desarrollo `http://10.0.2.2:8080` para emulator si la variable esta ausente; builds de dispositivo fisico deben recibir `--dart-define=API_BASE_URL=http://<ip-lan>:8080`. No habra URL productiva en codigo fuente.

Configuracion inicial de Dio:

- `baseUrl`: `ApiConfig.baseUrl` validada como URI absoluta.
- `connectTimeout`: 10 s; `sendTimeout`: 15 s; `receiveTimeout`: 30 s.
- Headers `Accept` y `Content-Type: application/json`.
- `AuthInterceptor` agrega `Authorization: Bearer <token>` salvo login/register y coordina un logout de una sola vez ante 401.
- No se implementara refresh token porque el contrato expuesto solo entrega JWT; un 401 invalida sesion. Si el backend agrega refresh, se incorporara como cambio separado con cola de requests.
- `FailureMapper` traduce `DioException`, 400/422, 401, 403, 404, 409 y 5xx a `Failure.network/auth/validation/forbidden/notFound/conflict/server`.
- Los logs de red se limitan a metodo, ruta, status y duracion en builds de desarrollo; nunca token, password, pregunta completa del chat o payload sensible.

Los repositorios solo exponen entidades de dominio o `Failure` mediante una convencion tipada (excepcion `RepositoryException` mapeada en providers). Las respuestas 200/201 se deserializan con DTO generado; listas paginadas aceptan el wrapper real del backend y fixtures tolerantes, pero no usan `dynamic` fuera de `ApiClient`/mapper. JSON grande, como reportes o logs, puede parsearse con `compute` si el profiling de Android lo justifica.

## Models and API Contracts

Los DTOs seran inmutables con `@freezed` y `fromJson/toJson`; se mapearan a modelos de dominio para evitar que el contrato HTTP se filtre a la UI.

| Modelo | Campos principales y contrato |
|---|---|
| `AuthSession` | `token`, `email`, `nombre`, `rol?`, `usuarioId`, `Set<String> permisos`; token/permisos son criticos para autenticacion |
| `Usuario` | `id`, `nombre`, `email`, `telefono?`, `activo`, `rolId?`, `rolNombre?`, `Set<String> permisos`, `overrides` |
| `Producto` | `id?`, `nombre`, `descripcion?`, `codigoBarras?`, `stockActual`, `stockMinimo?`, `stockMaximo?`, `precioCompra`, `precioVenta`, `unidadMedida?`, `imagen?`, `categoriaId?`, `categoriaNombre?`, `proveedorId?`, `proveedorNombre?`, `activo` |
| `Categoria` | `id?`, `nombre`, `descripcion?`, `activo?` según DTO real |
| `Proveedor` | `id?`, `nombre`, `contacto?`, `telefono?`, `email?`, `direccion?`, `activo?` según DTO real |
| `Cliente` | `id?`, `nombre`, `documento?`, `telefono?`, `email?`, `direccion?`, `activo?` según DTO real |
| `Venta/DetalleVenta` | venta: `id?`, `numeroFactura`, `clienteId?`, `clienteNombre?`, `subtotal`, `descuento`, `iva`, `total`, `metodoPago`, `estado`, `observaciones?`, `usuarioId?`, `fechaCreacion?`, `detalles`; detalle: `productoId`, `productoNombre?`, `cantidad`, `precioUnitario`, `subtotal?` |
| `Compra/DetalleCompra` | compra: `id?`, `numeroFactura`, `proveedorId?`, `proveedorNombre?`, `subtotal`, `descuento`, `iva`, `total`, `estado`, `observaciones?`, `fechaFactura?`, `usuarioId?`, `fechaCreacion?`, `detalles`; detalle equivalente con cantidades/precio |
| `MovimientoStock` | `id?`, `productoId`, `productoNombre?`, `cantidad`, `tipo`, `referencia?`, `motivo?`, `precioUnitario?`, `fecha?`, `usuarioId?` |
| `Gasto` | `id?`, `descripcion`, `monto`, `fechaGasto`, `categoria?`, `observaciones?`, `usuarioId?` |
| `Rol/Modulo/Permiso` | ids, nombres, descripcion?; rol incluye `permisos: Set<String>`; modulo/permisos alimentan matriz |
| `Auditoria` | `id`, `entidad`, `entidadId?`, `accion`, `usuarioId?`, `usuarioNombre?`, `fecha`, `detalle?` |
| `PrecioProducto/HistoricoPrecio` | producto/id/nombre, precio actual, `nuevoPrecio?`, `margenPorcentaje?`, `referencia?`, `fecha`, usuario? |
| Reportes | dashboard: KPIs de `ReporteDTO`, `productosMasVendidos`, `ventasPorDia`, stock bajo; reportes de ventas/inventario/movimientos modelan filas, totales y filtros |
| `ChatResponse/ChatSource` | `answer`, `sources?`; source: `entityType`, `entityId?`, `excerpt?`, `metadata.title?`; `guia` se conserva opcional por compatibilidad, sin renderizar HTML |

Enums se modelaran como enums Dart con converter tolerante `unknown` para `estado` (`COMPLETADA`, `ANULADA`, etc.), `tipo` (`ENTRADA`, `SALIDA`, `AJUSTE`) y `metodoPago`; si llega un valor nuevo no se descarta el registro. Los montos se mantienen como `double` para interoperar con JSON y se redondean solo en UI; no se usa `int` de centavos porque el backend entrega `BigDecimal`. Fechas de dominio son `DateTime`: timestamps con offset se convierten a local solo al mostrar y fechas `LocalDate` se representan como `DateTime` a medianoche local mediante un converter ISO `yyyy-MM-dd`; nunca se presenta un String crudo. Campos opcionales son nullable y listas ausentes se normalizan a lista vacia.

## Local Storage and Session Security

Se elegira `flutter_secure_storage` sobre `shared_preferences`: el token JWT y la identidad de sesion son credenciales y requieren almacenamiento protegido por Keystore en Android/iOS; preferencias no cifradas no son una frontera suficiente. Se almacenaran claves separadas (`jwt_token`, `session_user`, `session_permissions`) y una version de schema.

Escritura atomica logica: validar campos criticos de login, escribir token y snapshot de permisos, y solo despues publicar `authenticated`. Lectura corrupta, incompleta o ilegible limpia las tres claves y produce `unauthenticated`. `logout` limpia token, usuario, permisos y cualquier conversationId del chat. Los permisos persistidos son solo bootstrap; `/api/usuarios/me` es la fuente efectiva tras recuperar la sesion. No se guardaran respuestas de negocio ni cache offline.

## Chat

`ChatNotifier` conserva `List<ChatMessage>`, `conversationId?`, `isSending`, `error?` y `isRebuildingIndex`. `send(question)` valida no vacio, agrega burbuja del usuario, envia `{question, conversationId?}`, conserva el id devuelto si existe y agrega respuesta o fallback sin eliminar el historial. La reconstruccion se muestra solo si `CHAT_INDEX_REBUILD` y requiere confirmacion.

Se usara `flutter_markdown` con una configuracion de elementos permitidos y sanitizacion previa: se escapa/elimina HTML, no se habilitan raw HTML, URLs externas ejecutables ni scripts, y solo se soportan parrafos, negrita, cursiva, listas y enlaces tratados como texto seguro. Si el paquete no permite garantizar esa politica en la version fijada, se usara un parser propio pequeno que transforme esos tokens en widgets (`Text.rich`, `Column` y `ListTile`); no se aceptara `Html` sin sanitizacion. Cada respuesta con fuentes renderiza un `ExpansionTile` "Fuentes" con `entityType`, titulo, excerpt y metadata; con lista nula/vacia no se renderiza el acordeon.

## Forms and Validation

Las pantallas usaran `Form` + `TextFormField`/selectores Material, con validadores puros reutilizables. Campos requeridos, email, password, cantidades positivas, precios no negativos, fechas y al menos un detalle se validan antes de llamar al repositorio; el backend sigue siendo la autoridad final.

POS y compras mantendran detalles en un `Notifier` y recalcularan subtotal, descuento, IVA y total en un caso de uso puro. La tasa de IVA no se inventa en Flutter: se configurara con el valor/regla que usa el frontend o backend confirmado en fixtures; si el backend recalcula, la UI muestra el preview y acepta la respuesta del servidor como fuente final. No se permite cantidad superior al stock conocido en ventas, pero se deja un manejo de carrera para el error 422 del backend.

Montos usan `NumberFormat.currency` y teclado decimal; el payload usa `double` JSON sin simbolo ni separadores. `showDatePicker`/`showDateRangePicker` trabajan en locale del dispositivo, se muestran como `dd/MM/yyyy HH:mm` y se serializan a ISO 8601 o `yyyy-MM-dd` segun endpoint. Los formularios se descartan con `autoDispose` al salir sin guardar.

## Theme and UX

Material 3 centralizado en `AppTheme`: `primary #1565C0`, `primaryContainer #0D47A1`, `secondary/accent #FF7043`, fondo claro `#F5F5F5`, superficie blanca y texto `#1A1A1A`, derivados de `frontend/src/styles.scss`. Se definira tambien dark theme con los valores equivalentes del frontend (`#64B5F6`, `#FF8A65`, `#1A1A1A`, `#2A2A2A`). No se hardcodearan colores en widgets.

Todas las listas usaran `ListView.builder`, `RefreshIndicator` cuando corresponda y claves estables. `AsyncValue` se proyectara mediante widgets compartidos `LoadingState`, `EmptyState`, `ErrorState(retry)` y `PermissionGate`. Acciones destructivas requieren dialogo de confirmacion y feedback de exito/error. Controles tendran semantic labels, contraste adecuado, touch target minimo de 48 dp y comportamiento adaptativo para teclado/orientacion.

## Testing Strategy by Slice

El comando base es `cd flutter && flutter test`; cada slice debe pasar tambien `flutter analyze`. Mocks de Dio se aislaran mediante `ApiClient` fake o `mocktail`; ningun unit/widget test dependera del backend real.

| Slice | Unit tests | Widget/integration tests |
|---|---|---|
| S1 | `ApiConfig`, converters, storage corrupto, login incompleto, auth notifier, permisos, mapper de Dio, 401 idempotente, redirects y route permissions | Login exitoso/fallido, shell filtrado, dashboard inicial, logout y deep link protegido |
| S2 | DTO/domain mappers y repositorios de productos/categorias/proveedores/clientes, filtros, invalidacion y permisos de acciones | listado vacio/carga/error, busqueda, formulario representativo, botones ocultos |
| S3 | calculo POS/compras, validaciones de detalles/stock, payloads exactos, anulacion, filtros y repositorios de gastos/movimientos | POS con dos lineas, formulario de compra, confirmacion de anulacion y errores 422 |
| S4 | precios/margen, matrices de roles, reportes, paginacion/filtros de logs, borrado por rango y guards administrativos | tablas y filtros, KPIs/error-retry, matriz, acciones ocultas por permiso |
| S5 | parser Markdown seguro con HTML/script/listas malformadas, sources, conversationId, fallback y rebuild guardado | chat completo, fuentes expandibles, error sin perder historial, semantic labels; smoke autenticado Android |

Golden tests son opcionales y se reservaran para tema/shell cuando el layout se estabilice. Al cierre de S5 se ejecutara `flutter test --coverage`, `flutter analyze` y `flutter build apk --release --dart-define=API_BASE_URL=...`.

## Android Configuration

Se generara Android con `minSdk` compatible con la version Flutter/plug-in elegida en S1 (objetivo inicial Android 24+; se confirmara contra `flutter create` y dependencias). `android/app/src/main/AndroidManifest.xml` incluira `android.permission.INTERNET`. El trafico HTTP de desarrollo a `10.0.2.2` se habilitara solo en debug mediante `network_security_config`/`usesCleartextTraffic`; release exigira HTTPS y no heredara esa excepcion.

El nombre visible sera `FerrePlus`. Icono y splash se generaran desde los assets de marca, evitando ediciones manuales inconsistentes. R8/Proguard se dejara activo en release y solo se agregaran keep rules si un reporte de minificacion demuestra que los generadores/reflection de una dependencia lo requieren. Se validara APK release en emulator y se documentara que el host del emulator no es `localhost` sino `10.0.2.2`.

## Architecture Decision Records

### ADR-1: Clean Architecture por capas

**Contexto:** La app debe cubrir muchos modulos sin acoplar pantallas al contrato Spring Boot.

**Decision:** usar `presentation`, `domain` y `data`, con interfaces de repositorio en domain y mapeo DTO en data; no crear casos de uso para CRUD trivial.

**Consecuencias:** limites claros, tests faciles y posibilidad de cambiar Dio; existe mas codigo de mapeo, mitigado por `freezed` y generacion.

### ADR-2: Riverpod como estado e inyeccion

**Contexto:** Auth, permisos, formularios y consultas asincronas deben compartir estado sin `setState` global.

**Decision:** Riverpod con `AsyncNotifier` para recursos remotos y `Notifier/StateNotifier` para comandos y formularios.

**Alternativas consideradas:** Bloc y Provider tradicional.

**Rationale:** Riverpod integra dependencias, invalidacion, autoDispose y estados asincronos con menos boilerplate y permite sobrescribir providers en tests.

### ADR-3: StatefulShellRoute sobre Navigator manual

**Contexto:** El shell debe conservar estado entre secciones y admitir deep links.

**Decision:** GoRouter + `MaterialApp.router` + `StatefulShellRoute.indexedStack`.

**Alternativas consideradas:** rutas nombradas y un `Navigator` por tab construido manualmente.

**Rationale:** rutas declarativas, redirect centralizado, ramas persistentes y URLs coherentes reducen estados de navegacion inconsistentes.

### ADR-4: Autoridades como Set, no rol

**Contexto:** El backend autoriza con `hasAuthority` y puede aplicar overrides por usuario.

**Decision:** guardar y evaluar `Set<String> permisos`; usar el rol solo para mostrarlo.

**Rationale:** refleja la autorizacion efectiva, evita privilegios inferidos y permite refresco mediante `/api/usuarios/me`.

### ADR-5: Dio con interceptor JWT

**Contexto:** Todas las llamadas autenticadas requieren Bearer, mapping de errores y logout global ante 401.

**Decision:** Dio con interceptores, timeouts y `FailureMapper`.

**Alternativas consideradas:** `package:http` directo.

**Rationale:** Dio ofrece interceptores, cancelacion y configuracion central apropiada para el alcance; `http` queda como referencia de permisos HTTP, no como cliente elegido.

### ADR-6: Sin refresh token; 401 fuerza logout

**Contexto:** El contrato actual entrega solo JWT y exige logout ante cualquier 401.

**Decision:** no reintentar ni fabricar refresh; limpiar sesion y redirigir a login.

**Rationale:** cumple el contrato actual y evita bucles o sesiones ambiguas. Un refresh futuro requiere contrato backend separado.

### ADR-7: flutter_secure_storage

**Contexto:** El token y la sesion son credenciales.

**Decision:** `flutter_secure_storage` con claves versionadas y limpieza completa al logout.

**Alternativa considerada:** `shared_preferences`.

**Rationale:** Keystore/Keychain protege secretos; preferencias simples no ofrecen una frontera de seguridad equivalente.

### ADR-8: freezed + json_serializable

**Contexto:** Hay muchos DTOs con nulos, enums y fechas heterogeneas.

**Decision:** modelos inmutables generados, converters explicitos y mapeo separado al dominio.

**Rationale:** reduce errores de copia, hace visibles cambios de contrato y evita `dynamic` repartido por la UI.

### ADR-9: DateTime tipado y converters ISO

**Contexto:** El backend mezcla `String` timestamp y `LocalDate`.

**Decision:** `DateTime` en dominio; converter timestamp ISO con offset y converter date-only para `yyyy-MM-dd`.

**Rationale:** la UI puede formatear por locale y las requests conservan el formato exigido sin transportar Strings crudos.

### ADR-10: Markdown seguro limitado

**Contexto:** Chat devuelve Markdown potencialmente no confiable y la especificacion prohibe HTML ejecutable.

**Decision:** `flutter_markdown` sin raw HTML, precedido por sanitizacion y allowlist de elementos; fallback a parser de widgets si la version no garantiza esa politica.

**Rationale:** conserva listas/negritas legibles y evita XSS/HTML arbitrario; no se pretende implementar Markdown completo.

### ADR-11: URL por dart-define

**Contexto:** emulator, dispositivo LAN y release usan hosts distintos.

**Decision:** `String.fromEnvironment('API_BASE_URL')`, default solo de desarrollo `10.0.2.2` y sin URL productiva hardcodeada.

**Rationale:** cambia el entorno sin editar codigo y reduce el riesgo de distribuir endpoints locales o secretos.

### ADR-12: Material 3 alineado al frontend

**Contexto:** La app debe ser reconocible como FerrePlus y funcionar en telefono.

**Decision:** tema centralizado Material 3 con azul `#1565C0` y acento naranja `#FF7043`, mas variantes dark del frontend.

**Rationale:** reutiliza la identidad existente y permite accesibilidad, responsive layout y consistencia sin colores dispersos.

### ADR-13: Slices encadenados S1-S5

**Contexto:** El alcance completo es demasiado grande para un cambio monolitico.

**Decision:** cada slice debe compilar, testearse y revisarse antes del siguiente.

**Rationale:** limita el riesgo, permite rollback por commit/PR y mantiene cambios auditables para el usuario.

## Data Flow and API Mapping

Los repositorios mapearan los endpoints existentes sin alterar sus rutas:

```text
Auth: /api/auth/login,/register; session: /api/usuarios/me
Catalogos: /api/productos,/categorias,/proveedores,/clientes,/gastos
Operacion: /api/ventas,/compras,/movimientos-stock
Admin: /api/usuarios,/roles,/modulos,/permisos,/precios,/logs
Analitica: /api/reportes/dashboard,/ventas,/inventario,/movimientos
Chat: /api/chat y /api/chat/index/rebuild
```

Ventas enviara `VentaDTO` con `detalles[{productoId,cantidad,precioUnitario}]`; compras enviara su equivalente con `fechaFactura`; stock usara `tipo=ENTRADA|SALIDA|AJUSTE`; precio usara `nuevoPrecio` o `margenPorcentaje` y `referencia`. Logs conservara pagina/tamano y filtros `fechaDesde`, `fechaHasta`, `usuarioId`, `entidad`, `accion`; el borrado usa `desde`/`hasta`. La implementacion debe validar fixtures contra los DTO Java antes de fijar campos no confirmados de catalogos.

## File Changes

| Archivo | Accion | Responsabilidad |
|---|---|---|
| `flutter/` | Crear | Proyecto Flutter Android+iOS, pubspec y plataformas |
| `flutter/lib/**` | Crear | Capas, features, providers, rutas, red, storage y tema definidos arriba |
| `flutter/test/**` | Crear | Unit/widget tests por slice |
| `flutter/integration_test/**` | Crear | Smoke autenticado Android |
| `flutter/AGENTS.md` | Crear | Convenciones locales y comandos |
| `flutter/analysis_options.yaml` | Crear | Lints strict y reglas de calidad |
| `flutter/.gitignore` | Crear | Artefactos Flutter/Android/iOS |
| `backend/**`, `frontend/**` | Sin cambios | Solo se consumen contratos y estilos existentes |

## Migration / Rollout

No se requiere migracion de base de datos, cambio de backend ni rollout funcional del frontend. El despliegue sera incremental por S1-S5. Cada APK de desarrollo recibe su base URL por `--dart-define`; release solo se construye con HTTPS. Rollback consiste en detener la cadena y revertir el ultimo slice aprobado, sin tocar datos del backend. Las sesiones locales pueden invalidarse eliminando el storage seguro.

## Open Questions and Validation Gates

- [ ] En S1 confirmar con fixtures reales los campos nullable y wrappers de paginacion de todos los endpoints, especialmente catalogos y logs.
- [ ] Confirmar la autoridad exacta de dashboard/chat en `rutas-por-permiso` y no asumirla desde el nombre del modulo.
- [ ] Confirmar tasa/calculo de IVA del frontend/backend antes de cerrar el caso de uso POS; Flutter no debe inventar una regla.
- [ ] Verificar version Flutter/Dart disponible, `minSdk` y compatibilidad Android de `flutter_secure_storage`, `flutter_markdown` y Riverpod.
- [ ] Si el backend no expone una señal de "sin usuarios", definir en S1 el endpoint/respuesta de registro inicial antes de mostrar esa opcion.

Las preguntas anteriores no bloquean la estructura arquitectonica, pero si bloquean fijar DTOs finales y algunos detalles de S1; deben cerrarse antes de implementar cada contrato afectado.
