# Tasks: Módulo Gestión de Precios de Venta

> **Change**: `modulo-gestion-precios-venta`
> **Total tasks**: 19
> **Phases**: 4 (Foundation → Backend Core → Frontend → Testing)

---

## Phase 1: Backend — Foundation

### T1: Add H2 dependency and create test infrastructure

- **Description**: Add `com.h2database:h2` dependency in `<scope>test</scope>` to `backend/pom.xml`. Create directory structure `backend/src/test/java/com/ferreplus/`. Create `backend/src/test/resources/application-test.properties` with H2 in-memory datasource config (db: `jdbc:h2:mem:testdb`, ddl-auto: `create-drop`, dialect: `H2Dialect`). Create basic `FerreplusApplicationTests.java` for context load verification.
- **Dependencies**: None
- **Status**: completed
- **Effort**: M
- **Files affected**:
  - `backend/pom.xml` (modify — add H2 dependency)
  - `backend/src/test/resources/application-test.properties` (create)
  - `backend/src/test/java/com/ferreplus/FerreplusApplicationTests.java` (create)

### T2: Create HistoricoPrecioProducto entity

- **Description**: Create JPA entity `com.ferreplus.entity.HistoricoPrecioProducto` mapped to table `historico_precios_producto`. Use Lombok (`@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder`). Fields: `id` (Long, auto), `producto` (ManyToOne to Producto, not nullable, LAZY), `usuario` (ManyToOne to Usuario, nullable, LAZY), `precioCompra` (BigDecimal precision 12/2), `precioVenta` (BigDecimal precision 12/2), `tipoCambio` (String length 30, not null), `referencia` (String length 200, nullable), `fechaCambio` (LocalDateTime, not null, set via `@PrePersist`). Add `@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})` on both entity relationships.
- **Dependencies**: None
- **Status**: completed
- **Effort**: M
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/entity/HistoricoPrecioProducto.java` (create)

### T3: Create HistoricoPrecioProductoRepository

- **Description**: Create repository `com.ferreplus.repository.HistoricoPrecioProductoRepository` extending `JpaRepository<HistoricoPrecioProducto, Long>`. Add two query methods: `findByProductoIdOrderByFechaCambioDesc(Long productoId)` (for historial table — descending) and `findByProductoIdOrderByFechaCambioAsc(Long productoId)` (for chart — ascending).
- **Dependencies**: T2
- **Status**: completed
- **Effort**: S
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/repository/HistoricoPrecioProductoRepository.java` (create)

### T4: Create PrecioProductoDTO (with ganancia + margen calculations)

- **Description**: Create DTO `com.ferreplus.dto.PrecioProductoDTO`. NO Lombok — manual getters/setters (consistent with existing DTOs). Fields: `id` (Long), `nombre` (String), `codigoBarras` (String), `precioCompra` (BigDecimal), `precioVenta` (BigDecimal), `ganancia` (BigDecimal — nullable), `margenPorcentaje` (Double — nullable), `fechaActualizacion` (String). This DTO is the response type for GET endpoints and includes calculated fields.
- **Dependencies**: None
- **Status**: completed
- **Effort**: M
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/dto/PrecioProductoDTO.java` (create)

### T5: Create HistoricoPrecioProductoDTO

- **Description**: Create DTO `com.ferreplus.dto.HistoricoPrecioProductoDTO`. NO Lombok — manual getters/setters. Fields: `id` (Long), `productoId` (Long), `precioCompra` (BigDecimal), `precioVenta` (BigDecimal), `tipoCambio` (String), `referencia` (String — nullable), `fechaCambio` (String), `usuarioNombre` (String — nullable, extracted from Usuario entity relationship).
- **Dependencies**: None
- **Status**: completed
- **Effort**: S
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/dto/HistoricoPrecioProductoDTO.java` (create)

### T6: Create ActualizarPrecioVentaDTO

- **Description**: Create DTO `com.ferreplus.dto.ActualizarPrecioVentaDTO`. NO Lombok — manual getters/setters. Fields: `nuevoPrecio` (BigDecimal — nullable, mutually exclusive with margenPorcentaje), `margenPorcentaje` (Double — nullable, mutually exclusive with nuevoPrecio), `referencia` (String — nullable). This is the request body for PUT endpoint; validation of mutual exclusivity is done in PrecioService, not in the DTO.
- **Dependencies**: None
- **Status**: completed
- **Effort**: S
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/dto/ActualizarPrecioVentaDTO.java` (create)

---

## Phase 2: Backend — Core Implementation

### T7: Create PrecioService

- **Description**: Create `com.ferreplus.service.PrecioService`. Annotate with `@Service`, use `@RequiredArgsConstructor`. Inject `ProductoRepository`, `HistoricoPrecioProductoRepository` (from T3), `ProductoService`, `UsuarioService`. Implement methods:
  1. `listarPrecios()` → `List<PrecioProductoDTO>`: fetch all productos, filter `activo == true`, for each calculate `ganancia = precioVenta - precioCompra` and `margenPorcentaje = (ganancia / precioCompra) * 100` (both null if `precioCompra <= 0`, guarding against `ArithmeticException`).
  2. `obtenerPrecio(Long id)` → `PrecioProductoDTO`: fetch single product, validate exists + active (throw `ResourceNotFoundException` if not).
  3. `obtenerHistorial(Long id)` → `List<HistoricoPrecioProductoDTO>`: fetch historial descending, map from entity to DTO extracting `usuarioNombre` from `usuario.getNombre()` (null-safe).
  4. `actualizarPrecioVenta(Long id, ActualizarPrecioVentaDTO dto, Long usuarioId)` → `PrecioProductoDTO`: validate mutual exclusivity (throw `BadRequestException` if both or neither), if `margenPorcentaje` validate `precioCompra > 0` (throw `BadRequestException` if zero), calculate `precioVenta = precioCompra * (1 + margen/100)`, set on product, save, look up Usuario, call `registrarHistorico()`, return mapped DTO.
  5. `registrarHistorico(Producto, BigDecimal precioCompra, BigDecimal precioVenta, String tipoCambio, String referencia, Usuario)` → void: build `HistoricoPrecioProducto` entity with `@Builder`, save via repository.
  - Annotate class with `@Transactional(readOnly = true)`, override on `actualizarPrecioVenta()` with `@Transactional`.
- **Dependencies**: T2, T3, T4, T5, T6
- **Status**: pending
- **Effort**: L
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/service/PrecioService.java` (create)

### T8: Create PrecioController

- **Description**: Create `com.ferreplus.controller.PrecioController`. Annotate with `@RestController`, `@RequestMapping("/api/precios")`, `@CrossOrigin(origins = "http://localhost:4200")`, `@RequiredArgsConstructor`. Inject `PrecioService`. Implement endpoints:
  1. `GET /api/precios` → calls `precioService.listarPrecios()`, returns `200` with body.
  2. `GET /api/precios/{id}` → calls `precioService.obtenerPrecio(id)`, returns `200` or `404`.
  3. `GET /api/precios/{id}/historial` → calls `precioService.obtenerHistorial(id)`, returns `200` with body (can be empty list, NOT 404).
  4. `PUT /api/precios/{id}/venta` with `@RequestBody @Valid ActualizarPrecioVentaDTO` → extract authenticated user from `SecurityContextHolder.getContext().getAuthentication().getPrincipal()` cast to `Usuario`, call `precioService.actualizarPrecioVenta(id, dto, usuario.getId())`, returns `200` or `400`/`404`.
  - Handle `ResourceNotFoundException` and `BadRequestException` via existing `GlobalExceptionHandler`.
- **Dependencies**: T7
- **Status**: pending
- **Effort**: M
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/controller/PrecioController.java` (create)

### T9: Modify CompraService — inject PrecioService, update precioCompra + save historico

- **Description**: Modify `com.ferreplus.service.CompraService`:
  1. Inject `PrecioService` and `ProductoRepository` via `@RequiredArgsConstructor`.
  2. In `create()` method: after the existing `productoService.actualizarStock(...)` call (line 86), add:
     - `producto.setPrecioCompra(detalleDTO.getPrecioUnitario())`
     - `productoRepository.save(producto)`
     - `precioService.registrarHistorico(producto, detalleDTO.getPrecioUnitario(), producto.getPrecioVenta(), "COMPRA", compra.getNumeroFactura(), null)`
  3. In `update()` method: same pattern inside the loop at step 5 (after `actualizarStock` at line 160) — ONLY for new details, NOT reverting old ones.
  4. Add imports for `ProductoRepository` and `PrecioService`.
  - ⚠️ Risk: Ensure the existing `@Transactional` wraps these changes; no regression on stock/monto logic.
- **Dependencies**: T7
- **Status**: pending
- **Effort**: M
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/service/CompraService.java` (modify)

---

## Phase 3: Frontend — Foundation

### T10: Add PrecioProducto, HistoricoPrecioProducto, ActualizarPrecioVentaRequest to core/models.ts

- **Description**: Add three TypeScript interfaces to `frontend/src/app/core/models.ts`:
  1. `PrecioProducto`: `id` (number), `nombre` (string), `codigoBarras` (string), `precioCompra` (number), `precioVenta` (number), `ganancia` (number | null), `margenPorcentaje` (number | null), `fechaActualizacion` (string).
  2. `HistoricoPrecioProducto`: `id` (number), `productoId` (number), `precioCompra` (number), `precioVenta` (number), `tipoCambio` (string), `referencia` (string | null), `fechaCambio` (string), `usuarioNombre` (string | null).
  3. `ActualizarPrecioVentaRequest`: `nuevoPrecio?` (number), `margenPorcentaje?` (number), `referencia?` (string).
  - Append after the existing DashboardData interface at the end of the file, in a new comment section `// ===== PRECIOS =====`.
- **Dependencies**: None
- **Status**: pending
- **Effort**: S
- **Files affected**:
  - `frontend/src/app/core/models.ts` (modify)

### T11: Create Angular PrecioService

- **Description**: Create `frontend/src/app/gestion-precios/precio.service.ts`. Annotate with `@Injectable({ providedIn: 'root' })`. Inject `HttpClient`. Set `apiUrl` using environment: ``${environment.apiUrl}/precios``. Implement methods:
  1. `list()` → `this.http.get<PrecioProducto[]>(this.apiUrl)`
  2. `getById(id: number)` → `this.http.get<PrecioProducto>(\`${this.apiUrl}/${id}\`)`
  3. `getHistorial(id: number)` → `this.http.get<HistoricoPrecioProducto[]>(\`${this.apiUrl}/${id}/historial\`)`
  4. `actualizarPrecioVenta(id: number, dto: ActualizarPrecioVentaRequest)` → `this.http.put<PrecioProducto>(\`${this.apiUrl}/${id}/venta\`, dto)`
  - Import models from `../core/models`.
- **Dependencies**: T10
- **Status**: pending
- **Effort**: S
- **Files affected**:
  - `frontend/src/app/gestion-precios/precio.service.ts` (create)

---

## Phase 4: Frontend — Components & Wiring

### T12: Create GestionPreciosModule + routing module

- **Description**: Create two files:
  1. `frontend/src/app/gestion-precios/gestion-precios.module.ts` — `NgModule` (NOT standalone). `declarations`: `PreciosListComponent`, `PrecioDetailComponent`, `ActualizarPrecioDialog`. `imports`: `CommonModule`, `ReactiveFormsModule`, `GestionPreciosRoutingModule`, Angular Material modules (`MatTableModule`, `MatSortModule`, `MatPaginatorModule`, `MatFormFieldModule`, `MatInputModule`, `MatButtonModule`, `MatIconModule`, `MatCardModule`, `MatProgressSpinnerModule`, `MatDialogModule`, `MatTooltipModule`, `MatSnackBarModule`, `MatDividerModule`), and `NgChartsModule` from `ng2-charts`.
  2. `frontend/src/app/gestion-precios/gestion-precios-routing.module.ts` — routes: `{ path: '', component: PreciosListComponent }` and `{ path: ':id', component: PrecioDetailComponent }`.
  - Directory structure must be created first: `gestion-precios/`, `gestion-precios/precios-list/`, `gestion-precios/precio-detail/`, `gestion-precios/actualizar-precio-dialog/`.
- **Dependencies**: T13, T14, T15, T11
- **Status**: pending
- **Effort**: M
- **Files affected**:
  - `frontend/src/app/gestion-precios/gestion-precios.module.ts` (create)
  - `frontend/src/app/gestion-precios/gestion-precios-routing.module.ts` (create)

### T13: Create PreciosListComponent

- **Description**: Create component (TS + HTML + SCSS) at `frontend/src/app/gestion-precios/precios-list/`.
  - **TS**: `onInit` calls `precioService.list()`. Use `MatTableDataSource<PrecioProducto>` with `MatSort` (sort by columns) and `MatPaginator`. `applyFilter(event)` filters by nombre or codigoBarras via `filterPredicate`. `irADetalle(row)` navigates to `/gestion-precios/{id}`.
  - **HTML**: Material Table with columns: `nombre`, `codigoBarras`, `precioCompra` (currency pipe `GTQ`), `precioVenta` (currency), `ganancia` (currency or "—" if null), `margenPorcentaje` (percent or "Sin datos" if null), `fechaActualizacion` (date pipe). Search input above the table. Row click triggers navigation.
  - **SCSS**: Standard table styles consistent with other list components in the project.
- **Dependencies**: T11, T10
- **Status**: pending
- **Effort**: M
- **Files affected**:
  - `frontend/src/app/gestion-precios/precios-list/precios-list.component.ts` (create)
  - `frontend/src/app/gestion-precios/precios-list/precios-list.component.html` (create)
  - `frontend/src/app/gestion-precios/precios-list/precios-list.component.scss` (create)

### T14: Create PrecioDetailComponent (with chart)

- **Description**: Create component (TS + HTML + SCSS) at `frontend/src/app/gestion-precios/precio-detail/`.
  - **TS**: `onInit` loads `getById(id)` + `getHistorial(id)` via forkJoin. Chart config (ng2-charts line type): labels from historial ascending (fechas), dataset 1 = precioCompra series (blue), dataset 2 = precioVenta series (green). Historial as descending for table. `abrirDialogoActualizar()` opens `ActualizarPrecioDialog` via MatDialog, subscribes to `afterClosed()` to refresh data on success.
  - **HTML**: Top: MatCard grid with precioCompra, precioVenta, ganancia, margen. Middle: `canvas baseChart` with chart data, or "Sin datos históricos" text if no historial. Bottom: MatTable with historial (columns: tipoCambio, precioCompra, precioVenta, referencia, fechaCambio, usuarioNombre). Button "Actualizar Precio de Venta" in the card.
  - **SCSS**: Card grid layout, chart dimensions, consistent spacing.
- **Dependencies**: T11, T10
- **Status**: pending
- **Effort**: L
- **Files affected**:
  - `frontend/src/app/gestion-precios/precio-detail/precio-detail.component.ts` (create)
  - `frontend/src/app/gestion-precios/precio-detail/precio-detail.component.html` (create)
  - `frontend/src/app/gestion-precios/precio-detail/precio-detail.component.scss` (create)

### T15: Create ActualizarPrecioDialog component

- **Description**: Create component (TS + HTML + SCSS) at `frontend/src/app/gestion-precios/actualizar-precio-dialog/`.
  - **TS**: Receives `productoId` and `precioCompraActual` via `MAT_DIALOG_DATA`. Form controls: `nuevoPrecio`, `margenPorcentaje`, `referencia`. `valueChanges` on each: when one has value, disable the other (mutual exclusion). If `precioCompraActual === 0`, disable `margenPorcentaje` permanently with tooltip message. `onSubmit()` validates exactly one field has value, calls `precioService.actualizarPrecioVenta()`, shows success/error SnackBar, closes dialog with `true` on success.
  - **HTML**: Two option groups: "Nuevo Precio Directo" (numeric input) / "Margen Porcentual" (percent input) with mutual disable. Referencia text input. Actions: Cancel + Guardar buttons.
  - **SCSS**: Form layout, disabled state styling, spacing.
- **Dependencies**: T11, T10
- **Status**: pending
- **Effort**: M
- **Files affected**:
  - `frontend/src/app/gestion-precios/actualizar-precio-dialog/actualizar-precio-dialog.component.ts` (create)
  - `frontend/src/app/gestion-precios/actualizar-precio-dialog/actualizar-precio-dialog.component.html` (create)
  - `frontend/src/app/gestion-precios/actualizar-precio-dialog/actualizar-precio-dialog.component.scss` (create)

### T16: Update sidebar with "Precios" menu item

- **Description**: Modify `frontend/src/app/shared/sidebar/sidebar.component.ts`. Add item `{ label: 'Precios', icon: 'attach_money', route: '/gestion-precios' }` to the `menuItems` array, positioned after the existing `Compras` entry (after `{ label: 'Compras', ... }`, before `{ label: 'Movimientos', ... }`). No roles restriction (visible to all authenticated users).
- **Dependencies**: T12
- **Status**: pending
- **Effort**: S
- **Files affected**:
  - `frontend/src/app/shared/sidebar/sidebar.component.ts` (modify)

### T17: Update app-routing.module.ts with lazy route for gestion-precios

- **Description**: Modify `frontend/src/app/app-routing.module.ts`. Add a new route object in the `routes` array (after the existing `compras` route, before `movimientos`):
  ```
  { path: 'gestion-precios', loadChildren: () => import('./gestion-precios/gestion-precios.module').then(m => m.GestionPreciosModule), canActivate: [AuthGuard] }
  ```
- **Dependencies**: T12
- **Status**: pending
- **Effort**: S
- **Files affected**:
  - `frontend/src/app/app-routing.module.ts` (modify)

---

## Phase 5: Testing

### T18: Create PrecioServiceTest (unit tests with Mockito)

- **Description**: Create `com.ferreplus.service.PrecioServiceTest` at `backend/src/test/java/com/ferreplus/service/`. Use `@ExtendWith(MockitoExtension.class)`. Mock `ProductoRepository`, `HistoricoPrecioProductoRepository`, `ProductoService`, `UsuarioService` (the latter two only as needed). `@InjectMocks` on `PrecioService`. Implement minimum 5 test methods covering these spec scenarios:
  1. `listarPrecios_shouldReturnActiveProductsWithCalculatedMargins()` — mock 3 active + 2 inactive products, verify 3 results, verify ganancia and margenPorcentaje calculations.
  2. `listarPrecios_withZeroPrecioCompra_shouldReturnNullGananciaAndMargen()` — mock product with precioCompra=0, verify ganancia=null and margenPorcentaje=null.
  3. `actualizarPrecioVenta_withNewPrice_shouldUpdateAndSaveHistory()` — mock product, call with nuevoPrecio=200, verify producto.setPrecioVenta(200) and historicoRepository.save() called.
  4. `actualizarPrecioVenta_withMargin_shouldCalculatePriceAndSaveHistory()` — mock product with precioCompra=100, call with margenPorcentaje=50, verify precioVenta becomes 150.
  5. `actualizarPrecioVenta_withBothFields_shouldThrowError()` — call with both nuevoPrecio and margenPorcentaje, verify BadRequestException.
  6. `registrarHistorico_shouldSaveRecord()` — verify repository.save() is called with correct entity data.
- **Dependencies**: T7, T1
- **Status**: completed
- **Effort**: M
- **Files affected**:
  - `backend/src/test/java/com/ferreplus/service/PrecioServiceTest.java` (create)

### T19: Create CompraServiceIntegrationTest (integration tests with H2)

- **Description**: Create `com.ferreplus.service.CompraServiceIntegrationTest` at `backend/src/test/java/com/ferreplus/service/`. Use `@SpringBootTest`, `@AutoConfigureTestDatabase(replace = Replace.ANY)`, `@ActiveProfiles("test")`. Autowire `CompraService`, `ProductoRepository`, `HistoricoPrecioProductoRepository`, `CompraRepository`, `ProveedorRepository`, `CategoriaRepository`, `UsuarioRepository`. Implement minimum 2 integration tests:
  1. `createCompra_shouldUpdatePrecioCompraAndSaveHistory()` — set up test data (categoria, proveedor, usuario, producto with precioCompra=10), create `CompraDTO` with a detalle having precioUnitario=15, call `compraService.create(dto)`, verify `producto.precioCompra == 15`, verify historico_precios_producto has 1 record with tipoCambio="COMPRA" and precioCompra=15.
  2. `updateCompra_shouldUpdateNewProductPriceWithoutRevertingOldProductPrice()` — create compra with product X at precioUnitario=10, then update changing to product Y at precioUnitario=20, verify X.precioCompra is still 10 (NOT reverted), verify Y.precioCompra = 20, verify historial has records for both.
  - Ensure test data includes the minimum required entities (Categoria, Proveedor, Usuario) since these are FK dependencies.
  - ⚠️ Note: Security context may not be configured; for the endpoint authentication dependency, the integration test calls `CompraService` directly (bypassing the controller), so no auth setup is needed.
- **Dependencies**: T9, T1
- **Status**: completed
- **Effort**: M
- **Files affected**:
  - `backend/src/test/java/com/ferreplus/service/CompraServiceIntegrationTest.java` (create)

---

## Dependency Graph Summary

```
T1  (infrastructure)    T2  (entity)    T4/T5/T6  (DTOs)
        ↓                    ↓               ↓
        |                   T3  (repo)       |
        |                    ↓               |
        |                   T7  (service) ←──┘
        |                 ↙         ↘
        |              T8 (ctrl)    T9 (modify CompraService)
        |                            
T18 (unit tests) ←── dep on T7
T19 (intg tests) ←── dep on T9 + T1

                        T10 (models — frontend)
                            ↓
                         T11 (service — frontend)
                      ↙    ↓    ↘
         T13 (list)  T14 (detail)  T15 (dialog)
                 ↘      ↓      ↙
                  T12 (module + routing)
                  ↙          ↘
             T16 (sidebar)  T17 (app-routing)
```

---

## Review Workload Forecast

### Estimated Changed Lines

| Layer | Files Changed | Est. Lines New | Est. Lines Modified | Total Est. |
|-------|--------------|----------------|---------------------|------------|
| Backend — new | 7 files (entity, repo, 3 DTOs, service, controller) | ~520 | — | ~520 |
| Backend — modified | 2 files (pom.xml, CompraService) | — | ~40 | ~40 |
| Frontend — new | 10 files (module, routing, service, 3 components × 3 files each) | ~480 | — | ~480 |
| Frontend — modified | 3 files (models.ts, sidebar, app-routing) | — | ~30 | ~30 |
| Tests | 3 files (test config, unit test, integration test) | ~260 | — | ~260 |
| **Total** | **25 files** | **~1,260** | **~70** | **~1,330** |

### 400-Line Budget Risk Assessment

| Risk | Assessment |
|------|------------|
| **Total exceeds 400-line budget by 3.3×** | 🔴 **HIGH RISK** — ~1,330 lines across 25 files is well beyond the standard review budget. |
| **Backend alone** (~560 lines) | 🟡 Exceeds budget by 40% even without frontend or tests. |
| **Frontend alone** (~510 lines) | 🟡 Exceeds budget by ~28%. |
| **Tests alone** (~260 lines) | 🟢 Fits within budget (but depends on code being reviewed first). |

### Chained PRs Recommendation

**Strongly recommend 3 chained PRs** to keep each review under or near the 400-line threshold:

1. **PR 1: Backend Foundation + Service** (~380 lines)
   - T1, T2, T3, T4, T5, T6, T7 — entities, DTOs, PrecioService
   - Rationale: Self-contained — new files only, no modifications to existing code. Establishes the domain model and business logic. Reviewable independently.

2. **PR 2: Backend Controller + CompraService modification + Tests** (~420 lines)
   - T8, T9, T18, T19 — PrecioController, modify CompraService, unit + integration tests
   - Rationale: Groups the modified existing file (CompraService) with the controller that uses PrecioService, plus the tests that validate the modifications. Slightly over budget but acceptable since ~260 of those lines are tests.

3. **PR 3: Frontend Module** (~510 lines)
   - T10, T11, T12, T13, T14, T15, T16, T17 — complete frontend implementation
   - Rationale: Frontend is fully decoupled from backend (relies only on API contract). The ~510 lines exceed budget but splitting frontend further (e.g., list vs detail vs dialog) would create artificial churn.

### Decision Needed Before Apply

1. **Confirm PR splitting strategy**: Does the team prefer 3 chained PRs as recommended above, or a single large PR? If chained, what order and which tasks in each chain?
2. **Confirm test infrastructure approach**: H2 for integration tests (as designed) vs Testcontainers with PostgreSQL (heavier but production-like). The design decision favors H2 for simplicity.
3. **Confirm `application-test.yml` vs `application-test.properties`**: The main config uses YAML — test config should match (`application-test.yml`).
4. **Chart.js / ng2-charts version**: Confirm `ng2-charts` is already installed in `frontend/package.json` (the proposal assumes yes — verify before T14 implementation).
5. **Testing scope for Frontend**: Per the proposal, frontend tests are excluded (no test infrastructure exists). Confirm this is acceptable.
6. **`anular()` not in scope**: Confirm that the `anular()` method in `CompraService` should NOT be modified (per proposal: out of scope — no historial nor precioCompra revert on anulación).
