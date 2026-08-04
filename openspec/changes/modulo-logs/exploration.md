# Exploration: Módulo de Logs de Actividades del Sistema

## Current State

### Infraestructura de auditoría (YA existe, del change `modulo-roles-permisos`)

- **`Auditoria` entity** (`backend/.../entity/Auditoria.java`): tabla genérica `auditoria` con `id`, `entidad` (String 50, ej. `USUARIO`, `ROL`, `VENTA`), `entidad_id` (Long nullable), `accion` (String 20, ej. `CREAR`, `ACTUALIZAR`, `ELIMINAR`), `usuario_id` FK → `Usuario` (nullable para eventos de sistema/seed), `fecha` (LocalDateTime, `updatable=false`, set por `@PrePersist`), `detalle` (TEXT, nullable — usa JSON de cambios vía ObjectMapper).
- **`AuditService`** (`backend/.../service/AuditService.java`): `registrarEvento(entidad, entidadId, accion, detalle)` con `@Transactional(propagation = MANDATORY)` — el registro es **ATÓMICO** con la operación auditada (si la operación revierte, la fila revierte; si el save falla, la operación completa revierte). El usuario se resuelve del `SecurityContextHolder`; queda `null` para eventos de sistema/seed.
- **`AuditoriaRepository`** (`backend/.../repository/AuditoriaRepository.java`): SOLO tiene `findByEntidadAndEntidadIdAndAccion`. **NO tiene consulta paginada ni filtros** — el módulo de logs necesita un query con paginación + filtros (rango fecha, usuario, entidad, accion).
- **Uso actual**: `UsuarioService` (CREAR/ACTUALIZAR/ELIMINAR/PASSWORD) y `RolService` (CREAR/ACTUALIZAR/ELIMINAR) instrumentan con `registrarEvento(...)`. Las operaciones rechazadas (validación) NO generan filas porque el registro ocurre después del save exitoso. `Accion` usa verbos libres (`PASSWORD`), no solo `CREAR/ACTUALIZAR/ELIMINAR`.
- **Tests**: 48 tests backend (incl. `PreAuthorizeDriftTest`, 3 tests que verifican: catálogo exacto de 42 permisos / 3 roles / 69 pares rol_permisos, códigos en `@PreAuthorize` existen en catálogo, y permisos del catálogo sin anotación solo si están en allowlist `{VENTAS_EDITAR, ROLES_CREAR, ROLES_ELIMINAR}`). **Agregar permisos nuevos romperá los conteos exactos de este test**: con `LOGS_VER` + `LOGS_ELIMINAR` y solo ADMIN recibiéndolos → **44 permisos / 71 pares** (ADMIN 44 + VENDEDOR 9 + BODEGUERO 18).
- **Sin borrado existente**: `AuditoriaRepository` no tiene método de DELETE por rango; no hay `LogController`. El borrado por rango es 100% nuevo.

### Catálogo de módulos/permisos

- **`DataSeeder`** (`backend/.../config/DataSeeder.java`): `MODULOS` es `LinkedHashMap<String, int[]>` = `{orden, VER, CREAR, EDITAR, ELIMINAR}`. Hoy 13 módulos (DASHBOARD 1 … REPORTES 13). `ACCIONES = {VER, CREAR, EDITAR, ELIMINAR}`. Permiso se nombra `"Ver productos"` (VERBO + nombre módulo lowercase). Matriz ADMIN/VENDEDOR/BODEGUERO. Idempotente (solo inserta si el código no existe; a roles existentes AÑADE permisos faltantes).
- Agregar LOGS como 14º módulo = `MODULOS.put("LOGS", new int[]{14, 1, 0, 0, 0})` → genera permiso `LOGS_VER` con nombre "Ver logs". Para habilitar borrado: `{14, 1, 0, 0, 1}` → genera además `LOGS_ELIMINAR` ("Eliminar logs"). NOMBRES_MODULO necesita `"LOGS" → "Logs"`. Matriz: agregar `"LOGS_VER"` y `"LOGS_ELIMINAR"` a ADMIN (VENDEDOR/BODEGUERO: recomendado NO — logs sensibles).
- **Esquema de código de permiso**: convención `<MODULO>_<ACCION>`. LOGS = `LOGS_VER` (consulta) + `LOGS_ELIMINAR` (borrado por rango). Sin `LOGS_CREAR`/`LOGS_EDITAR` (contenido inmutable; la creación la hace el sistema).

### Seguridad backend

- `@EnableMethodSecurity` + `@PreAuthorize("hasAuthority('X_VER')")` por endpoint en cada controller (patrón confirmado en `UsuarioController`, `VentaController`, `ProductoController`).
- `PreAuthorizeDriftTest` escanea los controllers vía reflection y verifica consistencia catálogo ↔ anotaciones. Nuevo endpoint `GET /api/logs` con `hasAuthority('LOGS_VER')` pasará el test 2 automáticamente; el test 1 requiere actualizar conteos.

### Frontend

- **NgModule, NO standalone** (confirmado en `config.yaml`: "Angular 22 (NgModule, feature modules, NO standalone)"). El especialista Angular asume standalone, pero el proyecto usa NgModules — seguir el patrón del proyecto.
- **Feature module template**: `frontend/src/app/roles/` = `roles.module.ts` + `roles-routing.module.ts` + `rol-list/` + `rol-form/` + `rol.service.ts`. `RolListComponent` usa `MatTableDataSource` + `MatSort` + filtro cliente (in-memory filter de la tabla, no servidor).
- **Fuente única de ruta→permiso**: `frontend/src/app/core/rutas-por-permiso.ts` (`RUTAS_POR_PERMISO` + `permisosDeRuta()`). Consumida por `SidebarComponent` (`visibleMenuItems` filtra con `authService.hasAnyPermission`), `AuthService.getHomeRoute()`, `AuthGuard`, y `AppRoutingModule` (`data.permissions`). Agregar LOGS = 1 entrada nueva en el mapa + 1 ruta en `app-routing.module.ts`.
- **API URL pattern**: `rol.service.ts` usa `environment.apiUrl + '/roles'`.
- **AuthService**: `hasAnyPermission(perms)`, `hasPermission()`; permisos en sessionStorage refrescados vía `GET /api/usuarios/me` en cada navegación.

## Gaps (lo que falta)

1. **No hay UI de consulta de logs** (ningún módulo `/logs`).
2. **No hay endpoint de consulta de logs** (`AuditoriaRepository` sin paginación/filtros; sin `LogController`).
3. **Instrumentación incompleta**: solo USUARIO y ROL auditan. El resto del sistema (producto, categoria, proveedor, cliente, venta, compra, precio, movimiento, gasto) no registra eventos. Reporte es read-only (no aplica). Auth login no audita.
4. **Columna `modulo` no existe** en `auditoria` — hoy el "dónde" se deriva de `entidad` (ej. `VENTA`, `USUARIO`).
5. **`PreAuthorizeDriftTest` se romperá** con el nuevo permiso (conteos exactos).
6. **Sin paginación server-side en todo el backend** (ningún controller usa `Pageable` — patrón nuevo para el proyecto).

## Approaches

### A. Schema: `entidad` como "dónde" vs columna `modulo` nueva

1. **Reutilizar `entidad`** (sin migración) — el "dónde" ES `entidad` (USUARIO, ROL, VENTA, PRODUCTO…). El filtro "por módulo" = filtro por `entidad`. Cero cambio de esquema, cero migración, funciona con `ddl-auto: update` actual.
   - Pros: sin migración; `entidad` ya fue diseñada "para todo el sistema" (comentario en la entity: "permiten extenderla a VENTA, COMPRA, etc. sin migración"); el catálogo de entidades es el mismo que el catálogo de módulos (misma convención de nombres).
   - Cons: la semántica de "módulo" queda acoplada al valor de `entidad` (el log de una venta queda en el módulo VENTAS — razonable); no hay forma de agrupar varias entidades bajo un módulo (ej. VENTA + VENTA_ITEM) — no es necesidad hoy.
   - Effort: Bajo
2. **Columna `modulo` nueva** (String, FK a `modulos` o libre) — desacopla "dónde se hizo" (módulo navegacional) del "sobre qué entidad" (entidad).
   - Pros: semántica explícita; permite loguear eventos no ligados a una entidad de negocio (ej. LOGIN → módulo AUTH/SISTEMA); filtro por módulo directo e indexable.
   - Cons: requiere DDL (columna nueva) + backfill de filas existentes; `ddl-auto: update` la crea sola pero el backfill es manual; el caller de `registrarEvento` necesita un parámetro más (todas las llamadas actuales se tocan); la "migración" deja la tabla con datos parciales.
   - Effort: Medio

**Recomendación: Opción A (reutilizar `entidad`)**. Los logs de "qué se hizo" quedan identificados por `entidad` (que ya coincide con la convención de módulos del catálogo) + `accion`. Para eventos de sistema sin entidad de negocio (login), usar `entidad="AUTH"` o `entidad="SISTEMA"` con `entidadId=null`. Cero migración, y la tabla ya está probada con 48 tests.

### B. Endpoints: paginación + filtros

1. **`GET /api/logs` con `Pageable` + filtros query params** (`fechaDesde`, `fechaHasta`, `usuarioId` o `usuario`, `entidad`, `accion`) usando un `@Query` con `Page<Auditoria>` o `JpaSpecificationExecutor`.
   - Pros: estándar Spring Data; el proyecto no usa paginación server-side todavía pero es el patrón correcto para volumen alto; evita traer toda la tabla.
   - Cons: nuevo patrón para el proyecto (el resto devuelve `List<T>` sin paginar); el frontend de logs tendrá paginación real (server-side) a diferencia de los demás listados (in-memory filter).
   - Effort: Medio
2. `GET /api/logs` sin paginar (List) — simple pero inaceptable para volumen alto (la tabla de auditoría crece sin límite).
   - Effort: Bajo — descartado por el requisito de volumen.

**Recomendación: Opción 1**. `LogController` con `GET /api/logs?page=0&size=20&fechaDesde=&fechaHasta=&usuarioId=&entidad=&accion=` protegido con `@PreAuthorize("hasAuthority('LOGS_VER')")`. Usar `JpaSpecificationExecutor` o `@Query` con parámetros opcionales. `Page<AuditoriaDTO>` como respuesta. El borrado NO es parte de este GET: se expone por separado en `DELETE /api/logs` (ver sección E — borrado por rango con permiso `LOGS_ELIMINAR`).

### C. Alcance de instrumentación

1. **Set pragmático completo** — instrumentar TODOS los servicios de escritura del dominio: `ProductoService`, `CategoriaService`, `ProveedorService`, `ClienteService`, `VentaService` (crear + anular), `CompraService` (crear + anular), `PrecioService` (actualizarPrecioVenta), `MovimientoStockService` (crear), `GastoService`. Usar la convención `entidad = MODULO` (PRODUCTO, CATEGORIA, PROVEEDOR, CLIENTE, VENTA, COMPRA, PRECIO, MOVIMIENTO, GASTO) y accion CREAR/ACTUALIZAR/ELIMINAR/ANULAR.
   - Pros: el log da visibilidad real de "qué se hizo" en todo el sistema, no solo usuarios/roles; es el requisito central del usuario.
   - Cons: toca ~9 servicios (mecánico, siguiendo el patrón ya existente en UsuarioService); requiere inyectar `AuditService` en cada uno y agregar `registrarEvento` tras cada save exitoso.
   - Effort: Medio
2. **Set mínimo** (solo usuarios/roles) — ya existe; no cumple el requisito.
   - Effort: — descartado.
3. **+ Login** (opcional): auditar login en `AuthService` (entidad `AUTH`, accion `LOGIN`).
   - Pros: trazabilidad de accesos.
   - Cons: volumen alto (cada login genera fila); el `usuarioActual()` de `AuditService` está disponible en el post-login; PII mínima (solo usuario+fecha).
   - Effort: Bajo
   - **Recomendación**: incluirlo como LOGIN exitoso (después del éxito) — opcional, decidible en spec. Marcar como no-obligatorio si el volumen preocupa.

### D. Módulo LOGS (14º) + permisos (VER + ELIMINAR)

1. **Módulo LOGS con `LOGS_VER` + `LOGS_ELIMINAR`** — `MODULOS.put("LOGS", {14, 1, 0, 0, 1})`, matriz ADMIN += ambos; VENDEDOR/BODEGUERO sin LOGS por defecto. El borrado por rango es un requisito confirmado del usuario (decidir no borrar inhabilitaría el requisito de "tabla no infinita").
   - Pros: el borrado por rango resuelve el requisito de "tabla no infinita"; ambos permisos entran a la matriz como los demás; `data.permissions: ['LOGS_VER']` para ruta, `*appHasPermission('LOGS_ELIMINAR')` para el botón de borrar.
   - Cons: dos permisos en vez de uno; `LOGS_ELIMINAR` es sensible (destructivo, no reversible) → solo ADMIN por defecto.
   - Effort: Bajo
2. **Solo `LOGS_VER`** (sin borrado) — **descartado** por el requisito del usuario; no resuelve el crecimiento indefinido de la tabla.
3. Reutilizar `USUARIOS_VER`/`ROLES_VER` como gate — **descartado**: sin granularidad propia; contradice el requisito de permiso nuevo en el catálogo.

**Recomendación: Opción 1**. Módulo LOGS orden 14, permisos `LOGS_VER` y `LOGS_ELIMINAR`. Ambos en la matriz (ADMIN recibe ambos; VENDEDOR/BODEGUERO ninguno por defecto).

### E. Borrado por rango — semántica y trade-offs

1. **Endpoint `DELETE /api/logs?desde=&hasta=` + bulk delete** (recomendado):
   - Validación: `desde` y `hasta` **obligatorios** (400 si falta) y `hasta >= desde` (400). Inclusivo `[desde, hasta]` sobre `fecha`.
   - Repositorio: `@Modifying @Query("DELETE FROM Auditoria a WHERE a.fecha BETWEEN :desde AND :hasta")` con `@Transactional`, `clearAutomatically=true`, `flushAutomatically=true` → UN statement SQL, sin iterar filas (eficiente en volumen alto). Devuelve filas eliminadas (int).
   - `@PreAuthorize("hasAuthority('LOGS_ELIMINAR')")`.
   - Pros: eficiente (bulk, no N eliminate), atómico, devuelve conteo real.
   - Cons: requiere manejo de transacción/clear (riesgo de entidades stale en JPA); el bulk grande puede bloquear la tabla (mitiga con índice `(fecha)` y ventanas acotadas).
   - Effort: Medio
2. **`deleteByFechaBetween` derivado de Spring Data**: más simple, pero internamente itera y borra de a uno (inaceptable para miles de filas; peor locking y N statements).
   - Descarte: menor rendimiento en el caso de uso de "tabla infinita".
3. **¿Se audita a sí mismo el borrado?** — **NO** (recomendado, decisión consciente): auditar un bulk delete de logs sería contradictorio (la fila "se borraron N logs" caería dentro del rango eliminado). El borrado masivo NO genera fila de auditoría; se documenta como excepción y riesgo (sin trazabilidad de quién borró, mitigado por `LOGS_ELIMINAR` restrictivo + logs de app/BD). Alternativa (fila sumaria fuera del rango) lleva complejidad y confusión — descartada.
   - Effort: Bajo
4. **¿Borrar sin rango (todo)? ** — **No**: rango obligatorio para no permitir el wipe accidental de la tabla entera.

**Recomendación**: `DELETE /api/logs` con rango obligatorio, bulk delete eficiente, sin auto-auditoría (excepción documentada), gated por `LOGS_ELIMINAR`.

## Affected Areas

- `backend/.../config/DataSeeder.java` — módulo LOGS 14 + permisos LOGS_VER + LOGS_ELIMINAR + matriz ADMIN.
- `backend/.../controller/LogController.java` — NUEVO: `GET /api/logs` paginado/filtrado (`LOGS_VER`) + `DELETE /api/logs?desde&hasta` (`LOGS_ELIMINAR`).
- `backend/.../service/AuditService.java` — posible método de consulta o delegar en service nuevo (query con filtros).
- `backend/.../repository/AuditoriaRepository.java` — query paginado con filtros (Specification o @Query) + `@Modifying` bulk delete por rango.
- `backend/.../dto/AuditoriaDTO.java` — NUEVO: DTO de respuesta (id, entidad, entidadId, accion, usuarioNombre, fecha, detalle) + DTO/response de conteo eliminado.
- `backend/.../service/{Producto,Categoria,Proveedor,Cliente,Venta,Compra,Precio,MovimientoStock,Gasto}Service.java` — instrumentar con `auditService.registrarEvento(...)`.
- `backend/.../service/AuthService.java` — opcional: auditar login exitoso.
- `backend/src/test/java/.../PreAuthorizeDriftTest.java` — actualizar conteos (**44 permisos / 71 pares**).
- `backend/src/test/java/...` — tests nuevos: consulta paginada con filtros, borrado por rango (400/403/200 + conteo), 403 sin LOGS_VER, instrumentación representativa.
- `frontend/src/app/core/rutas-por-permiso.ts` — entrada `{ label: 'Logs', route: '/logs', permissions: ['LOGS_VER'] }`.
- `frontend/src/app/app-routing.module.ts` — ruta `/logs` lazy con `data.permissions`.
- `frontend/src/app/logs/` — NUEVO feature module (NgModule): `logs.module.ts`, `logs-routing.module.ts`, `log-list/` (tabla paginada server-side + filtros + **borrado por rango con botón condicionado a `LOGS_ELIMINAR` y confirmación**), `log.service.ts`.
- `frontend/src/app/shared/sidebar/sidebar.component.ts` — sin cambio directo (lee de RUTAS_POR_PERMISO); el item aparece automáticamente.
- `frontend/src/app/core/auth.service.ts` / `auth.guard.ts` / `has-permission.directive.ts` — el botón de borrar se oculta con `*appHasPermission('LOGS_ELIMINAR')` (directiva ya existente).

## Risks

- **`PreAuthorizeDriftTest` falla** si no se actualizan los conteos exactos (**44 permisos / 71 pares**) al agregar LOGS_VER + LOGS_ELIMINAR — se actualiza en el mismo cambio; es un test que nos protege (no se puede mergear sin actualizarlo).
- **Borrado por rango**: riesgo de borrar fuera del rango esperado o toda la tabla → rango `desde`/`hasta` **obligatorio** + `hasta >= desde` (400 si no); para evitar locks con volumen alto, índice `(fecha)` y ventanas acotadas en UI.
- **No-auto-auditoría del borrado masivo**: el bulk delete no genera fila de auditoría (excepción consciente; sin trazabilidad de quién borró, mitigado por `LOGS_ELIMINAR` restrictivo + logs de app/BD).
- **`AuditService` con `MANDATORY`**: todos los servicios de dominio usan `@Transactional` a nivel clase → el `registrarEvento` hereda la transacción. OK. Pero servicios con transacciones readOnly en el listado no llaman audit. Verificar que cada método de escritura está bajo `@Transactional`.
- **Login logging**: `usuarioActual()` en login exitoso — el `Authentication` post-login ya tiene el principal; pero si se registra DENTRO de `login()` el `SecurityContextHolder` aún no se actualizó (el login no usa el filtro JWT). **Simplificación recomendada**: `registrarEvento("AUTH", usuario.getId(), "LOGIN", null)` pasando el usuario explícitamente, o dejar login fuera de alcance (decisión en spec).
- **Paginación server-side es patrón nuevo** en el frontend (los demás listados filtran in-memory) — el listado de logs debe usar `MatPaginator` contra la respuesta `Page`, no `MatTableDataSource` con filter client-side.
- **Volumen alto**: la tabla crece indefinidamente; sin índice en `fecha`/`entidad` las consultas paginadas se degradan. Mitigación: filtros + paginación desde el día 1 + **borrado por rango** como herramienta de contención (este requisito lo resuelve a largo plazo).
- **Nombre de entidad vs módulo**: si `entidad` no coincide con el código del módulo del catálogo, el filtro por módulo no mapea. Mitigación: usar la MISMA convención (`PRODUCTO`, `VENTA`...) en la instrumentación.

## Recommendation

**Enfoque conservador y sin migración**:

1. **Schema**: reutilizar `entidad` como "dónde" (Opción A) — sin columna `modulo`. Cero migración; la tabla ya es genérica y probada.
2. **Módulo**: LOGS como 14º módulo con **dos permisos — `LOGS_VER` (consulta) y `LOGS_ELIMINAR` (borrado por rango)**. ADMIN recibe ambos; VENDEDOR/BODEGUERO ninguno por defecto (asignable por override).
3. **Endpoints**: `LogController` con `GET /api/logs` paginado (Pageable) + filtros (fechaDesde, fechaHasta, usuarioId, entidad, accion) protegido con `LOGS_VER`; y **`DELETE /api/logs?desde=&hasta=`** (rango obligatorio, `hasta >= desde` → 400) con **bulk delete eficiente**, protegido con `LOGS_ELIMINAR`. El borrado masivo **no se auto-audita** (excepción documentada).
4. **Instrumentación**: set pragmático completo (producto, categoria, proveedor, cliente, venta, compra, precio, movimiento, gasto) + opcional login exitoso (decidir en spec si pasa usuario explícito). Reporte read-only queda fuera.
5. **Frontend**: feature module `logs/` NgModule, listado con paginación server-side + filtros + **botón "Borrar por rango" (solo con `LOGS_ELIMINAR`, picker de fechas + confirmación)**, entrada en `RUTAS_POR_PERMISO` y ruta en `app-routing.module.ts` con `data.permissions`.
6. **Tests**: actualizar `PreAuthorizeDriftTest` (**44 permisos / 71 pares**); tests nuevos de consulta paginada, borrado por rango (400/403/200 + conteo), 403 sin permiso, y auditoría de una operación representativa.

## Ready for Proposal

Sí — decisiones exploradas y tradeoffs documentados, incl. la nueva capacidad de borrado por rango. La propuesta debe declarar como decisiones confirmadas del usuario: PostgreSQL (no Mongo), permisos en catálogo asignables al crear perfiles/usuarios, **borrado por rango de fechas con permiso `LOGS_ELIMINAR`**, no edición de logs, backup vía replicación (fuera de alcance).
