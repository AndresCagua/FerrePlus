# Tasks: Módulo de Logs de Actividades del Sistema

> **Change**: `modulo-logs`
> **Total tasks**: 31
> **Fases**: 8 (Backend Foundation → Backend Core Logs → Backend Seed → Backend Instrumentación → Frontend Foundation → Frontend Logs Module → Backend Tests → Frontend/Verificación)
> **Specialists**: cada tarea marca su especialista (`springboot` | `angular` | `ambos`) — el especialista indica el stack al que pertenece. El especialista correspondiente debe cargar sus skills obligatorias (ver `especialista_springboot.md` / `especialista_angular.md`) antes de implementar. La convención del proyecto gana para el frontend (**NgModule feature, NO standalone** → el especialista Angular asume standalone por defecto pero este change sigue `config.yaml`: NgModules + Reactive Forms).
> **TDD (strict, ambos stacks)**: donde el código introduce comportamiento, primero se escribe el test que FALLA (RED) y luego la implementación (GREEN). Para el backend: unit test de `LogService` (lógica pura de spec + validación) va ANTES de su implementación (T2.1 RED → T2.2 GREEN); los tests de integración (Phase 7) requieren el stack completo por naturaleza. Frontend: `log.service.spec.ts` y `log-list.component.spec.ts` se escriben en el mismo batch que su código de la feature (infra vitest existente).

---

## ⚠️ ENTREGA POR STACKS — el usuario revisa y commitea; el agente NO ejecuta git

- La implementación avanza **por stacks**, no por PRs: primero el **backend completo**, luego el **frontend completo**.
- El agente **no ejecuta ninguna operación git** (ni commits, ni push, ni PRs). El usuario hace todos los commits/chequeos manualmente.
- **Al completar cada stack y pasar su verificación, el agente se DETIENE y notifica al usuario** para review + commit antes de continuar con el siguiente stack.
- Flujo: **STACK 1 (backend completo, tandas B1..B5) → STOP → review/commit del usuario → STACK 2 (frontend completo, tandas F1..F4) → STOP → review/commit del usuario.**

---

## STACK 1: BACKEND (tandas B1..B5) — backend completo

> **Regla del stack**: al completar el conjunto (todos los tests backend en verde, incluyendo `mvn test` en Docker), **STOP y notificar al usuario para revisar y commitear** antes de iniciar STACK 2.

| Tanda | Fase | Tareas | Salida verificable |
|-------|------|--------|--------------------|
| B1 | Phase 1 — Foundation | T1.1–T1.4 | AuditService overload + AuditoriaRepository + DTOs + script índice |
| B2 | Phase 2 — Core Logs | T2.1(RED)–T2.3 | `LogServiceTest` verde; `GET/DELETE /api/logs` funcionales |
| B3 | Phase 3 — Seed | T3.1 | Catálogo 14 módulos / 44 permisos / 71 pares; drift + seeder count tests actualizados en el MISMO batch |
| B4 | Phase 4 — Instrumentación | T4.1–T4.8 | 9 services + login auditan tras save; operaciones rechazadas no auditan |
| B5 | Phase 7 — Tests backend | T7.1–T7.6 | `mvn test` (Docker) 100% verde (incluye tests preexistentes) |

### Phase 1: Backend — Foundation (AuditService, repository, DTOs)

#### T1.1: Add `AuditService` overload with explicit `Usuario` actor
- **Description**: Modify `com.ferreplus.service.AuditService` agregando un overload `registrarEvento(String entidad, Long entidadId, String accion, String detalle, Usuario usuario)` que usa el `usuario` pasado (en lugar de `usuarioActual()`) como actor, manteniendo `Propagation.MANDATORY`. El overload existente delega en el nuevo con `usuarioActual()`. Conservar atomicidad (MANDATORY) y resolver `null` para eventos de sistema/seed.
- **Dependencies**: None
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/service/AuditService.java` (modify)
- **Acceptance criteria**:
  - `AuthService.login()` puede pasar el usuario explícito (R5): `registrarEvento("AUTH", usuario.getId(), "LOGIN", null, usuario)`.
  - Overload existente (4 params) no cambia su contrato; tests existentes (`AuditoriaTest`) siguen pasando.
  - `Propagation.MANDATORY` se mantiene en ambos métodos → atomicidad R10.

#### T1.2: Modify `AuditoriaRepository` — Specification + `@EntityGraph` + bulk delete
- **Description**: Modify `com.ferreplus.repository.AuditoriaRepository`:
  - Agregar `extends ... JpaSpecificationExecutor<Auditoria>`.
  - Re-declarar `@Override @EntityGraph(attributePaths = "usuario") Page<Auditoria> findAll(Specification<Auditoria> spec, Pageable pageable)` (anti N+1: `a.usuario` es LAZY).
  - Agregar bulk delete: `@Modifying(clearAutomatically = true, flushAutomatically = true) @Query("DELETE FROM Auditoria a WHERE a.fecha BETWEEN :desde AND :hasta") int borrarPorRango(@Param("desde") LocalDateTime desde, @Param("hasta") LocalDateTime hasta);`.
  - Conservar `findByEntidadAndEntidadIdAndAccion` (lo usan `AuditoriaTest`/instrumentación).
- **Dependencies**: None
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/repository/AuditoriaRepository.java` (modify)
- **Acceptance criteria**:
  - Consulta paginada con `@EntityGraph` sin N+1 (Decisión 1, R2).
  - `borrarPorRango` = UN solo statement SQL (Decisión 4, R3), con `clearAutomatically`/`flushAutomatically`.

#### T1.3: Create `AuditoriaDTO` + `LogsEliminadosDTO`
- **Description**: Create DTOs (getters/setters manuales, convención del proyecto — sin Lombok; KISS):
  - `com.ferreplus.dto.AuditoriaDTO`: `id`, `entidad`, `entidadId`, `accion`, `usuarioId` (Long, nullable), `usuarioNombre` (String, nullable/vacío), `fecha` (LocalDateTime), `detalle` (String crudo). `@JsonInclude(NON_NULL)` para omitir `usuarioId`/`usuarioNombre` cuando son null (edge case 5).
  - `com.ferreplus.dto.LogsEliminadosDTO`: `eliminados` (int) con getter/setter.
- **Dependencies**: None
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/dto/AuditoriaDTO.java` (create)
  - `backend/src/main/java/com/ferreplus/dto/LogsEliminadosDTO.java` (create)
- **Acceptance criteria**:
  - Contrato JSON de `GET /api/logs` (R2: DTO `Page`, no `Auditoria`) y respuesta `{ "eliminados": N }` (R3).
  - `detalle` se expone tal cual (sin parseo; edge case 9, D-JSON crudo).

#### T1.4: Create `db/indices-auditoria.sql` (script revisado, NO ejecutado)
- **Description**: Create `backend/src/main/resources/db/indices-auditoria.sql` con `CREATE INDEX IF NOT EXISTS idx_auditoria_fecha ON auditoria (fecha);` y `CREATE INDEX IF NOT EXISTS idx_auditoria_entidad_fecha ON auditoria (entidad, fecha);` y un comentario que NO los crea `ddl-auto`, deben aplicarse manualmente tras revisión del usuario. **No se autoejecuta** (regla de BD del proyecto).
- **Dependencies**: None
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/resources/db/indices-auditoria.sql` (create)
- **Acceptance criteria**:
  - Script presente para el operador; sin auto-migración (open question del design resuelta: se incluye pero no se corre).

### Phase 2: Backend — Core Logs (LogService RED→GREEN + LogController)

#### T2.1: Write `LogServiceTest` (RED — unit, Mockito)
- **Description**: Create `com.ferreplus.service.LogServiceTest` con `@ExtendWith(MockitoExtension.class)` y `@Mock AuditoriaRepository`. Casos (contrato de `LogService`, R2/R3):
  1. `consultar` build de `Specification`: con todos los filtros opcionales presentes (`fechaDesde`, `fechaHasta`, `usuarioId`, `entidad`, `accion`) el `findAll(spec, pageable)` recibe un spec; con todos ausentes recibe `Specification.where(null)`.
  2. Mapeo `toDTO`: una `Auditoria` con usuario → `usuarioNombre`/`usuarioId`; una con usuario null → `null/""` (edge case 5).
  3. Parse dual de rango: `yyyy-MM-dd` → `startOfDay` para `desde` y `LocalTime.MAX` (endOfDay) para `hasta`; `yyyy-MM-dd'T'HH:mm:ss` → `LocalDateTime` tal cual (D4, tabla de parse).
  4. `eliminarPorRango`: rango válido → devuelve el `int` de `borrarPorRango`; **400** (`BadRequestException`) si falta/vacío `desde` o `hasta`; **400** si formato inválido; **400** si `hasta < desde` (revertido).
- **Dependencies**: T1.3
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/test/java/com/ferreplus/service/LogServiceTest.java` (create)
- **Acceptance criteria**:
  - Test compila y FALLA (RED) porque `LogService` no existe → define el contrato del componente.

#### T2.2: Create `LogService` (GREEN)
- **Description**: Create `com.ferreplus.service.LogService` (`@Service`, `@RequiredArgsConstructor`, inyecta `AuditoriaRepository`):
  - `@Transactional(readOnly = true) Page<AuditoriaDTO> consultar(String fechaDesde, String fechaHasta, Long usuarioId, String entidad, String accion, Pageable pageable)` construyendo `Specification<Auditoria>` con predicates **solo si** el filtro viene (desde/hasta con parse dual; `entidad` y `accion` con `trim().toUpperCase()`), y llamando `auditoriaRepository.findAll(spec, pageable).map(toDTO)`.
  - `@Transactional int eliminarPorRango(String desde, String hasta)`: parse dual con `startOfDay`/`endOfDay` (D4), valida ausente/vacío/inválido → `BadRequestException`, `hasta < desde` → `BadRequestException`, luego `auditoriaRepository.borrarPorRango(ds, hs)` y devuelve el `int`.
- **Dependencies**: T2.1, T1.1, T1.2
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/service/LogService.java` (create)
- **Acceptance criteria**:
  - `LogServiceTest` completa y pasa (GREEN) — escenarios R2 (4) y R3 validación (400) y R3 rango vacío implícito (0 filas).
  - `findAll` con `@EntityGraph` (anti N+1).

#### T2.3: Create `LogController` — `GET /api/logs` + `DELETE /api/logs`
- **Description**: Create `com.ferreplus.controller.LogController` (`@RestController`, `@RequestMapping("/api/logs")`, `@CrossOrigin(origins = "http://localhost:4200")`, `@RequiredArgsConstructor`):
  - `@GetMapping` con `@PreAuthorize("hasAuthority('LOGS_VER')")`: params `page` (default 0), `size` (default 20), `fechaDesde`, `fechaHasta`, `usuarioId`, `entidad`, `accion` (opcionales); `Pageable` con `Sort.by(DESC, "fecha")`; devuelve `ResponseEntity<Page<AuditoriaDTO>>`.
  - `@DeleteMapping` con `@PreAuthorize("hasAuthority('LOGS_ELIMINAR')")`: `@RequestParam String desde`, `@RequestParam String hasta` (obligatorios → 400 si faltan); devuelve `ResponseEntity.ok(new LogsEliminadosDTO(logService.eliminarPorRango(desde, hasta)))`.
  - **NO debe existir** `DELETE /api/logs/{id}` (R3: solo borrado por rango).
- **Dependencies**: T2.2
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/controller/LogController.java` (create)
- **Acceptance criteria**:
  - `GET /api/logs` 200 solo con `LOGS_VER`; `DELETE /api/logs` 200/400/403 según R3; ambos requieren auth (`anyRequest().authenticated()` de `SecurityConfig` existente).
  - `LOGS_VER` y `LOGS_ELIMINAR` quedan referenciados en `@PreAuthorize` → el drift test (T7.1) los encuentra sin modificar la allowlist.

### Phase 3: Backend — Seed (módulo LOGS)

#### T3.1: Modify `DataSeeder` — módulo LOGS (14º) + permisos + matriz ADMIN + NOMBRE_MODULO
- **Description**: Modify `com.ferreplus.config.DataSeeder` para agregar el **14º módulo LOGS**:
  - `MODULOS.put("LOGS", new int[]{14, 1, 0, 0, 1})` → genera `LOGS_VER` y `LOGS_ELIMINAR` (NO `LOGS_CREAR`/`LOGS_EDITAR`).
  - `NOMBRES_MODULO.put("LOGS", "Logs")`.
  - `MATRIZ_ROLES.put("ADMIN", Set.of(...))` → **agregar** `"LOGS_VER", "LOGS_ELIMINAR"` (pasan ADMIN de 42→44 códigos). VENDEDOR y BODEGUERO **sin cambios** (sin LOGS por defecto; override vía UI).
  - No tocar la idempotencia existente (consulta antes de insertar por código y par (rol, permiso); doble ejecución sin duplicar).
- **Dependencies**: T1.1 (AuditService no requerido aquí; el seed NO audita — bootstrap)
- **⚠️ Batch obligatório**: el conteo de **`PreAuthorizeDriftTest`** y **`DataSeederIdempotencyTest`** se actualiza en el MISMO batch que este seeder (T7.1/T7.2) — el drift/seeder SIEMPRE pasa antes de mergear.
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/config/DataSeeder.java` (modify)
- **Acceptance criteria**:
  - Catálogo pasa a **14 módulos / 44 permisos**; matriz **71 pares** (ADMIN 44 + VENDEDOR 9 + BODEGUERO 18). ADMIN recibe ambos; VENDEDOR/BODEGUERO ninguno por defecto (R1).
  - Idempotencia: segunda ejecución no duplica (R1, escenario 4).

### Phase 4: Backend — Instrumentación del dominio (9 services + login)

> Patrón (igual a `UsuarioService`): inyectar `AuditService` (y `ObjectMapper` para `detalle` JSON con fallback a texto) vía `@RequiredArgsConstructor`, y llamar `auditService.registrarEvento("<ENTIDAD>", entidad.getId(), "ACCION", jsonDetalle)` como **última línea** tras el `save` exitoso. `entidad` = **singular** (Decisión D5: `PRODUCTO`, `VENTA`, ... → coinciden con los códigos de módulo del catálogo; NO plural). `Propagation.MANDATORY` + `@Transactional` de clase → registro atómico con la operación (R4/R10). `ReporteService` NO se instrumenta (read-only). UNA operación rechazada (400/404/stock) lanza antes del `registrarEvento` → sin fila (R4 escenario 3, R10). Todos los services objetivo ya tienen `@Transactional` a nivel clase.

#### T4.1: Instrument `ProductoService` (PRODUCTO)
- **Description**: Inyectar `AuditService` (+ `ObjectMapper` para `detalle`) en `com.ferreplus.service.ProductoService` y registrar tras save: `create` → `registrarEvento("PRODUCTO", prod.getId(), "CREAR", json)`; `update` → `"ACTUALIZAR"`; `delete` (soft) → `"ELIMINAR"` con `{"activo":false}`. NO instrumentar `actualizarStock` (helper interno de venta/compra/movimiento ya auditados por su "dueño").
- **Dependencies**: T2.3
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/service/ProductoService.java` (modify)
- **Acceptance criteria**:
  - `POST /api/productos` → fila `PRODUCTO`/`CREAR` con `entidad_id` y `usuario_id` correctos (R4 escenario 1); rechazado → sin fila.

#### T4.2: Instrument `CategoriaService` (CRUD)
- **Description**: Instrumentar `create`/`update`/`delete` de `CategoriaService` con entidad `CATEGORIA`, detalles `{"nombre":...}`, `entidad_id` = la categoría id.
- **Dependencies**: T2.3
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**: `backend/src/main/java/com/ferreplus/service/CategoriaService.java` (modify)
- **Acceptance criteria**: filas `CATEGORIA`/`CREAR|ACTUALIZAR|ELIMINAR` en operaciones exitosas; rechazadas sin fila.

#### T4.3: Instrument `ProveedorService` (CRUD)
- **Description**: Instrumentar `create`/`update`/`delete` con entidad `PROVEEDOR`, `detalle` `{"nombre":...}`.
- **Dependencies**: T2.3
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**: `backend/src/main/java/com/ferreplus/service/ProveedorService.java` (modify)
- **Acceptance criteria**: filas `PROVEEDOR`/`*` en operaciones avanzadas.

#### T4.4: Instrument `ClienteService` (CRUD)
- **Description**: Instrumentar `create`/`update`/`delete` con entidad `CLIENTE`, `detalle` `{"nombre":...,"ruc":...}`.
- **Dependencies**: T2.3
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**: `backend/src/main/java/com/ferreplus/service/ClienteService.java` (modify)
- **Acceptance criteria**: filas `CLIENTE`/`*` en operaciones avanzadas.

#### T4.5: Instrument `VentaService` (VENTA: CREAR + ANULAR)
- **Description**: Instrumentar `create` → `registrarEvento("VENTA", venta.getId(), "CREAR", json)` con `{"numeroFactura":..., "total":...}` y `anular` → `registrarEvento("VENTA", venta.getId(), "ANULAR", json)`. La **anulación = semántica de ELIMINAR** sin borrado físico (D7).
- **Dependencies**: T2.3
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**: `backend/src/main/java/com/ferreplus/service/VentaService.java` (modify)
- **Acceptance criteria**: fila `VENTA`/`ANULAR` al anular (R4 escenario 2); venta rechazada por stock insuficiente → rollback completo sin fila (R4 escenario 3, R10).

#### T4.6: Instrument `CompraService` (COMPRA + ACTUALIZAR + ANULAR)
- **Description**: Instrumentar `create` → `COMPRA`/`CREAR`, `update` → `COMPRA`/`ACTUALIZAR`, `anular` → `COMPRA`/`ANULAR`, con `detalle` `{"numeroFactura":...}`.
- **Dependencies**: T2.3
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**: `backend/src/main/java/com/ferreplus/service/CompraService.java` (modify)
- **Acceptance criteria**: filas `COMPRA`/`CREAR|ACTUALIZAR|ANULAR`; rechazada sin fila.

#### T4.7: Instrument `PrecioService` + `MovimientoStockService` + `GastoService` (PRECIO + MOVIMIENTO + GASTO)
- **Description**: 
  - `PrecioService.actualizarPrecioVenta` → `registrarEvento("PRECIO", producto.getId(), "ACTUALIZAR", json{"precioVenta","margen"})`.
  - `MovimientoStockService.create` → `registrarEvento("MOVIMIENTO", mov.getId(), "CREAR", json{"productoId","tipo"})`.
  - `GastoService.{create,update,delete}` → `GASTO`/`CREAR|ACTUALIZAR|ELIMINAR` con `detalle` `{"descripcion","monto"}`.
- **Dependencies**: T2.3
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/service/PrecioService.java` (modify)
  - `backend/src/main/java/com/ferreplus/service/MovimientoStockService.java` (modify)
  - `backend/src/main/java/com/ferreplus/service/GastoService.java` (modify)
- **Acceptance criteria**: filas correctas por entidad/accion; rechazadas sin fila.

#### T4.8: Instrument `AuthService.login` (AUTH/LOGIN con usuario explícito)
- **Description**: Instrumentar `AuthService.login` para registrar el **login exitoso** mediante el overload con usuario explícito: `auditService.registrarEvento("AUTH", usuario.getId(), "LOGIN", null, usuario)` como última línea (después del armado del AuthResponse y tras los checks). Usa el overload de T1.1 porque el `SecurityContextHolder` aún no se actualizó durante `login()` (D7/R5). NO registrar intentos fallidos (volumen + PII; la excepción lanza antes de esta línea).
- **Dependencies**: T1.1, T2.3
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**: `backend/src/main/java/com/ferreplus/service/AuthService.java` (modify)
- **Acceptance criteria**: login exitoso → fila `AUTH`/`LOGIN` con `entidad_id` y `usuario_id` = mismo usuario (R5 escenario 1); credenciales incorrectas → **no** fila AUTH (R5 escenario 2). Integrable en `AuthService` ya `@Transactional` (MANDATORY).

---

## STACK 2: FRONTEND (tandas F1..F4) — frontend completo

> **Regla del stack**: al completar `ng build` limpio + `npm test` verde + checklist manual T8.2 aprobado, **STOP y notificar al usuario para revisar y commitear**.
> **Requisito**: el STACK 1 debe estar completado y committeado (el backend y el contrato de `Page<...>`/`{eliminados}` deben estar disponibles).

| Tanda | Fase | Tareas | Salida verificable |
|-------|------|--------|--------------------|
| F1 | Phase 5 — Foundation | T5.1–T5.3 | Contract types + sidebar entry + ruta `/logs` |
| F2 | Phase 6 — Logs Module | T6.1–T6.4 | `logs/` NgModule con lista server-side + filtros + servicio + borrado por rango + tests |
| F3 | Phase 7 — Backend Tests (partes) | T7.* ya completadas en B5 | — |
| F4 | Phase 8 — Verification | T8.1–T8.2 | `npm test` verde + checklist manual end-to-end |

### Phase 5: Frontend — Foundation (types, Rutas, routing)

#### T5.1: Update `core/models.ts` — tipos `Page`, `AuditoriaLog`, `EliminarLogsResponse`
- **Description**: Modify `frontend/src/app/core/models.ts`:
  - `export interface Page<T> { content: T[]; totalElements: number; totalPages: number; size: number; number: number; first?: boolean; last?: boolean; }`.
  - `export interface AuditoriaLog { id: number; entidad: string; entidadId: number | null; accion: string; usuarioId?: number | null; usuarioNombre?: string | null; fecha: string; detalle?: string | null; }`.
  - `export interface EliminarLogsResponse { eliminados: number }`.
- **Dependencies**: None
- **Status**: done
- **Effort**: S
- **Specialist**: angular
- **Files**: `frontend/src/app/core/models.ts` (modify)
- **Acceptance criteria**: contrato tipado refleja `Page<AuditoriaDTO>` y `{ eliminados }` (R2/R7).

#### T5.2: Modify `core/rutas-por-permiso.ts` — entrada Logs
- Modify `frontend/src/app/core/rutas-por-permiso.ts`: agregar `{ label: 'Logs', icon: 'receipt_long', route: '/logs', permissions: ['LOGS_VER'] }` como 14º elemento (después de Reportes). El `SidebarComponent` lo lee automáticamente (RUTAS_POR_PERMISO) → el item aparece solo con `LOGS_VER`.
- **Dependencies**: None
- **Status**: done
- **Effort**: S
- **Specialist**: angular
- **Files**: `frontend/src/app/core/rutas-por-permiso.ts` (modify)
- **Acceptance criteria**: sidebar muestra "Logs" solo con `LOGS_VER` (R7); `permisosDeRuta('/logs')` retorna `['LOGS_VER']`.

#### T5.3: Modify `app-routing.module.ts` — ruta `/logs` lazy
- Modify `frontend/src/app/app-routing.module.ts`: agregar `{ path: 'logs', loadChildren: () => import('./logs/logs.module').then(m => m.LogsModule), canActivate: [AuthGuard], data: { permissions: permisosDeRuta('/logs') } }` (después de reportes).
- **Dependencies**: T5.2, T6.2 (logs.module)
- **Status**: done
- **Effort**: S
- **Specialist**: angular
- **Files**: `frontend/src/app/app-routing.module.ts` (modify)
- **Acceptance criteria**: `/logs` lazy y protegido por `LOGS_VER`; navegación por URL directa sin `LOGS_VER` → bloqueada y redirigida a la primera ruta permitida (R7 escenario 2).

### Phase 6: Frontend — Logs Module (feature NgModule)

#### T6.1: Create `log.service.ts` + `log.service.spec.ts` (vitest)
- **Description** (test-first strict: escribir `log.service.spec.ts` en el mismo batch y luego el servicio):
  - `frontend/src/app/logs/log.service.ts` (`@Injectable({providedIn:'root'})`):
    - `list(params: LogFiltros & { page; size }): Observable<Page<AuditoriaLog>>` → `GET ${apiUrl}/logs` con `HttpParams` (omitir vacíos) y paginación+filtros.
    - `deleteByRange(desde: string, hasta: string): Observable<EliminarLogsResponse>` → `DELETE /logs?desde=&hasta=`.
  - `frontend/src/app/logs/log.service.spec.ts`: mockea `HttpClient`/`HttpTestingController` (patrón `catalogo.service.spec`/`auth.service.spec` vitest); assert `list` arma query con page/size/filtros (y omite vacíos) y `deleteByRange` llama con params.
- **Dependencies**: T5.1
- **Status**: done
- **Effort**: M
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/logs/log.service.ts` (create)
  - `frontend/src/app/logs/log.service.spec.ts` (create)
- **Acceptance criteria**: service consume el contrato (R7 list/server-side + R8 delete); `log.service.spec.ts` verde (RED→GREEN).

#### T6.2: Create `logs.module.ts` + `logs-routing.module.ts`
- **Description**: Crear feature module NgModule (NO standalone — patrón `roles/`):
  - `frontend/src/app/logs/logs.module.ts`: importa `CommonModule`, `ReactiveFormsModule`, `MaterialModule` (o los módulos Material del proyecto), `MatTableModule`, `MatPaginatorModule`, y `SharedModule` (para la directiva `appHasPermission`); declara `LogListComponent`.
  - `frontend/src/app/logs/logs-routing.module.ts`: ruta `''` → `LogListComponent`.
- **Dependencies**: 
- **Status**: done
- **Effort**: M
- **Specialist**: angular
- **Files**:
  - `frontend/src/app/logs/logs.module.ts` (create)
  - `frontend/src/app/logs/logs-routing.module.ts` (create)
- **Acceptance criteria**: módulo lazy-cargable; ruta interna `''`.

#### T6.3: Create `log-list` component (tabla server-side + formulario de filtros)
- **Description**: Crear `frontend/src/app/logs/log-list/log-list.component.{ts,html,scss}` (Reactive Forms + MatTable + `MatPaginator` **server-side**) y su spec:
  - **Tabla server-side**: `dataSource: MatTableDataSource<AuditoriaLog>` (solo DATA; sin `.filter` client-side) + `@ViewChild(MatPaginator)`; en cada `PageEvent` re-consulta `logService.list({page, size, filtros})` (no filtrar in-memory; R7 escenario 3).
  - Columnas: `entidad`, `entidadId`, `accion`, `usuarioNombre`, `fecha`, `detalle` (render `<pre>` en bruto; cautela PII sin export).
  - Filtros Reactive: `fechaDesde`, `fechaHasta` (MatDatepicker, formato `yyyy-MM-dd`), `usuarioId` (input numérico directo — no lista de usuarios, evita depender de `USUARIOS_VER`), `entidad` (select estático de entidades singulares o texto libre — KISS), `accion` (select `CREAR/ACTUALIZAR/ELIMINAR/ANULAR/LOGIN`). Botón "Aplicar" → re-consulta pág. 0.
  - **NOTE `entidad` (Decisión D5)**: el valor enviado al backend debe ser el **singular** (`VENTA`, `PRODUCTO` ...), no el código plural `VENTAS`. El select/frontend mapea label de módulo → `entidad` singular.
- **log-list.component.spec.ts** (vitest): render tabla + filtros; al cambiar página se llama `log.service.list` con los query params (R7 escenario 3); usuario sin `LOGS_VER` no ve la lista (opcional — guard ya bloquea).
- **Dependencies**: T6.1, T6.2
- **Status**: done
- **Effort**: L (3 archivos + spec)
- **Specialist**: angular
- **Files**:
  - `frontend/src/app/logs/log-list/log-list.component.ts` (create)
  - `frontend/src/app/logs/log-list/log-list.component.html` (create)
  - `frontend/src/app/logs/log-list/log-list.component.scss` (create)
- **Acceptance criteria**: lista paginada server-side con filtros (R7); escenarios R7 (1, 2, 3) cubiertos por spec.

#### T6.4: Add delete-by-range (botón condicionado + diálogo de confirmación + resultado)
- **Description**: Dentro de `log-list`:
  - Botón **"Borrar por rango"** visible solo con `*appHasPermission="'LOGS_ELIMINAR'"` (directiva `has-permission.directive` — ya existe). Sin `LOGS_ELIMINAR` el botón NO se renderiza.
  - Al clic → `MatDialog` con 2 `MatDatepicker` (desde/hasta) y botones Cancelar/Confirmar que **muestra el rango** a borrar (destructivo, NO reversible).
  - **Cancelar** → NO llama a `deleteByRange`.
  - **Confirmar** → valida rango `hasta >= desde`, llama `logService.deleteByRange(desde, hasta)`, muestra con `Swal` (sweetalert2 ya está) el conteo `eliminados`, y **recarga** la lista.
  - **Sin borrado por fila individual** (R8 escenario 4): no hay botón/ícono/menú por fila.
  - Agregar casos a `log-list.component.spec.ts` (mismo archivo): botón presente con `LOGS_ELIMINAR` y ausente sin él; cancelar no llama endpoint; confirmar llama y recarga la lista.
- **Dependencies**: T6.3
- **Status**: done
- **Effort**: L
- **Specialist**: angular
- **Files**:
  - `frontend/src/app/logs/log-list/log-list.component.ts` (modify)
  - `frontend/src/app/logs/log-list/log-list.component.html` (modify)
  - `frontend/src/app/logs/log-list/log-list.component.spec.ts` (modify)
- **Acceptance criteria**: escenarios R8 (1-4) verificados por spec; confirmación cancelada no llama al endpoint; confirmado muestra `eliminados` y recarga.

---

## Phase 7: Tests — Backend (integración H2 + drift + instrumentación)

> Patrones existentes: `@SpringBootTest` + `@AutoConfigureTestDatabase(replace = Replace.ANY)` + `@ActiveProfiles("test")` + H2; `SecurityContextHolder` con `Usuario` principal (y `@AfterEach clearContext()`) para tests de auditoría; `spring-security-test` en pom. Comando: `docker run --rm -v <...>/backend:/app -w /app maven:3.9-eclipse-temurin-21 mvn test`.

#### T7.1: Update `PreAuthorizeDriftTest` — conteos 44/71 (mismo batch que T3.1)
- **Description**: Modify `backend/src/test/java/com/ferreplus/security/PreAuthorizeDriftTest.java`:
  - `catalogo_seed_es_completo`: `assertEquals(44, count())` y pares → `assertEquals(71, ...)` (ADMIN 44 + VENDEDOR 9 + BODEGUERO 18). Los otros dos tests NO requieren cambio de allowlist: `LOGS_VER` y `LOGS_ELIMINAR` quedan referenciados en `@PreAuthorize` de `LogController`, por lo que el test `todo_permiso_del_catalogo_esta_protegido_salvo_allowlist` pasa sin tocar la `ALLOWLIST` (que permanece `{VENTAS_EDITAR, ROLES_CREAR, ROLES_ELIMINAR}`).
- **⚠️ Batch**: debe commitearse en el **mismo batch** que T3.1 (DataSeeder) — son una sola unidad de cambio.
- **Dependencies**: T3.1, T2.3
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files**: `backend/src/test/java/com/ferreplus/security/PreAuthorizeDriftTest.java` (modify)
- **Acceptance criteria**: los 3 tests del drift pasan con 44/71 y sin tocar allowlist (R9 escenario 1).

#### T7.2: Actualizar `DataSeederIdempotencyTest` — conteos 14/44/71 (mismo batch que T3.1)
- **Description**: Modify `backend/src/test/java/com/ferreplus/security/DataSeederIdempotencyTest.java`: `seed_siembraElEstadoCompletoEsperado` espera `14` módulos, `44` permisos y `71` pares. `dobleEjecucion_noCambiaElEstado` sigue verificando que una segunda `run()` no duplica (14/44/71 se mantienen).
- **Dependencies**: T3.1
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files**: `backend/src/test/java/com/ferreplus/security/DataSeederIdempotencyTest.java` (modify)
- **Acceptance criteria**: idempotencia con los nuevos conteos (R1 escenario 4).

#### T7.3: Create `LogControllerIntegrationTest` — consulta paginada/filtros + seguridad
- **Description**: `@SpringBootTest` con H2, usuarios admin (`LOGS_VER`) y vendedor (sin `LOGS_VER`) vía repos+login real (patrón `SecurityEnforcementIntegrationTest`), y registros en `auditoria` con distintas fechas/entidades/acciones. Assert (R2, R9):
  1. `GET /api/logs?page=0&size=20` (admin) → 200 con estructura `Page` (content, `totalElements`, `totalPages`, y elementos con `entidad/entidadId/accion/usuarioNombre/fecha/detalle`).
  2. `GET /api/logs` (vendedor) → **403**, sin filas expuestas.
  3. Filtro por rango `fechaDesde/fechaHasta` → solo filas del rango y `totalElements` filtrado.
  4. Filtro combinado `entidad=VENTA&accion=CREAR` → solo esa pareja y `totalElements` correcto.
  5. Solo `fechaDesde` o solo `fechaHasta` filtra por un extremo (edge case 4).
  6. Filtro `usuarioId` → solo filas de ese usuario; `entidad` opera sobre singular.
- **Dependencies**: T2.3, T3.1, T7.1
- **Status**: pending
- **Effort**: L
- **Specialist**: springboot
- **Files**: `backend/src/test/java/com/ferreplus/security/LogControllerIntegrationTest.java` (create)
- **Acceptance criteria**: escenarios R2/R9 (consulta) en integración real con H2.

#### T7.4: Modify `LogControllerIntegrationTest` — borrado por rango (200/400/403/conteo/no-auto-audit)
- **Description**: Agregar casos en el mismo `LogControllerIntegrationTest` para `DELETE /api/logs`:
  - 403 sin `LOGS_ELIMINAR` (usuario vendedor posee `LOGS_VER` pero no `LOGS_ELIMINAR`) y 0 filas borradas.
  - 400 sin `desde`/`hasta` (o solo uno) → 0 borrados.
  - 400 `hasta < desde` (rango revertido) → 0 borrados.
  - 400 formato inválido (ej. `abc`) → 0 borrados.
  - 200 con rango `[desde, hasta]` (admin) → `eliminados = N` y las filas **borradas físicamente** de `auditoria`.
  - Rango válido sin registros → 200 `eliminados = 0` (caso normal).
  - **No se auto-audita** (D6): tras el borrado NO existe fila `AUTH`/`LOGIN` nueva ni `LOGS`/`ELIMINAR` en `auditoria` (el borrado no genera su propia fila).
  - Assert no existe `DELETE /api/logs/{id}` (no hay endpoint por fila).
- **Dependencies**: T2.3, T7.1
- **Status**: pending
- **Effort**: L
- **Specialist**: springboot
- **Files**: `backend/src/test/java/com/ferreplus/security/LogControllerIntegrationTest.java` (modify)
- **Acceptance criteria**: escenarios R3/R9 completos (200/400/403/conteo/empty/no-autoaudit).

#### T7.5: Create `AuditoriaInstrumentacionTest` — instrumentación + atomicidad + login
- **Description**: Create `com.ferreplus.service.AuditoriaInstrumentacionTest` (`@SpringBootTest`, H2; `SecurityContextHolder` con usuario admin en `@AfterEach clearContext()`), cubre R4/R5/R10:
  1. Crear un `Producto` vía `ProductoService.create` → 1 fila `PRODUCTO`/`CREAR` con `entidad_id` y `usuario_id` correctos (R4 escenario 1).
  2. Anular una `Venta` vía `VentaService.anular` → fila `VENTA`/`ANULAR` con usuario correcto (R4 escenario 2).
  3. Crear `MovimientoStock` vía `MovimientoStockService.create` → fila `MOVIMIENTO`/`CREAR`.
  4. Operación rechazada (p. ej. crear `Producto` duplicado o `Categoria` duplicada que lanza 400) → sin fila (R4 escenario 3, R10).
  5. `AuthService.login` exitoso (admin/vendedor creado) → fila `AUTH`/`LOGIN` con `entidad_id` y `usuario_id` del mismo usuario (R5 escenario 1); intento con credenciales incorrectas (usa `authenticationManager` que lanza 401) → **no** fila `AUTH` (R5 escenario 2).
- **Dependencies**: T4.1–T4.8, T3.1
- **Status**: pending
- **Effort**: L
- **Specialist**: springboot
- **Files**: `backend/src/test/java/com/ferreplus/service/AuditoriaInstrumentacionTest.java` (create)
- **Acceptance criteria**: instrumentación completa y atomicidad (R4/R5/R10); operaciones rechazadas no dejan fila.

#### T7.6: Full backend test run (B5 exit)
- **Description**: Ejecutar `docker run --rm -v /home/andres/Documents/Andres/Proyectos/ferreplus/backend:/app -w /app maven:3.9-eclipse-temurin-21 mvn test` — verificar que quedan en verde: `LogServiceTest`, `LogControllerIntegrationTest`, `AuditoriaInstrumentacionTest`, drift actualizado, y **todos los preexistentes** (`AuditoriaTest`, `PrecioServiceTest`, `CompraServiceIntegrationTest`, `SecurityEnforcementTest`, etc.). Comprobar `mvn package` (o compilación) OK.
- **Dependencies**: Todas las anteriores
- **Status**: pending
- **Effort**: M
- **Specialist**: ambos
- **Files**: n/a (comandos de build)
- **Acceptance criteria**: backend 100% verde antes de merge y antes de STACK 2.

---

## Phase 8: Verification (STACK 2 exit)

#### T8.1: Frontend build + tests
- **Description**: En `frontend/`: `ng build` (sin NG8001/NG8002, compila el service) y `npm test` (vitest) — `log.service.spec.ts`, `log-list.component.spec.ts` y los specs existentes en verde. El backend (`mvn test`) ya quedó validado en B5.
- **Dependencies**: T5.x, T6.x
- **Status**: done
- **Effort**: M
- **Specialist**: ambos
- **Files**: n/a (comandos)
- **Acceptance criteria**: `npm test` verde (incluye tests previos) + `ng build` limpio.

#### T8.2: Manual end-to-end verification (checklist — regla de oro pre-merge)
- **Description**: Checklist manual con la app corriendo (backend + frontend + BD). Revisar a) con admin (`admin@ferreplus.com`/`admin123`):
  1. Sidebar muestra el item **"Logs"** (tiene `LOGS_VER`) y entra a `/logs` (tabla + filtros).
  2. Filtrar por rango de fecha, `entidad`, `accion`, `usuarioId` y paginar → re-consulta server-side (verificado en `totalElements`).
  3. **Borrar por rango** con `LOGS_ELIMINAR`: seleccionar desde–hasta, ver el rango en diálogo, Confirmar → se muestra `eliminados` y la lista se recarga; Cancelar → nada.
  4. Usuario vendedor (sin `LOGS_VER`): no ve el item Logs y navegación por URL directa a `/logs` es bloqueada; sin `LOGS_ELIMINAR` no ve el botón "Borrar por rango".
  5. Verificación de instrumentación: crear producto/anular venta → filas nuevas en `auditoria` con `entidad`/`entidad_id`/`usuario_id` correctos (vía consulta de logs o BD).
  6. **@PreAuthorize**: GET `/api/logs` 403 con usuario sin `LOGS_VER`; DELETE 403 sin `LOGS_ELIMINAR`; DELETE rango revertido → 400.
  7. Comprobar que `LOGS_VER` y `LOGS_ELIMINAR` se pueden otorgar/quitar desde la UI de roles (matriz) y usuarios (overrides) y aplican al siguiente request sin re-login (R6).
- **Dependencies**: T8.1
- **Status**: pending
- **Effort**: L
- **Specialist**: ambos
- **Files**: n/a
- **Acceptance criteria**: sin la verificación manual (incluida la no-auditoría del borrado y la irreversibilidad del rango) NO se mergea; es la regla de oro del design.

---

## Dependency Graph Summary

```
STACK 1 — BACKEND
  Phase 1: T1.1 (AuditService overload) ─ T1.2 (repo+EntityGraph+bulk) ─ T1.3 (DTOs) ─ T1.4 (indices script)
        │
  Phase 2: T2.1 (LogServiceTest RED) ─→ T2.2 (LogService GREEN, ←T1.1,T1.2) ─→ T2.3 (LogController, ←T2.2)
        │
  Phase 3: T3.1 (DataSeeder LOGS ⚠️ batch con T7.1/T7.2)
        │
  Phase 4: T4.1–T4.8 (instrumentación 9 services + login, ←T2.3/T1.1)
        │
  Phase 7 (tests): T7.1 (drift 44/71) + T7.2 (seeder 14/44/71) [batch con T3.1]
                    T7.3/T7.4 (LogControllerIntegrationTest, ←T2.3)  T7.5 (instrumentación, ←T4.x)
                    T7.6 (mvn test full green)
        │  [exit: mvn test 100% verde → STOP → review/commit del usuario]

STACK 2 — FRONTEND
  Phase 5: T5.1 (models) → T5.2 (rutas-por-permiso) → T5.3 (app-routing, ←T6.2 logs.module)
  Phase 6: T6.1 (log.service + spec) → T6.2 (logs.module+routing) → T6.3 (log-list tabla server-side + spec)
            T6.4 (borrado por rango + diálogo + casos en spec)
        │
  Phase 8 (verif): T8.1 (ng build + npm test)  T8.2 (checklist manual)
        │  [exit: npm test verde + checklist manual aprobado → STOP → review/commit del usuario]
```

**Orden de ejecución**: **STACK 1 (B1→B2→B3→B4→B5) → STOP → review/commit del usuario → STACK 2 (F1→F2→F4) → STOP → review/commit del usuario.**

**Nota TDD (strict)**: `T2.1` (RED) escribe `LogServiceTest` ANTES de `T2.2` (GREEN `LogService`) — lógica pura de spec/filtros/validación. Los tests de integración (Phase 7) requieren el stack completo por naturaleza. **El drift test y el seeder seed-count test se actualizan en el MISMO batch que el cambio de `DataSeeder` (T3.1 + T7.1/T7.2)** — si el seeder cambia sin los tests, `PreAuthorizeDriftTest` y `DataSeederIdempotencyTest` fallarán. Frontend: `log.service.spec.ts` y `log-list.component.spec.ts` se escriben en el mismo batch de su feature (vitest infra existente).

---

## Review Workload Forecast (entregable por stacks)

> **Entregable por stacks — el usuario revisa y commitea; el agente no ejecuta git.** El cambio se entrega en **2 stacks**, no en PRs encadenadas. Cada stack termina con un **STOP** para review + commit manual del usuario.

### Estimated Changed Lines

| Stack | Fases (tandas) | Files Changed | Est. Líneas Nuevas | Est. Líneas Modificadas | Total Est. |
|-------|----------------|---------------|--------------------|-------------------------|------------|
| **STACK 1 — BACKEND** (B1-B5) | Phase 1 (T1.1-T1.4) + Phase 2 (T2.x) + Phase 3 (T3.1) + Phase 4 (T4.1-T4.8) + Phase 7 (T7.x) | ~23 (8 nuevos + 15 modificados) | ~915 (AuditoriaDTO 55, LogsEliminadosDTO 20, LogService 130, LogController 70, script 12, + 3 tests ~630) | ~365 (AuditService +20, Repository +35, DataSeeder +8, 9 services × ~30, AuthService +15, 2 tests count +10) | **~1,280** |
| **STACK 2 — FRONTEND** (F1-F4) | Phase 5 (T5.1-T5.3) + Phase 6 (T6.1-T6.4) + Phase 8 (T8.x) | ~11 (8 nuevos + 3 modificados) | ~750 (module 30, routing 15, service 75, service spec 100, log-list ts 200 + html 70 + scss 40, spec 220) | ~35 (models +25, rutas +1, routing +8) | **~785** |
| **Total** | | **~34 files** | **~1,665** | **~400** | **~2,065** |

Detalle de complejidad: 4 archivos backend nuevos (`LogService`, `LogController`, `AuditoriaDTO` y `LogsEliminadosDTO`) son donde se concentra la lógica (Specifications + validación de rango + `@Modifying`); la instrumentación (T4.x) es mecánica pero toca 10 archivos (inyección del helper `ObjectMapper` + llamada por método).

### Review Budget Risk Assessment (budget de esta sesión: 400 líneas)

| Risk | Assessment |
|------|------------|
| **Total vs budget** | 🔴 **HIGH RISK** — ~2,065 líneas ≈ **5×** el presupuesto de 400 líneas. |
| **STACK 1 BACKEND solo** | 🔴 ~1,280 líneas — excede el presupuesto por sí solo (~3.2×). |
| **STACK 2 FRONTEND solo** | 🔴 ~785 líneas — excede el presupuesto (~2×). |

### Límites de entrega (2 stacks — decisión del usuario)

**`Chained PRs recommended: No`** — la entrega NO es por PR; el usuario decidió **2 stacks** (sin operaciones git del agente):

1. **STACK 1 — BACKEND COMPLETO** (~1,280 líneas / ~23 files): tandas **B1** (Foundation) → **B2** (Core logs) → **B3** (Seed) → **B4** (Instrumentación) → **B5** (Tests).
   - **Exit criteria**: `mvn test` (Docker) 100% verde → **STOP y notificar al usuario para review + commit** antes de STACK 2.
   - Racional: el backend es autocontenido (catálogo, endpoint, instrumentación, tests) y define el contrato `Page`/`{eliminados}` que consume el frontend.
2. **STACK 2 — FRONTEND COMPLETO** (~785 líneas / ~11 archivos): tandas **F1** (Foundation) → **F2** (Logs module) → **F4** (Verificación).
   - **Exit criteria**: `ng build` limpio + `npm test` verde + checklist manual T8.2 aprobado → **STOP y notificar al usuario para review + commit final**.
   - Nota: la parte `mvn test` ya validada en B5.

### Decision Needed Before Apply

**`Decision needed before apply: Yes`**

1. ~~Confirmar estrategia de PRs encadenadas~~ → **DECIDIDO por el usuario**: entrega por **2 stacks** (BACKEND → FRONTEND); el agente no ejecuta git; el usuario revisa y commitea tras cada stack.
2. **Open question del design — índice**: confirmar si `indices-auditoria.sql` se aplica en esta entrega o queda solo documentado (DTO). Se incluye el script pero **no se ejecuta** (regla BD: solo SELECT/script revisado).
3. **Open question del design — filtro `entidad` del front**: select estático de entidades singulares vs input libre / endpoint `SELECT DISTINCT entidad`. Por KISS se usa select/texto; validar en demo (no se agrega endpoint).
4. **Tamaño de página por defecto** — `size=20` / `pageSizeOptions` de la UI (se adopta 20; ajustable).

---

## Checkpoints clave que no deben olvidarse

- **⚠️ Drift test / seeder**: `PreAuthorizeDriftTest` (44/71) y `DataSeederIdempotencyTest` (14/44/71) DEBEN actualizarse en el **mismo batch** que `DataSeeder` (T3.1 + T7.1/T7.2) o el stack B5 falla en `mvn test`. La allowlist NO se modifica (`LOGS_VER`/`LOGS_ELIMINAR` referenciados en `LogController`).
- **Ranges delete edge cases**: `DELETE /api/logs` cubre 400 (params faltantes/`hasta < desde`/formato inválido — no borra), 403 sin `LOGS_ELIMINAR` (no borra), 200 + `eliminados` y **borrado físico** comprobado, rango vacío → `eliminados=0`, **no se auto-audita** (D6), y **no hay delete por fila individual**.
- **@EntityGraph en `findAll(spec, Pageable)`** anti N+1 (usuario LAZY).
- **Bulk delete single-statement** (`borrarPorRango`) con `clearAutomatically`/`flushAutomatically` — no iterar.
- **Login override con usuario explícito** (el `SecurityContext` aún no está actualizado durante `login()`).
- **`entidad` singular** en instrumentación y en el filtro del frontend (mapear label → singular; `VENTA` no `VENTAS`).
- **Irreversibilidad del borrado por rango**: solo ADMIN por defecto (`LOGS_ELIMINAR`), confirmación obligatoria en UI; es IRREVERSIBLE (filas no recuperables salvo backup/replicación Postgres).