# Proposal: Módulo Gestión de Precios de Venta

## Intent

Actualmente el sistema registra compras con `precioUnitario` por detalle y cada producto tiene campos `precioCompra` y `precioVenta`, pero no existe un mecanismo para:

1. **Actualizar automáticamente** el `precioCompra` del producto cuando se registra una compra (el campo queda en cero o desactualizado).
2. **Trazar el historial** de cambios de precio — no se sabe cuándo ni por qué cambió un precio.
3. **Gestionar precios de venta** de forma centralizada — no hay una vista dedicada que muestre márgenes y ganancias por producto.
4. **Calcular precios de venta basados en margen** — actualmente no hay una herramienta que permita al usuario fijar precio de venta a partir de un porcentaje de ganancia sobre el precio de compra.

Este cambio introduce un módulo completo de **Gestión de Precios de Venta** que resuelve estos cuatro problemas, agregando valor directo al negocio al permitir controlar márgenes y mantener un historial auditable de precios.

## Scope

### In Scope

1. Nueva entidad `HistoricoPrecioProducto` con su repositorio JPA.
2. Nuevos DTOs: `PrecioProductoDTO` (precios actuales + ganancia + margen), `HistoricoPrecioProductoDTO`, `ActualizarPrecioVentaDTO`.
3. Nuevo `PrecioService` con lógica de consulta de precios y actualización de precio de venta (con opción de cálculo por margen).
4. Nuevo `PrecioController` con los endpoints REST:
   - `GET /api/precios` — listar todos los productos con info de precio
   - `GET /api/precios/{id}` — obtener precio de un producto
   - `GET /api/precios/{id}/historial` — historial de cambios de precio
   - `PUT /api/precios/{id}/venta` — actualizar precio de venta (nuevo precio o margen %)
5. Modificación de `CompraService.create()` para actualizar `producto.precioCompra` y guardar `HistoricoPrecioProducto` con `tipoCambio = 'COMPRA'`.
6. Modificación de `CompraService.update()` para aplicar la misma lógica al re-aplicar stock (con los nuevos detalles).
7. Nuevo módulo Angular `GestionPreciosModule` (feature module, NO standalone):
   - Routing lazy-loaded en `/gestion-precios`
   - Componente de listado con tabla Material (Producto, Código, Precio Compra, Precio Venta, Ganancia $, Margen %, Última Actualización)
   - Componente de detalle con info actual + chart histórico (ng2-charts) + tabla de historial
   - Diálogo (Material Dialog) para establecer nuevo precio de venta, con opción de calcular por margen %
8. Nuevo `PrecioService` en Angular para consumir los endpoints.
9. Actualización del `SidebarComponent` para agregar item "Precios" al menú.
10. Actualización de `core/models.ts` con los nuevos tipos `PrecioProducto`, `HistoricoPrecioProducto`.
11. **Tests mínimos** — cobertura básica del backend para garantizar que la funcionalidad crítica no regrese:
    - Test unitario de `PrecioService.listarPrecios()` (mocking repositorios)
    - Test unitario de `PrecioService.actualizarPrecioVenta()` (con margen y con precio directo)
    - Test unitario de `PrecioService.registrarHistorico()`
    - Test de integración de `CompraService.create()` verificando que se actualiza `precioCompra` y se guarda historial
    - Test de integración de `CompraService.update()` con verificación de historial y reversión de stock

### Out of Scope

- **Edición manual de `precioCompra` fuera de compras** — NO existe una interfaz directa para modificar `precioCompra`. La única forma de cambiarlo es registrando o editando una compra desde el módulo de Compras. Al editar una compra, el `precioCompra` se actualiza automáticamente en `Producto` y queda registrado en `HistoricoPrecioProducto`. El `tipoCambio = 'AJUSTE'` queda definido en la entidad para futuros usos, pero no se implementa en este cambio.
- **Modificación de `anular()` en `CompraService`** — no se revertirá `precioCompra` ni se agregará historial al anular una compra, porque el stock se revierte pero el precio al que se compró sigue siendo válido como referencia histórica.
- **Seeders o migraciones de datos históricos** — no se migrarán precios existentes al historial; el historial empieza a registrar desde la implementación.
- **Sistema de roles y permisos por módulo** — se adelanta que a futuro se implementará un sistema de visibilidad por módulo donde los usuarios se creen con roles y permisos específicos por módulo. Eso es otro cambio aparte y NO está en el alcance de este módulo.
- **Notificaciones** — no se enviarán alertas cuando un precio cambie.
- **Múltiples precios de venta por producto** (ej. precio mayorista vs minorista) — cada producto tiene un solo `precioVenta`.
- **Tabla independiente de productos en el backend** — el listado de precios se construye consultando `Producto` directamente, no se crea una tabla separada.

## Approach

### Arquitectura General

Se extiende la arquitectura existente (controlador → servicio → repositorio → entidad) agregando una nueva entidad y modificando la existente `CompraService` con inyección del nuevo `PrecioService`.

### Backend

1. **Entidad `HistoricoPrecioProducto`** (`com.ferreplus.entity`):
   - Mapeada a tabla `historico_precios_producto`
   - Lombok (`@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder`)
   - FK a `Producto` (obligatorio), FK a `Usuario` (opcional)
   - Campos: `precioCompra`, `precioVenta`, `tipoCambio` (String: `COMPRA|ACTUALIZACION_VENTA|AJUSTE`), `referencia`, `fechaCambio` (LocalDateTime)

2. **Repositorio `HistoricoPrecioProductoRepository`** (`com.ferreplus.repository`):
   - `findByProductoIdOrderByFechaCambioDesc(Long productoId)`
   - `findByProductoIdOrderByFechaCambioAsc(Long productoId)` (para el chart cronológico)

3. **DTOs** (`com.ferreplus.dto`):
   - `PrecioProductoDTO`: `id`, `nombre`, `codigoBarras`, `precioCompra`, `precioVenta`, `ganancia`, `margenPorcentaje`, `fechaActualizacion`
   - `HistoricoPrecioProductoDTO`: `id`, `productoId`, `precioCompra`, `precioVenta`, `tipoCambio`, `referencia`, `fechaCambio`, `usuarioNombre`
   - `ActualizarPrecioVentaDTO`: `nuevoPrecio` (opcional si se usa margen), `margenPorcentaje` (opcional si se usa nuevoPrecio), `referencia`

4. **`PrecioService`** (`com.ferreplus.service`):
   - `listarPrecios()` → `List<PrecioProductoDTO>`: consulta todos los `Producto` activos, calcula `ganancia` y `margenPorcentaje`
   - `obtenerPrecio(Long id)` → `PrecioProductoDTO`: un producto específico
   - `obtenerHistorial(Long id)` → `List<HistoricoPrecioProductoDTO>`: historial ordenado descendente
   - `actualizarPrecioVenta(Long id, ActualizarPrecioVentaDTO dto, Long usuarioId)`: valida que se envíe `nuevoPrecio` o `margenPorcentaje` (no ambos ni ninguno). Si se envía margen, calcula: `precioVenta = precioCompra * (1 + margenPorcentaje/100)`. Actualiza `producto.precioVenta`, guarda `HistoricoPrecioProducto` con `tipoCambio = 'ACTUALIZACION_VENTA'`.
   - `registrarHistorico(Producto, BigDecimal precioCompra, BigDecimal precioVenta, String tipoCambio, String referencia, Usuario)`: método interno reutilizable.

5. **Modificaciones en `CompraService`**:
   - Inyectar `PrecioService` (via `@RequiredArgsConstructor`)
   - En `create()`: después de `productoService.actualizarStock(...)`, agregar:
     - `producto.setPrecioCompra(detalleDTO.getPrecioUnitario())`
     - `productoService.update(producto.getId(), ...)` o llamado específico para actualizar solo precioCompra
     - `precioService.registrarHistorico(producto, detalleDTO.getPrecioUnitario(), producto.getPrecioVenta(), "COMPRA", compra.getNumeroFactura(), usuario)`
   - En `update()`: misma lógica en el paso 5 (crear nuevos detalles), después de `actualizarStock(...)`
   - Se debe persistir `producto` después de modificar `precioCompra` (usar `ProductoRepository.save()` o `ProductoService.update()`)

6. **`PrecioController`** (`com.ferreplus.controller`):
   - `@RestController`, `@RequestMapping("/api/precios")`, `@CrossOrigin(origins = "http://localhost:4200")`, `@RequiredArgsConstructor`
   - Endpoints según tabla en sección Scope.

### Frontend

1. **Modelos** (`core/models.ts`):
   - `PrecioProducto`: `id`, `nombre`, `codigoBarras`, `precioCompra`, `precioVenta`, `ganancia`, `margenPorcentaje`, `fechaActualizacion`
   - `HistoricoPrecioProducto`: `id`, `productoId`, `precioCompra`, `precioVenta`, `tipoCambio`, `referencia`, `fechaCambio`, `usuarioNombre`
   - `ActualizarPrecioVentaRequest`: `nuevoPrecio?`, `margenPorcentaje?`, `referencia`

2. **`PrecioService`** (Angular, inyectable):
   - `list()` → `Observable<PrecioProducto[]>`
   - `getById(id)` → `Observable<PrecioProducto>`
   - `getHistorial(id)` → `Observable<HistoricoPrecioProducto[]>`
   - `actualizarPrecioVenta(id, dto)` → `Observable<PrecioProducto>`

3. **Módulo `GestionPreciosModule`**:
   - Estructura: `gestion-precios/gestion-precios.module.ts`, `gestion-precios/gestion-precios-routing.module.ts`, subdirectorios de componentes
   - Routing: `{ path: '', component: PreciosListComponent }`, `{ path: ':id', component: PrecioDetailComponent }`
   - Dependencias Angular Material: `MatTableModule`, `MatPaginatorModule`, `MatSortModule`, `MatFormFieldModule`, `MatInputModule`, `MatButtonModule`, `MatIconModule`, `MatCardModule`, `MatProgressSpinnerModule`, `MatDialogModule`, `MatTooltipModule`
   - Dependencias de ng2-charts: `NgChartsModule`

4. **Componente `PreciosListComponent`**:
   - Tabla Material con columnas: Producto, Código, Precio Compra, Precio Venta, Ganancia ($), Margen (%), Última Actualización
   - Búsqueda/filtro por nombre o código
   - Al hacer clic en una fila, navegar a `/gestion-precios/{id}`

5. **Componente `PrecioDetailComponent`**:
   - Sección superior: tarjeta con info actual (precioCompra, precioVenta, ganancia, margen)
   - Sección media: chart de línea (ng2-charts) mostrando evolución de precios en el tiempo (dos series: precioCompra y precioVenta)
   - Sección inferior: tabla Material con historial de cambios de precio
   - Botón "Actualizar Precio de Venta" que abre el diálogo

6. **Componente `ActualizarPrecioDialog`** (Material Dialog):
   - Input para nuevo precio de venta
   - Input para margen % (seleccionar uno u otro, con validación mutuamente excluyente)
   - Input para referencia/motivo
   - Al confirmar, llama al endpoint PUT y refresca la vista de detalle

7. **Sidebar**:
   - Agregar item `{ label: 'Precios', icon: 'attach_money', route: '/gestion-precios' }` en la sección de administración (después de Productos o cerca de Reportes)

8. **App Routing**:
   - Agregar ruta lazy-loaded: `{ path: 'gestion-precios', loadChildren: () => import('./gestion-precios/gestion-precios.module').then(m => m.GestionPreciosModule), canActivate: [AuthGuard] }`

### Testing

Se incluyen tests mínimos de backend para garantizar que la funcionalidad crítica funciona y no regresa:

1. **Prerrequisito**: Crear `src/test/` con la estructura base de Spring Boot Test.
2. **Test unitario `PrecioServiceTest`**:
   - `listarPrecios_shouldReturnAllActiveProductsWithCalculatedMargins()` — mock de `ProductoRepository`, verifica que `ganancia` y `margenPorcentaje` se calculan correctamente.
   - `actualizarPrecioVenta_withNewPrice_shouldUpdateAndSaveHistory()` — mock de `ProductoRepository` e `HistoricoPrecioProductoRepository`, verifica que se actualiza `precioVenta` y se guarda historial.
   - `actualizarPrecioVenta_withMargin_shouldCalculatePriceAndSaveHistory()` — verifica que el cálculo de precio desde margen % funciona.
   - `actualizarPrecioVenta_withBothPriceAndMargin_shouldThrowError()` — validación de exclusión mutua.
   - `registrarHistorico_shouldSaveRecord()` — verifica que se guarda correctamente un registro histórico.
3. **Test de integración `CompraServiceIntegrationTest`**:
   - `createCompra_shouldUpdatePrecioCompraAndSaveHistory()` — contexto Spring con BD en memoria (H2), crea compra y verifica que `producto.precioCompra` se actualizó y `historico_precios_producto` tiene el registro.
   - `updateCompra_shouldUpdatePrecioCompraForNewDetails()` — similar pero con update, verificando que los nuevos detalles actualizan precioCompra y el historial refleja los cambios.

El frontend queda sin tests por ahora (no tiene infraestructura de testing instalada).

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `backend/src/main/java/com/ferreplus/entity/HistoricoPrecioProducto.java` | **New** | Nueva entidad JPA para historial de precios |
| `backend/src/main/java/com/ferreplus/repository/HistoricoPrecioProductoRepository.java` | **New** | Nuevo repositorio para la entidad |
| `backend/src/main/java/com/ferreplus/dto/PrecioProductoDTO.java` | **New** | DTO con info de precio + ganancia + margen |
| `backend/src/main/java/com/ferreplus/dto/HistoricoPrecioProductoDTO.java` | **New** | DTO para historial de precios |
| `backend/src/main/java/com/ferreplus/dto/ActualizarPrecioVentaDTO.java` | **New** | DTO para request de actualización |
| `backend/src/main/java/com/ferreplus/service/PrecioService.java` | **New** | Servicio con lógica de negocio de precios |
| `backend/src/main/java/com/ferreplus/controller/PrecioController.java` | **New** | Controlador REST para endpoints de precios |
| `backend/src/main/java/com/ferreplus/service/CompraService.java` | **Modified** | Inyectar PrecioService, actualizar precioCompra y guardar historial en create/update |
| `backend/src/main/java/com/ferreplus/entity/Producto.java` | **Unchanged** | Ya tiene precioCompra y precioVenta — no se modifica estructuralmente |
| `frontend/src/app/core/models.ts` | **Modified** | Agregar interfaces PrecioProducto, HistoricoPrecioProducto, ActualizarPrecioVentaRequest |
| `frontend/src/app/gestion-precios/gestion-precios.module.ts` | **New** | Nuevo feature module |
| `frontend/src/app/gestion-precios/gestion-precios-routing.module.ts` | **New** | Routing del módulo |
| `frontend/src/app/gestion-precios/precios-list/precios-list.component.ts` | **New** | Componente de listado |
| `frontend/src/app/gestion-precios/precios-list/precios-list.component.html` | **New** | Template del listado |
| `frontend/src/app/gestion-precios/precios-list/precios-list.component.scss` | **New** | Estilos del listado |
| `frontend/src/app/gestion-precios/precio-detail/precio-detail.component.ts` | **New** | Componente de detalle con chart |
| `frontend/src/app/gestion-precios/precio-detail/precio-detail.component.html` | **New** | Template del detalle |
| `frontend/src/app/gestion-precios/precio-detail/precio-detail.component.scss` | **New** | Estilos del detalle |
| `frontend/src/app/gestion-precios/precio.service.ts` | **New** | Servicio HTTP para precios |
| `frontend/src/app/gestion-precios/actualizar-precio-dialog/actualizar-precio-dialog.component.ts` | **New** | Diálogo de actualización |
| `frontend/src/app/gestion-precios/actualizar-precio-dialog/actualizar-precio-dialog.component.html` | **New** | Template del diálogo |
| `frontend/src/app/gestion-precios/actualizar-precio-dialog/actualizar-precio-dialog.component.scss` | **New** | Estilos del diálogo |
| `frontend/src/app/shared/sidebar/sidebar.component.ts` | **Modified** | Agregar item "Precios" al menú |
| `frontend/src/app/app-routing.module.ts` | **Modified** | Agregar ruta lazy-loaded para gestion-precios |
| `frontend/package.json` | **Unchanged** | ng2-charts ya está instalido (confirmar) |
| `docker-compose.yml` | **Unchanged** | Sin cambios en infraestructura |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| **R1: regresión en CompraService.create/update** al modificar lógica existente. | **Med** | Asegurar que la actualización de `precioCompra` y guardado de historial ocurra DENTRO de la misma transacción (ya existe `@Transactional`). Agregar logger. Probar con casos: compra de 1 producto, compra de múltiples productos, actualización de compra. |
| **R2: error de cálculo de margen** si `precioCompra = 0` (producto sin compras previas). | **Med** | En `PrecioService.listarPrecios()` y en `obtenerPrecio()`, si `precioCompra` es 0, retornar margen como `null` o indicador "Sin datos". En el diálogo de actualización, si `precioCompra = 0`, deshabilitar la opción de calcular por margen. |
| **R3: chart con muchos datos históricos** afectando rendimiento. | **Low** | El historial por producto no será masivo. Si escala, se puede paginar el historial en el backend. |
| **R4: inconsistencia si CompraService.update() recibe detalles con productos diferentes a los originales.** | **Med** | La lógica de update ya revierte stock de los viejos detalles y aplica stock de los nuevos. La actualización de precioCompra debe hacerse SOLO para los productos en los nuevos detalles, no para los revertidos. Se debe actualizar precioCompra de cada producto en el nuevo detalle al precioUnitario correspondiente. |
| **R5: el `precioCompra` se sobrescribe con cada compra** incluso si la nueva compra tiene precio inferior. Esto es correcto para el negocio (último precio de compra), pero debe documentarse. | **Low** | Documentar en la interfaz que `precioCompra` siempre refleja el último precio de compra registrado. |

## Rollback Plan

### Por fases (parcial):
1. **Revertir backend**: Eliminar `HistoricoPrecioProducto.java`, `HistoricoPrecioProductoRepository.java`, `PrecioService.java`, `PrecioController.java`, y los 3 nuevos DTOs. Revertir cambios en `CompraService.java`.
2. **Revertir base de datos**: Ejecutar `DROP TABLE IF EXISTS historico_precios_producto;`
3. **Revertir frontend**: Eliminar directorio `gestion-precios/`, revertir `models.ts`, `sidebar.component.ts`, `app-routing.module.ts`.
4. **Full revert**: `git checkout HEAD~1` en cada repositorio (o `git restore` de archivos específicos).

Al ser un cambio sin afectación a infraestructura (Docker, etc.), la reversión es segura y sin downtime.

## Dependencies

| Dependencia | Propósito | Ya existe? |
|------------|-----------|------------|
| Spring Boot Starter Data JPA | Repositorios | ✅ Sí |
| Lombok | Entidades | ✅ Sí |
| Jakarta Validation | Validación de DTOs | ✅ Sí |
| ng2-charts + Chart.js | Gráfico histórico en frontend | ✅ Sí (confirmar en package.json) |
| Angular Material | Tablas, diálogos, inputs | ✅ Sí |
| Angular Router | Lazy-loading | ✅ Sí |

## Success Criteria

- [ ] Se crea la tabla `historico_precios_producto` con FK a `productos` y FK opcional a `usuarios`.
- [ ] Al crear una compra, `producto.precioCompra` se actualiza automáticamente con el `precioUnitario` del detalle.
- [ ] Al crear una compra, se guarda un registro en `historico_precios_producto` con `tipoCambio = 'COMPRA'` y el número de factura como referencia.
- [ ] Al actualizar una compra (update), los nuevos detalles actualizan `precioCompra` y guardan historial.
- [ ] `GET /api/precios` retorna todos los productos activos con `precioCompra`, `precioVenta`, `ganancia` (precioVenta - precioCompra) y `margenPorcentaje`.
- [ ] `GET /api/precios/{id}` retorna la información de precio de un producto específico.
- [ ] `GET /api/precios/{id}/historial` retorna el historial de cambios de precio ordenado por fecha descendente.
- [ ] `PUT /api/precios/{id}/venta` acepta `nuevoPrecio` o `margenPorcentaje` (mutuamente excluyentes) y actualiza `producto.precioVenta` + guarda historial con `tipoCambio = 'ACTUALIZACION_VENTA'`.
- [ ] La ruta `/gestion-precios` carga el módulo lazy-loaded correctamente.
- [ ] El listado muestra tabla con las columnas definidas y datos correctos.
- [ ] El detalle muestra info actual + chart de evolución de precios + tabla de historial.
- [ ] El diálogo de actualización permite setear precio de venta directo o por margen, con validación.
- [ ] El sidebar muestra el item "Precios" y navega correctamente.
- [ ] No hay regresiones en la creación/actualización de compras (stock, montos, etc.).
