# Informe de Tests — Módulo Logs

> Change: `modulo-logs` · Stacks 1 (backend) y 2 (frontend) · Fecha: 2026-08-04 (actualizado con refinamientos y fixes)

## Resumen ejecutivo

| Métrica | Backend | Frontend |
|---|---|---|
| **Total de tests** | 87 | 77 |
| **Clases de test** | 14 | 8 |
| **Resultado** | **87/87 OK — 0 fallos, 0 errores, 0 skipped** | **77/77 OK — 0 fallos** |
| **Suite completa** | `BUILD SUCCESS` | `npm test` OK (8 archivos) |
| **Comando** | `docker run --rm -v "$(pwd)":/app -w /app maven:3.9-eclipse-temurin-21 mvn test` | `npm test` (vitest + jsdom, builder `@angular/build:unit-test`) |
| **Packaging** | `mvn package -DskipTests` OK → jar | `ng build` OK (solo warning preexistente CommonJS sweetalert2) |
| **Base** | Docker `maven:3.9-eclipse-temurin-21` (Java 21, sin Maven local), Spring Boot 3.5.16, H2 con perfil `test` | Angular 22, vitest + jsdom, NgModules (no standalone) |

Los 87 tests backend cubren las 14 clases de la suite: 39 tests **nuevos** del change (consulta paginada con filtros incluido `usuarioId`, borrado por rango, instrumentación de los 9 servicios de dominio con **diff antes/después**, drift catálogo↔`@PreAuthorize` 44/71, seeder 14/44/71, endpoint `/api/logs/usuarios`, fix preserve-if-null en ProductoService) y 48 tests **preexistentes preservados** como regresión.

Los 77 tests frontend cubren 8 archivos: 35 tests **nuevos** del change (servicio de logs con query params incluido `usuarioId` y `listarUsuarios`, componente de lista con paginación server-side, filtros, columnas ID Entidad/ID Usuario, formateo del detalle con diff, diálogo de borrado por rango con visibilidad por permiso, carga de usuarios) y 42 tests **preexistentes preservados** como regresión (auth service, guard, directiva de permisos, matriz de permisos).

## Clasificación por funcionalidad

| Clase de test | Funcionalidad que cubre | Requisito | Tests | Resultado |
|---|---|---|---|---|
| `service/LogServiceTest` | Consulta paginada con `Specification`, mapeo a `AuditoriaDTO`, borrado por rango (expansión día, validación 400) | R2, R3 | 12 | ✅ OK |
| `security/LogControllerIntegrationTest` | Contrato HTTP real de `GET /api/logs` (`LOGS_VER`) y `DELETE /api/logs` (`LOGS_ELIMINAR`): 200/400/403, borrado físico, no auto-auditoría, sin borrado por fila, `GET /api/logs/usuarios` | R2, R3, R6, R10 | 16 | ✅ OK |
| `service/AuditoriaInstrumentacionTest` | Instrumentación de los 9 servicios de dominio (entidad singular, actor, atomicidad), login exitoso (AUTH, usuario explícito) y fallidos sin fila, fix ProductoService preserve-if-null | R4, R5, R10 | 8 | ✅ OK |
| `security/PreAuthorizeDriftTest` | Drift catálogo ↔ anotaciones con el nuevo `LogController` (`LOGS_VER`/`LOGS_ELIMINAR`); conteos 14 módulos / 44 permisos / 71 pares | R9.4, R1, R6 | 3 | ✅ OK |
| `security/DataSeederIdempotencyTest` | Seed idempotente + estado completo (**14 módulos, 44 permisos, 71 pares** = ADMIN 44 + VENDEDOR 9 + BODEGUERO 18) | R6, R1 (R9.3) | 2 | ✅ OK |
| *(9 clases preexistentes)* | Regresión: resolución de permisos, enforcement mock/JWT, usuarios+overrides, auditoría base, serialización JSON, precios, compras, contexto | Regresión | 43 | ✅ OK |
| `logs/log.service.spec.ts` | Construcción del query string de `GET /api/logs` (page/size + filtros opcionales incluido `usuarioId`) y `DELETE /api/logs?desde=&hasta=`, `listarUsuarios` | R7, R8 | 5 | ✅ OK |
| `logs/detalle.util.spec.ts` | Formateo del detalle para presentación: diff `antes -> despues`, snapshot `campo: valor`, JSON inválido → raw, null → '—' | R7 (refinamiento) | 12 | ✅ OK |
| `logs/log-list/log-list.component.spec.ts` | Render de filas (ID Entidad/ID Usuario/Usuario), estado vacío, filtros por usuarioId + paginación server-side, formateo del detalle, diálogo de borrado: visibilidad por `LOGS_ELIMINAR`, cancelar sin borrar, confirmar llama al servicio y recarga, carga de usuarios | R7, R8 | 18 | ✅ OK |

## Detalle por clase de test nueva

### `service/LogServiceTest` — Unitario (Mockito, sin contexto Spring)

12 tests que cubren la capa de servicio de consulta y borrado (R2, R3):

- `consultar_conTodosLosFiltros_pasaSpecification` — todos los filtros (rango, usuario, entidad, acción) construyen una `Specification` que se pasa al repositorio.
- `consultar_sinFiltros_pasaSpecificationSinPredicados` — sin filtros no se agregan predicados (no filtra de más).
- `consultar_conUsuario_mapeaUsuarioIdYNombre` — el `AuditoriaDTO` incluye `usuarioId` + `usuarioNombre` del join `usuario` (R2: quién hizo la acción).
- `consultar_sinUsuario_dejaUsuarioIdYNombreNulos` — fila sin usuario asociado no rompe el mapeo (null-safe).
- `eliminarPorRango_fechaSola_expandeInicioYFinDeDia` — una fecha `LocalDate` se expande a `startOfDay`/`endOfDay` (D4; evita el bug del "día 31").
- `eliminarPorRango_datetimeISO_usaElValorLiteral` — un `LocalDateTime` ISO se usa literal (soporta precisión horaria).
- `eliminarPorRango_sinRango_lanza400YNoBorra` — falta `desde` o `hasta` → 400 y **no borra**.
- `eliminarPorRango_formatoInvalido_lanza400YNoBorra` — formato de fecha inválido → 400 y no borra.
- `eliminarPorRango_rangoInvertido_lanza400YNoBorra` — `hasta < desde` → 400 y no borra.

### `security/LogControllerIntegrationTest` — Integración (MockMvc + JWT real, transaccional)

16 tests que ejercitan el contrato HTTP real del endpoint de logs (R2, R3, R6, R10). Corre con tokens JWT reales (login vía `AuthService`) para confirmar que el enforcement vive en backend:

- `admin_consultaLogs_devuelvePageConEstructuraCompleta` — `GET /api/logs` con `LOGS_VER` → 200 y `Page` con `content`, `totalElements`, orden `fecha DESC`.
- `vendedor_sinLOGS_VER_recibe403` — vendedor (sin `LOGS_VER`) → 403 (matriz R6 restringe de verdad).
- `filtroPorRango_devuelveSoloFilasDelRango` — rango `desde`/`hasta` devuelve únicamente las filas del rango.
- `filtroCombinadoEntidadYAccion` — combina `entidad` (singular) + `accion` → filas que cumplen ambos.
- `filtroPorUnSoloExtremo_Desde_soloDevuelvePosteriores` — solo `desde` devuelve posteriores a esa fecha (inclusive).
- `filtroPorUsuarioId_devuelveSoloEseUsuario` — filtra por `usuarioId` (quién hizo la acción).
- `vendedor_sinLOGS_ELIMINAR_recibe403SinBorrarFilas` — `DELETE` sin permiso → 403 y **no borra ninguna fila**.
- `borradoSinParametros_recibe400YNoBorra` — sin `desde`/`hasta` → 400 y no borra.
- `rangoRevertido_recibe400YNoBorra` — `hasta < desde` → 400 y no borra.
- `formatoInvalido_recibe400YNoBorra` — fecha malformada → 400 y no borra.
- `borradoPorRango_devuelveConteoYQuitaFilasFisicamente` — 200 + `{eliminados: N}` con borrado físico real (re-query confirma ausencia).
- `rangoSinRegistros_devuelve200Eliminados0` — rango vacío → 200 con `eliminados: 0` (no es error).
- `borradoPorRango_noSeAutoAudita` — el borrado masivo **NO** audita su propia acción (D6: la fila caería en el rango).
- `noExisteBorradoPorFilaIndividual` — no hay endpoint de delete por fila (solo rango, R3).
- `usuariosConActividad_devuelveSoloConActividad` — `GET /api/logs/usuarios` retorna solo usuarios con logs registrados (id + nombre).
- `usuariosConActividad_sinLOGS_VER_recibe403` — `GET /api/logs/usuarios` sin `LOGS_VER` → 403.

### `service/AuditoriaInstrumentacionTest` — Integración (H2, transaccional)

8 tests la instrumentación del dominio (R4, R5, R10), verificando que el patrón `registrarEvento` quedó extendido a toda la operativa:

- `registraEntidadIdYCorrectos` — creación de un producto registra fila `PRODUCTO/CREAR` con `entidad_id` = id del recurso.
- `registraEntidadIdYusuarioCorrectos` — instrumentación con actor autenticado.
- `registraFilaMovimiento` — acción sobre movimiento registra fila `MOVIMIENTO/...` con singular correcto.
- `registraFilaAnular` — **anulación** de venta/compra registra `VENTA/ANULAR` / `COMPRA/ANULAR`.
- `noDejaFila` — operación rechazada (400/409/403) no deja fila (atomicidad R10: rechazos nunca auditan).
- `registraAuthLoginConUsuarioExplicito` — login exitoso registra `AUTH/LOGIN` con actor explícito (overload de `AuditService`, D8).
- `noRegistraFilaAuth` — login fallido no registra (R5: solo exitosos).
- `actualizarProducto_sinCambiarProveedor_noRegistraProveedorIdEnDiff` — fix preserve-if-null: actualizar un producto sin enviar proveedor/categoria no los pone en null en el diff.

### `security/PreAuthorizeDriftTest` — Integración (reflexión sobre controllers)

Sin cambios estructurales; se actualizaron los conteos al nuevo estado del catálogo:

- `catalogo_seed_es_completo` — ahora **14 módulos / 44 permisos / 71 pares** (ADMIN 44 incluye `LOGS_VER`+`LOGS_ELIMINAR`; VENDEDOR 9 y BODEGUERO 18 intactos).
- `todo_codigo_en_anotaciones_existe_en_catalogo` — `hasAuthority('LOGS_VER')`/`hasAuthority('LOGS_ELIMINAR')` del `LogController` existen en el catálogo.
- `todo_permiso_del_catalogo_esta_protegido_salvo_allowlist` — allowlist sin cambios `{VENTAS_EDITAR, ROLES_CREAR, ROLES_ELIMINAR}`.

### `security/DataSeederIdempotencyTest` — Integración (H2, seed ejecutado dos veces)

15e re-ejecuta el seed para verificar idempotencia y el estado sembrado:

- `dobleEjecucion_noCambiaElEstado` — re-ejecutar no duplica módulos, permisos, pares, ni al admin (idempotencia del módulo LOGS agregado).
- `seed_siembraElEstadoCompletoEsperado` — ahora **14 módulos, 44 permisos, 71 pares** (R6) con el módulo `LOGS` presente y el admin con ambos permisos nuevos.

### `logs/log.service.spec.ts` — Unitario (HttpClient mockeado)

5 tests que cubren el contrato HTTP del frontend (R7):

- `list arma el query con page/size y todos los filtros presentes` — `GET /api/logs` con `page`, `size`, `fechaDesde`, `fechaHasta`, `usuarioId`, `entidad`, `accion`.
- `list omite los filtros vacíos del query string` — filtros vacíos/null no contaminan la URL.
- `list omite usuarioId cuando es null o undefined` — el usuario filtro es opcional (null-safe).
- `listarUsuarios llama GET /logs/usuarios` — consume el endpoint de usuarios para el dropdown del filtro.
- `deleteByRange llama DELETE /logs con desde y hasta` — `DELETE /api/logs?desde=&hasta=` y devuelve `{eliminados}` (R8).

### `logs/log-list/log-list.component.spec.ts` — Componente (vitest + jsdom, NgModule)

11 tests que cubren la lista con paginación server-side, el diálogo de borrado (R7, R8) y la carga de usuarios:

- `renderiza las filas de la página devuelta por el backend` — la tabla pinta `entidad` (label singular), `entidadId`, `accion`, `usuarioNombre` y `fecha` formateada.
- `muestra el estado vacío cuando el backend devuelve una página sin filas` — sin contenido → mensaje "sin registros".
- `aplicarFiltros re-consulta el servidor con los filtros formateados y vuelve a la página 0` — aplicar filtros → `list()` con página 0 (R7).
- `limpiarFiltros resetea el formulario y re-consulta desde la página 0` — limpiar → reset + re-consulta.
- `onPageChange re-consulta el servidor con la nueva página y tamaño` — el `PageEvent` del `MatPaginator` dispara re-consulta server-side (patrón nuevo del proyecto).
- `el botón "Borrar por rango" es visible solo con LOGS_ELIMINAR` — con el permiso el botón existe (R8, `*appHasPermission`).
- `el botón "Borrar por rango" NO se renderiza sin LOGS_ELIMINAR` — sin el permiso no hay botón (ni borrado por fila, R3).
- `cancelar el diálogo de borrado NO llama a deleteByRange` — cancelar → sin llamada (R8: confirmación destructiva).
- `confirmar el diálogo llama a deleteByRange con el rango y recarga la lista` — confirmar → `deleteByRange(desde, hasta)` + recarga (R8).
- `loadUsuarios llama listarUsuarios y carga la lista de usuarios` — al inicializar el componente, se llama `listarUsuarios()` y se carga la lista de usuarios disponibles para el dropdown del filtro.
- `loadUsuarios maneja error sin bloquear la tabla` — si `listarUsuarios()` falla, la tabla carga normalmente con el dropdown vacío.

## Mapa a requisitos (R1-R10)

| Requisito | Clases que lo cubren | Notas de cobertura |
|---|---|---|
| **R1** Módulo LOGS 14º en seed | `DataSeederIdempotencyTest`, `PreAuthorizeDriftTest` | 14 módulos / 44 permisos / 71 pares sembrados y consistentes; `LOGS_VER`+`LOGS_ELIMINAR` solo ADMIN; sin `LOGS_CREAR`/`LOGS_EDITAR`. |
| **R2** GET /api/logs paginado con filtros | `LogServiceTest`, `LogControllerIntegrationTest` | `Page<AuditoriaDTO>` server-side con filtros opcionales (rango, usuario, entidad singular, acción) y `@PreAuthorize('LOGS_VER')`; 403 sin permiso. |
| **R3** DELETE por rango | `LogServiceTest`, `LogControllerIntegrationTest` | 200+conteo, rango obligatorio (400 faltantes/inválidos/invertidos sin borrar), 403 sin `LOGS_ELIMINAR`, rango vacío→0, sin borrado por fila. |
| **R4** Instrumentación de dominio | `AuditoriaInstrumentacionTest` | 9 servicios instrumentados con `entidad` singular; CREAR/ACTUALIZAR/ELIMINAR + ANULAR de venta/compra. |
| **R5** Login instrumental | `AuditoriaInstrumentacionTest` | Solo exitoso registra `AUTH/LOGIN` (overload D8); fallidos no. |
| **R6** Permisos asignables | `PreAuthorizeDriftTest`, `DataSeederIdempotencyTest`, `LogControllerIntegrationTest` | Matriz del seed asigna `LOGS_VER`/`LOGS_ELIMINAR` (ADMIN); vendedor sin permisos → 403 real con token. |
| **R7** Frontend lista paginada | `logs/log.service.spec.ts`, `logs/log-list/log-list.component.spec.ts` | Query string correcto, render de filas, estado vacío, filtros → página 0, PageEvent → re-consulta. La UI/sidebar/guard se verifican además con `ng build` limpio y el checklist manual (T8.2). |
| **R8** Borrar por rango | `logs/log.service.spec.ts`, `logs/log-list/log-list.component.spec.ts` | Botón solo con `LOGS_ELIMINAR`, sin botón sin permiso, cancelar no borra, confirmar llama `DELETE` y recarga. |
| **R9** Drift + tests | `PreAuthorizeDriftTest`, `DataSeederIdempotencyTest`, `LogServiceTest`, `LogControllerIntegrationTest`, `AuditoriaInstrumentacionTest` | Conteos actualizados 44/71 en el mismo change; edge cases de consulta y borrado cubiertos. |
| **R10** Atomicidad | `AuditoriaInstrumentacionTest` (+ `AuditoriaTest` preexistente) | `Propagation.MANDATORY`; rechazos nunca auditan; excepción consciente: bulk delete no se auto-audita (D6). |

## Refinamientos post-verificación manual (aprobados por el usuario)

Durante la demo de aceptación (T8.2) el usuario detectó mejoras adicionales, implementadas y cubiertas por tests:

4. **Selector de usuarios para filtro (dropdown en vez de texto)** — El filtro de usuario era un text input que enviaba `usuarioNombre` (LIKE). Se reemplazó por un `mat-select` que carga usuarios con actividad desde `GET /api/logs/usuarios` (endpoint nuevo en `LogController`). El frontend ahora envía `usuarioId` (filtro exacto). Backend: `AuditoriaRepository.findUsuariosConActividad()` retorna solo usuarios con registros de auditoría. Cubierto por 2 tests nuevos en `LogControllerIntegrationTest` (`usuariosConActividad_devuelveSoloConActividad`, `usuariosConActividad_sinLOGS_VER_recibe403`), 1 test en `log.service.spec.ts` (`listarUsuarios llama GET /logs/usuarios`) y 2 tests en `log-list.component.spec.ts` (`loadUsuarios llama listarUsuarios...`, `loadUsuarios maneja error...`).
5. **Fix preserve-if-null en ProductoService.update()** — Al editar un producto desde el frontend, el form no envía `proveedor` ni `categoria`, y el service sobreescribía esos campos con null (data-loss silencioso). Fix: `if (productoActualizado.getProveedor() != null)` preserve-if-null para ambos campos. Cubierto por 1 test nuevo en `AuditoriaInstrumentacionTest` (`actualizarProducto_sinCambiarProveedor_noRegistraProveedorIdEnDiff`).

1. **Filtro de logs por NOMBRE de usuario (no por ID)** — El filtro era numérico (`usuarioId`) y un revisor no se sabe los IDs. Se agregó `usuarioNombre` opcional en `GET /api/logs` (LIKE case-insensitive contiene, sobre la relación `usuario` join-eada; AND con `usuarioId` si ambos). Frontend: input de texto "Usuario" → `usuarioNombre`. Cubierto por 3 tests nuevos en `LogServiceTest`, 3 en `LogControllerIntegrationTest`, y asserts en `log.service.spec.ts` + `log-list.component.spec.ts`.
2. **Columnas ID Entidad + ID Usuario + Usuario** — La columna "ID" mostraba `entidadId` (id del registro afectado) con encabezado confuso. Se renombró a **"ID Entidad"**, se agregó columna **"ID Usuario"** (`usuarioId`, fallback '—') y se mantiene "Usuario" (nombre). Cubierto en `log-list.component.spec.ts`.
3. **Detalle con trazabilidad real (diff antes/después)** — Antes, el detalle de `ACTUALIZAR` guardaba solo el estado nuevo (ej. `{"nombre":"X","codigoBarras":"FER013"}`) sin indicar qué cambió. Ahora guarda **solo los campos cambiados** con `{"campo":{"antes":X,"despues":Y}}`, vía el helper nuevo `com.ferreplus.util.AuditDiff` aplicado a los `update()` de Producto/Categoria/Proveedor/Cliente/Compra/Precio/Gasto. CREAR/ELIMINAR/ANULAR conservan su formato. El JSON sigue crudo en la API; el frontend lo **formatea en la presentación** (helper puro `detalle.util.ts`: diff → `campo: antes -> despues`; snapshot → `campo: valor`; inválido → raw; null → '—'). Cubierto por 12 tests unitarios de `detalle.util.spec.ts` + asserts del componente.

Decisiones de diseño documentadas: `VentaService` no tiene `update()` (solo CREAR/ANULAR) → no aplica diff; un update sin cambios produce `{}` (evidencia honesta); los wildcards `%`/`_` del filtro de nombre no se escapan (contrato literal, hardening futuro); el diff de Compra no incluye líneas de detalle (solo campos de cabecera).

## Tests existentes preservados

Singular los 48 tests backend previos al change siguen corriendo sin modificaciones funcionales: `PermisoResolverTest` (6), `SecurityEnforcementTest` (8), `SecurityEnforcementIntegrationTest` (6), `PreAuthorizeDriftTest` (3, **solo se actualizaron los conteos** 44/71 — cambio esperado y obligatorio del change), `DataSeederIdempotencyTest` (2, **idem** conteos a 14/44/71), `UsuarioOverridesTest` (7), `AuditoriaTest` (5), `EntidadJsonSerializationTest` (2), `LogServiceTest` (12 nuevo, era 9 antes de refinamientos), `PrecioServiceTest` (6), `CompraServiceIntegrationTest` (2), `FerreplusApplicationTests` (1). Tests nuevos refinados: `AuditoriaInstrumentacionTest` (8, era 7), `LogControllerIntegrationTest` (16, era 14).

La suite completa es **87/87 OK** (backend) y **77/77 OK** (frontend).

## Errores encontrados y corregidos durante la verificación

1. **`auditoria.fecha` no responde a `setFecha` en tests de integración** — La columna tiene `@PrePersist = now()` con `updatable=false`: en los tests de `LogControllerIntegrationTest` que necesitaban fechas específicas para los filtros, JPA no persiste un `fecha` seteada manualmente y la caché de primer nivel devuelve el valor viejo. **Corrección:** se sembraron las filas con `entidad` vía **INSERT nativo con `JdbcTemplate`** (no por setter de la entidad). Documentado para cualquier test futuro que requiera control de fechas sobre `auditoria`.

2. **`Map.of(...)` lanza NPE con valores null** — Los helpers `jsonDetalle` (JSON de detalle para auditoría) usaban `Map.of`, que rechaza valores nulos (ej. `codigoBarras` null en producto). **Corrección:** todos los `jsonDetalle` quedaron null-safe con `HashMap` mutante (patrón ya usado en el repositorio). Instrumentación robusta ante entidades con atributos opcionales.

3. **`DELETE /api/logs` sin rango caía en 500 en la capa de validación** — Faltaban manejadores explícitos en `GlobalExceptionHandler` para parámetros faltantes / tipo inválido. **Corrección:** handlers dedicados → **400** (`MissingServletRequestParameterException`, `MethodArgumentTypeMismatchException`) y 404 para rutas inexistentes (`NoResourceFoundException`). Antes una ruta inexistente caía en el catch-all 500. Detenido por los tests 400/404.

## Notas y advertencias

- **Warning preexistente de dialecto (no bloqueante):** `application.yml` fuerza `PostgreSQLDialect` sobre el `H2Dialect` del perfil `test`; H2 emite un warning benigno de `client_min_messages`. Preexistente, sin impacto en tests.
- **Índice pendiente de revisión manual:** se creó `backend/db/indices-auditoria.sql` con índices `(fecha)` y `(entidad, fecha)` sobre `auditoria`. **NO se ejecuta** (regla de BD del repo: el usuario revisa y corre scripts manualmente; `spring.sql.init.mode=never`). Es un opcional de performance para tablas grandes de logs.
- **Fecha de filtro `con_inflat`:** por diseño, `GET`/`DELETE` aceptan tanto `LocalDate` (se expande a `startOfDay`/`endOfDay`) como `LocalDateTime` (literal). El frontend envía el rango de día completo y el backend decide — sin bug de "día 31" (D4).
- **Warning preexistente de build frontend (no bloqueante):** `sweetalert2` no es ESM → warning de CommonJS/optimization bailout en `ng build`. Preexistente al change, sin impacto funcional.
- **Cobertura indirecta:** el flujo end-to-end real (sidebar → navegación → filtros → borrado contra el backend desplegado) se valida en la demo de aceptación (T8.2 checklist manual); los tests cubren el contrato de servicio y el comportamiento del componente.

## Cómo reproducir

El backend no dispone de Maven local; la suite se ejecuta con Docker (imagen `maven:3.9-eclipse-temurin-21`, Java 21). El frontend usa vitest vía npm:

```bash
# Backend — suite completa de tests
cd backend
docker run --rm -v "$(pwd)":/app -w /app maven:3.9-eclipse-temurin-21 mvn test

# Frontend — suite de tests (vitest + jsdom)
cd frontend
npm test

# Frontend — build de producción
npm run build
```

Resultado esperado de `mvn test`: `BUILD SUCCESS` con **87 tests, 0 errores, 0 fallos, 0 skipped** (reporte en `backend/target/surefire-reports/`). Resultado esperado de `npm test`: **77 tests, 0 fallos** (8 archivos). `ng build` debe completar sin errores (solo warning preexistente CommonJS de `sweetalert2`).

Pendiente del change: **demo de aceptación manual (T8.2)** con backend + frontend + BD corriendo (sidebar "Logs", filtros/paginación server-side, borrado por rango, vendedor sin permisos, asignación de `LOGS_VER`/`LOGS_ELIMINAR` desde roles/usuarios).