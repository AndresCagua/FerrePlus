# Módulo de Logs de Actividades del Sistema — Especificación Delta

## Propósito

Este cambio construye la **capa de consulta y administración de los logs de actividades** (auditoría) sobre la infraestructura ya existente y probada del change `modulo-roles-permisos` (tabla genérica `auditoria`, `AuditService` reutilizable, catálogo de permisos con matriz de roles). Hoy la infraestructura de auditoría registra solo operaciones de usuarios y roles, pero NO existe forma de consultar los logs, ni de borrarlos, ni se registra actividad del resto del sistema (productos, categorías, proveedores, clientes, ventas, compras, precios, movimientos, gastos).

Este change agrega:

1. El **módulo LOGS como 14º módulo del catálogo** con dos permisos: `LOGS_VER` (consulta) y `LOGS_ELIMINAR` (borrado por rango de fechas), ambos asignables a roles y usuarios como cualquier otro permiso del catálogo.
2. El **endpoint de consulta** `GET /api/logs`, paginado y filtrable, protegido con `@PreAuthorize("hasAuthority('LOGS_VER')")`.
3. El **endpoint de borrado por rango** `DELETE /api/logs?desde=&hasta=`, protegido con `@PreAuthorize("hasAuthority('LOGS_ELIMINAR')")`, con rango obligatorio y validado, ejecutado como **bulk delete** eficiente, y que **NO se audita a sí mismo** (excepción consciente y documentada).
4. La **instrumentación del resto del sistema** (productos, categorías, proveedores, clientes, ventas y anulación, compras y anulación, precios, movimientos, gastos), más el login exitoso, siguiendo el patrón ya existente en `UsuarioService`/`RolService`.
5. La **UI de consulta de logs** en Angular (feature module NgModule, NO standalone — patrón del proyecto), con tabla paginada **server-side**, filtros, entrada en el sidebar vía `RUTAS_POR_PERMISO`, y la acción destructiva **"Borrar por rango"** visible solo con `LOGS_ELIMINAR` y con diálogo de confirmación.

Esta es una **spec delta**: describe lo que se AGREGA y MODIFICA respecto del comportamiento actual del módulo de auditoría. No reescribe la infraestructura de auditoría ya existente (la reutiliza), ni toca el catálogo de los 13 módulos actuales salvo para agregar LOGS y sus permisos.

## Alcance

### ADDED (agregado)

- Módulo **LOGS** (14º) en `DataSeeder` con dos permisos: `LOGS_VER` ("Ver logs") y `LOGS_ELIMINAR` ("Eliminar logs"), y nombre de módulo "Logs". Matriz: **ADMIN recibe ambos**; VENDEDOR y BODEGUERO **no reciben ninguno** por defecto (logs sensibles; asignables por override de rol/usuario).
- Endpoint `GET /api/logs`, paginado con filtros (`fechaDesde`, `fechaHasta`, `usuarioId`, `usuarioNombre`, `entidad`, `accion`), protegido con `LOGS_VER`, que devuelve `Page<AuditoriaDTO>`.
- Endpoint `DELETE /api/logs?desde=&hasta=`, protegido con `LOGS_ELIMINAR`, bulk delete por rango de fechas, devuelve conteo de eliminados.
- No existe borrado por fila individual: el borrado solo existe por rango de fechas. El borrado masivo NO se audita a sí mismo (excepción documentada).
- Instrumentación con `auditService.registrarEvento(...)` en los servicios de escritura del dominio: `ProductoService`, `CategoriaService`, `ProveedorService`, `ClienteService`, `VentaService` (crear + anular), `CompraService` (crear + anular), `PrecioService` (actualizar precio de venta), `MovimientoStockService` (crear), `GastoService` (crear/actualizar/eliminar). `ReporteService` es read-only y **no** se instrumenta.
- Instrumentación del **login exitoso** (`AuthService`, entidad `AUTH`, acción `LOGIN`) — ver R5.
- UI de logs: feature module `frontend/src/app/logs/`, lista paginada server-side con filtros, botón **"Borrar por rango"** (solo con `LOGS_ELIMINAR`) y diálogo de confirmación.
- Entrada `Logs` en `RUTAS_POR_PERMISO` y ruta `/logs` en `app-routing.module.ts` con `data.permissions: ['LOGS_VER']`.
- Tests backend nuevos (consulta paginada con filtros, borrado por rango 200/400/403 + conteo, 403 sin `LOGS_VER`, auditoría representativa, actualización del drift test) y frontend (lista paginada/filtros, borrado condicionado + confirmación).

### MODIFIED (modificado)

- `DataSeeder`: catálogo pasa a **14 módulos / 44 permisos / 71 pares** (ADMIN 44 + VENDEDOR 9 + BODEGUERO 18, ADMIN += LOGS_VER + LOGS_ELIMINAR).
- `AuditoriaRepository`: agrega consulta paginada con filtros y método de **bulk delete** por rango de fechas.
- `ProductoService`, `CategoriaService`, `ProveedorService`, `ClienteService`, `VentaService`, `CompraService`, `PrecioService`, `MovimientoStockService`, `GastoService`, `AuthService`: inyectan `AuditService` y registran eventos tras el save exitoso.
- `frontend/src/app/core/rutas-por-permiso.ts`: nueva entrada "Logs".
- `frontend/src/app/app-routing.module.ts`: nueva ruta `/logs` lazy.
- `PreAuthorizeDriftTest`: se actualizan los conteos exactos (42→44 permisos, 69→71 pares).

### REMOVED (eliminado)

- Nada se elimina de la infraestructura existente. No hay `LOGS_CREAR` ni `LOGS_EDITAR` en el catálogo (los logs son inmutables en contenido; solo existen VER y ELIMINAR).

---

## Decisiones confirmadas

Las decisiones 1-10 de la propuesta son vinculantes. Este spec las incorpora:

| # | Decisión | Opción elegida / Racional |
|---|----------|---------------------------|
| 1 | `entidad` como "dónde" (sin columna `modulo` nueva) | Reutilizar la columna `entidad` de `auditoria` como identificador del módulo/entidad (ej. `VENTA`, `PRODUCTO`, `AUTH`). El filtro por módulo = filtro por `entidad`. Cero DDL, cero backfill, cero cambio a los callers de `registrarEvento`. |
| 2 | Módulo LOGS 14º con `LOGS_VER` + `LOGS_ELIMINAR` | El borrado por rango es requisito. `MODULOS.put("LOGS", new int[]{14, 1, 0, 0, 1})`. ADMIN recibe ambos; VENDEDOR/BODEGUERO ninguno por defecto. Ambos entran a la matriz como los demás permisos. |
| 3 | Paginación server-side (`Pageable`) + filtros | Volumen alto de la tabla de auditoría. Patrón Spring Data estándar; patrón nuevo para el proyecto (los demás listados devuelven `List<T>` sin paginar). |
| 4 | Borrado por rango = **bulk delete** eficiente | `@Modifying @Query("DELETE FROM Auditoria a WHERE a.fecha BETWEEN :desde AND :hasta")` — un solo statement SQL con `@Transactional` + `clearAutomatically`. No itera fila a fila (evita N deletes y carga en memoria). |
| 5 | Rango `desde`/`hasta` **obligatorio** y validado | Sin rango → 400; `hasta < desde` → 400; formato inválido → 400; inclusivo `[desde, hasta]` sobre `fecha`. Previene el wipe accidental de la tabla entera. |
| 6 | El borrado masivo **NO se auto-audita** | Excepción consciente (la fila "se borraron N logs" caería dentro del rango eliminado). Riesgo aceptado (sin trazabilidad de quién borró en tabla auditoria); mitigación: `LOGS_ELIMINAR` restrictivo (solo ADMIN por defecto) + evidencia en logs de app/BD. |
| 7 | Instrumentación del resto del sistema | Set pragmático completo de servicios de escritura del dominio. `entidad` = código de módulo en mayúsculas (coherencia entidad↔módulo). Registro tras el save exitoso, atómico (MANDATORY). |
| 8 | Login: solo exitoso, con usuario explícito | `registrarEvento("AUTH", usuario.getId(), "LOGIN", null)` pasando el usuario explícito (el `SecurityContextHolder` aún no se actualizó durante `login()`). No se registran intentos fallidos (volumen y PII). |
| 9 | Frontend NgModule (NO standalone) | Patrón del proyecto (`config.yaml`: "Angular 22 (NgModule, feature modules, NO standalone)"). Seguir `frontend/src/app/roles/`. |
| 10 | Backup por replicación de PostgreSQL | Contexto confirmado por el usuario; no se implementa ningún segundo motor de logs. |

---

## Requisitos

### R1: Módulo LOGS en el catálogo con `LOGS_VER` y `LOGS_ELIMINAR`

**Domain**: Base de datos / Configuración / Seguridad

El sistema DEBE agregar el módulo **LOGS** al catálogo como el **14º módulo** (orden 14) con **dos permisos**:

- `LOGS_VER` (acción `VER`, nombre "Ver logs").
- `LOGS_ELIMINAR` (acción `ELIMINAR`, nombre "Eliminar logs").

El catálogo DEBE pasar a tener **exactamente 44 permisos** (era 42) y la matriz DEBE pasar a tener **exactamente 71 pares** rol↔permiso (ADMIN 44 + VENDEDOR 9 + BODEGUERO 18). La matriz por defecto:

- **ADMIN** DEBE recibir **ambos** (`LOGS_VER` y `LOGS_ELIMINAR`).
- **VENDEDOR** y **BODEGUERO** NO DEBEN recibir ninguno por defecto.

El sistema NO DEBE crear `LOGS_CREAR` ni `LOGS_EDITAR` (los logs son inmutables en contenido; su creación la hace el propio sistema).

El seed DEBE mantener la idempotencia existente: ejecutarlo dos veces sobre la misma base NO DEBE duplicar el módulo LOGS, los permisos `LOGS_VER`/`LOGS_ELIMINAR` ni los pares de la matriz.

#### Scenario: El catálogo pasa a 14 módulos y 44 permisos

- GIVEN que el catálogo antes del cambio tiene 13 módulos y 42 permisos
- WHEN se siembra el módulo LOGS (`MODULOS.put("LOGS", new int[]{14, 1, 0, 0, 1})`) y se consulta el catálogo
- THEN existen **14 módulos**, con `LOGS` en la posición 14 y nombre "Logs"
- AND existen **44 permisos**, incluyendo `LOGS_VER` y `LOGS_ELIMINAR`

#### Scenario: El módulo LOGS solo tiene acciones VER y ELIMINAR

- GIVEN el módulo LOGS en el catálogo
- WHEN se listan los códigos de permiso del módulo LOGS
- THEN el conjunto DEBE ser exactamente `{LOGS_VER, LOGS_ELIMINAR}`
- AND NO DEBE existir `LOGS_CREAR` ni `LOGS_EDITAR`

#### Scenario: La matriz por defecto asigna LOGS solo a ADMIN

- GIVEN los roles base sembrados
- WHEN se resuelven los permisos efectivos de cada rol
- THEN `ADMIN` incluye `LOGS_VER` y `LOGS_ELIMINAR`
- AND `VENDEDOR` NO incluye `LOGS_VER` ni `LOGS_ELIMINAR`
- AND `BODEGUERO` NO incluye `LOGS_VER` ni `LOGS_ELIMINAR`

#### Scenario: Seed idempotente — no duplica LOGS

- GIVEN una base con el catálogo ya sembrado (con LOGS incluido)
- WHEN el seeder se ejecuta por segunda vez
- THEN `modulos` sigue en **14** y `permisos` en **44** (no 28 ni 88)
- AND el número de pares `rol_permisos` no se duplica

---

### R2: Consulta paginada de logs con filtros

**Domain**: API / Backend / Seguridad

El sistema DEBE exponer `GET /api/logs`, protegido con `@PreAuthorize("hasAuthority('LOGS_VER')")`, que devuelve una lista **paginada server-side** de registros de auditoría filtrables:

- **Filtros** (todos opcionales, `@RequestParam(required = false)`): `fechaDesde`, `fechaHasta`, `usuarioId`, `usuarioNombre`, `entidad`, `accion`.
- **Paginación**: `page`, `size`, `sort` estándar de Spring Data (`Pageable`).
- **Respuesta** DEBE ser `Page<AuditoriaDTO>` con, al menos: `id`, `entidad`, `entidadId`, `accion`, `usuarioNombre` (nombre del usuario que ejecutó, o vacío/`null` para eventos de sistema), `fecha`, `detalle`.
- El sistema NO DEBE exponer la entidad JPA `Auditoria` directamente (se expone el DTO).
- Sin filtros = trae todos los registros paginados.
- El filtro por módulo/entidad DEBE aplicarse sobre la columna `entidad` (decisión D1).
- El filtro `usuarioNombre` DEBE ser un **contiene (CONTAINS / `LIKE %valor%`) case-insensitive** sobre `usuario.nombre` (vía el join `@EntityGraph` de `auditoria.usuario`), y DEBE combinarse con AND con `usuarioId` si ambos se pasan. Un valor `null`/vacío/solo espacios DEBE ignorarse.

#### Scenario: Usuario con `LOGS_VER` lista logs paginados

- GIVEN un usuario autenticado con el permiso `LOGS_VER` y más registros de los que caben en una página en `auditoria`
- WHEN se llama a `GET /api/logs?page=0&size=20`
- THEN la respuesta DEBE ser 200 con una estructura `Page` (elementos de la página, `totalElements`, `totalPages`)
- AND los elementos DEBEN ser DTOs con `entidad`, `entidadId`, `accion`, `usuarioNombre`, `fecha`, `detalle`

#### Scenario: Usuario sin `LOGS_VER` recibe 403

- GIVEN un usuario autenticado sin el permiso `LOGS_VER` (p. ej. un VENDEDOR sin override)
- WHEN se llama a `GET /api/logs`
- THEN la respuesta DEBE ser HTTP 403
- AND NO DEBE devolverse ninguna fila de auditoría

#### Scenario: Filtro por rango de fechas

- GIVEN una tabla `auditoria` con registros con distintas fechas
- WHEN se llama a `GET /api/logs?fechaDesde=2026-01-01T00:00:00&fechaHasta=2026-01-31T23:59:59`
- THEN la respuesta DEBE contener solo los registros cuya `fecha` cae dentro del rango [desde, hasta]
- AND `totalElements` DEBE reflejar el conteo filtrado

#### Scenario: Filtro combinado por entidad y acción

- GIVEN registros de auditoría con distintas `entidad`/`accion`
- WHEN se llama a `GET /api/logs?entidad=VENTA&accion=CREAR`
- THEN la respuesta DEBE contener solo registros con `entidad=VENTA` y `accion=CREAR`
- AND `totalElements` DEBE ser igual al conteo de registros con esa pareja (entidad, accion)

#### Scenario: Filtro por nombre de usuario (contiene, case-insensitive)

- GIVEN registros de auditoría de distintos usuarios (p. ej. "Ana Gómez" y "Andrés Pérez")
- WHEN se llama a `GET /api/logs?usuarioNombre=ana`
- THEN la respuesta DEBE contener solo los registros cuyo `usuario.nombre` contiene "ana" (coincidencia parcial e insensible a mayúsculas)
- AND `usuarioNombre` vacío o solo espacios DEBE ignorarse (no filtra)
- AND si se pasa además `usuarioId`, ambos filtros DEBEN combinarse con AND

---

### R3: Borrado de logs por rango de fechas

**Domain**: API / Backend / Seguridad

El sistema DEBE exponer `DELETE /api/logs`, protegido con `@PreAuthorize("hasAuthority('LOGS_ELIMINAR')")`, para borrar registros de auditoría en un **rango de fechas**:

- Parámetros de query **obligatorios**: `desde` y `hasta` (formato `yyyy-MM-dd` o `yyyy-MM-dd'T'HH:mm:ss`).
- **Validación**: si falta `desde` u `hasta` → **400**; si `hasta < desde` → **400**; formato no parseable → **400**. En todos los casos NO se borra nada.
- **Alcance del borrado**: inclusivo `[desde, hasta]` sobre la columna `fecha`.
- **Ejecución**: bulk delete eficiente — un solo statement SQL (`DELETE ... WHERE fecha BETWEEN :desde AND :hasta`) con `@Transactional` y `clearAutomatically=true` (y `flushAutomatically` según diseño). NO itera fila a fila.
- **Respuesta**: conteo de filas eliminadas (`{ "eliminados": N }`), o `204` + header con el conteo (forma exacta se define en diseño; el conteo DEBE quedar accesible).
- **No se autoaudita**: el borrado masivo NO genera una fila de auditoría de sí mismo (decisión D6).
- **No existe borrado por fila individual** ni selectivo: solo por rango. NO DEBE existir `DELETE /api/logs/{id}`.

#### Scenario: Borrado por rango exitoso con conteo

- GIVEN un administrador autenticado con `LOGS_ELIMINAR` y registros en `auditoria`
- WHEN se llama a `DELETE /api/logs?desde=2026-01-01&hasta=2026-01-31`
- THEN la respuesta DEBE ser 200 con el conteo `eliminados = N` (filas cuya `fecha` ∈ [desde, hasta])
- AND el borrado DEBE haberse ejecutado en un solo bulk statement (no fila a fila)
- AND los registros del rango DEBEN haber desaparecido de `auditoria`

#### Scenario: Sin `LOGS_ELIMINAR` recibe 403

- GIVEN un usuario autenticado con `LOGS_VER` pero SIN `LOGS_ELIMINAR`
- WHEN se llama a `DELETE /api/logs?desde=2026-01-01&hasta=2026-01-31`
- THEN la respuesta DEBE ser **403**
- AND NO DEBE borrarse ningún registro

#### Scenario: Falta el rango → 400 y no borra nada

- GIVEN un usuario autenticado con `LOGS_ELIMINAR`
- WHEN se llama a `DELETE /api/logs` sin `desde` ni `hasta` (o solo uno de ellos)
- THEN la respuesta DEBE ser **400**
- AND `auditoria` DEBE permanecer intacta (0 filas eliminadas)

#### Scenario: Rango invertido (`hasta < desde`) → 400 y no borra nada

- GIVEN un usuario autenticado con `LOGS_ELIMINAR`
- WHEN se llama a `DELETE /api/logs?desde=2026-02-01&hasta=2026-01-01`
- THEN la respuesta DEBE ser **400**
- AND NO DEBE borrarse ningún registro

#### Scenario: Rango vacío devuelve conteo 0 sin error

- GIVEN un usuario autenticado con `LOGS_ELIMINAR` y sin registros en el rango consultado
- WHEN se llama a `DELETE /api/logs?desde=2020-01-01&hasta=2020-01-02`
- THEN la respuesta DEBE ser 200 con `eliminados = 0` (sin error)

#### Scenario: El borrado masivo NO se audita a sí mismo

- GIVEN un administrador autenticado con `LOGS_ELIMINAR`
- WHEN ejecuta `DELETE /api/logs?desde=&hasta=` sobre un rango que incluye la fecha actual
- THEN NO DEBE existir en `auditoria` una fila que registre la propia operación de borrado masivo (ni sumaria, ni huérfana)
- AND la única evidencia de la operación queda en logs de aplicación/BD (no en la tabla auditoria)

---

### R4: Instrumentación del resto del sistema

**Domain**: Backend / Auditoría

El sistema DEBE instrumentar los servicios de escritura del dominio registrando eventos en `auditoria` tras cada **save exitoso**, siguiendo el patrón ya existente (`AuditService.registrarEvento`, con `AuditService` inyectado vía `@RequiredArgsConstructor`):

| Servicio | `entidad` (código de módulo, mayúsculas) | `accion`(es) |
|---|---|---|
| `ProductoService` | `PRODUCTO` | `CREAR`, `ACTUALIZAR`, `ELIMINAR` (desactivación) |
| `CategoriaService` | `CATEGORIA` | `CREAR`, `ACTUALIZAR`, `ELIMINAR` |
| `ProveedorService` | `PROVEEDOR` | `CREAR`, `ACTUALIZAR`, `ELIMINAR` |
| `ClienteService` | `CLIENTE` | `CREAR`, `ACTUALIZAR`, `ELIMINAR` |
| `VentaService` | `VENTA` | `CREAR`, `ANULAR` (la anulación es la semántica de ELIMINAR) |
| `CompraService` | `COMPRA` | `CREAR`, `ACTUALIZAR`, `ANULAR` |
| `PrecioService` | `PRECIO` | `ACTUALIZAR` (actualizar precio de venta) |
| `MovimientoStockService` | `MOVIMIENTO` | `CREAR` |
| `GastoService` | `GASTO` | `CREAR`, `ACTUALIZAR`, `ELIMINAR` |

Reglas:

- `entidad` DEBE coincidir con el código del módulo del catálogo en mayúsculas (`PRODUCTO`, `VENTA`, ...) para que el filtro por módulo mapee (decisión D1).
- `entidad_id` DEBE ser el id de la entidad afectada y `usuario_id` DEBE resolverse por `AuditService` (el principal autenticado; `null` para eventos de sistema/seed).
- El registro DEBE ser **atómico** con la operación (el `AuditService` con `Propagation.MANDATORY` hereda la transacción del service llamador): una operación rechazada (validación 400, stock insuficiente, 404, etc.) NO DEBE generar fila porque el registro ocurre DESPUÉS del save exitoso.
- `ReporteService` NO DEBE instrumentarse (es read-only).
- **`detalle` de `ACTUALIZAR` = diff de solo los campos cambiados** (refinamiento): las operaciones de actualización (`ProductoService`, `CategoriaService`, `ProveedorService`, `ClienteService`, `CompraService`, `PrecioService`, `GastoService` `update()`) DEBEN registrar `{"campo": {"antes": X, "despues": Y}}` para cada campo cuyo valor cambió, garantizando **trazabilidad real antes→después**. `CREAR` conserva el snapshot completo del registro; `ELIMINAR` conserva el registro eliminado; `ANULAR` conserva el registro anulado. `VentaService` NO tiene `update()` (solo `CREAR`/`ANULAR`) → la forma diff no aplica ahí. El `detalle` se persiste crudo (string JSON) en `auditoria.detalle`; la presentación formateada es responsabilidad del frontend (R7).

#### Scenario: Crear un producto registra evento de auditoría

- GIVEN un usuario autenticado con `PRODUCTOS_CREAR`
- WHEN se crea un producto vía `POST /api/productos`
- THEN se DEBE registrar una fila con `entidad=PRODUCTO`, `entidad_id` = id del producto, `accion=CREAR`, `usuario_id` = id del usuario
- AND `fecha` y `detalle` DEBEN quedar poblados

#### Scenario: Anular una venta registra VENTA/ANULAR

- GIVEN un usuario autenticado con permiso de anular la venta (`VENTAS_ELIMINAR`)
- WHEN se anula una venta
- THEN se DEBE registrar una fila con `entidad=VENTA`, `entidad_id` = id de la venta, `accion=ANULAR`, `usuario_id` = id del usuario

#### Scenario: Operación rechazada no genera fila de auditoría

- GIVEN un usuario autenticado intentando crear un producto con datos inválidos (o una venta con stock insuficiente)
- WHEN la operación de escritura falla (400) y hace rollback
- THEN NO DEBE existir una fila de auditoría para esa operación fallida (el registro ocurre tras el save exitoso)

#### Scenario: Actualizar un producto registra el diff de los campos cambiados

- GIVEN un usuario autenticado con `PRODUCTOS_EDITAR` y un producto existente con `nombre="Martillo"` y `precio=10.0`
- WHEN se actualiza el producto cambiando SOLO el `nombre` a "Martillo 500g" (el precio no se toca)
- THEN se DEBE registrar una fila `PRODUCTO`/`ACTUALIZAR` cuyo `detalle` sea el diff de lo que cambió: `{"nombre": {"antes": "Martillo", "despues": "Martillo 500g"}}`
- AND el `detalle` NO DEBE incluir los campos sin cambios (p. ej. `precio`)

---

### R5: Instrumentación del login exitoso

**Domain**: Backend / Auditoría / Seguridad

El sistema DEBE registrar el **login exitoso** en `auditoria` con `entidad="AUTH"`, `accion="LOGIN"`, `entidadId` = id del usuario y `usuario` = el mismo usuario autenticado, en `AuthService.login()` **tras** la autenticación correcta.

- El sistema DEBE pasar el usuario como actor **explícito** (el `SecurityContextHolder` aún no se actualizó durante `login()`, por lo que `AuditService.usuarioActual()` puede devolver `null`).
- El sistema NO DEBE registrar intentos fallidos (volumen alto y riesgo PII).

#### Scenario: Login exitoso registra evento AUTH/LOGIN

- GIVEN un usuario activo con credenciales correctas
- WHEN invoca `POST /api/auth/login` y recibe 200
- THEN se DEBE registrar una fila con `entidad=AUTH`, `accion=LOGIN`, `entidad_id` = id del usuario, `usuario_id` = id del mismo usuario

#### Scenario: Intento fallido no registra evento

- GIVEN un usuario con credenciales incorrectas
- WHEN invoca `POST /api/auth/login` y recibe 401
- THEN NO DEBE existir una fila de auditoría con `entidad=AUTH` para ese intento

---

### R6: Los permisos de LOGS se asignan por roles y usuarios

**Domain**: Permisos / Roles / Usuarios / Seguridad

El sistema DEBE permitir otorgar y quitar `LOGS_VER` y `LOGS_ELIMINAR` desde la **UI de roles** y de **usuarios** existente, como cualquier permiso del catálogo:

- En la edición de un rol (matriz de checkboxes `permisos-matriz`), los permisos `LOGS_VER` y `LOGS_ELIMINAR` DEBEN mostrarse dentro del módulo **"Logs"** con sus acciones y poder marcarse/desmarcarse.
- En el formulario de usuario, los overrides DEBEN permitir conceder/denegar `LOGS_VER` y `LOGS_ELIMINAR` por usuario.
- Al crear/editar un rol o usuario con estos permisos, el sistema DEBE persistirlos en `rol_permisos`/`usuario_permisos` vía FK (sin cambio de esquema; mismo mecanismo del change anterior).
- Un cambio de matriz/override DEBE aplicar al siguiente request sin re-login (backend resuelve autoridades en cada request; frontend refresca vía `/me` en cada navegación).
- No se requiere enforcement adicional: se reutiliza el CRUD existente de roles/usuarios.

#### Scenario: Otorgar LOGS_VER a VENDEDOR desde la UI de roles

- GIVEN el rol `VENDEDOR` sin `LOGS_VER` y un admin con `ROLES_EDITAR`
- WHEN el admin marca "Logs → Ver" en la matriz del rol y guarda `PUT /api/roles/{id}`
- THEN la matriz del rol DEBE incluir `LOGS_VER`
- AND un usuario VENDEDOR con ese rol DEBE poder llamar `GET /api/logs` (200) al siguiente request sin re-login

#### Scenario: Otorgar permisos de LOGS a un usuario vía override

- GIVEN un usuario con rol `BODEGUERO`
- WHEN un admin le agrega los overrides `LOGS_VER` y `LOGS_ELIMINAR` desde la UI de usuarios (`PUT /api/usuarios/{id}`)
- THEN sus permisos efectivos DEBEN incluir `LOGS_VER` y `LOGS_ELIMINAR`
- AND `GET /api/logs` responde 200 y `DELETE /api/logs?desde=&hasta=` responde 200 para ese usuario

#### Scenario: Se pueden quitar los permisos de LOGS

- GIVEN un rol/usuario con `LOGS_VER` y `LOGS_ELIMINAR`
- WHEN un admin quita `LOGS_ELIMINAR` de la matriz del rol o por override de usuario
- THEN los permisos efectivos NO DEBEN incluir `LOGS_ELIMINAR` al siguiente request
- AND `DELETE /api/logs` DEBE responder 403 para ese usuario

---

### R7: UI de consulta de logs (listado paginado server-side + filtros)

**Domain**: Frontend / UI

El sistema DEBE agregar un feature module Angular `frontend/src/app/logs/` (NgModule, NO standalone) con:

- `logs.module.ts` y `logs-routing.module.ts`. `app-routing.module.ts` DEBE declarar la ruta `/logs` lazy con `canActivate: [AuthGuard]` y `data: { permissions: permisosDeRuta('/logs') }`.
- `log.service.ts`: método de listado que llama a `GET /api/logs` con query params de paginación + filtros, y método de borrado por rango que llama a `DELETE /api/logs`.
- `log-list/`:
  - **Tabla paginada server-side**: usa `MatPaginator` (y `MatSort` si aplica) y consulta contra la respuesta `Page` del backend; NO usa el filtro client-side de `MatTableDataSource` (a diferencia de los demás listados del proyecto).
  - **Formulario de filtros**: `fechaDesde`, `fechaHasta`, `usuarioNombre` (input de TEXTO "Usuario"; reemplaza al `usuarioId` numérico), `entidad`, `accion`, que al aplicarse re-consultan el servidor.
  - Columnas: **entidad**, **ID Entidad** (`entidadId` — el id del registro afectado), **acción**, **ID Usuario** (`usuarioId`, fallback `—`), **Usuario** (`usuarioNombre`, fallback `—`), **fecha**, **detalle**. `displayedColumns = ['entidad', 'entidadId', 'accion', 'usuarioId', 'usuarioNombre', 'fecha', 'detalle']`.
  - **`detalle` formateado en la presentación**: el `detalle` se renderiza con un helper puro (`frontend/src/app/logs/detalle.util.ts`): la forma diff de `ACTUALIZAR` se muestra como filas "campo: antes → despues"; el snapshot como "campo: valor"; JSON inválido cae al string crudo; `null` se muestra como `—`. El JSON permanece crudo en la API (el backend no lo parsea).

- Entrada en `RUTAS_POR_PERMISO` (`{ label: 'Logs', route: '/logs', permissions: ['LOGS_VER'] }`) para que el `SidebarComponent` muestre el item solo con `LOGS_VER` y `AuthGuard`/`getHomeRoute` lo consideren.

#### Scenario: Usuario con LOGS_VER ve el item Logs y la lista

- GIVEN un usuario autenticado con `LOGS_VER`
- WHEN se renderiza el sidebar y se navega a `/logs`
- THEN el item "Logs" DEBE aparecer en el sidebar
- AND `/logs` renderiza la tabla paginada server-side con el formulario de filtros

#### Scenario: Usuario sin LOGS_VER no ve la ruta ni el item

- GIVEN un usuario autenticado sin `LOGS_VER`
- WHEN se renderiza el sidebar
- THEN el item "Logs" NO DEBE aparecer
- AND al navegar por URL directa a `/logs`, el `AuthGuard` DEBE bloquear la navegación (redirigir a ruta permitida)

#### Scenario: Paginación y filtros son server-side

- GIVEN un usuario en `/logs`
- WHEN cambia de página, tamaño de página o aplica filtros (fecha/usuario/módulo/acción)
- THEN el componente DEBE re-consultar el servidor con los query params correspondientes (NO filtrar client-side)
- AND la tabla DEBE mostrar la página devuelta por el backend

---

### R8: UI de borrado por rango con confirmación y control de permiso

**Domain**: Frontend / UI / Seguridad

El sistema DEBE incluir en `log-list` la acción **"Borrar por rango"** con:

- **Botón visible SOLO con `LOGS_ELIMINAR`**: el botón DEBE mostrarse condicionado a `*appHasPermission('LOGS_ELIMINAR')` (directiva `has-permission.directive` existente); sin el permiso, el botón NO se renderiza.
- **Selección de rango de fechas** (`desde` y `hasta`).
- **Diálogo de confirmación** (operación destructiva e irreversible) que muestra el rango desde–hasta antes de ejecutar:
  - Cancelar → NO se llama al endpoint.
  - Confirmar → `DELETE /api/logs?desde=&hasta=` y se muestra el conteo de eliminados.
- **No existe borrado por fila individual**: no hay control de eliminación por fila; el único borrado es el masivo por rango.
- Tras el borrado, la lista DEBE recargarse.

#### Scenario: Botón de borrado visible solo con LOGS_ELIMINAR

- GIVEN un usuario con `LOGS_VER` y `LOGS_ELIMINAR` en `/logs`
- WHEN se renderiza `log-list`
- THEN el botón "Borrar por rango" DEBE estar visible
- GIVEN un usuario con `LOGS_VER` pero SIN `LOGS_ELIMINAR`
- WHEN se renderiza `log-list`
- THEN el botón DEBE estar oculto

#### Scenario: Confirmación cancelada no ejecuta nada

- GIVEN un usuario con `LOGS_ELIMINAR` y un rango seleccionado
- WHEN el diálogo de confirmación se cancela
- THEN NO DEBE llamarse al endpoint `DELETE /api/logs`
- AND la lista DEBE permanecer intacta

#### Scenario: Confirmación aceptada ejecuta y muestra el resultado

- GIVEN un usuario con `LOGS_ELIMINAR` y un rango seleccionado
- WHEN confirma el diálogo (que muestra el rango desde–hasta)
- THEN se llama a `DELETE /api/logs?desde=&hasta=`
- AND el conteo `eliminados` devuelto se muestra al usuario
- AND la lista se recarga y los registros del rango ya no aparecen

#### Scenario: No existe borrado por fila individual

- GIVEN la vista `log-list`
- WHEN se inspecciona la UI
- THEN NO DEBE existir ningún control de eliminación por fila individual (ni botón, ni ícono, ni menú por fila)
- AND la única operación de borrado es por rango de fechas (bulk)

---

### R9: Tests de backend (incl. actualización del drift test)

**Domain**: Testing — Backend

El sistema DEBE actualizar y ampliar las pruebas de backend:

1. **Actualizar `PreAuthorizeDriftTest`**: los conteos pasan a **44 permisos** y **71 pares** (ADMIN 44 + VENDEDOR 9 + BODEGUERO 18) con aserciones de igualdad exacta actualizadas. La allowlist (`{VENTAS_EDITAR, ROLES_CREAR, ROLES_ELIMINAR}`) NO DEBE modificarse, porque `LOGS_VER` y `LOGS_ELIMINAR` quedan referenciados en las anotaciones `@PreAuthorize` del nuevo `LogController`.
   - Los tres tests del drift (catálogo completo, todo código de anotación existe en catálogo, todo permiso del catálogo está protegido salvo allowlist) DEBEN seguir pasando.
2. **Nuevos tests**:
   - Consulta paginada con filtros (rango de fechas, entidad, acción, combinados).
   - Borrado por rango: 200 + conteo con `LOGS_ELIMINAR`; 403 sin `LOGS_ELIMINAR`; 400 por falta de rango; 400 por `hasta < desde`; rango vacío → 200 con `eliminados=0`; verificación de que las filas se borran físicamente.
   - Seguridad de consulta: `GET /api/logs` 403 sin `LOGS_VER`, 200 con `LOGS_VER`.
   - Auditoría representativa: una operación de escritura del dominio genera fila con `entidad`/`entidad_id`/`accion`/`usuario_id` correctos; una operación rechazada (400) no genera fila.

#### Scenario: Drift test con los nuevos conteos

- GIVEN `DataSeeder` con LOGS como módulo 14 y ADMIN con `LOGS_VER` + `LOGS_ELIMINAR`
- WHEN se ejecuta `PreAuthorizeDriftTest`
- THEN el test de catálogo DEBE esperar exactamente **44 permisos** y **71 pares**
- AND los tres tests del drift DEBEN pasar (consistencia catálogo ↔ `@PreAuthorize`, incluyendo `LOGS_VER` y `LOGS_ELIMINAR` referenciados en `LogController`)
- AND el test NO DEBE requerir cambios en la allowlist

#### Scenario: Borrado por rango cubierto en tests (400/403/200 + conteo)

- GIVEN un contexto de tests con H2, un usuario con `LOGS_ELIMINAR` y otro sin él, y registros en `auditoria`
- THEN:
  - `DELETE /api/logs` sin params → 400, 0 eliminaciones
  - `DELETE /api/logs?desde=...&hasta=<desde` → 400, 0 eliminaciones
  - `DELETE /api/logs?desde=...&hasta=...` sin `LOGS_ELIMINAR` → 403
  - `DELETE /api/logs?desde=...&hasta=...` con `LOGS_ELIMINAR` → 200 con conteo y filas borradas físicamente
  - rango válido sin registros → 200, `eliminados=0`

---

### R10: Atomicidad de la auditoría (cross-cutting)

**Domain**: Backend / Auditoría

El cambio DEBE mantener el modelo de auditoría atómica existente para TODA la instrumentación nueva: el registro DEBE ocurrir en la **misma transacción** que la operación del dominio (vía `Propagation.MANDATORY` en `AuditService` y `@Transactional` a nivel de clase en los services). **Única excepción**: el `DELETE /api/logs` de borrado masivo NO genera fila de auditoría propia (decisión D6).

Esta garantía DEBE implicar que una operación exitosa nunca queda sin su fila de auditoría, y una fallida (rollback) nunca la deja.

#### Scenario: Registro atómico con la operación instrumentada

- GIVEN un service de dominio con `@Transactional` a nivel de clase
- WHEN una operación de escritura se persiste exitosamente
- THEN la fila de auditoría correspondiente DEBE quedar persistida en la misma transacción
- AND si el registro de auditoría fallara, la operación completa DEBE revertirse (no existe operación sin su auditoría)

---

## Requisitos no funcionales

#### Códigos de error

1. **403 Forbidden** — `GET /api/logs` sin `LOGS_VER`; `DELETE /api/logs` sin `LOGS_ELIMINAR`.
2. **400 Bad Request** — `DELETE /api/logs` sin `desde`/`hasta`; `hasta < desde`; formato de fecha inválido. Ninguno borra filas.
3. **200 OK** — `GET /api/logs` (Page) y `DELETE /api/logs` con rango válido (conteo o 204 + header).

#### Edge cases

4. En `GET /api/logs`, los filtros son opcionales: si se pasa solo `fechaDesde` o solo `fechaHasta`, se filtra por ese extremo únicamente.
5. Los registros de sistema/seed (con `usuario_id` null) se muestran con `usuarioNombre` vacío/null y son filtrables por los demás campos.
6. El borrado por rango incluye también filas con `usuario_id` null: el borrado filtra solo por `fecha`.
7. Rango válido sin registros → `eliminados=0` sin error (caso normal, no excepcional).
8. Los cambios de permisos de LOGS nunca exigen re-login (backend recarga en cada request; frontend refresca por `/me` en cada navegación).
9. El `detalle` de auditoría puede ser texto o JSON; el módulo de consulta no depende del formato.
10. En `GET /api/logs`, el filtro `usuarioNombre` ignora `null`/vacío/whitespace y se envía recortado (`trim()`); `usuarioId` y `usuarioNombre` se combinan con AND si ambos vienen.

---

## Fuera de alcance

- **Mongo / RAG / chat**: los logs viven SOLO en PostgreSQL; Mongo queda reservado para un futuro spec RAG/chat (decisión de arquitectura del usuario).
- **Redundancia/backup**: por replicación de PostgreSQL; fuera de implementación.
- **Edición o creación manual de logs** (`LOGS_CREAR`/`LOGS_EDITAR` no existen) y **exportación de PII** de logs: no en este cambio.
- **Borrado por fila individual / selectivo**: solo borrado por rango de fechas.
- **Retención, archivo, particionado o purgado automático** de logs: política futura; el borrado por rango de este cambio es la herramienta de contención.
- **Auditoría de intentos fallidos de login**: excluida (volumen y PII).

---

## Summary

### Requirements Summary

| # | Requirement | Type | Dominio | Escenarios |
|---|-------------|------|---------|------------|
| R1 | Módulo LOGS (14º) + `LOGS_VER`/`LOGS_ELIMINAR` + seed 44/71 | New | BD / Config | 4 |
| R2 | `GET /api/logs` paginado + filtros (`LOGS_VER`, incl. `usuarioNombre` contains) | New | API / Backend | 5 |
| R3 | `DELETE /api/logs` por rango (`LOGS_ELIMINAR`, bulk, validación, no auto-audit) | New | API / Backend | 6 |
| R4 | Instrumentación del resto del sistema (`ACTUALIZAR` = diff ANTES/DESPUES) | New | Backend / Auditoría | 4 |
| R5 | Instrumentación del login exitoso | New | Backend / Auditoría | 2 |
| R6 | `LOGS_VER`/`LOGS_ELIMINAR` asignables por roles/usuarios | New | Permisos | 3 |
| R7 | Frontend: lista paginada server-side + filtros (incl. nombre) + columnas y `detalle` formateado | New | Frontend / UI | 3 |
| R8 | Frontend: borrado por rango + confirmación + permiso | New | Frontend / UI | 4 |
| R9 | Tests backend (incl. drift test 44/71) | New | Testing | 2 |
| R10 | Atomicidad de auditoría (cross-cutting) | New | Backend | 1 |

### Coverage

- **Happy paths**: ✅ Cubiertos (listar logs paginado, borrar por rango con conteo, instrumentación de operaciones del dominio, login exitoso, UI con filtros y botón condicionado)
- **Edge cases**: ✅ Cubiertos (filtros combinados, filtro por nombre case-insensitive, rango vacío → 0, no auto-auditoría del borrado, no borrado por fila, confirmación cancelada, permisos otorgados/quitados sin re-login)
- **Error states**: ✅ Cubiertos (403 sin `LOGS_VER`, 403 sin `LOGS_ELIMINAR`, 400 por falta de rango o `hasta < desde`, 400 formato inválido, drift test actualizado)
- **Total scenarios**: 34 (R1: 4, R2: 5, R3: 6, R4: 4, R5: 2, R6: 3, R7: 3, R8: 4, R9: 2, R10: 1)

### Next Step

Ready for **design** (`sdd-design`). El design debe aterrizar: forma exacta del `LogController`/`LogService`, mecanismo de consulta paginada (`JpaSpecificationExecutor` vs `@Query` con parámetros opcionales), contrato exacto de respuesta del DELETE (`200 + {eliminados}` vs `204` + header), uso de `@Transactional` + `clearAutomatically`/`flushAutomatically` para el bulk delete, posible índice `(fecha)`/`(entidad, fecha)` en `auditoria` (script revisado por el usuario), y el `detalle` JSON de cada servicio instrumentado.
