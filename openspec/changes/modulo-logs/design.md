# Design: Módulo de Logs de Actividades del Sistema

## Technical Approach

Se construye la **capa de consulta y administración** de la tabla genérica `auditoria` sobre la infraestructura ya existente y probada del change `modulo-roles-permisos` (entity `Auditoria`, `AuditService` con `Propagation.MANDATORY`, catálogo de permisos con matriz, `@EnableMethodSecurity` + `@PreAuthorize`). El enfoque es **conservador y sin migración de esquema** (Decisión D1 confirmada): no se agrega columna `modulo` ni se reconstruye nada; el "dónde" es la columna `entidad` ya existente.

Lo que este change **agrega**:

1. **Módulo LOGS (14º) en `DataSeeder`** con dos permisos: `LOGS_VER` (consulta) y `LOGS_ELIMINAR` (borrado por rango). Matriz: **ADMIN recibe ambos**; VENDEDOR/BODEGUERO ninguno por defecto. Catálogo pasa a **14 módulos / 44 permisos / 71 pares**.
2. **`LogController`** con:
   - `GET /api/logs` paginado server-side + filtros (`fechaDesde`, `fechaHasta`, `usuarioId`, `usuarioNombre`, `entidad`, `accion`), protegido con `LOGS_VER`, devuelve `Page<AuditoriaDTO>`.
   - `DELETE /api/logs?desde=&hasta=` **bulk delete** por rango de fechas, protegido con `LOGS_ELIMINAR`, devuelve `{ "eliminados": N }`. No se auto-audita (excepción D6).
3. **`AuditoriaRepository`**: consulta paginada vía `JpaSpecificationExecutor` + método de borrado masivo `@Modifying @Query DELETE ... BETWEEN`.
4. **Instrumentación del resto del sistema** (9 services) + **login exitoso**, siguiendo el patrón `AuditService.registrarEvento(...)` ya usado en `UsuarioService`/`RolService`.
5. **UI Angular** feature module `logs/` (NgModule, NO standalone — patrón del proyecto; el especialista Angular asume standalone pero `config.yaml` fija "feature modules, NO standalone"), con tabla paginada **server-side**, filtros, y **borrado por rango** con `*appHasPermission('LOGS_ELIMINAR')` y diálogo de confirmación.
6. **Tests**: actualización del drift test (**44 permisos / 71 pares**) + tests de consulta/borrado/seguridad/instrumentación.

Las especificaciones (spec.md) definen 10 requerimientos (R1-R10) con 32 escenarios. Este diseño cubre todos.

## Architecture Decisions

### Decision: Consulta paginada con filtros vía `JpaSpecificationExecutor` + `Specification` dinámica (con `@EntityGraph` anti-N+1)

**Choice**: `AuditoriaRepository` extiende `JpaRepository<Auditoria, Long>` **y** `JpaSpecificationExecutor<Auditoria>`. Se re-declara `findAll(Specification<Auditoria>, Pageable)` con `@EntityGraph(attributePaths = "usuario")`. `LogService` construye una `Specification<Auditoria>` a partir de los filtros **opcionales** (`fechaDesde`, `fechaHasta`, `usuarioId`, `usuarioNombre`, `entidad`, `accion`) y la combina con el `Pageable`.

**Refinamiento post-verificación (filtro por nombre)**: `usuarioNombre` es un **contiene case-insensitive** sobre `auditoria.usuario.nombre` (`cb.like(cb.lower(root.get("usuario").get("nombre").as(String.class)), "%" + valor.trim().toLowerCase() + "%")`), no un match por id. Se ignora si viene `null`/vacío/whitespace y se combina con **AND** con `usuarioId` cuando ambos se pasan. `usuarioId` sigue funcionando (filtro por igualdad).

**Alternatives considered**:
- `@Query` con `WHERE` dinámico y parámetros opcionales (`:desde IS NULL OR a.fecha >= :desde`): funciona pero genera consultas menos legibles/óptimas con `OR ... IS NULL` y duplica el SQL por cada combinación de filtros.
- Métodos derivados (`findByFechaBetweenAndEntidad...`): número combinatorio de firmas para 5 filtros opcionales → inaceptable.
- Traer sin paginar (`List`): descartado — volumen alto de la tabla de auditoría.

**Rationale**: `JpaSpecificationExecutor` es el patrón Spring Data estándar para **filtros dinámicos con nulos** (cada predicado se agrega solo si el filtro viene), exactamente lo que pide R2 (filtros todos opcionales). Es el enfoque del especialista Spring Boot ("paginá listados con Pageable"). `@EntityGraph("usuario")` evita N+1 al mapear `auditoria.usuario` → `usuarioNombre` dentro de la `Page` (la relación es LAZY; sin el graph cada fila dispara una consulta al resolver el nombre del usuario).

### Decision: `AuditoriaDTO` — `detalle` como string JSON crudo

**Choice**: `AuditoriaDTO` (clase con getters/setters manuales, convención del proyecto) con campos `id`, `entidad`, `entidadId`, `accion`, `usuarioId`, `usuarioNombre`, `fecha`, `detalle`. El campo `detalle` **se expone tal cual** (String; puede ser un JSON serializado o texto plano).

**Refinamiento post-verificación (formato del detalle)**: las operaciones `ACTUALIZAR` guardan el **diff solo de los campos que cambiaron**, con forma `{"campo": {"antes": X, "despues": Y}}`, calculado con el helper `com.ferreplus.util.AuditDiff` (snapshot del objeto ANTES de mutar, diff tras el save). `CREAR` conserva el snapshot completo; `ELIMINAR`/`ANULAR` conservan el registro eliminado/anulado. `VentaService` no tiene `update()` → la forma diff no aplica.

**Alternatives considered**: parsear `detalle` a objeto Jackson en el DTO.

**Rationale**: La spec permite que `detalle` sea texto o JSON (edge case 9) y el módulo de consulta **no depende del formato**. Exponerlo crudo mantiene la capa de consulta **agnóstica al contenido**; el **frontend** lo formatea en la presentación con `detalle.util.ts` (`parsearDetalle`/`formatearDetalle`: diff → "campo: antes → despues", snapshot → "campo: valor", JSON inválido → raw, `null` → `—`). **Cautela PII**: el `detalle` puede contener nombres, montos y campos transaccionales; se muestra tal cual, sin exportación ni descarga (fuera de alcance).

### Decision: Contrato del DELETE — rango `yyyy-MM-dd` o `yyyy-MM-dd'T'HH:mm:ss`, inclusivo `[desde, hasta]`, respuesta `200 + {eliminados: N}`, parse `LocalDate→LocalDateTime` (startOfDay / endOfDay)

**Choice**:
- Query params **obligatorios**: `desde` y `hasta`, aceptados en **dos formatos**: `yyyy-MM-dd` (ISO date) o `yyyy-MM-dd'T'HH:mm:ss` (ISO datetime).
  - Fecha sola (`yyyy-MM-dd`) → `desde` se expande a `LocalDate.parse(s).atStartOfDay()`; `hasta` se expande a `LocalDate.parse(s).atTime(LocalTime.MAX)` → rango **inclusivo** de día completo.
  - Datetime ISO → se usa tal cual (inclusive).
- Validación en `LogService.eliminarPorRango` (lanza `BadRequestException`):
  - `desde` o `hasta` ausentes/vacíos → **400**.
  - formato no parseable → **400**.
  - `hasta < desde` (revertido) → **400**.
  - Ninguno borra nada.
- Respuesta: **HTTP 200** con cuerpo `{ "eliminados": N }` (`LogsEliminadosDTO`).

**Alternatives**: `204` + header con el conteo; `204` sin cuerpo; parsear solo `LocalDateTime` estricto.
**Rationale**: La spec permite "200 + body" o "204 + header". Se elige **200 + `{ "eliminados": N }`** porque el conteo **queda accesible** naturalmente para el frontend (R3: "el conteo debe quedar accesible") sin leer headers, y es coherente con el estilo de respuestas JSON del proyecto. Parse dual resuelve el caso de la UI con `MatDatepicker` de día (`yyyy-MM-dd`), evitando el bug clásico "hasta=2026-01-31T00:00" que salta el día 31; usa la expansión `startOfDay/endOfDay` igual al patrón `VentaService`/`CompraService`/`MovimientoStockService.listByFecha`.

### Decision: Bulk delete `@Modifying @Query DELETE ... WHERE fecha BETWEEN` + `@Transactional` + `clearAutomatically`/`flushAutomatically`

**Choice**: en `AuditoriaRepository`:
```java
@Modifying(clearAutomatically = true, flushAutomatically = true)
@Query("DELETE FROM Auditoria a WHERE a.fecha BETWEEN :desde AND :hasta")
int borrarPorRango(@Param("desde") LocalDateTime desde, @Param("hasta") LocalDateTime hasta);
```
`LogService.eliminarPorRango` está anotado `@Transactional` (el `@Modifying` exige transacción) y devuelve el `int` del conteo de filas afectadas que emite la JPQL.

**Alternatives**: método derivado `deleteByFechaBetween` (Spring Data itera y borra fila a fila → N statements y carga en memoria) — descartado; `findAll` + `delete` en loop — descartado.
**Rationale**: el borrado masivo es el caso "tabla infinita": un **solo statement** SQL, sin materializar filas. `clearAutomatically=true` limpia el persistence context (evita entidades stale) y `flushAutomatically=true` fuerza flush antes del DELETE. Devuelve el conteo real.

### Decision: Sin auto-auditoría del borrado masivo (excepción consciente D6)

**Choice**: `DELETE /api/logs` **no** registra fila de auditoría propia.
**Rationale**: auditar un bulk delete de logs es contradictorio (la fila "se borraron N logs" caería dentro del rango eliminado). Excepción documentada y aceptada (sin trazabilidad en `auditoria` de quién borró). Mitigación: `LOGS_ELIMINAR` restrictivo (solo ADMIN por defecto) + evidencia en logs de aplicación/BD. La fila sumaria fuera del rango se descarta por confusión y fila huérfana.

### Decision: Instrumentación con `entidad` SINGULAR vs códigos de módulo PLURAL

**Choice**: la instrumentación nueva usa `entidad` en **singular** (`PRODUCTO`, `CATEGORIA`, `PROVEEDOR`, `CLIENTE`, `VENTA`, `COMPRA`, `PRECIO`, `MOVIMIENTO`, `GASTO`, `AUTH`), coincidiendo con la convención ya existente en `auditoria` (`USUARIO`, `ROL` — singular aunque los códigos de catálogo son `USUARIOS`, `ROLES`).

**Rationale / advertencia de coherencia**: la spec texto dice "entidad = código de módulo en mayúsculas" pero la tabla real ya contiene `USUARIO`/`ROL` en singular. Instrumentar con singular evita migrar datos existentes y mantiene un criterio único. **Implicación para el filtro**: el filtro `GET /api/logs?entidad=` opera sobre el valor **singular** ya en la columna (p. ej. `VENTA`), NO sobre el código plural `VENTAS`. El frontend mapea la etiqueta del módulo (label "Ventas") al valor `entidad` singular (`"VENTA"`), o usa el campo `entidad` como texto/select. No se agrupan sub-entidades (D1: no es requerido hoy).

### Decision: Instrumentación del dominio — set pragmático (9 services) + login; no generan registro las operaciones rechazadas

**Choice**: se inyecta `AuditService` y se invoca `registrarEvento(...)` como **última línea** de cada operación de escritura exitosa (tras `save`), con `Propagation.MANDATORY`. Set completo del dominio. `ReporteService` (read-only) NO se instrumenta.

**Rationale**: R4 exige instrumentar los 9 services de escritura. El patrón es idéntico a `UsuarioService.create`/`RolService.create`: `save()` → audit. Como `AuditService` exige `MANDATORY` y los services de dominio son `@Transactional` a nivel de clase, el registro comparte la transacción: operación rechazada (400/404/stock) lanza antes del registro → sin fila; si el registro falla, la operación completa revierte (R10).

### Decision: Login auditado con usuario explícito (overload en `AuditService`)

**Choice**: `AuditService` agrega un **overload** `registrarEvento(String entidad, Long entidadId, String accion, String detalle, Usuario usuario)` que usa el usuario pasado como actor. `AuthService.login()` llamado. No se audita el fallo.

**Rationale**: R5 exige que `usuario_id` del `LOGIN` = usuario autenticado; pero dentro de `login()` el `SecurityContextHolder` aún **no se ha actualizado**, así que `usuarioActual()` devolvería null. Pasar el usuario explícito garantiza el actor. Solo se registra el login exitoso (evita volumen y PII). `AuthService` es `@Transactional` a nivel de clase → `MANDATORY` funciona.

### Decision: Frontend NgModule (NO standalone) + Reactive Forms; tabla server-side

**Choice**: feature module `logs/` NgModule no-standalone (igual `roles/`), Reactive Forms (FormBuilder) para los filtros, MatTable + **MatPaginator server-side** (re-consulta al backend en cada `PageEvent`; NO `MatTableDataSource.filter` client-side), MatDialog para el borrado por rango (MatDatepicker + confirmación), y `*appHasPermission('LOGS_ELIMINAR')` para ocultar el botón.

**Decision**: patrón del proyecto (`config.yaml`: "NgModule, feature modules, NO standalone"; Reactive Forms). El especialista Angular recomienda standalone/signals, pero la regla es seguir los patrones existentes salvo que el change los aborde. La **server-side pagination** es obligatoria por volumen (se rompe deliberadamente la convención de los demás listados que filtran in-memory).

## Refinements post-verificación (aprobados por el usuario e implementados)

Tres refinamientos aprobados tras la verificación del módulo, ya implementados en backend y frontend. Los cambios a las decisiones existentes (D2, D3) y al plan de archivos están marcados en cada sección; este bloque los resume:

1. **Filtro por nombre de usuario (`usuarioNombre`)** — `GET /api/logs` acepta el query param opcional `usuarioNombre`: CONTAINS case-insensitive (`LIKE %valor%`) sobre `auditoria.usuario.nombre` (vía el `@EntityGraph` existente). `usuarioId` sigue funcionando; ambos se combinan con AND; `null`/vacío/whitespace se ignora. En el frontend el filtro pasó de input numérico "Usuario ID" a input de TEXTO "Usuario" (`formControl usuarioNombre`); `LogFiltros.usuarioId` fue reemplazado por `usuarioNombre: string | null` (se envía `trim()` si no vacío).
2. **Columnas de la tabla** — el header "ID" pasó a llamarse "ID Entidad" (muestra `entidadId`, el id del registro afectado); se agregó la columna "ID Usuario" (`usuarioId`, fallback `—`); "Usuario" (`usuarioNombre`) se mantiene. `displayedColumns = ['entidad', 'entidadId', 'accion', 'usuarioId', 'usuarioNombre', 'fecha', 'detalle']`.
3. **`detalle` de `ACTUALIZAR` = diff ANTES/DESPUES + presentación formateada** — las filas `ACTUALIZAR` guardan SOLO los campos cambiados como `{"campo": {"antes": X, "despues": Y}}` vía `com.ferreplus.util.AuditDiff` (aplicado a `ProductoService`, `CategoriaService`, `ProveedorService`, `ClienteService`, `CompraService`, `PrecioService`, `GastoService`; `VentaService` no tiene `update()` → no aplica). `CREAR` conserva snapshot; `ELIMINAR`/`ANULAR` conservan el registro. El `detalle` sigue siendo string JSON crudo en la API; el frontend lo formatea con `frontend/src/app/logs/detalle.util.ts` (`parsearDetalle` + `formatearDetalle`: "campo: antes → despues", snapshot "campo: valor", JSON inválido → raw, `null` → `—`).

## Data Flow

### Flujo 1: Consulta paginada/filtrada (GET)

```
GET /api/logs?page=0&size=20&fechaDesde=2026-01-01&entidad=VENTA&accion=CREAR
  │ (Bearer, hasAuthority('LOGS_VER'))
  └─→ LogController.consultar(...)
        └─→ LogService.consultar(fechaDesde, fechaHasta, usuarioId, entidad, accion, pageable)
              ├─→ buildSpec(...)                        // Specification opcional
              └─→ auditoriaRepository.findAll(spec, PageRequest pageable)
                    [@EntityGraph("usuario") → 1 paginada + count, sin N+1]
                    → Page<Auditoria> ──map→ Page<AuditoriaDTO>
        └─→ HTTP 200 Page JSON { content:[...], totalElements, totalPages, ... }
```

### Flujo 2: Borrado por rango (DELETE)

```
DELETE /api/logs?desde=2026-01-01&hasta=2026-01-31
  (Bearer, hasAuthority('LOGS_ELIMINAR'))
  └─→ LogController.deleteLogs(desde, hasta)
        └─→ LogService.eliminarPorRango(desde, hasta)   [@Transactional]
              ├─ parseDesde / parseHasta (LocalDate→startOfDay/endOfDay ; o datetime ISO)
              ├─ validar: ausente/vacío → 400, inválido → 400, hasta<desde → 400
              └─→ auditoriaRepository.borrarPorRango(desde, hasta)   [@Modifying DELETE BETWEEN]
                    → int filas
        └─→ 200 { "eliminados": N }        (NO se auto-audita)
```

### Flujo 3: Instrumentación de una operación de dominio (patrón reutilizado)

```
POST /api/ventas          (usuario con VENTAS_CREAR)
  └─→ VentaService.create(dto)   [@Transactional]
        ├─ save(venta) + actualizarStock × detalle
        └─→ auditService.registrarEvento("VENTA", venta.id, "CREAR", jsonDetalle)   ← última línea, MISMA tx
              (si stock insuficiente → BadRequestException antes del registro → sin fila y rollback completo)
```

## Interfaces / Contracts

### LogController (`/api/logs`)

```java
@RestController
@RequestMapping("/api/logs")
@CrossOrigin(origins = "http://localhost:4200")
@RequiredArgsConstructor
public class LogController {
    private final LogService logService;

    @GetMapping
    @PreAuthorize("hasAuthority('LOGS_VER')")
    public ResponseEntity<Page<AuditoriaDTO>> consultar(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String fechaDesde,
            @RequestParam(required = false) String fechaHasta,
            @RequestParam(required = false) Long usuarioId,
            @RequestParam(required = false) String entidad,
            @RequestParam(required = false) String accion) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "fecha"));
        return ResponseEntity.ok(logService.consultar(fechaDesde, fechaHasta, usuarioId, entidad, accion, pageable));
    }

    @DeleteMapping
    @PreAuthorize("hasAuthority('LOGS_ELIMINAR')")
    public ResponseEntity<LogsEliminadosDTO> eliminarLogs(
            @RequestParam String desde,
            @RequestParam String hasta) {
        return ResponseEntity.ok(new LogsEliminadosDTO(logService.eliminarPorRango(desde, hasta)));
    }
}
```

### AuditoriaRepository

```java
public interface AuditoriaRepository
        extends JpaRepository<Auditoria, Long>, JpaSpecificationExecutor<Auditoria> {

    @Override
    @EntityGraph(attributePaths = "usuario")
    Page<Auditoria> findAll(Specification<Auditoria> spec, Pageable pageable);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("DELETE FROM Auditoria a WHERE a.fecha BETWEEN :desde AND :hasta")
    int borrarPorRango(@Param("desde") LocalDateTime desde, @Param("hasta") LocalDateTime hasta);
}
```

### LogService

```java
@Service
@RequiredArgsConstructor
public class LogService {
    private final AuditoriaRepository auditoriaRepository;

    @Transactional(readOnly = true)
    public Page<AuditoriaDTO> consultar(String fechaDesde, String fechaHasta,
                                        Long usuarioId, String entidad, String accion,
                                        Pageable pageable) {
        Specification<Auditoria> spec = Specification.where(null);
        LocalDateTime desde = parseDesde(fechaDesde);   // o null sin filtro
        LocalDateTime hasta = parseHasta(fechaHasta);
        if (desde != null) spec = spec.and((r, q, cb) -> cb.greaterThanOrEqualTo(r.get("fecha"), desde));
        if (hasta != null) spec = spec.and((r, q, cb) -> cb.lessThanOrEqualTo(r.get("fecha"), hasta));
        if (usuarioId != null) spec = spec.and((r, q, cb) -> cb.equal(r.get("usuario").get("id"), usuarioId));
        if (entidad != null)  spec = spec.and((r, q, cb) -> cb.equal(r.get("entidad"), entidad.trim().toUpperCase()));
        if (accion  != null)  spec = spec.and((r, q, cb) -> cb.equal(r.get("accion"), accion.trim().toUpperCase()));
        return auditoriaRepository.findAll(spec, pageable).map(this::toDTO);
    }

    @Transactional
    public int eliminarPorRango(String desde, String hasta) {
        LocalDateTime ds = parseDate(desde, true);    // startOfDay o datetime
        LocalDateTime hs = parseDate(hasta, false);   // endOfDay o datetime
        // parseDate lanza BadRequestException si ausente/vacío/formato inválido
        if (hs.isBefore(ds)) throw new BadRequestException(
                "El rango de fechas es inválido: 'hasta' es anterior a 'desde'");
        return auditoriaRepository.borrarPorRango(ds, hs);
    }

    private AuditoriaDTO toDTO(Auditoria a) { /* usuarioId/usuarioNombre nullable */ }
}
```

#### Semántica de parse (consistente consulta y borrado)

| Entrada | `desde` (lím. inf) | `hasta` (lím. sup) |
|---|---|---|
| `yyyy-MM-dd` | `LocalDate.parse(s).atStartOfDay()` | `LocalDate.parse(s).atTime(LocalTime.MAX)` |
| `yyyy-MM-dd'T'HH:mm:ss` | `LocalDateTime.parse(s)` | `LocalDateTime.parse(s)` |
| ausente / vacío / inválido | null (GET) o `400` (DELETE) | null (GET) o `400` (DELETE) |

Los filtros GET admiten la misma expansión de día para mantener consistencia con el borrado.

### DTO de respuesta de borrado

```java
public class LogsEliminadosDTO {
    private int eliminados;
    // getters/setters
}
```
Respuesta `200 { "eliminados": N }`.

### No se expone la entidad JPA
Solo se devuelve `AuditoriaDTO` (nunca `Auditoria`).

## Seed Matrix (R1)

### `DataSeeder` — catálogo LOGS

```java
MODULOS.put("LOGS", new int[]{14, 1, 0, 0, 1});   // orden 14; VER | CREAR=0 | EDITAR=0 | ELIMINAR=1
NOMBRES_MODULO.put("LOGS", "Logs");
```
→ genera `LOGS_VER` ("Ver logs") y `LOGS_ELIMINAR` ("Eliminar logs"). **No** genera `LOGS_CREAR`/`LOGS_EDITAR`.

### Matriz de roles

```java
// ADMIN (42 → 44):
"...", "REPORTES_VER",
"LOGS_VER", "LOGS_ELIMINAR"      // agregadas solo a ADMIN

// VENDEDOR (9) y BODEGUERO (18): sin cambios (sin LOGS por defecto; override vía UI/roles)
```
Conteos: catálogo 42→**44**; pares 69→**71** (ADMIN 44 + VENDEDOR 9 + BODEGUERO 18).

### Idempotencia
Consulta antes de insertar por código y por (rol, permiso) → doble ejecución sin duplicar `LOGS_VER`/`LOGS_ELIMINAR` ni pares. El seed no escribe auditoría (bootstrap).

## Security Design

**Sin cambios estructurales en `SecurityConfig`**: se mantiene `@EnableMethodSecurity`, `permitAll` para `/api/auth/**` y swagger/scalar, y `anyRequest().authenticated()`. `/api/logs` (GET y DELETE) cae bajo `authenticated()` y el enforcement fino va en las anotaciones del `LogController`.

| Endpoint | Anotación |
|---|---|
| `GET /api/logs` | `hasAuthority('LOGS_VER')` |
| `DELETE /api/logs` | `hasAuthority('LOGS_ELIMINAR')` |

## Data Model

**Sin migración de esquema**. `auditoria` se mantiene:
```
auditoria(id PK, entidad, entidad_id, accion, usuario_id FK→usuarios NULL, fecha, detalle TEXT)
```
No se agrega columna. `a.usuario` es `@ManyToOne(LAZY)` → `@EntityGraph` en la consulta.

### Índice recomendado (script revisado por el usuario, NO ejecutado)

Archivo nuevo `backend/src/main/resources/db/indices-auditoria.sql`:
```sql
-- Módulo de Logs — índices para filtrado y borrado por rango sobre auditoría.
-- NO los crea ddl-auto:update; aplicarse manualmente tras revisión.
CREATE INDEX IF NOT EXISTS idx_auditoria_fecha ON auditoria (fecha);
CREATE INDEX IF NOT EXISTS idx_auditoria_entidad_fecha ON auditoria (entidad, fecha);
```
No se autoejecuta (regla de BD: solo SELECT/script revisado por el usuario; fuera del auto-migración).

## Instrumentation Plan (entidad × detalle por servicio)

Convención: `entidad` = **singular** (Decisión 5). `accion`: verbos libres (`CREAR`/`ACTUALIZAR`/`ELIMINAR`/`ANULAR`/`LOGIN`). `detalle` = JSON corto con `ObjectMapper`, fallback a texto si falla.

| Servicio (método) | entidad | accion | entidad_id | detalle (ej.) |
|---|---|---|---|---|
| `ProductoService.create` | `PRODUCTO` | CREAR | prod.id | `{"codigoBarras":"...","nombre":"..."}` |
| `ProductoService.update` | `PRODUCTO` | ACTUALIZAR | prod.id | `{"nombre":"..."}` |
| `ProductoService.delete` (soft) | `PRODUCTO` | ELIMINAR | prod.id | `{"nombre":"...","activo":false}` |
| `CategoriaService.{create,update,delete}` | `CATEGORIA` | CREAR/ACTUALIZAR/ELIMINAR | id | `{"nombre":"..."}` |
| `ProveedorService.{create,update,delete}` | `PROVEEDOR` | ídem | id | `{"nombre":"..."}` |
| `ClienteService.{create,update,delete}` | `CLIENTE` | ídem | id | `{"nombre":"...","ruc":"..."}` |
| `VentaService.create` | `VENTA` | CREAR | venta.id | `{"numeroFactura":"FV-...","total":...}` |
| `VentaService.anular` | `VENTA` | ANULAR | venta.id | `{"numeroFactura":"..."}` |
| `CompraService.create` / `update` | `COMPRA` | CREAR / ACTUALIZAR | compra.id | `{"numeroFactura":"FC-..."}` |
| `CompraService.anular` | `COMPRA` | ANULAR | compra.id | `{"numeroFactura":"..."}` |
| `PrecioService.actualizarPrecioVenta` | `PRECIO` | ACTUALIZAR | producto.id | `{"precioVenta":...,"margen":...}` |
| `MovimientoStockService.create` | `MOVIMIENTO` | CREAR | mov.id | `{"productoId":...,"tipo":"ENTRADA"}` |
| `GastoService.{create,update,delete}` | `GASTO` | ídem | id | `{"descripcion":"...","monto":...}` |
| `AuthService.login` (exitoso) | `AUTH` | LOGIN | usuario.id | `null` (usuario explícito) |

Notas:
- **No instrumenta** `ReporteService` (read-only) ni `ProductoService.actualizarStock` (helper interno invocado por venta/compra/movimiento ya auditadas por su servicio "dueño" — evita ruido/duplicados).
- Cada servicio agrega `private final AuditService auditService;` (Lombok `@RequiredArgsConstructor`) + helper `jsonDetalle(...)` con `ObjectMapper` (patrón ya en `UsuarioService`/`RolService`).
- Operaciones rechazadas (validación, stock insuficiente, ya anulada, 409) lanzan antes del `registrarEvento` → sin fila.

## Frontend Design

### Estructura nueva

```
frontend/src/app/logs/
├── logs.module.ts
├── logs-routing.module.ts      # '' → LogListComponent
├── log.service.ts              # list(params) + deleteByRange(desde,hasta)
└── log-list/
    ├── log-list.component.{ts,html,scss}
    └── log-list.component.spec.ts   (vitest)
```

### `log.service.ts`
```ts
list(p: { page: number; size: number; fechaDesde?; fechaHasta?; usuarioId?; entidad?; accion? })
  : Observable<Page<AuditoriaLog>>            // GET `${apiUrl}/logs` con HttpParams (omitir vacíos)
deleteByRange(desde: string, hasta: string): Observable<EliminarLogsResponse>  // DELETE `/logs?desde=&hasta=`
```

### `log-list` (server-side)
- Tabla server-side: `data: AuditoriaLog[]` + `@ViewChild(MatPaginator)` con `(page)` → re-consulta `list({page: event.pageIndex, size: event.pageSize, filtros})`. Sin `MatTableDataSource.filter`.
- Columnas: `entidad`, `entidadId`, `accion`, `usuarioNombre`, `fecha`, `detalle` (render `<pre>` con texto crudo).
- Filtros (Reactive): `fechaDesde`, `fechaHasta` (MatDatepicker), `usuarioId` (input numérico), `entidad` (select de entidades singulares o texto), `accion` (select `CREAR/ACTUALIZAR/ELIMINAR/ANULAR/LOGIN` o texto). "Aplicar" re-consulta pág. 0. (No depende de `USUARIOS_VER` para listar usuarios: `usuarioId` es input directo.)
- Botón "Borrar por rango" visible solo con `*appHasPermission="'LOGS_ELIMINAR'"` → MatDialog con 2 `Datepicker` (desde/hasta) + confirmación. Cancelar → no llama; Confirmar → `deleteByRange(desde,hasta)` → muestra `Swal` con `eliminados` → recarga.
- Sin borrado por fila individual.

### Routing / sidebar
- `app-routing.module.ts`: ruta `/logs` lazy con `canActivate:[AuthGuard]` + `data: { permissions: permisosDeRuta('/logs') }`.
- `rutas-por-permiso.ts`: `{ label:'Logs', icon:'receipt_long', route:'/logs', permissions:['LOGS_VER'] }`.
- `models.ts`: `AuditoriaLog`, `Page<T>`, `EliminarLogsResponse`.

## File Changes

### Backend — nuevos
| Archivo | Descripción |
|---|---|
| `backend/.../controller/LogController.java` | GET paginado/filtrado + DELETE por rango |
| `backend/.../service/LogService.java` | Specification + bulk delete con validación |
| `backend/.../dto/AuditoriaDTO.java` | DTO de respuesta |
| `backend/.../dto/LogsEliminadosDTO.java` | `{ eliminados: N }` |
| `backend/src/main/resources/db/indices-auditoria.sql` | índice (script revisado) |

### Backend — modificados
| Archivo | Cambio |
|---|---|
| `backend/.../repository/AuditoriaRepository.java` | + `JpaSpecificationExecutor`, `findAll @EntityGraph`, `borrarPorRango @Modifying` |
| `backend/.../service/AuditService.java` | + overload con `Usuario` explícito |
| `backend/.../service/AuthService.java` | `registrarEvento("AUTH", id, "LOGIN", null, usuario)` |
| `backend/.../service/{Producto,Categoria,Proveedor,Cliente,Venta,Compra,Precio,MovimientoStock,Gasto}Service.java` | inyectar `AuditService`+`ObjectMapper`; registrar tras save |
| `backend/.../config/DataSeeder.java` | módulo LOGS + permisos + matriz ADMIN |
| `backend/src/test/.../PreAuthorizeDriftTest.java` | 44 / 71; allowlist sin cambios |
| `backend/src/test/.../DataSeederIdempotencyTest.java` | 14 módulos / 44 permisos / 71 pares |

### Frontend — nuevos
| Archivo | Descripción |
|---|---|
| `frontend/src/app/logs/logs.module.ts` | NgModule feature |
| `frontend/src/app/logs/logs-routing.module.ts` | ruta '' |
| `frontend/src/app/logs/log.service.ts` | list + deleteByRange |
| `frontend/src/app/logs/log-list/log-list.component.{ts,html,scss}` | tabla server-side + filtros + borrado |
| `frontend/src/app/logs/log-list/log-list.component.spec.ts` | tests vitest |

### Frontend — modificados
| Archivo | Cambio |
|---|---|
| `frontend/src/app/app-routing.module.ts` | ruta `/logs` lazy |
| `frontend/src/app/core/rutas-por-permiso.ts` | entrada Logs |
| `frontend/src/app/core/models.ts` | + `Log<AuditoriaLog>`, `Page<T>`, `EliminarLogsResponse` |

## Testing Strategy (strict_tdd)

| Capa | Qué se prueba | Approach |
|---|---|---|
| Unit (LogService) | spec construida + validación de rango (400 ausencia/rev/formato) | Mockito `AuditoriaRepository` |
| Integración (consulta) | 200 Page con `LOGS_VER`; filtros (range/entidad+accion); 403 sin `LOGS_VER` | MockMvc + H2 con token admin / vendedor |
| Integración (borrado) | 200+conteo y filas borradas; 400 por falta param; 400 hasta<desde; vacío→200 `eliminados=0`; 403 sin `LOGS_ELIMINAR` | MockMvc DELETE |
| Integración (instrumentación) | operación escribe fila correcta; rechazada (400) NO; login AUTH/LOGIN | repos + `SecurityContextHolder` |
| Drift | `PreAuthorizeDriftTest` con 44/71 y `LOGS_VER`/`LOGS_ELIMINAR` en `LogController` | reflexión existente + conteos |
| Frontend | render tabla + filtros + paginación server-side + borrado condicionado + diálogo cancelado/confirmado | vitest |

Cobertura: los 32 escenarios de la task de verificación. `mvn test` (Docker) + `npm test` en verde.

## Migration / Rollout

- Sin migración de esquema. Índice opcional: script `db/indices-auditoria.sql` aplicado manualmente (revisado) para performance; `ddl-auto` no crea índices.
- Orden: (1) AuditService overload → LogService+DTOs+LogController → AuditoriaRepo → DataSeeder → instrumentación (9 + AUTH). (2) Tests backend + drift + seeder. (3) Frontend: models → log.service → rutas/RUTAS_POR_PERMISO → logs/ → tests.
- Verificación manual premerge: admin loguea, ve item Logs, filtra, borra rango con confirmación; rol sin permiso 403.
- Rollback: `git revert` del PR; archivos nuevos se eliminan, modificados revierten. **El borrado por rango es IRREVERSIBLE** (filas no recuperables salvo backup/replicación postgres).

## Risks & Mitigations

| Riesgo | Prob | Mitigación |
|---|---|---|
| Drift/seeder fallan si conteos 44/71 no cuadran | Alta | Actualizar driftTest + seederTest en el mismo cambio |
| Borrado por rango borra todo por falta de rango | Media | params obligatorios (400); `hasta<desde`→400; diálogo confirmación |
| Bulk masivo bloquea tabla | Media | índice `(fecha)` + ventanas acotadas en UI |
| entidad singular vs módulo plural rompe filtro | Baja | convención singular + frontend mapea label→entidad singular |
| Login: `SecurityContext` aún no actualizado → usuario null | Media | overload con usuario explícito |
| N+1 en `Page<Auditoria>` al resolver usuario LAZY | Media | `@EntityGraph("usuario")` |
| No-auto-auditoría del borrado | Baja | excepción consciente; `LOGS_ELIMINAR` restrictivo |
| PII en `detalle` crudo | Media | muestra cruda, sin export; cautela documentada |

## Open Questions

- [ ] Confirmar si el índice `(fecha)`/`(entidad,fecha)` se aplica en esta entrega o queda solo documentado para que el operador lo corra (se incluye script pero no se ejecuta).
- [ ] El filtro `entidad` del front: select estático de entidades singulares vs input libre; ¿se requiere un endpoint `SELECT DISTINCT entidad`? (por KISS se usa select/texto; validar en demo).
- [ ] Tamaño de página por defecto (`size=20`) / `pageSizeOptions` de la UI.