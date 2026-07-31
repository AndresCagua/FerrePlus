# Módulo de Roles y Permisos — Especificación Delta

## Propósito

Este cambio introduce **enforcement real de permisos por módulo** en FerrePlus. Hoy el control de acceso es casi nulo: `SecurityConfig` solo tiene reglas URL hardcodeadas para `productos`, `usuarios` y `reportes`; todo lo demás cae en `anyRequest().authenticated()`, de modo que cualquier usuario autenticado puede operar ventas, compras, gastos, precios, movimientos, clientes, proveedores, categorías y roles sin restricción. Además, la entidad `Rol` solo tiene `nombre` y `descripcion`, y las autoridades se derivan de `"ROLE_" + rol.nombre` sin granularidad posible.

El cambio agrega un **catálogo dinámico de módulos y permisos** (tablas `modulos` y `permisos`), **matrices de permisos por rol** (`rol_permisos`), **overrides por usuario** (`usuario_permisos` con flag `concedido`), **resolución de autoridades por request** (`permisos(rol) ∪ concedidos ∖ denegados`), **migración de seguridad a `@EnableMethodSecurity` + `@PreAuthorize`**, un **seed reconstruido desde cero** (matriz confirmada que restringe de verdad a VENDEDOR/BODEGUERO), la **UI de administración de roles** (13º módulo del catálogo), el **refresco de permisos en frontend por navegación** vía `/me`, y el **arreglo del contrato roto de CRUD de usuarios** (prerrequisito lógico de la administración de permisos por usuario). Además, se construye la **infraestructura de auditoría** (tabla genérica `auditoria` + `AuditService` reutilizable) instrumentada para los cambios de usuarios, roles y permisos que toca este cambio (Decisión 7); el **módulo completo de auditoría** (UI de consulta, filtros, reportes e instrumentación del resto del sistema) se construirá en un spec/cambio futuro separado.

Esta es una **spec delta**: describe lo que se AGREGA, MODIFICA y ELIMINA respecto del comportamiento actual. No reemplaza specs existentes (no hay specs previas para estos dominios).

## Alcance

### ADDED (agregado)

- Tablas `modulos` y `permisos` (catálogo dinámico, FK `permisos.modulo_id`).
- Tablas de unión `rol_permisos` (matriz del rol) y `usuario_permisos` (overrides por usuario con flag `concedido`).
- Endpoints `GET /api/modulos` y `GET /api/permisos` para la UI de roles/usuarios.
- CRUD de roles con matriz de permisos administrable desde la UI (módulo ROLES, 13º módulo del catálogo).
- Overrides por usuario (agregar/quitar permisos individuales respecto del rol base).
- Resolución de autoridades por request y enforcement con `@EnableMethodSecurity` + `@PreAuthorize` en los controllers de los ~13 módulos.
- Seed reconstruido desde cero vía `CommandLineRunner` idempotente (catálogo + 3 roles + matriz + usuario admin).
- UI de administración de roles (feature module Angular) y formulario de usuario con rol base + matriz de overrides.
- Refresco de permisos en el guard por cada navegación (`GET /api/usuarios/me`).
- Tests mínimos de backend (resolución de autoridades, 403/200 por permiso, idempotencia del seed, consistencia catálogo ↔ `@PreAuthorize`, auditoría).
- Infraestructura de auditoría: tabla genérica `auditoria` (diseñada para todo el sistema: `entidad`, `entidad_id`, `accion`, `usuario_id`, `fecha`, `detalle`), `AuditService` reutilizable e instrumentación de los cambios de usuarios, roles y permisos (matriz de rol y overrides por usuario) que toca este cambio (Decisión 7). El módulo completo de auditoría (UI, endpoints de consulta, filtros, reportes) queda para un spec futuro.

### MODIFIED (modificado)

- `Rol`: pasa de solo `nombre`/`descripcion` a incluir una matriz de permisos (`rol_permisos`).
- `Usuario`: pasa de un rol simple a rol base + overrides de permisos por usuario.
- `SecurityConfig`: las reglas URL hardcodeadas (`hasRole`) se reemplazan por `@EnableMethodSecurity` + `@PreAuthorize` (`hasAuthority`) en los controllers; el `authority` `ROLE_<NOMBRE>` se conserva transitoriamente para compatibilidad.
- Contrato del CRUD de usuarios: el backend devuelve `UsuarioDTO` (`rolId`/`rolNombre` a nivel raíz + permisos efectivos) y acepta `rolId` + overrides; el frontend envía `rolId` cargado desde `/api/roles` (hoy envía `rolNombre` string → 400).
- `AuthResponseDTO` (login): incluye la lista de permisos efectivos.
- Sidebar: 12 items con filtrado por permiso `MODULO_VER` + item nuevo "Roles".
- `AuthGuard`/`AuthService`: soporte `data.permissions`, método `hasPermission()`, permisos en sessionStorage y refresh vía `/me` en cada navegación.

### REMOVED (eliminado)

- Roles fantasma **CAJERO** y **SUPERVISOR** de las listas hardcodeadas del frontend (`usuario-form` `['ADMIN','CAJERO','BODEGUERO','SUPERVISOR']`, badges de `usuario-list`, item Reportes con `roles: ['ADMIN','SUPERVISOR']`). La UI carga roles desde `/api/roles`; no se crean en el seed.
- Reglas URL hardcodeadas de `SecurityConfig` para productos/usuarios/reportes (reemplazadas por anotaciones por endpoint).
- INSERT manual de roles en `schema.sql` (queda como referencia ajustada; el seed vía `CommandLineRunner` es la fuente única de verdad).

---

## Decisiones confirmadas

Las decisiones 1-6 (catálogo en BD, seed reconstruido, roles fantasma, módulo ROLES, flag `concedido`, refresh `/me`) están en la propuesta y son vinculantes. Este spec incorpora dos decisiones nuevas confirmadas por el usuario:

| # | Decisión | Estado | Opción elegida / Racional |
|---|----------|--------|---------------------------|
| 7 | Infraestructura de auditoría | CONFIRMADA | Este cambio construye SOLO la **infraestructura**: tabla genérica `auditoria` + `AuditService` reutilizable + instrumentación de usuarios/roles/permisos. El **módulo completo de auditoría** (UI de consulta, filtros, reportes, instrumentación del resto del sistema) se construye en un **spec/cambio futuro separado**. La tabla se diseña genérica para todo el sistema (`entidad`/`entidad_id`) para que el módulo futuro solo necesite: (1) UI de consulta y (2) instrumentar los servicios restantes — **sin migración ni reestructuración**. |
| 8 | Sin flujo de aprobación | CONFIRMADA | Quien tiene `USUARIOS_EDITAR` / `ROLES_EDITAR` puede crear/editar usuarios y roles **directamente**. NO hay flujo de aprobación ni paso de aprobación de admin: **tener el permiso de edición ES la aprobación** (el admin ya aprobó al conceder ese acceso). |

---

## Requisitos

### R1: Catálogo dinámico de módulos y permisos

**Domain**: Base de datos / Seguridad

El sistema DEBE agregar un catálogo dinámico de módulos y permisos persistido en base de datos (NO como código hardcodeado ni como JSON blob en `usuarios`), compuesto por:

- Tabla `modulos` con, al menos: `id`, `nombre`, `codigo` (único, estable, en mayúsculas, ej. `VENTAS`), `orden` (para ordenar en la UI).
- Tabla `permisos` con, al menos: `id`, `codigo` (único global, estable, patrón `<MODULO>_<ACCION>`, ej. `VENTAS_VER`), `nombre` (legible, ej. "Ver ventas"), `accion` (uno de `VER`, `CREAR`, `EDITAR`, `ELIMINAR`), y FK `modulo_id` → `modulos.id`.
- El código de permiso DEBE ser único globalmente (no solo por módulo).
- Las acciones del catálogo DEBEN limitarse a `VER`/`CREAR`/`EDITAR`/`ELIMINAR`. Cada módulo declara las acciones que aplican: Dashboard y Reportes solo `VER`; Precios `VER`+`EDITAR`; Movimientos `VER`+`CREAR`; el resto (`PRODUCTOS`, `CATEGORIAS`, `PROVEEDORES`, `CLIENTES`, `VENTAS`, `COMPRAS`, `GASTOS`, `USUARIOS`, `ROLES`) declaran `VER`/`CREAR`/`EDITAR`/`ELIMINAR`.
- El catálogo DEBE contener exactamente **13 módulos**: Dashboard, Productos, Categorías, Proveedores, Clientes, Ventas, Compras, Precios, Movimientos, Gastos, Usuarios, Reportes y **ROLES**.
- Para Ventas y Compras, la acción `ELIMINAR` DEBE corresponder a la anulación de registros existente (no a borrado físico); la semántica concreta del endpoint se define en diseño.

#### Scenario: Catálogo sembrado con 13 módulos y sus acciones

- GIVEN la aplicación inicia por primera vez
- WHEN se consulta el catálogo
- THEN existen exactamente 13 módulos ordenados por `orden`
- AND `modulos` incluye el módulo `ROLES` como el 13º
- AND cada módulo tiene sus acciones (`VER`, `CREAR`, `EDITAR`, `ELIMINAR` según corresponda)
- AND Dashboard y Reportes solo tienen `VER`

#### Scenario: Un permiso pertenece a un solo módulo y su código es único

- GIVEN el permiso `VENTAS_VER` existe en el catálogo
- WHEN se intenta insertar un segundo permiso con el mismo código `VENTAS_VER`
- THEN la operación DEBE fallar por violación de la restricción de unicidad del código

#### Scenario: Los overrides NO se guardan como JSON blob

- GIVEN la tabla `usuarios` existente
- WHEN se revisa el modelo de datos resultante del cambio
- THEN NO existe ninguna columna tipo JSON/texto en `usuarios` que almacene permisos serializados
- AND todo permiso de rol o de usuario se referencia por FK a `permisos.id`

---

### R2: Endpoints de catálogo para la UI

**Domain**: API / Seguridad

El sistema DEBE exponer endpoints de solo lectura del catálogo para alimentar la UI de administración de roles y el formulario de usuario:

- `GET /api/modulos`: lista de módulos con sus permisos agrupados (cada módulo con su lista de códigos/acciones), ordenados por `orden`.
- `GET /api/permisos`: lista plana de permisos (código, nombre, acción, módulo).

Ambos endpoints DEBEN estar protegidos: solo usuarios con `ROLES_VER` o `USUARIOS_VER` (los dos flujos de UI que los consumen) DEBEN poder acceder; cualquier otro usuario autenticado DEBE recibir 403.

#### Scenario: Admin obtiene el catálogo completo

- GIVEN un usuario autenticado con permisos `ROLES_VER` o `USUARIOS_VER`
- WHEN se llama a `GET /api/modulos`
- THEN la respuesta DEBE contener 13 módulos ordenados
- AND cada módulo DEBE incluir sus permisos (código y acción)
- AND `GET /api/permisos` DEBE devolver la lista plana equivalente

#### Scenario: Usuario sin permiso de catálogo recibe 403

- GIVEN un usuario autenticado sin `ROLES_VER` ni `USUARIOS_VER`
- WHEN se llama a `GET /api/modulos` o `GET /api/permisos`
- THEN la respuesta DEBE ser HTTP 403

---

### R3: CRUD de roles con matriz de permisos

**Domain**: API / Roles / UI

El sistema DEBE permitir administrar roles y su matriz de permisos desde la API y desde la UI:

- `GET /api/roles`: lista de roles con sus códigos de permiso (matriz).
- `GET /api/roles/{id}`: rol individual con su matriz completa.
- `POST /api/roles`: crea un rol con nombre, descripción y matriz de permisos.
- `PUT /api/roles/{id}`: actualiza nombre, descripción y matriz de permisos.
- `DELETE /api/roles/{id}`: elimina un rol.

Protección de `/api/roles/**` (hoy abierto a cualquier autenticado):

- Lecturas (`GET`) DEBEN requerir `ROLES_VER`.
- Escrituras (`POST`/`PUT`/`DELETE`) DEBEN requerir `ROLES_EDITAR`.
- Un usuario con `ROLES_VER` pero sin `ROLES_EDITAR` DEBE poder listar/ver roles pero recibir 403 al crearlos, editarlos o eliminarlos.

Reglas de negocio del CRUD:

- El nombre del rol DEBE ser único (rechazo con 400/409 si ya existe).
- La matriz de permisos DEBE validarse contra el catálogo: códigos inexistentes DEBEN rechazarse con 400.
- Al actualizar la matriz, el sistema DEBE reemplazar la matriz completa del rol (los permisos no incluidos en la petición quedan fuera).
- `DELETE /api/roles/{id}` DEBE rechazarse (409/400) si al menos un usuario activo tiene asignado ese rol.
- Toda operación exitosa de creación/edición/eliminación de rol (incluidos los cambios de matriz de permisos) DEBE quedar registrada en auditoría (ver R10).

#### Scenario: Admin crea un rol con matriz de checkboxes

- GIVEN un admin autenticado con `ROLES_EDITAR`
- WHEN envía `POST /api/roles` con nombre "Contable" y permisos `[VENTAS_VER, VENTAS_CREAR, COMPRAS_VER, COMPRAS_CREAR, PRECIOS_VER]`
- THEN la respuesta DEBE ser 200/201 con el rol creado
- AND `GET /api/roles/{id}` DEBE devolver exactamente esos 5 permisos
- AND un usuario con ese rol recibe **exactamente** esas autoridades (ni más ni menos)

#### Scenario: Nombre de rol duplicado

- GIVEN un rol "VENDEDOR" existente
- WHEN se intenta crear otro rol con nombre "VENDEDOR"
- THEN la respuesta DEBE ser HTTP 400/409 con mensaje de nombre duplicado

#### Scenario: Matriz con código de permiso inexistente

- GIVEN un catálogo que no contiene `VENTAS_VER`
- WHEN se crea un rol con permiso `VENTAS_VER` (código inventado)
- THEN la respuesta DEBE ser HTTP 400 indicando que el código no existe en el catálogo

#### Scenario: Edición de rol reemplaza la matriz completa

- GIVEN un rol con permisos `[VENTAS_VER, GASTOS_VER]`
- WHEN se envía `PUT /api/roles/{id}` con solo `[VENTAS_VER]`
- THEN la matriz del rol DEBE quedar en exactamente `[VENTAS_VER]`
- AND `GASTOS_VER` ya NO DEBE estar en la matriz

#### Scenario: No se puede eliminar un rol asignado a usuarios

- GIVEN un rol "Contable" asignado a 2 usuarios activos
- WHEN un admin con `ROLES_EDITAR` envía `DELETE /api/roles/{id}` para ese rol
- THEN la respuesta DEBE ser HTTP 409/400
- AND el rol DEBE seguir existiendo

#### Scenario: Protección de escritura de roles

- GIVEN un usuario autenticado con `ROLES_VER` pero sin `ROLES_EDITAR`
- WHEN intenta `POST /api/roles` (o PUT/DELETE)
- THEN la respuesta DEBE ser HTTP 403

---

### R4: CRUD de usuarios con rol base y overrides por permiso

**Domain**: API / Usuarios / Seguridad

El sistema DEBE permitir crear y editar usuarios eligiendo un **rol base** y una lista de **overrides** por permiso individual:

- `UsuarioRequestDTO` DEBE aceptar `rolId` (Long, obligatorio) **y** una lista de overrides, cada uno con `permisoCodigo` (o `permisoId`) y flag `concedido` (boolean).
- `concedido = true` DEBE **agregar** el permiso al usuario; `concedido = false` DEBE **quitar** el permiso respecto del rol base.
- El flag `concedido` es **obligatorio** para cumplir el requerimiento de agregar y quitar permisos por usuario (Decisión 5).
- El sistema DEBE persistir los overrides en `usuario_permisos` con PK compuesta (`usuario_id`, `permiso_id`); no puede existir más de un override por (usuario, permiso).
- Los overrides DEBEN validarse contra el catálogo: permiso inexistente → 400. Un mismo permiso no DEBE aparecer con `concedido=true` y `concedido=false` simultáneamente en la misma petición → 400.
- Al editar un usuario, la lista de overrides DEBE reemplazar la lista anterior completa.
- `GET /api/usuarios/me` DEBE devolver los permisos **efectivos** del usuario autenticado (rol ∪ concedidos ∖ denegados), además de la información actual del usuario.
- La lista de usuarios (`GET /api/usuarios`) DEBE devolver `rolId` y `rolNombre` a nivel raíz y los permisos efectivos de cada usuario.
- Toda operación exitosa de creación/edición de usuario (incluidos cambios de rol base y overrides de permisos) DEBE quedar registrada en auditoría (ver R10).

#### Scenario: Crear usuario con rol base y override de AGREGAR

- GIVEN el rol "Contable" con permisos `[VENTAS_VER, COMPRAS_VER, PRECIOS_VER]` y un usuario autenticado con `USUARIOS_CREAR`
- WHEN se envía `POST /api/usuarios` con `rolId` del rol Contable y overrides `[{permisoCodigo: "GASTOS_VER", concedido: true}]`
- THEN el usuario se crea con rol base Contable
- AND sus permisos efectivos DEBEN ser `[VENTAS_VER, COMPRAS_VER, PRECIOS_VER, GASTOS_VER]` (el rol base + el permiso agregado)

#### Scenario: Crear usuario con override de QUITAR

- GIVEN el rol "Contable" con permisos `[VENTAS_VER, COMPRAS_VER, PRECIOS_VER]` y un usuario autenticado con `USUARIOS_CREAR`
- WHEN se envía `POST /api/usuarios` con `rolId` del rol Contable y overrides `[{permisoCodigo: "COMPRAS_VER", concedido: false}]`
- THEN sus permisos efectivos DEBEN ser `[VENTAS_VER, PRECIOS_VER]` (el rol base menos el permiso denegado)

#### Scenario: Edición de usuario reemplaza overrides

- GIVEN un usuario con override `GASTOS_VER=concedido(true)`
- WHEN se envía `PUT /api/usuarios/{id}` con la lista de overrides vacía (sin `GASTOS_VER`)
- THEN el override `GASTOS_VER` DEBE quedar eliminado
- AND los permisos efectivos del usuario vuelven a ser exactamente los del rol base

#### Scenario: Override con permiso inexistente

- GIVEN un catálogo sin el permiso `FACTURAS_VER`
- WHEN se envía `POST /api/usuarios` con override `{permisoCodigo: "FACTURAS_VER", concedido: true}`
- THEN la respuesta DEBE ser HTTP 400

#### Scenario: Conflicto concedido true/false en la misma petición

- GIVEN cualquier usuario y rol
- WHEN se envía una petición con overrides que incluyen `GASTOS_VER=true` y `GASTOS_VER=false`
- THEN la respuesta DEBE ser HTTP 400

#### Scenario: /me devuelve permisos efectivos

- GIVEN un usuario con rol "VENDEDOR" (que tiene `VENTAS_VER`) y override `GASTOS_VER=concedido(true)`
- WHEN se llama a `GET /api/usuarios/me`
- THEN la respuesta DEBE incluir `VENTAS_VER` y `GASTOS_VER` en su lista de permisos efectivos

---

### R5: Resolución de autoridades y enforcement por endpoint

**Domain**: Seguridad / Backend

El sistema DEBE resolver las autoridades de un usuario con la siguiente semántica:

```
permisos_efectivos = permisos(rol)
                   ∪ { p : usuario_permisos.concedido = true }
                   ∖ { p : usuario_permisos.concedido = false }
```

La resolución DEBE aplicarse en los dos puntos que construyen la autenticación: en el login (`CustomUserDetailsService`) y en **cada request** (`JwtAuthenticationFilter`), que ya recarga el usuario desde BD — por lo tanto, los cambios de rol o de overrides DEBEN aplicar al siguiente request **sin re-login** en backend.

El sistema DEBE migrar el enforcement:

- `SecurityConfig` DEBE habilitar `@EnableMethodSecurity`.
- Las reglas URL hardcodeadas (productos/usuarios/reportes con `hasRole`) DEBEN reemplazarse por anotaciones `@PreAuthorize("hasAuthority('<CODIGO>')")` por endpoint en los controllers, con el siguiente mapeo base:

| Endpoint actual | Permiso |
|---|---|
| `GET /api/productos/**` | `PRODUCTOS_VER` |
| `POST /api/productos/**` | `PRODUCTOS_CREAR` |
| `PUT /api/productos/**` | `PRODUCTOS_EDITAR` |
| `DELETE /api/productos/**` | `PRODUCTOS_ELIMINAR` |
| `GET/POST/PUT/DELETE /api/usuarios/**` | `USUARIOS_VER` / `USUARIOS_CREAR` / `USUARIOS_EDITAR` / `USUARIOS_ELIMINAR` según método |
| `GET/POST/PUT/DELETE /api/roles/**` | `ROLES_VER` / `ROLES_EDITAR` (según R3) |
| `GET /api/reportes/**` | `REPORTES_VER` |
| Módulos hoy abiertos (ventas, compras, clientes, gastos, precios, movimientos, categorías, proveedores) | `X_VER` / `X_CREAR` / `X_EDITAR` / `X_ELIMINAR` según método y catálogo |

- `SecurityConfig` DEBE quedar con: `permitAll` para auth y swagger/scalar, protección URL de los endpoints de administración (roles/usuarios) como defensa adicional si procede, y `anyRequest().authenticated()` como fallback. El control fino lo ejercen las anotaciones.
- El sistema DEBE conservar transitoriamente el `authority` `ROLE_<NOMBRE>` junto con los códigos de permiso (compatibilidad; la eliminación definitiva del claim queda fuera de alcance).
- La comprobación DEBE ser real en backend (403), no solo visual.

#### Scenario: Cambio de permisos aplica sin re-login (backend)

- GIVEN un usuario autenticado con rol VENDEDOR que hoy NO tiene `GASTOS_VER`
- WHEN un admin le agrega el permiso `GASTOS_VER` al rol VENDEDOR (o un override al usuario)
- AND el usuario hace una nueva petición con el mismo token
- THEN el backend DEBE resolver las autoridades recargando desde BD
- AND `GET /api/gastos` DEBE responder 200 (antes 403)

#### Scenario: Usuario sin permiso de módulo recibe 403 real en backend

- GIVEN un usuario autenticado con rol "Contable" (sin `GASTOS_VER`) y un token válido
- WHEN llama a `GET /api/gastos`
- THEN la respuesta DEBE ser HTTP 403
- AND NO DEBE devolverse data de gastos ni ejecutarse la lógica del endpoint

#### Scenario: Admin con todos los permisos accede a todo

- GIVEN un usuario con rol ADMIN (matriz completa en el seed)
- WHEN llama a un endpoint representativo de cada uno de los 13 módulos
- THEN TODAS las respuestas DEBEN ser 200 (ningún 403)

#### Scenario: Autoridad ROLE_<NOMBRE> se conserva transitoriamente

- GIVEN un usuario autenticado con rol VENDEDOR
- WHEN se inspecciona el `Authentication` resultante del filtro
- THEN DEBE incluir `ROLE_VENDEDOR` además de los códigos de permiso (`VENTAS_VER`, `CLIENTES_VER`, etc.)

---

### R6: Seed reconstruido desde cero (catálogo + roles + matriz)

**Domain**: Base de datos / Configuración

El sistema DEBE sembrar el catálogo, los roles base y la matriz mediante un `CommandLineRunner` (no vía `schema.sql`/`data.sql` automáticos, dado `spring.sql.init.mode=never`) con las siguientes reglas:

- El seed DEBE ser **idempotente**: ejecutarlo dos veces NO DEBE duplicar módulos, permisos, roles ni relaciones. DEBE consultar antes de insertar.
- El seed DEBE crear el catálogo de **13 módulos** con sus permisos (según R1).
- El seed DEBE crear exactamente **3 roles base**: `ADMIN`, `VENDEDOR`, `BODEGUERO`, con las matrices de la **matriz confirmada** (Decisión 2) siguiente:

| Módulo | ADMIN | VENDEDOR | BODEGUERO |
|---|---|---|---|
| Dashboard | VER | VER | VER |
| Productos | todo | VER | VER+CREAR+EDITAR |
| Categorías | todo | — | VER+CREAR+EDITAR |
| Proveedores | todo | — | VER+CREAR+EDITAR |
| Clientes | todo | VER+CREAR+EDITAR | VER |
| Ventas | todo | VER+CREAR | VER |
| Compras | todo | — | VER+CREAR+EDITAR |
| Precios | VER+EDITAR | VER | VER |
| Movimientos | VER+CREAR | — | VER+CREAR |
| Gastos | todo | — | — |
| Usuarios | todo | — | — |
| Roles | todo | — | — |
| Reportes | VER | VER | — |

Donde "todo" = todas las acciones declaradas del módulo en el catálogo.

- Esta matriz **restringe de verdad**: VENDEDOR pierde acceso a módulos que hoy ve por `authenticated()` (Categorías, Proveedores, Compras, Gastos, Movimientos) y BODEGUERO pierde Clientes CREAR/EDITAR y Reportes, entre otros. Es un cambio de comportamiento **intencional**.
- El seed DEBE crear el usuario administrador por defecto (`admin@ferreplus.com`) si no existe, con rol ADMIN.
- El seed NO DEBE crear los roles CAJERO ni SUPERVISOR (roles fantasma eliminados).
- Los INSERT manuales de roles/usuario admin en `schema.sql` DEBEN quedar ajustados como referencia (para no duplicar ni confundir) — el `CommandLineRunner` es la fuente única de verdad.
- La documentación interna (`DOCUMENTACION_INTERNA.md`, sección 4, matriz no enforced hoy) DEBE actualizarse para reflejar la matriz confirmada y el nuevo modelo, evitando que quede una matriz obsoleta como referencia.
- Las listas hardcodeadas del frontend DEBEN eliminar CAJERO/SUPERVISOR; los roles se cargan desde `/api/roles` y se administran desde la UI (Decisión 3).

#### Scenario: Seed idempotente — doble ejecución sin duplicados

- GIVEN la aplicación inicia y el `CommandLineRunner` ejecuta el seed completo
- WHEN se reinicia la aplicación (segunda ejecución del seed)
- THEN la tabla `modulos` DEBE seguir teniendo 13 filas (no 26)
- AND `permisos` DEBE tener el mismo número de filas
- AND `roles` DEBE tener exactamente 3 filas (ADMIN, VENDEDOR, BODEGUERO)
- AND `rol_permisos` DEBE tener el mismo número de filas (sin duplicados)

#### Scenario: VENDEDOR pierde acceso a Gastos (matriz confirmada)

- GIVEN un usuario con rol VENDEDOR creado por el seed
- WHEN se resuelven sus permisos efectivos
- THEN NO DEBE incluir `GASTOS_VER`
- AND `GET /api/gastos` con ese usuario DEBE responder 403

#### Scenario: BODEGUERO recibe exactamente la matriz confirmada

- GIVEN un usuario con rol BODEGUERO creado por el seed
- WHEN se resuelven sus permisos efectivos
- THEN DEBE incluir `PRODUCTOS_VER`, `PRODUCTOS_CREAR`, `PRODUCTOS_EDITAR`, `COMPRAS_VER`, `COMPRAS_CREAR`, `COMPRAS_EDITAR`, `CATEGORIAS_*`, `PROVEEDORES_*`, `MOVIMIENTOS_VER`, `MOVIMIENTOS_CREAR`, `PRECIOS_VER`, `CLIENTES_VER`, `VENTAS_VER`, `DASHBOARD_VER`
- AND NO DEBE incluir `REPORTES_VER` ni `GASTOS_VER` ni ningún permiso de `USUARIOS`/`ROLES`

#### Scenario: Los roles fantasma no existen en el sistema

- GIVEN la aplicación iniciada con el seed nuevo
- WHEN se consulta `GET /api/roles`
- THEN la respuesta DEBE contener solo ADMIN, VENDEDOR, BODEGUERO (o los que el admin haya creado desde la UI)
- AND NO DEBE contener CAJERO ni SUPERVISOR
- AND el formulario de usuario en frontend NO DEBE mostrar CAJERO/SUPERVISOR en el dropdown de roles

---

### R7: Frontend — UI de roles, formulario de usuario y filtrado por permiso

**Domain**: UI / Frontend

El sistema DEBE agregar la UI de administración de roles y adaptar el frontend al modelo de permisos:

- **Módulo Roles** (feature module Angular no-standalone, ruta lazy `/roles` protegida): listado de roles con sus permisos y formulario de rol con **matriz de checkboxes módulo → acciones** (cada módulo expandible para marcar/desmarcar acciones específicas). Crear y editar roles desde esta UI.
- **Formulario de usuario**: dropdown de rol base cargado desde `GET /api/roles` (NO hardcodeado) + matriz de checkboxes de permisos **precargada con los permisos del rol base**; marcar un permiso que no está en el rol = agregar (`concedido=true`), desmarcar un permiso del rol = quitar (`concedido=false`).
- **AuthService**: DEBE exponer `hasPermission(codigo)` (y `hasAnyPermission`), guardar los permisos efectivos en sessionStorage y refrescarlos vía `GET /api/usuarios/me`.
- **AuthGuard**: DEBE soportar `data.permissions` (además de `data.roles`) y DEBE invocar el refresh de permisos vía `/me` **en cada navegación** (Decisión 6): los cambios de permiso aplican sin re-login.
- **Sidebar**: DEBE contener los 13 items (12 existentes + "Roles") y DEBE filtrarlos por `MODULO_VER` (si el usuario no tiene el permiso `VER` de un módulo, el item NO se muestra).
- **Directiva de acción**: el sistema DEBE incluir una directiva ligera (p. ej. `HasPermissionDirective`) que oculte/deshabilite botones de acción según permiso (`CREAR`/`EDITAR`/`ELIMINAR`).
- **Modelos**: DEBEN agregarse los tipos `Modulo`, `Permiso`, y actualizarse `Usuario` (rolId/rolNombre a nivel raíz + permisos) y la respuesta del login (permisos efectivos).
- Las rutas de los 13 módulos DEBEN quedar protegidas con `data.permissions` (o equivalente): navegar por URL directa a un módulo sin permiso DEBE redirigir/bloquear en el guard.

#### Scenario: Admin crea un rol desde la UI con matriz de checkboxes

- GIVEN un admin autenticado con `ROLES_EDITAR` en `/roles/nuevo`
- WHEN marca los checkboxes de Ventas (VER, CREAR) y Precios (VER) y guarda
- THEN se envía `POST /api/roles` con los códigos `VENTAS_VER`, `VENTAS_CREAR`, `PRECIOS_VER`
- AND el rol aparece en el listado con su matriz

#### Scenario: Sidebar oculta módulos sin permiso VER

- GIVEN un usuario autenticado con rol "Contable" (permisos solo de Ventas, Compras y Precios)
- WHEN se renderiza el sidebar
- THEN DEBE mostrar Dashboard, Ventas, Compras y Precios
- AND NO DEBE mostrar Gastos, Usuarios, Roles, Categorías, Proveedores, Clientes, Movimientos, Productos ni Reportes

#### Scenario: Navegación por URL directa a módulo sin permiso

- GIVEN un usuario sin `GASTOS_VER` que navega manualmente a `/gastos`
- WHEN el guard evalúa la ruta
- THEN el guard DEBE bloquear la navegación (redirigir a una ruta permitida o pantalla de acceso denegado)

#### Scenario: Cambio de permisos aplica en frontend sin re-login (refresh por navegación)

- GIVEN un vendedor autenticado (sin `GASTOS_VER`) con la app abierta
- WHEN un admin le agrega `GASTOS_VER` al rol VENDEDOR
- AND el vendedor navega a otra ruta dentro de la app (dispara el guard → `GET /api/usuarios/me`)
- THEN los permisos en sessionStorage se refrescan
- AND el item "Gastos" aparece en su sidebar en la siguiente navegación
- AND `GET /api/gastos` responde 200 (el backend ya aplicó el cambio al siguiente request)

#### Scenario: Botón de acción oculto sin permiso específico

- GIVEN un usuario con `PRODUCTOS_VER` pero sin `PRODUCTOS_CREAR`
- WHEN se renderiza el listado de productos
- THEN el botón "Nuevo producto" DEBE estar oculto o deshabilitado (directiva de permiso)

#### Scenario: Dropdown de roles sin valores hardcodeados

- GIVEN el formulario de usuario en modo creación
- WHEN se abre el dropdown de rol
- THEN las opciones DEBEN cargarse desde `GET /api/roles`
- AND NO DEBE existir la lista `['ADMIN','CAJERO','BODEGUERO','SUPERVISOR']` en el código frontend

---

### R8: Arreglo del contrato de CRUD de usuarios

**Domain**: API / Usuarios / Frontend

El sistema DEBE corregir el contrato roto de usuarios que hoy impide crear/editar desde la UI y muestra la columna Rol vacía:

- El backend DEBE devolver `UsuarioDTO` en las operaciones de usuarios, con `rolId` y `rolNombre` a nivel raíz (hoy devuelve la entidad con objeto `rol` anidado y el frontend espera campos a nivel raíz).
- `UsuarioDTO` DEBE incluir además la lista de permisos efectivos del usuario.
- El backend DEBE aceptar `rolId` (Long) en creación/edición (el `UsuarioRequestDTO` ya lo exige; el frontend hoy envía `rolNombre` string → 400).
- El frontend DEBE enviar `rolId` numérico cargado desde `GET /api/roles`.
- El login (`AuthResponseDTO`) DEBE incluir la lista de permisos efectivos del usuario autenticado para inicializar el estado del frontend.
- Los badges/colores de rol en `usuario-list` DEBEN quedar sin referencias a CAJERO/SUPERVISOR (pueden derivarse de `rolNombre` genéricamente).

#### Scenario: Crear usuario desde la UI funciona end-to-end

- GIVEN un admin autenticado en el formulario de usuario
- WHEN completa los datos, selecciona el rol "VENDEDOR" del dropdown (cargado desde `/api/roles`) y guarda
- THEN la petición DEBE incluir `rolId` (numérico) y los overrides marcados
- AND la respuesta DEBE ser 200 (antes 400 por `rolNombre`)
- AND el usuario creado aparece en el listado con la columna Rol mostrando "VENDEDOR"

#### Scenario: Listado de usuarios muestra el rol correctamente

- GIVEN usuarios con distintos roles
- WHEN se carga `GET /api/usuarios`
- THEN cada elemento DEBE tener `rolId` y `rolNombre` a nivel raíz
- AND la columna Rol DEBE mostrarse sin depender de un objeto anidado

#### Scenario: Login inicializa permisos del frontend

- GIVEN un usuario con rol VENDEDOR y override `GASTOS_VER=true`
- WHEN inicia sesión en `/auth`
- THEN la respuesta del login DEBE incluir la lista de permisos efectivos (`VENTAS_VER`, `CLIENTES_VER`, ..., `GASTOS_VER`)
- AND el frontend DEBE inicializar sessionStorage con esos permisos

---

### R9: Tests de backend

**Domain**: Testing

El sistema DEBE incluir como mínimo los siguientes tests de backend (siguiendo los patrones existentes: unitario con Mockito — `PrecioServiceTest` — e integración con H2 — `CompraServiceIntegrationTest` con `application-test.properties`):

1. **Unitario — resolución de autoridades**: dado un rol con permisos conocidos, un set de overrides `concedido=true` y otro `concedido=false`, la resolución DEBE producir exactamente `(rol ∪ concedidos) ∖ denegados`.
2. **Integración — enforcement 403/200**: un usuario sin el permiso de un endpoint representativo recibe 403; un usuario con el permiso recibe 200. (Ej.: `GET /api/gastos` con/ sin `GASTOS_VER`.)
3. **Integración — idempotencia del seed**: ejecutar el seed dos veces no duplica catálogo, roles ni matriz.
4. **Integración — consistencia catálogo ↔ `@PreAuthorize` (drift test)**: todo código de permiso usado en anotaciones `@PreAuthorize("hasAuthority('X')")` DEBE existir en el catálogo sembrado; y todo permiso del catálogo DEBE estar referenciado por al menos una anotación (salvo justificación documentada, p. ej. `DASHBOARD_VER`).
5. **Integración — contrato de usuarios**: crear un usuario con `rolId` + overrides persiste rol y overrides; el DTO devuelto expone `rolId`/`rolNombre` y permisos efectivos.
6. **Integración — auditoría**: crear un usuario y editar la matriz de un rol registra filas en `auditoria` con `entidad`, `entidad_id`, `accion` y `usuario_id` correctos; operaciones rechazadas (409) no generan filas.

#### Scenario: Resolución de autoridades — unidad

- GIVEN rol con permisos `[A, B, C]`, overrides `concedido=true: [D]`, `concedido=false: [B]`
- WHEN se resuelven las autoridades efectivas
- THEN el resultado DEBE ser exactamente `[A, C, D]`

#### Scenario: Endpoint representativo devuelve 403 sin permiso y 200 con permiso

- GIVEN un usuario sin `GASTOS_VER`
- WHEN llama a `GET /api/gastos`
- THEN la respuesta DEBE ser HTTP 403
- GIVEN un usuario con `GASTOS_VER`
- WHEN llama al mismo endpoint
- THEN la respuesta DEBE ser HTTP 200

#### Scenario: Drift test — código en @PreAuthorize sin respaldo en catálogo

- GIVEN el código de la aplicación con anotaciones `@PreAuthorize`
- WHEN el drift test recorre todas las anotaciones y las compara con el catálogo sembrado
- THEN NO DEBE existir ningún código de permiso en anotaciones que no esté en el catálogo
- AND el test DEBE fallar si un desarrollador introduce `hasAuthority('INVENTADO_VER')`

#### Scenario: Seed ejecutado dos veces no duplica

- GIVEN el contexto de tests con H2
- WHEN el seeder se ejecuta dos veces sobre la misma BD
- THEN `modulos` tiene 13 filas, `roles` tiene 3 filas y `rol_permisos` no tiene pares duplicados

#### Scenario: Auditoría registra operaciones de usuario y rol

- GIVEN un contexto Spring con H2 y un usuario autenticado con permisos de administración
- WHEN se crea un usuario y se edita la matriz de permisos de un rol
- THEN `auditoria` DEBE contener 2 filas (una por operación)
- AND cada fila DEBE tener `entidad`, `entidad_id`, `accion` y `usuario_id` correctos
- AND una operación rechazada (p. ej. `DELETE` de un rol en uso → 409) NO DEBE generar fila

---

### R10: Infraestructura de auditoría

**Domain**: Base de datos / Auditoría / API

El sistema DEBE construir la infraestructura genérica de auditoría para registrar quién hizo qué y cuándo, diseñada para todo el sistema (Decisión 7):

- Nueva tabla `auditoria` con, al menos: `id`, `entidad` (String, ej. `USUARIO`, `ROL`, `VENTA`, `COMPRA` — extensible a cualquier entidad futura), `entidad_id` (Long), `accion` (uno de `CREAR`, `ACTUALIZAR`, `ELIMINAR`), `usuario_id` (FK a `usuarios`, quién ejecutó la operación), `fecha` (timestamp), `detalle` (resumen del cambio; texto o JSON).
- El sistema DEBE exponer un `AuditService` reutilizable (p. ej. `registrarEvento(entidad, entidadId, accion, detalle)`) que cualquier servicio del sistema pueda invocar en el futuro; la identificación del usuario autenticado DEBE resolverse internamente (contexto de seguridad).
- En ESTE cambio, la instrumentación DEBE limitarse a las operaciones que toca el cambio: creación/edición de usuarios, creación/edición/eliminación de roles y cambios de permisos (matriz de rol y overrides por usuario). El resto del sistema (ventas, compras, productos, etc.) NO DEBE instrumentarse en este cambio.
- El registro DEBE ser **atómico con la operación** auditada: una operación exitosa sin su fila de auditoría NO DEBE existir (misma transacción).
- Operaciones bloqueadas o fallidas (p. ej. `DELETE` de un rol en uso → 409, validación → 400) NO DEBEN generar filas de auditoría.
- La tabla `auditoria` DEBE diseñarse genérica (`entidad`/`entidad_id`) para que el módulo futuro de auditoría solo requiera: (1) UI de consulta/endpoints/filtros/reportes y (2) instrumentar los servicios restantes — **sin migración ni reestructuración** (Decisión 7).
- Este cambio NO DEBE incluir endpoints de consulta de auditoría, UI, filtros ni reportes (fuera de alcance, spec futuro).

#### Scenario: Crear usuario registra evento de auditoría

- GIVEN un admin autenticado con `USUARIOS_CREAR`
- WHEN crea un usuario vía `POST /api/usuarios`
- THEN se DEBE registrar una fila en `auditoria` con `entidad=USUARIO`, `entidad_id` = id del usuario creado, `accion=CREAR`, `usuario_id` = id del admin
- AND `fecha` y `detalle` DEBEN quedar poblados

#### Scenario: Editar la matriz de un rol registra evento de auditoría

- GIVEN un admin autenticado con `ROLES_EDITAR`
- WHEN actualiza la matriz de permisos de un rol vía `PUT /api/roles/{id}`
- THEN se DEBE registrar una fila con `entidad=ROL`, `entidad_id` = id del rol, `accion=ACTUALIZAR`, `usuario_id` = id del admin
- AND el `detalle` DEBE reflejar el resumen del cambio de permisos

#### Scenario: Cambio de overrides por API registra evento de auditoría

- GIVEN un admin autenticado con `USUARIOS_EDITAR`
- WHEN edita un usuario vía `PUT /api/usuarios/{id}` modificando sus overrides de permisos
- THEN se DEBE registrar una fila con `entidad=USUARIO`, `entidad_id` = id del usuario, `accion=ACTUALIZAR`
- AND el `detalle` DEBE incluir el resumen de los overrides modificados

#### Scenario: Operación bloqueada no genera auditoría

- GIVEN un rol asignado a al menos un usuario activo
- WHEN un admin con `ROLES_EDITAR` intenta eliminarlo y recibe 409
- THEN NO DEBE existir ninguna fila en `auditoria` con `entidad=ROL`, `entidad_id` = ese id y `accion=ELIMINAR`

#### Scenario: Registro atómico con la operación

- GIVEN una operación de creación de usuario en transacción
- WHEN la operación se persiste exitosamente
- THEN la fila de auditoría correspondiente DEBE quedar persistida en la misma transacción
- AND si el registro de auditoría fallara, la operación DEBE revertirse (no existe operación sin su auditoría)

---

## Requisitos no funcionales

#### Códigos de error

1. **403 Forbidden** — Acceso a endpoint sin el permiso requerido (`@PreAuthorize` o regla URL). Mensaje genérico de acceso denegado.
2. **400 Bad Request** — Matriz de rol con código de permiso inexistente; override de usuario con permiso inexistente; conflicto `concedido` true/false para el mismo permiso en la misma petición.
3. **400/409 Conflict** — Nombre de rol duplicado al crear.
4. **409/400 Conflict** — Intento de eliminar un rol asignado a al menos un usuario activo.
5. **400 Bad Request** — Falta `rolId` al crear/editar usuario (contrato existente).

#### Reglas de negocio

6. El catálogo es la fuente única de verdad: permisos referenciados por FK, nunca por string libre.
7. La matriz del rol se reemplaza por completo al editar; los overrides del usuario se reemplazan por completo al editar.
8. `ELIMINAR` en Ventas/Compras corresponde a anulación (semántica existente), no borrado físico.
9. El flag `concedido` es obligatorio en el modelo de overrides; sin él no se cumple el requerimiento de agregar y quitar permisos por usuario.
10. La auditoría es atómica con la operación: una operación exitosa siempre tiene su fila en `auditoria`; una operación rechazada (400/403/409) nunca la tiene.
11. Sin flujo de aprobación (Decisión 8): el permiso `USUARIOS_EDITAR` / `ROLES_EDITAR` es suficiente para crear/editar usuarios y roles directamente; no existe paso de aprobación intermedio.

#### Edge cases

10. Un usuario puede tener un permiso por rol y otro por override; si el rol concede `X` y el override lo deniega (`concedido=false`), el resultado es **denegado** (∖ aplica después de ∪).
11. Si un permiso del rol no tiene override, el rol manda.
12. Un rol sin permisos (matriz vacía) es válido: sus usuarios solo tienen `DASHBOARD_VER` si el catálogo/seed lo concede (o ninguno).
13. El cambio de permisos nunca exige re-login: backend recarga en cada request; frontend refresca en cada navegación.
14. Si un admin edita su propio rol o sus propios permisos, el backend aplica el cambio al siguiente request; la UI muestra los cambios tras la siguiente navegación (refresh `/me`).
15. El `detalle` de auditoría puede ser texto o JSON; el módulo futuro de consulta no depende del formato.
16. La instrumentación de auditoría de ESTE cambio cubre solo usuarios, roles y permisos; ventas, compras, productos, etc. se instrumentarán en el spec futuro de auditoría (Decisión 7).

---

## Fuera de alcance

- **Módulo completo de auditoría** (UI de consulta, endpoints de consulta, filtros, reportes e instrumentación del resto del sistema — ventas, compras, productos, etc.): fuera de alcance de ESTE cambio; se construirá en un spec/cambio futuro separado. La infraestructura (tabla genérica `auditoria` + `AuditService`, Decisión 7) queda lista para que ese módulo futuro solo requiera: (1) UI/endpoints de consulta y (2) instrumentar los servicios restantes — sin migración ni reestructuración.
- **Flujos de aprobación** para cambios de permisos (que un admin apruebe la solicitud de otro): **excluido explícitamente y confirmado como decisión (Decisión 8)** — quien tiene `USUARIOS_EDITAR` / `ROLES_EDITAR` crea/edita usuarios y roles directamente; tener el permiso de edición ES la aprobación.
- **Granularidad por campo** dentro de una página (ej. ocultar columna de costo a ciertos roles): el alcance es módulo + acción.
- **Auto-servicio** de solicitud de permisos por parte del usuario final.
- **Eliminación definitiva** del `authority` `ROLE_X` y del claim `rol` del token: se conservan transitoriamente.
- **Multi-tenant / organizaciones**.
- **Roles CAJERO/SUPERVISOR**: eliminados de las listas hardcodeadas del frontend; no se crean en el seed ni se implementa lógica de negocio adicional para ellos.

---

## Summary

### Requirements Summary

| # | Requirement | Type | Dominio | Escenarios |
|---|-------------|------|---------|------------|
| R1 | Catálogo dinámico de módulos y permisos | New | BD / Seguridad | 3 |
| R2 | Endpoints de catálogo (GET /api/modulos, /api/permisos) | New | API | 2 |
| R3 | CRUD de roles con matriz de permisos | New | API / Roles / UI | 6 |
| R4 | CRUD de usuarios con rol base + overrides | New | API / Usuarios | 6 |
| R5 | Resolución de autoridades y enforcement | New | Seguridad | 4 |
| R6 | Seed reconstruido (catálogo + roles + matriz) | New | BD / Config | 4 |
| R7 | Frontend: UI roles, formulario usuario, filtrado | New | UI | 6 |
| R8 | Arreglo contrato CRUD de usuarios | Modified | API / Usuarios | 3 |
| R9 | Tests de backend | New | Testing | 5 |
| R10 | Infraestructura de auditoría | New | BD / Auditoría | 5 |

### Coverage

- **Happy paths**: ✅ Cubiertos (creación de rol con matriz, creación de usuario con overrides add/remove, resolución de autoridades, seed idempotente, refresh sin re-login, contrato de usuarios, registro de auditoría de usuarios/roles/permisos)
- **Edge cases**: ✅ Cubiertos (rol asignado no eliminable, override de permiso inexistente, conflicto true/false, matriz vacía, cambio sin re-login, superadmin editando su propio rol, operaciones rechazadas sin fila de auditoría)
- **Error states**: ✅ Cubiertos (403 backend, 400 catálogo inválido, 400/409 rol duplicado, 409 rol en uso, drift test de catálogo)
- **Total scenarios**: 44 (R1: 3, R2: 2, R3: 6, R4: 6, R5: 4, R6: 4, R7: 6, R8: 3, R9: 5, R10: 5)

### Next Step

Ready for **design** (sdd-design).
