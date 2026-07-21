# Design: Módulo Gestión de Precios de Venta

## Technical Approach

Se extiende la arquitectura existente (controlador → servicio → repositorio → entidad) agregando una nueva entidad `HistoricoPrecioProducto` para auditoría de cambios de precio, un nuevo `PrecioService` con la lógica de negocio de precios, y modificando `CompraService` para que actualice automáticamente el `precioCompra` del producto y registre el historial al crear/actualizar compras.

En el frontend se crea un nuevo feature module `GestionPreciosModule` (NO standalone, consistente con el patrón existente), con listado, detalle con gráfico ng2-charts, y diálogo de actualización de precio de venta.

Las especificaciones (spec.md) definen 13 requerimientos con 43 escenarios. Este diseño cubre todos ellos.

## Architecture Decisions

### Decision: Entidad `HistoricoPrecioProducto` separada de `Producto`

**Choice**: Nueva tabla `historico_precios_producto` con FK a `productos`.
**Alternatives considered**: Columnas JSON en `productos`, tabla de eventos genérica, columnas de auditoría en `Producto`.
**Rationale**: Una tabla separada permite:
- Trazar todos los cambios históricos sin contaminar la entidad `Producto`
- Consultas eficientes por producto y orden cronológico
- `tipoCambio` como discriminador (COMPRA, ACTUALIZACION_VENTA, AJUSTE para futuro)
- FK opcional a `usuarios` sin forzar relación
El diseño sigue el mismo patrón que `MovimientoStock` (entidad separada con FK a `Producto`).

### Decision: `PrecioService` como servicio separado (no métodos en `ProductoService`)

**Choice**: Nuevo `PrecioService` con dependencias de `ProductoRepository` e `HistoricoPrecioProductoRepository`.
**Alternatives considered**: Agregar métodos a `ProductoService`.
**Rationale**: 
- `ProductoService` ya maneja CRUD de producto + stock. Agregar lógica de precios le daría múltiples responsabilidades.
- `PrecioService` es consumido por `CompraService` (para registrar historial) y por el nuevo `PrecioController`. Separarlo evita dependencias circulares y mantiene SRP.
- El cálculo de ganancia/margen es lógica de negocio específica de precios, no de productos.

### Decision: Validación de exclusión mutua en `PrecioService` (no en DTO)

**Choice**: Validación `nuevoPrecio` ↔ `margenPorcentaje` en el servicio, lanzando `BadRequestException`.
**Alternatives considered**: `@AssertTrue` en DTO, validador personalizado Jakarta.
**Rationale**: 
- La validación cruzada entre dos campos no es soportada limpiamente por Jakarta Bean Validation (`@AssertTrue` requiere acceso al DTO completo y es frágil).
- El servicio ya tiene acceso a `Producto` para validar `precioCompra > 0` cuando se usa margen.
- Consistente con el patrón existente en `CompraService` donde las validaciones de negocio están en el servicio.
- El DTO se mantiene simple con tipos opcionales (`BigDecimal` puede ser null).

### Decision: Actualización de `precioCompra` directa en `CompraService` (no vía `ProductoService.update`)

**Choice**: En `CompraService.create()` y `update()`, se obtiene `Producto` vía `productoService.getById()`, se setea `producto.setPrecioCompra()` y se guarda con `productoRepository.save()`.
**Alternatives considered**: Pasar a `ProductoService.update()` todo el producto, crear método `actualizarPrecioCompra()` en `ProductoService`.
**Rationale**:
- `ProductoService.update()` espera un `Producto` completo y modifica TODOS los campos. Solo necesitamos actualizar `precioCompra`.
- Inyectar `ProductoRepository` directamente en `CompraService` es más directo y evita acoplar `ProductoService` con la lógica de compras.
- `CompraService` ya tiene `@Transactional` — todo ocurre en la misma transacción.
- La entidad `Producto` se persiste con `productoRepository.save()`; JPA detecta cambios y hace update.

### Decision: Extraer usuario del `SecurityContextHolder` en `PrecioController`

**Choice**: Obtener usuario autenticado vía `(Usuario) SecurityContextHolder.getContext().getAuthentication().getPrincipal()`.
**Alternatives considered**: Pasar `usuarioId` en el request body, extraer de token en controller.
**Rationale**:
- El `JwtAuthenticationFilter` ya carga el `Usuario` completo en el SecurityContext.
- Es el mecanismo estándar de Spring Security y evita exponer el `usuarioId` en el body del request.
- El `ActualizarPrecioVentaDTO` no necesita incluir datos de usuario.

### Decision: DTOs sin Lombok (manual getters/setters)

**Choice**: Los 3 DTOs nuevos (`PrecioProductoDTO`, `HistoricoPrecioProductoDTO`, `ActualizarPrecioVentaDTO`) usan getters/setters manuales, NO Lombok.
**Alternatives considered**: Lombok `@Data`, `@Getter @Setter`.
**Rationale**: Los 19 DTOs existentes en el proyecto (`CompraDTO`, `ProductoDTO`, etc.) NO usan Lombok. Para mantener consistencia en el código base, los nuevos DTOs siguen el mismo patrón. La entidad `HistoricoPrecioProducto` SÍ usa Lombok (como todas las entidades existentes).

### Decision: Agregar dependencia H2 para tests de integración

**Choice**: Agregar `com.h2database:h2` en scope `test` en `pom.xml`.
**Alternatives considered**: Usar PostgreSQL embebido o Testcontainers.
**Rationale**:
- No existe H2 ni Testcontainers en el pom.xml actual.
- H2 es la opción más simple y ligera para integration tests con `@AutoConfigureTestDatabase`.
- Testcontainers requiere Docker y es overkill para tests de integración de lógica de negocio (no probamos SQL nativo).
- H2 es la práctica estándar de Spring Boot para tests que no requieren dialectos específicos de PostgreSQL.

### Decision: PrecioService NO anotado con `@Transactional` completo (solo operaciones de escritura)

**Choice**: `PrecioService` con `@Transactional(readOnly = true)` a nivel de clase para las queries, y transacciones individuales para escritura. Pero como el servicio se inyectará en `CompraService` que ya tiene `@Transactional`, las operaciones de escritura heredarán la transacción del llamador.
**Alternatives considered**: `@Transactional` a nivel de clase.
**Rationale**:
- `PrecioService` es mayormente consultas. Las operaciones de escritura (`actualizarPrecioVenta`, `registrarHistorico`) ocurren dentro de transacciones iniciadas por el caller (`CompraService` tiene `@Transactional`).
- `actualizarPrecioVenta` modifica `Producto` y guarda `HistoricoPrecioProducto` — ambas operaciones deben estar en la misma transacción.
- Se usa `@Transactional` a nivel de método en `actualizarPrecioVenta` con `propagation = Propagation.REQUIRED` (default) para unirse a la transacción existente.

## Data Flow

### Flujo 1: Creación de compra con actualización de precioCompra

```
CompraController.create(dto)
  │
  └─→ CompraService.create(dto)  [@Transactional]
        │
        ├─→ [por cada detalle]
        │     ├─→ productoService.getById(productoId) → Producto
        │     ├─→ DetalleCompraRepository.save(detalle)
        │     ├─→ productoService.actualizarStock(...)
        │     ├─→ producto.setPrecioCompra(detalleDTO.getPrecioUnitario())
        │     ├─→ productoRepository.save(producto)
        │     └─→ precioService.registrarHistorico(
        │             producto, precioCompra, precioVenta,
        │             "COMPRA", numeroFactura, null  ← usuario null para compras
        │          )
        │
        └─→ return compra
```

### Flujo 2: Actualización de precio de venta

```
PrecioController.actualizarPrecioVenta(id, dto, usuarioId)
  │
  └─→ PrecioService.actualizarPrecioVenta(id, dto, usuarioId)  [@Transactional]
        │
        ├─→ Validar: exactamente uno de nuevoPrecio/margenPorcentaje
        ├─→ productoService.getById(id) → Producto
        ├─→ Si margenPorcentaje:
        │     ├─→ Validar precioCompra > 0
        │     └─→ precioVenta = precioCompra * (1 + margenPorcentaje / 100)
        │
        ├─→ Si nuevoPrecio:
        │     └─→ precioVenta = nuevoPrecio
        │
        ├─→ producto.setPrecioVenta(precioVenta)
        ├─→ productoRepository.save(producto)
        ├─→ usuarioService.getById(usuarioId) → Usuario
        ├─→ registrarHistorico(producto, precioCompra, precioVenta,
        │       "ACTUALIZACION_VENTA", referencia, usuario)
        └─→ mapToPrecioProductoDTO(producto)
```

### Flujo 3: Consulta de listado de precios

```
PrecioController.listarPrecios()
  │
  └─→ PrecioService.listarPrecios()
        │
        ├─→ productoRepository.findAll() → List<Producto>
        │     (se filtran activos en el servicio)
        │
        └─→ [por cada producto activo]
              ├─→ Si precioCompra > 0:
              │     ├─→ ganancia = precioVenta - precioCompra
              │     └─→ margen = ((precioVenta - precioCompra) / precioCompra) * 100
              └─→ Si precioCompra == 0:
                    ├─→ ganancia = null
                    └─→ margen = null
              └─→ mapper → PrecioProductoDTO
```

### Flujo 4: Frontend — detalle con gráfico

```
/gestion-precios/{id}
  │
  PrecioDetailComponent.ngOnInit()
    │
    ├─→ precioService.getById(id) → PrecioProducto (info actual)
    │
    ├─→ precioService.getHistorial(id) → HistoricoPrecioProducto[]
    │     │
    │     ├─→ historial ascendente (fechaAsc) → ChartData (series línea)
    │     │     ├─→ labels: fechas
    │     │     ├─→ dataset 1: precioCompra
    │     │     └─→ dataset 2: precioVenta
    │     │
    │     └─→ historial descendente () → MatTableDataSource
    │
    └─→ Render: card info + chart + table historial
```

## File Changes

### New Files

| File | Action | Description |
|------|--------|-------------|
| `backend/src/main/java/com/ferreplus/entity/HistoricoPrecioProducto.java` | Create | Nueva entidad JPA para historial de precios |
| `backend/src/main/java/com/ferreplus/repository/HistoricoPrecioProductoRepository.java` | Create | Repositorio para HistoricoPrecioProducto |
| `backend/src/main/java/com/ferreplus/dto/PrecioProductoDTO.java` | Create | DTO con precio actual + ganancia + margen |
| `backend/src/main/java/com/ferreplus/dto/HistoricoPrecioProductoDTO.java` | Create | DTO para historial de precios |
| `backend/src/main/java/com/ferreplus/dto/ActualizarPrecioVentaDTO.java` | Create | DTO para request de actualización de precio |
| `backend/src/main/java/com/ferreplus/service/PrecioService.java` | Create | Servicio con lógica de negocio de precios |
| `backend/src/main/java/com/ferreplus/controller/PrecioController.java` | Create | Controlador REST para endpoints de precios |
| `backend/src/test/java/com/ferreplus/service/PrecioServiceTest.java` | Create | Test unitario de PrecioService con Mockito |
| `backend/src/test/java/com/ferreplus/service/CompraServiceIntegrationTest.java` | Create | Test de integración de CompraService con H2 |
| `backend/src/test/resources/application-test.yml` | Create | Config para tests con H2 |
| `frontend/src/app/gestion-precios/gestion-precios.module.ts` | Create | Feature module NO standalone |
| `frontend/src/app/gestion-precios/gestion-precios-routing.module.ts` | Create | Routing del módulo con lazy loading |
| `frontend/src/app/gestion-precios/precio.service.ts` | Create | Servicio HTTP para endpoints de precios |
| `frontend/src/app/gestion-precios/precios-list/precios-list.component.ts` | Create | Componente de listado con tabla Material |
| `frontend/src/app/gestion-precios/precios-list/precios-list.component.html` | Create | Template del listado |
| `frontend/src/app/gestion-precios/precios-list/precios-list.component.scss` | Create | Estilos del listado |
| `frontend/src/app/gestion-precios/precio-detail/precio-detail.component.ts` | Create | Componente de detalle con chart ng2-charts |
| `frontend/src/app/gestion-precios/precio-detail/precio-detail.component.html` | Create | Template del detalle |
| `frontend/src/app/gestion-precios/precio-detail/precio-detail.component.scss` | Create | Estilos del detalle |
| `frontend/src/app/gestion-precios/actualizar-precio-dialog/actualizar-precio-dialog.component.ts` | Create | Diálogo Material para actualizar precio |
| `frontend/src/app/gestion-precios/actualizar-precio-dialog/actualizar-precio-dialog.component.html` | Create | Template del diálogo |
| `frontend/src/app/gestion-precios/actualizar-precio-dialog/actualizar-precio-dialog.component.scss` | Create | Estilos del diálogo |

### Modified Files

| File | Action | Description |
|------|--------|-------------|
| `backend/src/main/java/com/ferreplus/service/CompraService.java` | Modify | Inyectar PrecioService y ProductoRepository, actualizar precioCompra + registrar historial en create() y update() |
| `backend/pom.xml` | Modify | Agregar dependencia `com.h2database:h2` en scope test |
| `frontend/src/app/core/models.ts` | Modify | Agregar interfaces `PrecioProducto`, `HistoricoPrecioProducto`, `ActualizarPrecioVentaRequest` |
| `frontend/src/app/shared/sidebar/sidebar.component.ts` | Modify | Agregar item "Precios" con icon `attach_money` y ruta `/gestion-precios` |
| `frontend/src/app/app-routing.module.ts` | Modify | Agregar ruta lazy-loaded para `gestion-precios` con AuthGuard |

## Interfaces / Contracts

### Backend: Entidad JPA

```java
// Entity — usa Lombok como las entidades existentes
@Entity
@Table(name = "historico_precios_producto")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class HistoricoPrecioProducto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "producto_id", nullable = false)
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private Producto producto;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal precioCompra;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal precioVenta;

    @Column(nullable = false, length = 30)
    private String tipoCambio;  // COMPRA | ACTUALIZACION_VENTA | AJUSTE

    @Column(length = 200)
    private String referencia;

    @Column(nullable = false, updatable = false)
    private LocalDateTime fechaCambio;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id")
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private Usuario usuario;

    @PrePersist
    protected void onCreate() {
        fechaCambio = LocalDateTime.now();
    }
}
```

### Backend: Repositorio

```java
@Repository
public interface HistoricoPrecioProductoRepository extends JpaRepository<HistoricoPrecioProducto, Long> {
    List<HistoricoPrecioProducto> findByProductoIdOrderByFechaCambioDesc(Long productoId);
    List<HistoricoPrecioProducto> findByProductoIdOrderByFechaCambioAsc(Long productoId);
}
```

### Backend: DTOs (sin Lombok, consistentes con DTOs existentes)

```java
// PrecioProductoDTO — respuesta GET /api/precios y /api/precios/{id}
public class PrecioProductoDTO {
    private Long id;
    private String nombre;
    private String codigoBarras;
    private BigDecimal precioCompra;
    private BigDecimal precioVenta;
    private BigDecimal ganancia;         // null cuando precioCompra = 0
    private Double margenPorcentaje;     // null cuando precioCompra = 0
    private LocalDateTime fechaActualizacion;
    // + getters/setters manuales
}

// HistoricoPrecioProductoDTO — respuesta GET /api/precios/{id}/historial
public class HistoricoPrecioProductoDTO {
    private Long id;
    private Long productoId;
    private BigDecimal precioCompra;
    private BigDecimal precioVenta;
    private String tipoCambio;
    private String referencia;
    private LocalDateTime fechaCambio;
    private String usuarioNombre;        // null si usuario == null
    // + getters/setters manuales
}

// ActualizarPrecioVentaDTO — request body PUT /api/precios/{id}/venta
public class ActualizarPrecioVentaDTO {
    private BigDecimal nuevoPrecio;       // opcional, mutuamente excluyente con margenPorcentaje
    private Double margenPorcentaje;      // opcional, mutuamente excluyente con nuevoPrecio
    private String referencia;            // opcional
    // + getters/setters manuales
}
```

### Backend: API REST Contract

| Método | Endpoint | Request | Response | Errores |
|--------|----------|---------|----------|---------|
| GET | `/api/precios` | — | `200`: `PrecioProductoDTO[]` | — |
| GET | `/api/precios/{id}` | — | `200`: `PrecioProductoDTO` | `404`: producto no encontrado/inactivo |
| GET | `/api/precios/{id}/historial` | — | `200`: `HistoricoPrecioProductoDTO[]` | `404`: producto no encontrado |
| PUT | `/api/precios/{id}/venta` | `ActualizarPrecioVentaDTO` | `200`: `PrecioProductoDTO` actualizado | `400`: validación (exclusión mutua, precioCompra=0 con margen); `404`: producto no encontrado |

### Backend: PrecioService API

```java
public interface PrecioService {
    List<PrecioProductoDTO> listarPrecios();
    PrecioProductoDTO obtenerPrecio(Long id);
    List<HistoricoPrecioProductoDTO> obtenerHistorial(Long id);
    PrecioProductoDTO actualizarPrecioVenta(Long id, ActualizarPrecioVentaDTO dto, Long usuarioId);
    void registrarHistorico(Producto producto, BigDecimal precioCompra, BigDecimal precioVenta,
                            String tipoCambio, String referencia, Usuario usuario);
}
```

### Frontend: Interfaces (en `core/models.ts`)

```typescript
export interface PrecioProducto {
  id: number;
  nombre: string;
  codigoBarras: string;
  precioCompra: number;
  precioVenta: number;
  ganancia: number | null;
  margenPorcentaje: number | null;
  fechaActualizacion: string;
}

export interface HistoricoPrecioProducto {
  id: number;
  productoId: number;
  precioCompra: number;
  precioVenta: number;
  tipoCambio: string;
  referencia: string | null;
  fechaCambio: string;
  usuarioNombre: string | null;
}

export interface ActualizarPrecioVentaRequest {
  nuevoPrecio?: number;
  margenPorcentaje?: number;
  referencia?: string;
}
```

### Frontend: PrecioService API

```typescript
@Injectable({ providedIn: 'root' })
export class PrecioService {
  private apiUrl = `${environment.apiUrl}/precios`;

  list(): Observable<PrecioProducto[]>
  getById(id: number): Observable<PrecioProducto>
  getHistorial(id: number): Observable<HistoricoPrecioProducto[]>
  actualizarPrecioVenta(id: number, dto: ActualizarPrecioVentaRequest): Observable<PrecioProducto>
}
```

### Frontend: Routing Contract

```typescript
// AppRoutingModule — lazy-loaded route
{
  path: 'gestion-precios',
  loadChildren: () => import('./gestion-precios/gestion-precios.module').then(m => m.GestionPreciosModule),
  canActivate: [AuthGuard]
}

// GestionPreciosRoutingModule — child routes
const routes: Routes = [
  { path: '', component: PreciosListComponent },
  { path: ':id', component: PrecioDetailComponent }
];
```

## Detailed Component Design

### Backend: PrecioService.listarPrecios()

```
1. productoRepository.findAll() → List<Producto>
2. Filtrar productos activos (p.activo == true)
3. Para cada producto activo:
   a. Si precioCompra > 0:
      - ganancia = precioVenta.subtract(precioCompra)
      - margen = ganancia.divide(precioCompra, 4, RoundingMode.HALF_UP)
                 .multiply(new BigDecimal("100"))
                 .doubleValue()
   b. Si precioCompra <= 0:
      - ganancia = null
      - margen = null
   c. Construir PrecioProductoDTO
4. Retornar List<PrecioProductoDTO>
```

### Backend: PrecioService.actualizarPrecioVenta()

```
1. Validar exclusión mutua:
   - Si (nuevoPrecio != null && margenPorcentaje != null) → throw BadRequestException
   - Si (nuevoPrecio == null && margenPorcentaje == null) → throw BadRequestException
2. Producto producto = productoService.getById(id) → ResourceNotFoundException si no existe o inactivo
3. Si margenPorcentaje != null:
   - Si producto.precioCompra <= 0 → throw BadRequestException("No se puede calcular margen sin precio de compra")
   - precioVenta = producto.getPrecioCompra()
                   .multiply(BigDecimal.ONE.add(
                       BigDecimal.valueOf(margenPorcentaje).divide(new BigDecimal("100"))))
   - Redondear a 2 decimales HALF_UP
4. Si nuevoPrecio != null:
   - precioVenta = nuevoPrecio
5. producto.setPrecioVenta(precioVenta)
6. productoRepository.save(producto)
7. Usuario usuario = usuarioService.getById(usuarioId)
8. registrarHistorico(producto, producto.precioCompra, producto.precioVenta,
                      "ACTUALIZACION_VENTA", dto.getReferencia(), usuario)
9. Retornar mapToDTO(producto)
```

### Backend: Modificaciones en CompraService

```java
// Nuevas inyecciones
private final PrecioService precioService;
private final ProductoRepository productoRepository;

// En create(), después de actualizarStock (línea 86):
for (DetalleCompraDTO detalleDTO : dto.getDetalles()) {
    // ... código existente hasta línea 86 ...
    productoService.actualizarStock(producto.getId(), detalleDTO.getCantidad(), "ENTRADA");

    // --- NUEVO: Actualizar precioCompra y guardar historial ---
    producto.setPrecioCompra(detalleDTO.getPrecioUnitario());
    productoRepository.save(producto);
    precioService.registrarHistorico(
        producto,
        detalleDTO.getPrecioUnitario(),
        producto.getPrecioVenta(),
        "COMPRA",
        compra.getNumeroFactura(),
        null  // usuario null — cambios automáticos por compra no tienen usuario directo
    );
}

// En update(), mismo patrón dentro del loop de nuevos detalles (paso 5):
for (DetalleCompraDTO detalleDTO : dto.getDetalles()) {
    // ... código existente hasta línea 160 ...
    productoService.actualizarStock(producto.getId(), detalleDTO.getCantidad(), "ENTRADA");

    // --- NUEVO: Misma lógica que en create() ---
    producto.setPrecioCompra(detalleDTO.getPrecioUnitario());
    productoRepository.save(producto);
    precioService.registrarHistorico(
        producto,
        detalleDTO.getPrecioUnitario(),
        producto.getPrecioVenta(),
        "COMPRA",
        compra.getNumeroFactura(),
        null
    );
}
```

### Frontend: PreciosListComponent

- **Data Source**: `MatTableDataSource<PrecioProducto>` con `MatSort` y `MatPaginator`
- **Columnas**: `imagen`, `nombre`, `codigoBarras`, `precioCompra`, `precioVenta`, `ganancia`, `margenPorcentaje`, `fechaActualizacion`
- **Filtro**: input con `(keyup)="applyFilter($event)"` que filtra por nombre o código
- **Navegación**: `(click)="irADetalle(row)"` → `router.navigate(['/gestion-precios', row.id])`
- **Pipe para moneda**: `| currency:'GTQ':'symbol-narrow':'1.2-2'`
- **Pipe para fecha**: `| date:'short'`
- **Display condicional**: si `ganancia === null` mostrar `"—"`, si `margenPorcentaje === null` mostrar `"Sin datos"`

### Frontend: PrecioDetailComponent

- **ngOnInit**: Carga `getById(id)` y `getHistorial(id)` en paralelo con `forkJoin`
- **Card info**: MatCard con 4 campos en grid: precioCompra, precioVenta, ganancia, margen
- **Chart**: ng2-charts `canvas baseChart` con tipo `'line'`
  - Labels: fechas del historial ascendente
  - Dataset 1: `{ data: precioCompra[], label: 'Precio Compra', borderColor: 'blue', fill: false }`
  - Dataset 2: `{ data: precioVenta[], label: 'Precio Venta', borderColor: 'green', fill: false }`
  - Si no hay historial: mostrar `[Chart.emptydata]` o texto "Sin datos históricos"
- **Tabla historial**: MatTable con datos descendentes, columnas: tipoCambio, precioCompra, precioVenta, referencia, fechaCambio, usuarioNombre
- **Botón**: `ActualizarPrecioDialog.open(dialogConfig)` → suscribirse a `afterClosed()` para refrescar

### Frontend: ActualizarPrecioDialog

- **Data input**: recibe `productoId` y `precioCompraActual`
- **Form controls**: `nuevoPrecio`, `margenPorcentaje`, `referencia`
- **Validación mutuamente excluyente**: 
  - `valueChanges` en `nuevoPrecio`: si tiene valor, deshabilitar `margenPorcentaje` y viceversa
  - Si `precioCompraActual === 0`: deshabilitar `margenPorcentaje` con tooltip
- **Submit**: validar que exactamente un campo tenga valor, construir `ActualizarPrecioVentaRequest`, llamar a `precioService.actualizarPrecioVenta()`
- **SnackBar**: mostrar éxito/error
- **Retorno**: cerrar con `true` para que el detail refresque

## Testing Strategy

### Prerrequisito: Infraestructura de tests

Se debe crear la estructura `backend/src/test/java/com/ferreplus/` (no existe actualmente) y agregar H2 al `pom.xml`:

```xml
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>test</scope>
</dependency>
```

Crear `backend/src/test/resources/application-test.yml`:
```yaml
spring:
  datasource:
    url: jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1
    driver-class-name: org.h2.Driver
    username: sa
    password:
  jpa:
    hibernate:
      ddl-auto: create-drop
    database-platform: org.hibernate.dialect.H2Dialect
```

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit (PrecioService) | `listarPrecios()` — cálculo de ganancia/margen, null safety | Mock `ProductoRepository`, verificar DTOs calculados |
| Unit (PrecioService) | `actualizarPrecioVenta()` con nuevoPrecio | Mock repos, verificar `precioVenta` set y historial guardado |
| Unit (PrecioService) | `actualizarPrecioVenta()` con margenPorcentaje | Mock repos, verificar cálculo `100 * 1.5 = 150` |
| Unit (PrecioService) | `actualizarPrecioVenta()` con ambos campos | Verificar `BadRequestException` |
| Unit (PrecioService) | `actualizarPrecioVenta()` sin campos | Verificar `BadRequestException` |
| Unit (PrecioService) | `registrarHistorico()` | Verificar `HistoricoPrecioProductoRepository.save()` llamado |
| Unit (PrecioService) | `listarPrecios()` con precioCompra = 0 | Verificar ganancia/margen null |
| Integration (CompraService) | `create()` actualiza precioCompra y guarda historial | `@SpringBootTest` + H2, crear compra, verificar producto e historial |
| Integration (CompraService) | `update()` con cambio de producto | Verificar que NO revierte precioCompra del producto viejo, SÍ actualiza del nuevo |

### Unit Tests: Configuration

```java
@ExtendWith(MockitoExtension.class)
class PrecioServiceTest {
    @Mock private ProductoRepository productoRepository;
    @Mock private HistoricoPrecioProductoRepository historicoRepository;
    @Mock private UsuarioService usuarioService;
    @InjectMocks private PrecioService precioService;
    // ...
}
```

### Integration Tests: Configuration

```java
@SpringBootTest
@AutoConfigureTestDatabase(replace = Replace.ANY)
@ActiveProfiles("test")
class CompraServiceIntegrationTest {
    @Autowired private CompraService compraService;
    @Autowired private ProductoRepository productoRepository;
    @Autowired private HistoricoPrecioProductoRepository historicoRepository;
    // ...
}
```

## Migration / Rollout

No migration required. La tabla `historico_precios_producto` se crea automáticamente por Hibernate (`ddl-auto: update`). El historial comienza vacío y se llena a partir de la implementación.

**Orden de despliegue recomendado**:
1. Backend: entidad → repositorio → DTOs → PrecioService → PrecioController → modificar CompraService
2. Agregar H2 a pom.xml + crear estructura de tests
3. Tests unitarios + integración
4. Frontend: modelos → servicio → módulo + routing → list component → detail component → dialog
5. Sidebar + App routing

## Open Questions

- None. Todas las decisiones están cubiertas por las especificaciones y el análisis del código existente.

## Technical Learnings (durante implementación)

### Angular: métodos del template deben ser públicos
**Error**: `loadData()` declarado como `private` no es accesible desde el template HTML (TS2341).
**Fix**: Usar `loadData(): void` (sin private) para métodos invocados desde `(click)`, `*ngIf`, etc.
**Lección**: Angular compila los templates y verifica accesibilidad. Todo binding del template solo puede acceder a miembros públicos del componente.

### Angular Material: imports faltantes
**Error**: `mat-radio-group` y `mat-radio-button` no reconocidos (NG8001).
**Fix**: Agregar `MatRadioModule` al `imports` del módulo.
**Lección**: Cada componente de Angular Material requiere su módulo propio importado explícitamente. Verificar la documentación de cada componente usado en el template.

### Angular Material: control de radio buttons
**Error**: `[checked]` no es una propiedad válida de `mat-radio-button` (NG8002).
**Fix**: Usar `formControlName="tipoOpcion"` en el `<mat-radio-group>` y dejar que el grupo maneje la selección. Los valores `value="precio"` y `value="margen"` en los botones definen las opciones.
**Lección**: Angular Material Radio Button se controla a través del `mat-radio-group` con `formControlName`, no bindeando propiedades individuales en cada botón. Es un patrón diferente a HTML nativo.

### Proceso: verificar compilación después de escribir código
**Error recurrente**: Múltiples errores de compilación que podrían haberse detectado antes.
**Lección**: Según la skill Angular Developer, después de generar código hay que ejecutar `ng build` para verificar que no haya errores de compilación. Este paso es crítico y no debe omitirse.

## Technical Learnings (skill-resolver integration)

### NG0100: ExpressionChangedAfterItHasBeenCheckedError en DashboardComponent

**Problema**: En `dashboard.component.ts`, el método `loadDashboard()` llamaba a `this.detectChanges()` y luego a `this.loadChartData()`. `loadChartData()` setea `this.loadingChart = true` sincrónicamente, lo que cambiaba el estado entre el primer y segundo chequeo de Angular en modo dev.

**Solución**: Mover `this.loadChartData()` ANTES de `this.detectChanges()` para que ambos cambios (`loading = false` y `loadingChart = true`) ocurran en el mismo ciclo de detección y Angular los vea estables.

**Lección**: Cuando se usa `ChangeDetectionStrategy.Default` (o `Eager`, que es equivalente) y se llama a `detectChanges()` manualmente, asegurarse de que TODOS los cambios de estado sincrónicos ocurran antes de la llamada. Si un método llamado después de `detectChanges()` modifica el estado, Angular lo detecta como un cambio ilegal en modo dev.

**Referencia**: https://v22.angular.dev/errors/NG0100

### Sidebar no muestra nuevo módulo después de agregar archivos

**Problema**: Al crear nuevos archivos de un módulo Angular mientras `ng serve` ya está corriendo, el compilador en watch mode puede no detectar los nuevos archivos si estos crean una nueva estructura de directorios que no existía al inicio.

**Solución**: Reiniciar `ng serve` (Ctrl+C y volver a ejecutar). Esto fuerza una recompilación completa que incluye los nuevos archivos y módulos.

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| **R1**: No existe `src/test/` — se debe crear desde cero | Medium | La estructura es estándar de Maven; crear `src/test/java/com/ferreplus/service/` + `src/test/resources/` |
| **R2**: H2 no está en pom.xml | Low | Agregar dependencia; H2 es compatible con JPA y `@AutoConfigureTestDatabase` |
| **R3**: `CompraService.create()` y `update()` son métodos existentes con lógica compleja — riesgo de regresión | Medium | Los tests de integración existentes + los nuevos tests cubren los flujos críticos. Mantener `@Transactional` existente. La modificación agrega líneas DESPUÉS de `actualizarStock()`, no modifica lógica existente |
| **R4**: `SecurityContextHolder.getPrincipal()` puede no ser `Usuario` si el test no configura seguridad | Low | En tests de integración, el contexto de seguridad no se configura automáticamente. `PrecioController` se probará vía `MockMvc` con usuario mock si es necesario, pero los tests de servicio no dependen del SecurityContext |
