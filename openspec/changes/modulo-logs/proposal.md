# Proposal: Módulo de Logs de Actividades del Sistema

## Intent

El sistema necesita **ver qué se ha hecho, quién lo hizo, en qué parte del sistema y a qué hora**: un módulo de consulta de logs de actividades (auditoría operativa y de accesos). Hoy ya existe la **infraestructura de auditoría** (construida en el change completado `modulo-roles-permisos`): la tabla genérica `auditoria`, `AuditService` reutilizable y la instrumentación de usuarios/roles. Pero **falta la capa de consulta** (UI de logs, endpoint paginado con filtros, permiso nuevo en el catálogo) y **falta instrumentar el resto del sistema** (productos, categorías, proveedores, clientes, ventas, compras, precios, movimientos, gastos), que hoy no registran actividad.

El usuario confirmó decisiones vinculantes:
1. Debe existir un **módulo para VER los logs** (UI de consulta).
2. Los permisos de logs (`LOGS_VER`, `LOGS_ELIMINAR`) se asignan al **crear perfiles/roles y usuarios** — entran a la matriz de roles como los demás permisos del catálogo.
3. Los logs viven en **PostgreSQL** (decisión de arquitectura tomada por el usuario). **NO en Mongo**; Mongo queda reservado para un futuro spec RAG/chat — fuera de alcance de este change.
4. La redundancia/backup es por **replicación de PostgreSQL**, no por un segundo motor — fuera de alcance, solo contexto.
5. **Debe existir borrado de logs por rango de fechas** (`fechaDesde`..`fechaHasta`) — la tabla no puede ser indefinida. El borrado se habilita con un **permiso de eliminación** (`LOGS_ELIMINAR`) asignable a roles/usuarios como los demás.

Este change **extiende la infraestructura ya existente y probada (48 tests backend), no la reconstruye**.

## Scope

### In Scope

1. **Catálogo: módulo LOGS (14º) con dos permisos — `LOGS_VER` y `LOGS_ELIMINAR`**:
   - `DataSeeder`: `MODULOS.put("LOGS", new int[]{14, 1, 0, 0, 1})`, `NOMBRES_MODULO["LOGS"]="Logs"`. Genera `LOGS_VER` ("Ver logs") y `LOGS_ELIMINAR` ("Eliminar logs").
   - Matriz (recomendado, ajustable desde la UI): **ADMIN recibe `LOGS_VER` + `LOGS_ELIMINAR`**; VENDEDOR y BODEGUERO **no** reciben ninguno por defecto (logs sensibles; se asignan por override de usuario/perfil según necesidad).
   - Semántica: los logs son inmutables en cuanto a edición y creación manual — solo existen VER y ELIMINAR (borrado por rango). No hay `LOGS_CREAR` ni `LOGS_EDITAR` (la creación la hace el propio sistema).
2. **Endpoint de consulta `GET /api/logs`**:
   - Paginado (`Pageable`: page, size, sort) y **filtrable** por: `fechaDesde`, `fechaHasta`, `usuarioId`, `entidad`, `accion`.
   - Protegido con `@PreAuthorize("hasAuthority('LOGS_VER')")`.
   - Respuesta `Page<AuditoriaDTO>` (id, entidad, entidadId, accion, usuarioNombre, fecha, detalle).
3. **Endpoint de borrado `DELETE /api/logs` (por rango de fechas)**:
   - Query params **obligatorios**: `desde` y `hasta` (formato `yyyy-MM-dd` o `yyyy-MM-dd'T'HH:mm:ss`). Se borran las filas con `fecha` en `[desde, hasta]` (inclusive).
   - Validación: `hasta >= desde` (400 si no). **Sin rango = rechazado** (400) — previene el borrado accidental de toda la tabla.
   - Protegido con `@PreAuthorize("hasAuthority('LOGS_ELIMINAR')")`.
   - Respuesta: conteo de filas eliminadas (`{ "eliminados": N }`) o 204 + header. Ejecución como **bulk delete** (ver Approach, decisión D2).
   - **No se audita a sí mismo** (ver decisión D3): el borrado masivo no genera filas de auditoría porque la misma operación las eliminaría — excepción consciente documentada como riesgo.
4. **`AuditoriaRepository` — consulta paginada con filtros + borrado por rango** (relacionado al "dónde" = `entidad`):
   - Consulta: `JpaSpecificationExecutor`, `@Query` con parámetros opcionales, o método derivado con `Pageable`. Filtro por módulo/entidad = filtro por columna `entidad` (decisión documentada abajo).
   - Borrado: **bulk delete eficiente** — `@Modifying @Query("DELETE FROM Auditoria a WHERE a.fecha BETWEEN :desde AND :hasta")` (o método derivado `deleteByFechaBetween`) con `@Transactional` y `clearAutomatically`. NO iterar fila a fila (evita N eliminatorios y carga en memoria con volumen alto).
5. **Instrumentación del resto del sistema** (pattern ya existente en `UsuarioService`/`RolService`): inyectar `AuditService` y registrar `CREAR`/`ACTUALIZAR`/`ELIMINAR`/`ANULAR` tras el save exitoso en:
   - `ProductoService` (entidad PRODUCTO), `CategoriaService` (CATEGORIA), `ProveedorService` (PROVEEDOR), `ClienteService` (CLIENTE), `VentaService` (VENTA, incl. `ANULAR`), `CompraService` (COMPRA, incl. `ANULAR`), `PrecioService` (PRECIO, actualizar precio de venta), `MovimientoStockService` (MOVIMIENTO, crear), `GastoService` (GASTO).
   - `ReporteService` es read-only → **no aplica**.
   - Convención `entidad` = nombre de módulo en mayúsculas (`PRODUCTO`, `VENTA`, `COMPRA`…), coincidiendo con el catálogo de módulos del sidebar.
   - Operaciones rechazadas/validadas no generan filas (el registro ocurre tras el save exitoso, atómico con la operación vía `Propagation.MANDATORY`).
   - **Opcional/bajo**: auditar login exitoso (`entidad="AUTH"`, `accion="LOGIN"`) — ver decisión D5; decidible en spec por consideraciones de volumen/PII.
6. **UI de logs (Angular, feature module NgModule — patrón del proyecto, NO standalone)**:
   - `frontend/src/app/logs/` (`logs.module.ts`, `logs-routing.module.ts`, `log-list/` con tabla paginada **server-side** + formulario de filtros, `log.service.ts`).
   - Entrada nueva en `RUTAS_POR_PERMISO` (`{ label: 'Logs', route: '/logs', permissions: ['LOGS_VER'] }`) → el sidebar la muestra automáticamente y el guard/rutas la protegen.
   - Ruta `/logs` en `app-routing.module.ts` con `data: { permissions: permisosDeRuta('/logs') }` y `AuthGuard`.
   - **Borrado por rango**: acción "Borrar por rango" (botón) **visible solo con `LOGS_ELIMINAR`** (via `*appHasPermission` o `HasPermissionDirective`), con date-range picker y **diálogo de confirmación** (destructivo, no reversible) que muestra la fecha desde/hasta antes de ejecutar. No hay borrado por fila individual (bulk por rango únicamente).
7. **Tests**:
   - Backend: actualizar `PreAuthorizeDriftTest` (catálogo pasa a **44 permisos**; **71 pares** con ADMIN = 44 + VENDEDOR 9 + BODEGUERO 18); nuevo test de consulta paginada con filtros; test de borrado por rango (403 sin `LOGS_ELIMINAR` / 200 con, rango inválido → 400, borrado físico + conteo); test de seguridad (403 sin `LOGS_VER`, 200 con); test de auditoría representativa (una operación escriba fila; otra rechazada no la escriba).
   - Frontend: test del `log-list` (render tabla + filtros + paginación + botón borrar por rango condicionado a permiso + diálogo de confirmación satisfecho/cancelado), opcional test del service.

### Out of Scope

- **Persistencia en Mongo / RAG / chat**: Mongo queda reservado para un futuro RAG/chat. Excluido (decisión de arquitectura del usuario). Los logs viven SOLO en PostgreSQL.
- **Redundancia/backup**: la redundancia es por **replicación de PostgreSQL**, no por un segundo motor de logs. Solo contexto, fuera de implementación.
- **Edición o creación manual de logs** desde la UI/API: los logs son inmutables en contenido; no hay `LOGS_CREAR` ni `LOGS_EDITAR` (la creación la hace el propio sistema). **El borrado por rango SÍ está en scope** (decisión confirmada del usuario, punto 5 del Intent).
- **Borrado por fila individual / borrado selectivo** de logs: solo existe borrado **por rango de fechas** (`DELETE /api/logs?desde=..&hasta=..`), no por id ni por selección múltiple.
- **Exportación de PII / de logs a CSV/Excel**: no en este change.
- **Auditoría de login de fallidos** (alto volumen y riesgo PII): no incluida por defecto; solo login exitoso (opcional, decisión en spec).
- **Retención, archivo, particionado o purgado de logs**: política de BD futura; fuera de alcance (contexto: replicación Postgres ya da disponibilidad).
- **Granularidad de "módulo" por entidad derivada** (ej. agrupar VENTA + VENTA_ITEM en el módulo VENTAS): no es necesidad hoy (ver decisión B1).

## Approach

**Enfoque conservador y sin migración de esquema**: se reutiliza la tabla genérica `auditoria` existente (columna `entidad` como "dónde") y se agrega únicamente la capa de consulta + instrumentación.

### Decisiones con trade-offs

| # | Decisión | Opción elegida / Racional | Alternativas (descartadas) |
|---|----------|---------------------------|----------------------------|
| 1 | **"Dónde" = columna `entidad` (sin columna `modulo` nueva)** | El "en qué parte del sistema" YA lo captura `entidad` (USUARIO, ROL, VENTA, PRODUCTO…). La entity fue diseñada "para todo el sistema" sin migración. Filtrar logs por módulo = filtrar por `entidad` (índexable, directo). Cero DDL, cero backfill, cero cambio a todos los llamadores de `registrarEvento`. | Agregar `columna modulo` FK: desacopla "módulo navegacional" de "entidad" y permite logs de sistema (login→AUTH) y agrupación de sub-entidades. **Descartado**: requiere DDL + backfill + tocar todos los callers; no es necesidad actual. Eventos de sistema usan `entidad="AUTH"/"SISTEMA"` con `entidadId=null`. |
| 2 | **Módulo LOGS 14º con dos permisos: `LOGS_VER` + `LOGS_ELIMINAR`** | El requisito nuevo exige borrado por rango → se habilita `LOGS_ELIMINAR` (view + delete). Sin `LOGS_CREAR`/`LOGS_EDITAR` (logs inmutables en contenido). `MODULOS.put("LOGS", {14, 1, 0, 0, 1})`. Matriz: **ADMIN = ambos**; VENDEDOR/BODEGUERO sin LOGS por defecto (asignable por override). Ambos entran a la matriz como los demás permisos (requisito). | Reutilizar `USUARIOS_VER`/`ROLES_VER` como gate: **descartado** — sin granularidad propia. Y `LOGS_VER` como único permiso (sin borrado): **descartado** por el requisito del usuario (punto 5 del Intent). |
| 3 | **Paginación server-side (Pageable) + filtros** | El volumen alto de la tabla de auditoría obliga a no traer toda la lista; `Page<AuditoriaDTO>` es el patrón de Spring Data estándar. Filtros: rango de fecha, usuario, entidad, accion. | Lista sin paginar (como el resto del backend): **descartada** por alto volumen de la tabla de logs. |
| 4 | **Borrado por rango = bulk delete (no iterativo)** | `@Modifying @Query("DELETE ... WHERE fecha BETWEEN :desde AND :hasta")` ejecuta UN statement SQL; no carga filas en memoria ni hace N borrados uno a uno. Devuelve filas eliminadas. Requiere `@Transactional` + `clearAutomatically` para no dejar entidades stale en el contexto. | `deleteByFechaBetween` derivado de Spring Data: **también válido** (internamente itera — aceptable en H2/tests, menos ideal en prod con mucho volumen). Preferir el `@Modifying @Query` para el borrado masivo. |
| 5 | **Rango `desde`/`hasta` OBLIGATORIO y validado** | Borrar sin rango = riesgo de borrar TODA la tabla. Se exigen ambos params (`400` si faltan, `400` si `hasta < desde`). El borrado es `[desde, hasta]` inclusive sobre `fecha`. | Permitir delete sin parámetros (borrar todo): **descartado** — operación destructiva irreversible sin límite. |
| 6 | **El borrado NO se audita a sí mismo** (excepción consciente) | Auditar un bulk delete de auditoría sería contradictorio: la fila "se borraron N logs" caería dentro del rango eliminado (o crearía un hueco). Se documenta como excepción: la operación de borrado masivo NO genera fila de auditoría. **Riesgo aceptado** (sin trazabilidad de quién borró logs); mitigación parcial: el permiso `LOGS_ELIMINAR` es restrictivo (solo ADMIN por defecto) y el endpoint queda en logs de aplicación/BD (no en tabla auditoria). | Escribir una fila de auditoría "sumaria" ANTES del borrado (fuera del rango): **descartado** — complejidad y confusión (fila huérfana); se acepta la no-auditoría del borrado masivo. |
| 7 | **Instrumentación: set pragmático completo** de servicios de escritura del dominio | Da visibilidad real de "qué se hizo" en todo el sistema (requisito central). Es mecánico siguiendo el patrón ya existente en `UsuarioService`. | Mínimo (solo usuarios/roles): no cumple el requisito. |
| 8 | **Login: solo exitoso, opcional, con usuario explícito** | Trazabilidad de accesos. `AuditService.usuarioActual()` puede no estar disponible durante `login()` (el `SecurityContext` aún no se actualizó), por lo que debe pasarse el usuario como parámetro; y solo registar tras el éxito para no inflar el volumen con intentos fallidos/PII. | Log de fallidos: **excluido** por volumen alto y riesgo PII. |
| 9 | **Frontend NgModule (no standalone)** | El proyecto usa NgModules (config.yaml): seguir el patrón de `frontend/src/app/roles/`, el especialista angular. NO se crean componentes standalone. | Standalone: **descartado** — rompe la convención del proyecto (NgModule, feature modules). |
| 10 | **Backup = replicación de PostgreSQL** | Confirmado por el usuario como contexto; no se implementa ningún segundo motor. | — |

### Modelo de datos (sin migración — schema existente)

```
auditoria(id, entidad, entidad_id, accion, usuario_id → Usuario, fecha, detalle)
  -- EXISTENTE. Uso ampliado: entidad = módulo del catálogo (VENTA, PRODUCTO, ...) o AUTH/SISTEMA; accion = CREAR/ACTUALIZAR/ELIMINAR/ANULAR/LOGIN
```

`ddl-auto: update` ya creó la tabla; no se agrega columna nueva. **Índice recomendado en `(fecha)` o `(entidad, fecha)`** — mejora el filtrado y el borrado por rango con volumen alto; pendiente de decisión en spec/Flyway (script/sql revisado por el usuario, no auto-migración destructiva).

### Seguridad

- `@PreAuthorize("hasAuthority('LOGS_VER')")` en `GET /api/logs`; `@PreAuthorize("hasAuthority('LOGS_ELIMINAR')")` en `DELETE /api/logs`. Ambos permisos se siembran en el catálogo (DataSeeder) y en la matriz de ADMIN; se asignan a otros roles/usuarios desde la UI de roles/usuarios ya existente.
- `PreAuthorizeDriftTest`: se actualizan los conteos (42→**44 permisos**; 3 roles; pares 69→**71** = ADMIN(44) + VENDEDOR(9) + BODEGUERO(18), con ADMIN recibiendo LOGS_VER + LOGS_ELIMINAR). El test de "todo permiso del catálogo protegido" ahora encuentra `LOGS_VER` y `LOGS_ELIMINAR` en el nuevo controller (pasa el test 3 sin modificar allowlist).

### Tamaño estimado

**Medio** (~2-3 sesiones de implementación). Backend: catálogo + seeder (bajo), `LogController` + `LogService` + query paginado (medio), bulk delete con validación de rango (bajo-medio), instrumentación de ~9 services (mecánico, medio), tests backend incl. drift test (medio). Frontend: feature module `logs/` con tabla server-side + filtros (medio) y borrado por rango con confirmación (bajo). La adición del borrado por rango incrementa el estimado original en ~15-20% (endpoint + UI de borrado + tests de 400/403/conteo).

## Affected Areas

| Área | Impacto | Descripción |
|------|---------|-------------|
| `backend/.../config/DataSeeder.java` | Modificado | Módulo LOGS (14) → 2 permisos LOGS_VER + LOGS_ELIMINAR, NOMBRE módulo, matriz ADMIN += ambos |
| `backend/.../controller/LogController.java` | Nuevo | `GET /api/logs` paginado/filtrado (`LOGS_VER`) + `DELETE /api/logs?desde&hasta` (`LOGS_ELIMINAR`) |
| `backend/.../service/LogService.java` | Nuevo | Consulta paginada con filtros + borrado por rango sobre `AuditoriaRepository` |
| `backend/.../repository/AuditoriaRepository.java` | Modificado | Query paginado con filtros (`Pageable` + Specification) + `@Modifying @Query DELETE ... WHERE fecha BETWEEN` (bulk) |
| `backend/.../dto/AuditoriaDTO.java` | Nuevo | DTO de respuesta (incl. usuarioNombre); respuesta de borrado (conteo eliminados) |
| `backend/.../service/{Producto,Categoria,Proveedor,Cliente,Venta,Compra,Precio,MovimientoStock,Gasto}Service.java` | Modificado | Instrumentar `auditService.registrarEvento(...)` tras save |
| `backend/.../service/AuthService.java` | Modificado (opcional) | Auditar login exitoso (entidad AUTH) |
| `backend/src/test/.../PreAuthorizeDriftTest.java` | Modificado | Actualizar conteos catálogo/matriz (44 permisos / 71 pares) |
| `backend/src/test/...` | Nuevo | Tests: consulta paginada/filtros, borrado por rango (403/200/400+conteo), 403 sin LOGS_VER, auditoría de operación |
| `frontend/src/app/logs/` | Nuevo | Feature module NgModule: listado paginado server-side + filtros + **borrado por rango (botón + picker + confirmación)** + service |
| `frontend/src/app/core/rutas-por-permiso.ts` | Modificado | Entrada `Logs` → `/logs` con `['LOGS_VER']` (muestra en sidebar + guard) |
| `frontend/src/app/app-routing.module.ts` | Modificado | Ruta `/logs` lazy con `data.permissions` + `AuthGuard` |
| `frontend/src/app/shared/sidebar/` | Sin cambio directo | Lee de RUTAS_POR_PERMISO; el item aparece automìticamente |
| `frontend/src/app/core/auth.service.ts` | Sin cambio directo | Guard ya evalúa `data.permissions`; `HasPermissionDirective` oculta el botón de borrado sin `LOGS_ELIMINAR` |

## Risks

| Riesgo | Probabilidad | Mitigación |
|--------|--------------|------------|
| `PreAuthorizeDriftTest` (y seeder) fallan al agregar LOGS_VER + LOGS_ELIMINAR si no se actualizan los conteos exactos | Alta (test de igualdad exacta) | Actualizar conteos (**44 permisos / 71 pares**) en el MISMO cambio; el test DEBE pasar antes de merge |
| Consistencia audit por `AuditService` con `MANDATORY` y servicios claros con `@Transactional` en clase | Baja | Todos los servicios de escritura objetivo ya tienen `@Transactional` a nivel clase; los listados readOnly no auditan (no aplican) |
| **Borrado por rango borra más/menos de lo esperado** (límites de fecha) o permite borrar toda la tabla | Media | Rango `desde`/`hasta` **obligatorio** (400 si falta); `400` si `hasta < desde`; inclusividad explícita `[desde, hasta]` sobre `fecha`; diálogo de confirmación que muestra el rango |
| **Bulk delete masivo** (muchos días) puede bloquear la tabla durante el statement | Media | Índice `(fecha)` convierte el DELETE by range en barrido indexado; rangos acotados en UI; límite opcional de ventana (decisión en spec) |
| Login audit: `usuarioActual()` no disponible dentro de `login()` (SecurityContext aún no actualizado) | Media (solo opcional) | Pasar usuario explícito como argumento a `registrarEvento("AUTH", id, "LOGIN", null)`; si se omite, no se incluye en el change base y se decide en spec |
| Frontend: los demás listados filtran in-memory (MatTableDataSource.filter); los logs requieren paginación server-side | Media | `log-list` usa `MatPaginator` + consulta con query params contra la `Page`, no el filter client-side |
| **No-auditoría del borrado masivo** (sin trazabilidad de quién borró logs en la tabla auditoria) | Media (aceptado, decisión D6) | Excepción consciente y documentada; mitigación: `LOGS_ELIMINAR` restrictivo (solo ADMIN por defecto) + endpoint queda en logs de app/BD; trazabilidad futura evaluable (auditar fuera del rango) |
| Volumen alto: crecimiento indefinido de `auditoria` degrada consultas filtradas | Media | Filtros + paginación desde el día 1; índice (`fecha`, `entidad`) como parte del cambio; **borrado por rango disponible como herramienta de contención** (este requisito resuelve este riesgo) |
| Coherencia entidad↔módulo: si la instrumentación nueva no usa la convención del catálogo, el filtro por módulo no mapea | Baja | Usar `entidad` == código de módulo en mayúsculas (PRODUCTO, VENTA, ...); documentado en la instrumentación |

## Rollback Plan

Como el cambio NO modifica esquema existente (reusa `auditoria`), el rollback es de código y datos:

- **Código**: revertir el PR (git revert / checkout del commit previo). Archivos nuevos (`LogController`, `LogService`, `AuditoriaDTO`, módulo `frontend/src/app/logs/`) se eliminan; los modificados (DataSeeder, repositorio, servicios instrumentados, rutas, RUTAS_POR_PERMISO, PreAuthorizeDriftTest) vuelven al estado previo.
- **Datos**: las filas de auditoría instrumentadas nuevas quedan en la tabla (no violan el contrato); los permisos `LOGS_VER`/`LOGS_ELIMINAR` y el módulo LOGS se retiran del seeder con el revert del código (el seed es idempotente; no duplica catálogo). **Ojo**: el borrado por rango es IRREVERSIBLE — una vez ejecutado, las filas no se recuperan salvo backup/replicación de Postgres (que es la estrategia confirmada del usuario). El rollback del código NO restaura filas ya borradas.
- **Regla de oro**: no mergear sin que `PreAuthorizeDriftTest` pase con los nuevos conteos (44 permisos / 71 pares) y sin verificar manualmente: (1) usuario con `LOGS_VER` lista logs y sin él recibe 403 en `GET /api/logs`; (2) usuario con `LOGS_ELIMINAR` borra un rango acotado y el conteo devuelto coincide; (3) usuario sin `LOGS_ELIMINAR` recibe 403 en `DELETE /api/logs`.

## Dependencies

- **Prerrequisito interno**: change `modulo-roles-permisos` completado (tabla `auditoria`, `AuditService`, catálogo de permisos, guards con `data.permissions`) — YA implementado y probado (48 tests). No se reconstruye nada.
- **Sin dependencias externas**. Se asume el stack existente (Spring Boot 3.5.16 / Java 21, Angular 22 NgModule, PostgreSQL prod / H2 tests) sin cambios.
- Posible índice en `auditoria` (migración/DDL) — si se agrega, se documenta como script/sql revisado por el usuario (no auto-migración destructiva).

## Success Criteria

- [ ] Un usuario con `LOGS_VER` puede listar logs (UI o GET /api/logs) y filtrar por fecha, usuario, módulo/entidad y accion; la respuesta es paginada.
- [ ] Un usuario sin `LOGS_VER` recibe **403** en `GET /api/logs` (backend) y no ve la ruta `/logs` en el sidebar (frontend).
- [ ] Un usuario con `LOGS_ELIMINAR` puede borrar un rango de fechas vía `DELETE /api/logs?desde=&hasta=`; el backend devuelve el **conteo de filas eliminadas** y el borrado **se ejecuta como bulk** (verificado en el conteo/repositorio). El rango es **obligatorio**: sin `desde`/`hasta` o con `hasta < desde` responde **400** y no borra nada.
- [ ] Un usuario sin `LOGS_ELIMINAR` recibe **403** en `DELETE /api/logs` (backend) y **no ve** el botón "Borrar por rango" en la UI (frontend).
- [ ] Los permisos `LOGS_VER` y `LOGS_ELIMINAR` aparecen en el catálogo, se asignan/remueven al crear/editar roles y usuarios desde la UI de usuarios/roles existente, y los datos de instrumentación de usuario/rol existentes se conservan.
- [ ] Operaciones de escritura del dominio (producto, categoria, proveedor, cliente, venta/anulación, compra/anulación, precio, movimiento, gasto) registran filas en `auditoria` con `entidad`, `entidad_id`, `accion`, `usuario_id` y `fecha` correctos; operaciones rechazadas **no** generan filas.
- **`PreAuthorizeDriftTest`** pasa con los conteos actualizados (**44 permisos / 71 pares**) y con `LOGS_VER` y `LOGS_ELIMINAR` referenciados en `@PreAuthorize` (se mantiene el resto del catálogo).
- El cambio incluye tests backend (consulta paginada/filtros, borrado por rango incl. 400/403/200 + conteo, auditoría de operación) y frontend (lista paginada/filtros, borrado por rango condicionado a permiso + confirmación) que pasan; `mvn test` (Docker) y `npm test` en verde.
- El borrado masivo **NO** se audita a sí mismo (excepción documentada, decisión D6) y no hay exportación de PII ni edición/creación manual de logs; no se agrega ningún motor de logs fuera de PostgreSQL. (non-goals verificables en código).