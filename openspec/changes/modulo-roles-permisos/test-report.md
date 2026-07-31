# Informe de Tests — Módulo Roles/Permisos

> Change: `modulo-roles-permisos` · Stacks 1 (backend) y 2 (frontend) · Fecha: 2026-07-31 (actualizado)

## Resumen ejecutivo

| Métrica | Backend | Frontend |
|---|---|---|
| **Total de tests** | 48 | 42 |
| **Clases de test** | 11 | 4 |
| **Resultado** | **48/48 OK — 0 fallos, 0 errores** | **42/42 OK — 0 fallos, 0 errores** |
| **Suite completa** | `BUILD SUCCESS` | `npm test` OK |
| **Comando** | `docker run --rm -v "$(pwd)":/app -w /app maven:3.9-eclipse-temurin-21 mvn test` | `npm test` (vitest + jsdom, builder `@angular/build:unit-test`) |
| **Packaging** | `mvn package -DskipTests` OK → `ferreplus-backend-1.0.0.jar` | `ng build` OK |
| **Base** | Docker `maven:3.9-eclipse-temurin-21` (Java 21, sin Maven local), Spring Boot 3.5.16, H2 con perfil `test` | Angular 22, vitest + jsdom |

Los 48 tests backend cubren las 11 clases de la suite: 39 tests **nuevos** del change (resolución de autoridades, enforcement, drift catálogo↔`@PreAuthorize`, seed idempotente, contrato de usuarios con overrides, auditoría, serialización JSON) y 9 tests **preexistentes preservados** como regresión (contexto, precios, compras).

Los 42 tests frontend cubren la lógica de permisos en el cliente: AuthService (`getHomeRoute`, permisos efectivos), AuthGuard (refresh por navegación, redirección a primera ruta permitida, anti-bucle), directiva `*appHasPermission` y la matriz de permisos reutilizable (build/aplicar overrides).

## Clasificación por funcionalidad

| Clase de test | Funcionalidad que cubre | Requisito | Tests | Resultado |
|---|---|---|---|---|
| `auth/PermisoResolverTest` | Resolución de autoridades: `permisos_efectivos = rol ∪ concedidos ∖ denegados`, edge cases y autoridad `ROLE_<NOMBRE>` transitoria | R5 (R9.1) | 6 | ✅ OK |
| `security/SecurityEnforcementTest` | Enforcement de `@PreAuthorize` con `@WithMockUser`: 401 sin token, 403 sin permiso, 200 con permiso (lectura y escritura), protección del catálogo y contrato de login | R2, R5, R8 | 8 | ✅ OK |
| `security/SecurityEnforcementIntegrationTest` | Enforcement end-to-end con **tokens JWT reales** (login vía `AuthService`): matriz del seed restringe de verdad | R5, R6 (R9.2) | 6 | ✅ OK |
| `security/PreAuthorizeDriftTest` | Drift catálogo ↔ anotaciones: todo código en `@PreAuthorize` existe en el catálogo; todo permiso del catálogo está anotado salvo allowlist | R9.4, R1, R6 | 3 | ✅ OK |
| `security/DataSeederIdempotencyTest` | Seed idempotente (doble ejecución sin duplicados) y estado sembrado completo (13 módulos, 42 permisos, 3 roles, 69 pares) | R6, R1 (R9.3) | 2 | ✅ OK |
| `service/UsuarioOverridesTest` | Overrides por usuario: `concedido=true` agrega, `concedido=false` quita, PUT reemplaza la lista completa, validaciones 400 y contrato del DTO | R4, R8 (R9.5) | 7 | ✅ OK |
| `service/AuditoriaTest` | Auditoría atómica: filas `auditoria` en creación/edición de usuario y rol, actor autenticado, operaciones rechazadas sin fila | R10 (R9.6) | 5 | ✅ OK |
| `entity/EntidadJsonSerializationTest` | Regresión de serialización: entidades con grafo circular (`usuario → rol → permisos → modulo`) se serializan sin `StackOverflowError` | Regresión (bug verificado) | 2 | ✅ OK |
| `service/PrecioServiceTest` | *(preexistente)* Cálculo de precios, ganancia/margen y registro de histórico | Regresión | 6 | ✅ OK |
| `service/CompraServiceIntegrationTest` | *(preexistente)* Compra actualiza `precioCompra` y guarda histórico (create + update) | Regresión | 2 | ✅ OK |
| `FerreplusApplicationTests` | *(preexistente)* Contexto de Spring Boot carga con perfil `test` y seed | Regresión | 1 | ✅ OK |

## Detalle por clase de test

### `auth/PermisoResolverTest` — Unitario (Mockito puro, sin contexto Spring)

Verifica la semántica exacta de resolución de autoridades (R5/R9.1 y edge cases 10 y 12 de la spec) en el componente compartido por login, filtro JWT y `UsuarioDTO`:

- `codigosEfectivos_debeAplicarUnionYDenegacion_rolConOverrides` — rol `[A,B,C]` + override concedido `[D]` + denegado `[B]` → resultado exacto `[A,C,D]`.
- `codigosEfectivos_denegacionGanaAlRol_edgeCase10` — el rol concede `X` pero el override `concedido=false` lo quita (∖ aplica después de ∪).
- `codigosEfectivos_rolSinPermisos_edgeCase12` — rol con matriz vacía produce cero permisos.
- `codigosEfectivos_sinOverrides_sonExactamenteLosDelRol` — sin overrides, los efectivos son exactamente los del rol (ni más ni menos).
- `resolverAutoridades_incluyeCodigosYRoleTransitorio` — las `GrantedAuthority` incluyen los códigos efectivos **y** `ROLE_<NOMBRE>` (compatibilidad, R5).
- `resolverAutoridades_rolSinPermisos_soloRoleTransitorio` — rol vacío solo emite `ROLE_AUDITOR`.

### `security/SecurityEnforcementTest` — Integración (MockMvc + `@WithMockUser`, transaccional)

Verifica que el enforcement real vive en backend (R2, R5, R8), con cada test en su propia transacción:

- `sinAutenticacion_devuelve401` — sin token, `GET /api/productos` → 401.
- `sinPermisoDelModulo_devuelve403` — autenticado con `VENTAS_VER` accediendo a productos → 403.
- `conPermiso_devuelve200` — con `PRODUCTOS_VER` → 200.
- `conPermisoDeEscritura_devuelve200` — `POST /api/productos` con `PRODUCTOS_VER`+`PRODUCTOS_CREAR` → 200.
- `sinPermisoDeEscritura_devuelve403` — `POST` solo con `PRODUCTOS_VER` → 403.
- `catalogoDisponibleParaQuienGestionaRoles` — `GET /api/modulos` con `ROLES_VER` → 200 (R2).
- `catalogoDenegadoSinPermisosDeGestion` — `GET /api/modulos` con `VENTAS_VER` → 403 (R2).
- `loginEsPublico_yDevuelvePermisosEfectivos` — `POST /api/auth/login` con admin: devuelve token, rol ADMIN y **42 permisos efectivos**, sin exponer autoridades `ROLE_` en la lista (contrato R8).

### `security/SecurityEnforcementIntegrationTest` — Integración (MockMvc + tokens JWT reales)

Ejercita el enforcement con el flujo completo login→JWT→request (R5/R9.2, escenarios "403 real" y "admin accede a todo"), creando un usuario VENDEDOR persistido y logueándolo por `AuthService`:

- `vendedor_sinGASTOS_VER_recibe403` — vendedor con token real → `GET /api/gastos` 403 (matriz confirmada R6).
- `vendedor_conPRODUCTOS_VER_recibe200` — vendedor → `GET /api/productos` 200.
- `admin_accedeATodo` — admin (matriz completa) → `GET /api/gastos` 200.
- `vendedor_sinROLES_EDITAR_recibe403AlCrearRol` — vendedor intenta `POST /api/roles` → 403 (protección de escritura R3).
- `vendedor_sinPermisosDeCatalogo_recibe403` — vendedor → `GET /api/modulos` 403 (R2).
- `admin_accedeAlCatalogo` — admin → `GET /api/modulos` 200 (R2).

### `security/PreAuthorizeDriftTest` — Integración (reflexión sobre controllers)

Garantiza que el catálogo sembrado y las anotaciones no se desalineen (R9.4, escenario "código sin respaldo"): escanea los `@RestController` con `ClassPathScanningCandidateComponentProvider`, extrae los códigos con regex de `hasAuthority('X')`/`hasAnyAuthority(...)` y los compara contra el catálogo:

- `catalogo_seed_es_completo` — catálogo con exactamente 42 permisos, 3 roles y 69 pares; todos los permisos de los roles existen en el catálogo (R1/R6).
- `todo_codigo_en_anotaciones_existe_en_catalogo` — falla si un desarrollador introduce `hasAuthority('INVENTADO_VER')`.
- `todo_permiso_del_catalogo_esta_protegido_salvo_allowlist` — todo permiso del catálogo está referenciado por al menos una anotación, salvo la allowlist documentada `{VENTAS_EDITAR, ROLES_CREAR, ROLES_ELIMINAR}`.

### `security/DataSeederIdempotencyTest` — Integración (H2, seed ejecutado dos veces)

Verifica las reglas del seed (R6, R1, R9.3):

- `dobleEjecucion_noCambiaElEstado` — re-ejecutar `dataSeeder.run()` no duplica módulos, permisos, pares `rol_permisos` ni al usuario admin (idempotencia).
- `seed_siembraElEstadoCompletoEsperado` — 13 módulos, 42 permisos, 3 roles base, **69 pares** (ADMIN 42 + VENDEDOR 9 + BODEGUERO 18), ausencia de los roles fantasma CAJERO/SUPERVISOR (R6) y presencia del admin por defecto.

### `service/UsuarioOverridesTest` — Integración (H2, transaccional)

Cubre el CRUD de usuarios con rol base + overrides (R4, R8, R9.5):

- `overrideConcedidoTrue_agregaPermisoSobreElRol` — override `PRECIOS_VER=true` se suma a los permisos del rol base.
- `overrideConcedidoFalse_quitaPermisoDelRol` — override `GASTOS_VER=false` resta el permiso del rol base.
- `updateConOverridesVacios_eliminaTodosLosOverrides` — `PUT` con lista vacía elimina los overrides y el permiso agregado desaparece (reemplazo completo, escenario R4).
- `overrideConCodigoInexistente_lanza400` — permiso que no existe en el catálogo → `BadRequestException`.
- `overrideDuplicado_lanza400` — el mismo permiso con `concedido=true` y `false` en la misma petición → 400 (escenario R4 de conflicto).
- `permisosEfectivosResueltos_porElResolver_coincidenConElDTO` — los permisos efectivos del `UsuarioDTO` coinciden con la resolución de `PermisoResolver` sobre la entidad persistida (consistencia de la fuente de verdad).
- `usuarioDTO_exponeRolBaseYPermisosYOverrides` — el DTO expone `rolId`/`rolNombre` a nivel raíz, permisos efectivos y overrides (contrato R8).

### `service/AuditoriaTest` — Integración (H2, transaccional, admin autenticado en contexto)

Verifica la infraestructura de auditoría atómica (R10, R9.6):

- `crearUsuario_registraFilaDeAuditoriaConElActor` — `POST` de usuario → exactamente 1 fila `USUARIO/CREAR` con `usuario_id` = actor autenticado (escenarios R10.1/R10.5).
- `eliminarRolEnUso_lanza409SinFilaDeAuditoria` — `DELETE` de rol con usuarios activos → `ConflictException` y **sin** fila `ROL/ELIMINAR` (R3: rol en uso; R10.4).
- `crearRol_registraFilaDeAuditoria` — creación de rol → 1 fila `ROL/CREAR` con `detalle` serializando la matriz (R10).
- `editarMatrizDeRol_registraFilaDeAuditoria` — `PUT` de la matriz de un rol → 1 fila `ROL/ACTUALIZAR` con detalle (escenario R10.2).
- `operacionFallida_noDejaFilaDeAuditoria` — nombre de rol duplicado → 400 **sin** fila de auditoría (regla de negocio 10: rechazos nunca auditan).

### `entity/EntidadJsonSerializationTest` — Unitario (Jackson puro, sin contexto Spring)

Regresión del bug de serialización circular: construye el grafo completo en memoria con builders de Lombok (`Gasto → Usuario → Rol → Permiso → Modulo.permisos → Permiso.modulo → mismo Modulo`, más `Usuario.overrides → UsuarioPermiso → usuario/permiso`) y verifica que `ObjectMapper.writeValueAsString` **complete sin lanzar `StackOverflowError`** (las anotaciones `@JsonIgnoreProperties` rompen los ciclos):

- `serializarGasto_conGrafoCircularCompleto_noLanzaRecursionInfinita` — el endpoint que se rompió en producción (`GET /api/gastos`); el JSON resultante incluye el permiso y el usuario.
- `serializarUsuario_conOverrides_noLanzaRecursionInfinita` — cubre el camino `Usuario.overrides → UsuarioPermiso → usuario`; el JSON incluye el rol.

Corre en milisegundos (0.042 s) sin `@SpringBootTest`.

### `service/PrecioServiceTest` — Unitario (preexistente, Mockito)

Regresión del módulo de precios:
- `actualizarPrecioVenta_withNewPrice_shouldUpdateAndSaveHistory` — actualización por precio directo y registro de histórico.
- `actualizarPrecioVenta_withMargin_shouldCalculatePriceAndSaveHistory` — cálculo por margen (`100 * 1.5 = 150`).
- `actualizarPrecioVenta_withBothFields_shouldThrowError` — `nuevoPrecio` + `margen` simultáneos → 400.
- `actualizarPrecioVenta_withNoFields_shouldThrowError` — sin campos → 400.
- `registrarHistorico_shouldSaveRecord` — persistencia del histórico con tipo/referencia/usuario.

### `service/CompraServiceIntegrationTest` — Integración (preexistente, `@DirtiesContext`)

Regresión del flujo de compras:

- `createCompra_shouldUpdatePrecioCompraAndSaveHistory` — crear compra actualiza `precioCompra` del producto y crea el registro histórico (`tipoCambio=COMPRA`, referencia = factura, sin usuario automático).
- `updateCompra_shouldUpdatePrecioCompraForNewDetails` — actualizar la compra con nuevo detalle actualiza el precio y acumula 2 registros históricos (create + update) con orden correcto.

### `FerreplusApplicationTests` — Contexto (preexistente)

- `contextLoads` — el contexto Spring Boot carga completo con el perfil `test` (incluye el seed y la configuración de seguridad nueva).

## Mapeo a requerimientos

| Requisito | Clases que lo cubren | Notas de cobertura |
|---|---|---|
| **R1** Catálogo dinámico | `DataSeederIdempotencyTest`, `PreAuthorizeDriftTest` | 13 módulos / 42 permisos sembrados y consistentes. La unicidad de códigos (escenario "código único") se garantiza por el catálogo sembrado + drift, no por un test directo de constraint en H2. El escenario "NO JSON blob" no es testeable automatizado (revisión de modelo). |
| **R2** Endpoints de catálogo | `SecurityEnforcementTest`, `SecurityEnforcementIntegrationTest` | Ambos escenarios cubiertos: acceso con `ROLES_VER`/`USUARIOS_VER` → 200 y sin permisos de gestión → 403 (mock y token JWT real). |
| **R3** CRUD de roles | `AuditoriaTest`, `SecurityEnforcementIntegrationTest` | Cubierto: protección de escritura (`ROLES_EDITAR`, vendedor → 403), rol en uso → 409, nombre duplicado → 400 sin auditoría. No hay test directo de "matriz con código inexistente → 400" para roles (la validación es el mismo componente ya testeado en `UsuarioOverridesTest` para R4). |
| **R4** CRUD de usuarios con overrides | `UsuarioOverridesTest` | 6 escenarios de la spec cubiertos (agregar, quitar, reemplazo en PUT, permiso inexistente, conflicto true/false, permisos efectivos). El escenario `/me` se cubre de forma indirecta vía el resolver compartido y el DTO; no hay test HTTP dedicado a `GET /api/usuarios/me`. |
| **R5** Resolución de autoridades y enforcement | `PermisoResolverTest`, `SecurityEnforcementTest`, `SecurityEnforcementIntegrationTest` | Semántica `∪ ∖` exacta (incl. edge cases 10 y 12), 401/403/200 reales en backend, `ROLE_<NOMBRE>` transitorio, admin con matriz completa accede a todo. El escenario "cambio aplica sin re-login" se apoya en la recarga por request del filtro JWT (diseño); la suite integración lo ejerce con tokens reales recargados de BD. |
| **R6** Seed reconstruido | `DataSeederIdempotencyTest`, `PreAuthorizeDriftTest`, `SecurityEnforcementIntegrationTest` | Idempotencia, estado exacto (13/42/3/69), roles fantasma ausentes, admin por defecto y "la matriz restringe de verdad" (vendedor sin `GASTOS_VER` → 403). |
| **R7** Frontend | `auth.service.spec.ts`, `auth.guard.spec.ts`, `has-permission.directive.spec.ts`, `permisos-matriz.component.spec.ts` (42 tests) | Cobertura del STACK 2: `getHomeRoute` (primera ruta permitida por permisos, `null` sin permisos), guard con refresh vía `/me` por navegación y redirección sin bucle, directiva `*appHasPermission`, y la matriz de permisos reutilizable (build/aplicar overrides). La UI/sidebar/guard se verifican además con `ng build` limpio (T8.1) y el checklist manual (T8.2). |
| **R8** Contrato CRUD de usuarios | `SecurityEnforcementTest`, `UsuarioOverridesTest` | Login devuelve permisos efectivos sin `ROLE_` en la lista; `UsuarioDTO` expone `rolId`/`rolNombre` raíz + permisos efectivos + overrides. |
| **R9** Tests de backend | Todas las clases nuevas | Los 6 tests mínimos exigidos están presentes: 1) unitario resolución (`PermisoResolverTest`), 2) integración 403/200 (`SecurityEnforcementTest` + integración JWT), 3) idempotencia seed (`DataSeederIdempotencyTest`), 4) drift catálogo↔anotaciones (`PreAuthorizeDriftTest`), 5) contrato usuarios (`UsuarioOverridesTest`), 6) auditoría (`AuditoriaTest`). |
| **R10** Infraestructura de auditoría | `AuditoriaTest` | Atomicidad (misma transacción), actor autenticado como `usuario_id`, `detalle` poblado, rechazos (400/409) sin fila. El escenario de diseño genérico (extensible a VENTA/COMPRA) se verifica por el modelo `entidad`/`entidad_id`, no por test. |

**Escenarios de la spec:** 44 totales → 38 son de backend (R1–R6, R8, R9, R10) y 6 de frontend (R7). Los 38 de backend quedan cubiertos de forma directa o indirecta por la suite; la cobertura indirecta se señala en las notas anteriores. Los 6 de frontend quedan cubiertos por los 42 tests del STACK 2 y la verificación de build.

## Tests existentes preservados

Los tests previos al change siguen pasando sin modificaciones funcionales — verificación de regresión:

- `PrecioServiceTest` — 6/6 OK (unitario, Mockito).
- `CompraServiceIntegrationTest` — 2/2 OK (integración H2). Única modificación: anotación `@DirtiesContext` de aislamiento (ver errores corregidos), sin cambios en los asserts.
- `FerreplusApplicationTests` — 1/1 OK (contexto con seed y seguridad nueva).

Ninguno de estos tests fue alterado en su lógica; la suite completa es **48/48 OK** (backend).

## Errores encontrados y corregidos durante la verificación

1. **`AccessDeniedException` devolvía 500 en vez de 403** — Al ejecutar `SecurityEnforcementTest`, un usuario autenticado sin permiso obtenía HTTP 500: `@PreAuthorize` lanza `AccessDeniedException` en el interceptor de método y el `GlobalExceptionHandler` no la contemplaba, cayendo en el manejador genérico. **Corrección:** handler dedicado `@ExceptionHandler(AccessDeniedException.class)` → 403 JSON (`JsonAccessDeniedHandler` ya cubría la vía del filtro). Detenido por el test de enforcement 403.

2. **Faltaba `DASHBOARD_VER` en el seed** — El módulo Dashboard se sembraba sin su permiso `VER`: el catálogo quedaba en 41 permisos y 66 pares (en vez de 42/69) y el drift test habría fallado (código usado en `@PreAuthorize` sin respaldo en catálogo). **Corrección:** se agregó `DASHBOARD_VER` al seeder (dashboard y reportes quedan separados por endpoint, decisión documentada en diseño). Detenido por los asserts de conteo exacto de `DataSeederIdempotencyTest`/`PreAuthorizeDriftTest`.

3. **`DELETE` de rol sin guard de usuarios inactivos** — `RolService.delete` solo consultaba usuarios activos (`countByRolIdAndActivoTrue`); un rol con usuarios **inactivos** asignados se podía eliminar, rompiendo la FK. **Corrección:** doble guard `countByRolIdAndActivoTrue` + `countByRolId` → 409 en ambos casos, con fila de auditoría ausente. Cubierto por `AuditoriaTest.eliminarRolEnUso_lanza409SinFilaDeAuditoria`.

4. **`CompraServiceIntegrationTest` contaminaba el contexto cacheado** — Su `setUp`/`tearDown` borra roles y usuarios; con el seed sembrando roles/admin, otros tests del contexto cacheado fallaban en cascada (admin ausente). **Corrección:** `@DirtiesContext(ClassMode.AFTER_CLASS)` para que la clase corra en su propio contexto aislado.

5. **Ciclo JSON infinito en serialización de entidades (bug de verificación en vivo)** — Cualquier endpoint que serializara una entidad con `usuario` (`GET /api/gastos`, `/api/ventas`, `/api/compras`, `/api/movimientos-stock`, reportes) devolvía HTTP 200 con JSON **truncado a ~50KB** + `{"error":"Error interno del servidor"}` concatenado: las entidades nuevas del STACK 1 (`Rol.permisos`, `Permiso.modulo`, `Modulo.permisos`) crearon un ciclo bidireccional `modulo → permisos → modulo → ...` y Jackson moría con `StackOverflowError` a mitad de la serialización. **Corrección:** `@JsonIgnoreProperties` en los 6 puntos del ciclo (`Modulo.permisos`, `Permiso.modulo`, `Rol.permisos`, `Usuario.rol`, `UsuarioPermiso.usuario`/`.permiso`), preservando el contrato de los DTOs (`/api/modulos`, `/api/roles`, `/api/usuarios` siguen devolviendo matrices completas). **Regresión cubierta** por `EntidadJsonSerializationTest` (grafo circular en memoria, sin BD).

6. **Login atrapaba a usuarios sin `DASHBOARD_VER` (verificación manual frontend)** — El login y el guard navegaban siempre a `/dashboard`, que exige `DASHBOARD_VER`; un rol sin ese permiso (ej. rol de prueba "Prueba") quedaba logueado pero con pantalla rota. **Corrección (STACK 2):** mapa centralizado `RUTAS_POR_PERMISO` + `AuthService.getHomeRoute()` → navega a la primera ruta permitida; si no hay ninguna, mensaje claro en login; el guard usa `redirectToHome()` anti-bucle. Cubierto por los tests de `getHomeRoute` y `auth.guard.spec.ts`.

## Notas y advertencias

- **Warning preexistente de dialecto (no bloqueante):** `application.yml` fuerza `hibernate.dialect=PostgreSQLDialect`, que gana sobre `H2Dialect` del perfil `test`. H2 emite un warning de `client_min_messages` no soportado durante el arranque. Es benigno y preexistente al change; los tests no dependen de él. (Opcional futuro: sobrescribir el dialecto en `application-test.properties`.)
- **Frontend con suite de tests (STACK 2):** infraestructura vitest + jsdom creada por decisión del usuario (el design la tenía como mejora futura). El builder `unit-test` de `@angular/build` es **experimental** (Angular 22.0.7); `tsconfig.spec.json` incluye `files: [src/main.ts]` para resolver el grafo de NgModules. Patrón para componentes no-standalone: componente directo + sincronización manual de `ngOnChanges` con `SimpleChange`.
- **Cobertura indirecta:** los escenarios "no JSON blob" (R1), "generación genérica de `auditoria`" (R10) y `/me` por HTTP (R4) se cubren por diseño/modelo y por el componente compartido, no por un test HTTP dedicado.
- **Código de prueba manual:** los 48 tests backend corren sobre H2 con el perfil `test`; la base real (PostgreSQL) se valida en la demo de aceptación.

## Cómo reproducir

El backend no dispone de Maven local; la suite se ejecuta con Docker (imagen `maven:3.9-eclipse-temurin-21`, Java 21). El frontend usa vitest vía npm:

```bash
# Backend — suite completa de tests
cd backend
docker run --rm -v "$(pwd)":/app -w /app maven:3.9-eclipse-temurin-21 mvn test

# Backend — construir el jar (sin re-ejecutar tests)
docker run --rm -v "$(pwd)":/app -w /app maven:3.9-eclipse-temurin-21 mvn package -DskipTests

# Frontend — suite de tests (vitest + jsdom)
cd frontend
npm test

# Frontend — build de producción
npm run build
```

Resultado esperado de `mvn test`: `BUILD SUCCESS` con **48 tests, 0 errores, 0 fallos** (reporte en `backend/target/surefire-reports/`). Resultado esperado de `npm test`: **42 tests, 0 fallos**. `ng build` debe completar sin errores.
