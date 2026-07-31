# Proposal: Módulo de Roles y Permisos Granulares

## Intent

Hoy el sistema **NO impone permisos por módulo**: `SecurityConfig` solo tiene reglas hardcodeadas para `productos`, `usuarios` y `reportes`; todo lo demás (ventas, compras, gastos, precios, movimientos, clientes, proveedores, categorías, roles) cae en `anyRequest().authenticated()` — cualquier usuario autenticado puede ver y operar esos módulos sin restricción.

Además, la entidad `Rol` solo tiene `nombre` y `descripcion`; las autoridades se derivan de `"ROLE_" + rol.nombre` y **no hay forma de configurar granularidad** (qué acciones puede hacer un rol dentro de un módulo) ni de ajustar permisos por usuario individual.

El negocio necesita:

1. **Roles/perfiles administrables**: al crear/editar un rol se marca con checkboxes a qué módulos accede (Ventas, Compras, Precios, Gastos, Usuarios, etc.), con opción de desplegar acciones específicas por módulo (ver/crear/editar/eliminar).
2. **Ajustes por usuario**: al crear/editar un usuario se elige un rol base y se pueden **agregar o quitar** permisos de módulo individuales (ej. un "contador especial" que además ve Gastos, o un "pasante contable" que solo ve Compras).
3. **Todo administrable desde la UI** (roles, permisos de usuario, catálogo).
4. **Enforcement real en backend**: que el control de acceso no sea solo visual.

Este cambio además **arregla el contrato roto de CRUD de usuarios** (el frontend envía `rolNombre` como string pero el backend espera `rolId` Long → 400 al crear/editar; y el backend devuelve la entidad con `rol` anidado pero el modelo TS espera `rolNombre`/`rolId` a nivel raíz → columna Rol vacía en la UI). Sin ese arreglo, la administración de permisos por usuario es imposible desde la UI.

## Decisiones confirmadas

Las siguientes decisiones de diseño fueron **confirmadas por el usuario** y son vinculantes para el diseño y la implementación:

| # | Decisión | Estado | Opción elegida / Racional |
|---|----------|--------|---------------------------|
| 1 | Persistencia del catálogo | CONFIRMADA | Catálogo **en BD, dinámico**: tablas `modulos` + `permisos` (FK `permisos.modulo_id`); `rol_permisos` y `usuario_permisos` referencian permisos por FK. **Se rechaza el JSON blob** en `usuarios`: duplica datos, pierde integridad referencial, impide consultas sobre permisos y no permite expresar "quitar" de forma limpia. |
| 2 | Estrategia de seed | CONFIRMADA | **Reconstrucción limpia desde cero** (proyecto en desarrollo, no producción): ADMIN con todo; VENDEDOR y BODEGUERO con matrices coherentes que **restringen de verdad** (pierden accesos que hoy tienen por defecto). Se corrige el seed actual roto (roles sin permisos, CAJERO/SUPERVISOR inexistentes). |
| 3 | Roles fantasma | CONFIRMADA | **CAJERO y SUPERVISOR se eliminan** de las listas hardcodeadas del frontend. Los roles se crean desde la UI: 100% administrables. |
| 4 | Módulo ROLES | CONFIRMADA | **ROLES es el 13º módulo** del catálogo; solo `ROLES_VER` / `ROLES_EDITAR` (y acciones afines) permiten administrar roles. |
| 5 | Overrides por usuario | CONFIRMADA | Flag **`concedido` (boolean)** en `usuario_permisos`: habilita "agregar" (concedido=true) y "quitar" (concedido=false) permisos individuales respecto al rol base. El nombre del flag no importa; el flag es **obligatorio** para cumplir el requerimiento. |
| 6 | Refresco frontend | CONFIRMADA | **Refresh por navegación** vía `GET /api/usuarios/me` dentro del guard: los cambios de permiso aplican sin re-login. |
| 7 | Infraestructura de auditoría | CONFIRMADA | Este cambio construye SOLO la **infraestructura**: tabla genérica `auditoria` (entidad, entidad_id, accion, usuario_id, fecha, detalle) + `AuditService` reutilizable + instrumentación de usuarios/roles/permisos. El **módulo completo de auditoría** (UI de consulta, filtros, reportes, instrumentación del resto del sistema) se construye en un **spec/cambio futuro separado**. La tabla se diseña genérica para todo el sistema para que el módulo futuro solo necesite: (1) UI de consulta y (2) instrumentar los servicios restantes — sin migración ni reestructuración. |
| 8 | Sin flujo de aprobación | CONFIRMADA | Quien tiene `USUARIOS_EDITAR` / `ROLES_EDITAR` puede crear/editar usuarios y roles **directamente**. NO hay flujo de aprobación ni paso de aprobación de admin: **tener el permiso de edición ES la aprobación** (el admin ya aprobó al conceder ese acceso). |

## Scope

### In Scope

1. **Catálogo de módulos y permisos (backend)**:
   - Nueva entidad `Modulo` (nombre, codigo, orden) y nueva entidad `Permiso` (codigo estable tipo `VENTAS_VER`, nombre, modulo FK, accion).
   - Repositorios JPA correspondientes.
   - Catálogo sembrado de los 13 módulos (12 del sidebar + `ROLES`, confirmado — Decisión 4) con acciones `VER`/`CREAR`/`EDITAR`/`ELIMINAR` según aplique (Dashboard y Reportes solo `VER`; Precios `VER`+`EDITAR`; Movimientos `VER`+`CREAR`).
2. **Tablas de unión**:
   - `rol_permisos` (ManyToMany `Rol` ↔ `Permiso`) — matriz de permisos del rol.
   - `usuario_permisos` (`Usuario` ↔ `Permiso` con flag `concedido` true/false) — overrides por usuario: **agregar** (concedido=true) o **quitar** (concedido=false) permisos del rol base.
3. **Resolución de autoridades por request**: `CustomUserDetailsService` y `JwtAuthenticationFilter` calculan `autoridades = permisos(rol) ∪ permisos(usuario concedidos=true) ∖ permisos(usuario concedidos=false)`. Como el filtro ya recarga el usuario desde BD en cada request, los cambios de permiso aplican al siguiente request sin re-login (backend).
4. **Migración a `@EnableMethodSecurity` + `@PreAuthorize`**: se reemplazan las reglas URL hardcodeadas de `SecurityConfig` por anotaciones `@PreAuthorize("hasAuthority('VENTAS_VER')")` en todos los controllers. `hasRole` → `hasAuthority` (los códigos de permiso sustituyen a `ROLE_X`; el authority `ROLE_X` se conserva transitoriamente para compatibilidad).
5. **Seed reconstruido desde cero vía `CommandLineRunner`** (Decisión 2; `spring.sql.init.mode=never` impide usar schema.sql/data.sql automáticamente): catálogo módulos/permisos, roles base ADMIN/VENDEDOR/BODEGUERO con matrices coherentes que restringen de verdad, matriz `rol_permisos` y usuario admin existente. Reemplaza los INSERT manuales de roles en `schema.sql` (se corrigen/actualizan como referencia). Debe ser idempotente (no duplicar al reiniciar).
6. **Arreglo del contrato de usuarios**:
   - `UsuarioController` devuelve `UsuarioDTO` (ya existe, sin uso) con `rolId`/`rolNombre` a nivel raíz + lista de permisos efectivos.
   - `UsuarioRequestDTO` acepta `rolId` (ya lo exige) **y** lista de permisos por usuario (overrides).
   - Frontend: `usuario-form` envía `rolId` (cargado desde `/api/roles`, no hardcodeado) y los overrides de permisos; `Usuario` model alineado.
   - **Eliminar los roles fantasma** CAJERO y SUPERVISOR de la lista hardcodeada `['ADMIN','CAJERO','BODEGUERO','SUPERVISOR']` del frontend (Decisión 3); los roles se cargan desde `/api/roles` y se crean desde la UI.
7. **UI de administración de roles (Angular, feature module no-standalone)**:
   - Listado y formulario de rol con matriz de checkboxes módulo → acciones (acordeón/expansión por módulo).
   - Endpoints protegidos: `GET /api/roles/**`, `POST/PUT/DELETE /api/roles/**` con `ROLES_*` (hoy `/api/roles/**` está abierto a cualquier autenticado).
8. **Formulario de usuario con overrides**: dropdown de rol base + matriz de checkboxes de permisos precargada con los del rol base; marcar = agregar, desmarcar un permiso del rol = quitar.
9. **Frontend guards y refresh de permisos**:
   - `AuthGuard` extiende `data.roles` con `data.permissions`.
   - `AuthService` agrega `hasPermission()`, guarda permisos en sessionStorage y refresca vía `GET /api/usuarios/me` **en cada navegación** (dentro del guard, Decisión 6) — los cambios de permiso aplican sin re-login.
   - `SidebarComponent` filtra los 13 items del menú (12 existentes + Roles) por permiso (`MODULO_VER`).
   - Directiva ligera `HasPermissionDirective` para ocultar botones de acción según permiso (ver/crear/editar/eliminar).
10. **Tests mínimos backend** (siguiendo el patrón existente: unitario con Mockito — `PrecioServiceTest` — e integración con H2 — `CompraServiceIntegrationTest`):
    - Unitario de resolución de autoridades (rol ∪ usuario ∖ denegados).
    - Integración de seguridad: `@PreAuthorize` rechaza (403) a un usuario sin el permiso en un endpoint representativo.
    - Idempotencia del seed (correr 2 veces, sin duplicados).
11. **Infraestructura de auditoría** (Decisión 7):
    - Nueva tabla genérica `auditoria` (diseñada para todo el sistema): `entidad` (ej. USUARIO, ROL, VENTA, COMPRA), `entidad_id`, `accion` (CREAR/ACTUALIZAR/ELIMINAR), `usuario_id` (quién ejecutó), `fecha`, `detalle` (texto o JSON).
    - `AuditService` reutilizable (p. ej. `registrarEvento(entidad, entidadId, accion, detalle)`) invocable por cualquier servicio; resuelve el usuario autenticado internamente.
    - Instrumentación SOLO de lo que toca este cambio: creación/edición de usuarios, roles y cambios de permisos (matriz de rol y overrides por usuario). Registro atómico con la operación (operaciones rechazadas no generan filas).
    - El **módulo completo de auditoría** (UI de consulta, endpoints, filtros, reportes e instrumentación del resto del sistema) queda **FUERA de alcance** → spec/cambio futuro separado.

### Out of Scope

- **Módulo completo de auditoría** (UI de consulta, endpoints de consulta, filtros, reportes e instrumentación del resto del sistema — ventas, compras, productos, etc.): **fuera de alcance de este cambio**; se construirá en un spec/cambio futuro separado. La infraestructura (`auditoria` + `AuditService`, Decisión 7) queda lista para que ese módulo futuro solo requiera: (1) UI/endpoints de consulta y (2) instrumentar los servicios restantes — sin migración ni reestructuración.
- **Flujos de aprobación** para cambios de permisos (que un admin apruebe la solicitud de otro): **excluidos explícitamente y confirmados como decisión (Decisión 8)** — quien tiene `USUARIOS_EDITAR` / `ROLES_EDITAR` crea/edita directamente; el permiso de edición ES la aprobación.
- **Granularidad por campo** dentro de una página (ej. ocultar columna de costo a ciertos roles) — el alcance es módulo + acción.
- **Auto-servicio** de solicitud de permisos por parte del usuario final.
- **Eliminación definitiva** del authority `ROLE_X` y del claim `rol` del token — se conservan transitoriamente; la limpieza final es un cambio futuro.
- **Multi-tenant / organizaciones**.
- **Roles CAJERO/SUPERVISOR**: eliminados de las listas hardcodeadas del frontend (Decisión 3); **no se crean en el seed** ni se implementa lógica de negocio adicional para ellos — los roles se crean desde la UI de administración.

## Approach

**Opción C — Híbrida (recomendada por la exploración)**: catálogo sembrado + tablas de unión + resolución por request.

### Modelo de datos (nuevo)

```
modulos(id, nombre, codigo, orden)
permisos(id, modulo_id FK, codigo UNIQUE, nombre, accion)   -- ej. VENTAS_VER
rol_permisos(rol_id FK, permiso_id FK)                       -- PK compuesta
usuario_permisos(usuario_id FK, permiso_id FK, concedido BOOLEAN)  -- PK compuesta
auditoria(id, entidad, entidad_id, accion, usuario_id FK, fecha, detalle)  -- genérica para todo el sistema
```

Con `ddl-auto: update` las tablas nuevas se crean solas; el `CommandLineRunner` se encarga del catálogo, los roles y la matriz.

**Catálogo dinámico en BD (Decisión 1)**: los permisos se referencian **por FK** desde `rol_permisos` y `usuario_permisos`; NO se guarda un JSON blob de permisos en `usuarios` (rechazado: duplica datos, pierde integridad referencial, impide consultar permisos y no permite expresar "quitar" de forma limpia). El catálogo es datos, no código: agregar un módulo o permiso nuevo no exige deploy de esquema.

### Resolución de autoridades

```
permisos_efectivos = permisos(rol)
                    ∪ { p : usuario_permisos.concedido = true }
                    ∖ { p : usuario_permisos.concedido = false }
```

Se aplica igual en `CustomUserDetailsService` (login) y en `JwtAuthenticationFilter` (cada request). El filtro ya recarga el usuario desde BD → **cambios de permiso aplican al siguiente request sin re-login**.

### Migración de seguridad

1. `@EnableMethodSecurity` en `SecurityConfig`.
2. Se reemplazan las reglas URL por `@PreAuthorize` en cada controller, mapeando las reglas actuales a códigos:
   - `GET /api/productos/**` → `hasAuthority('PRODUCTOS_VER')`
   - `POST/PUT /api/productos/**` → `hasAuthority('PRODUCTOS_CREAR')` / `hasAuthority('PRODUCTOS_EDITAR')`
   - `DELETE /api/productos/**` → `hasAuthority('PRODUCTOS_ELIMINAR')`
   - `/api/usuarios/**` → `hasAuthority('USUARIOS_VER' | 'USUARIOS_CREAR' | ...)`
   - `/api/reportes/**` → `hasAuthority('REPORTES_VER')`
   - Módulos hoy "abiertos" (ventas, compras, gastos, precios, etc.) reciben `hasAuthority('X_VER')` etc. — **cambio de comportamiento intencional** (ver Riesgos: los roles VENDEDOR/BODEGUERO pierden acceso a módulos que hoy ven).
3. `SecurityConfig` queda con: permitAll (auth + swagger/scalar), protección `ROLES_*`/`USUARIOS_*` para los endpoints de administración si hace falta, y `anyRequest().authenticated()` como fallback.

### Matriz de seed (confirmada — Decisión 2)

**El seed se reconstruye desde cero** (proyecto en desarrollo, no producción). La matriz **restringe de verdad**: VENDEDOR y BODEGUERO pierden deliberadamente accesos que hoy tienen por defecto vía `anyRequest().authenticated()`. ADMIN recibe todos los permisos. Los accesos que tenían regla URL explícita (productos/usuarios/reportes) se respetan en lo que corresponde al nuevo modelo de permisos.

| Módulo | ADMIN | VENDEDOR | BODEGUERO |
|--------|-------|----------|-----------|
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

La matriz respeta el comportamiento actual donde existía regla explícita (productos/usuarios/reportes) y **restringe** donde hoy era `authenticated()` para todos. Las acciones `ELIMINAR` en Ventas/Compras se mapean a la anulación existente (detalle de diseño). La matriz es **datos sembrados y administrables desde la UI** — el usuario podrá ajustarla creando/editando roles sin tocar código.

### Refresco frontend (Decisión 6)

`AuthService.refreshPermisos()` consume `GET /api/usuarios/me` (devuelve permisos efectivos) y actualiza sessionStorage. Se invoca **en el guard, en cada navegación** (además de tras editar el propio usuario): los cambios de permiso aplican en el siguiente request del backend (el filtro recarga de BD) y el frontend queda sincronizado sin re-login.

### Infraestructura de auditoría (Decisión 7)

Este cambio construye solo la infraestructura: tabla genérica `auditoria` + `AuditService` (p. ej. `registrarEvento(entidad, entidadId, accion, detalle)`) que resuelve el usuario autenticado desde el contexto de seguridad. Se instrumenta únicamente lo que toca este cambio (creación/edición de usuarios, roles y cambios de permisos), con registro atómico a la operación (las operaciones rechazadas no generan filas). El módulo completo de auditoría (consulta, filtros, reportes, instrumentación del resto del sistema) se construirá en un spec futuro; la tabla genérica lo habilita sin migración ni reestructuración.

## Affected Areas

| Área | Impacto | Descripción |
|------|---------|-------------|
| `backend/.../entity/{Modulo,Permiso}.java` | Nuevo | Catálogo de módulos y permisos |
| `backend/.../entity/Rol.java` | Modificado | `@ManyToMany` permisos |
| `backend/.../entity/Usuario.java` | Modificado | `@ManyToMany` overrides de permisos |
| `backend/.../entity/UsuarioPermiso.java` | Nuevo | Overrides por usuario con flag `concedido` |
| `backend/.../repository/{Modulo,Permiso,UsuarioPermiso}Repository.java` | Nuevo | Acceso JPA |
| `backend/.../config/DataSeeder.java` | Nuevo | `CommandLineRunner` idempotente — seed **reconstruido desde cero** (catálogo 13 módulos + permisos + roles + matriz) |
| `backend/src/main/resources/schema.sql` | Modificado | INSERT manual de roles/usuario admin queda **reemplazado por el seed** (se ajusta como referencia para evitar duplicados/confusión) |
| `backend/.../config/SecurityConfig.java` | Modificado | `@EnableMethodSecurity`, reglas URL reducidas |
| `backend/.../auth/CustomUserDetailsService.java` | Modificado | Resolución de autoridades |
| `backend/.../auth/JwtAuthenticationFilter.java` | Modificado | Resolución de autoridades por request |
| `backend/.../auth/JwtTokenProvider.java` | Modificado (menor) | Claim `rol` se conserva; sin cambios funcionales |
| `backend/.../service/UsuarioService.java` | Modificado | Persistir overrides de permisos |
| `backend/.../controller/UsuarioController.java` | Modificado | Devuelve `UsuarioDTO` (+ permisos efectivos), `/me` enriquecido, `@PreAuthorize` |
| `backend/.../dto/UsuarioDTO.java` | Modificado | + lista de permisos efectivos |
| `backend/.../dto/UsuarioRequestDTO.java` | Modificado | + lista de overrides de permisos |
| `backend/.../dto/AuthResponseDTO.java` | Modificado | + lista de permisos (para el login) |
| `backend/.../controller/RolController.java` | Modificado | CRUD con permisos del rol, `@PreAuthorize('ROLES_*')` |
| `backend/.../controller/*Controller.java` | Modificado | `@PreAuthorize` por endpoint en los ~13 módulos |
| `backend/src/test/java/...` | Nuevo | Tests mínimos (autoridades, seguridad, seed) |
| `backend/.../entity/Auditoria.java` | Nuevo | Entidad de auditoría genérica (entidad, entidad_id, accion, usuario, fecha, detalle) |
| `backend/.../repository/AuditoriaRepository.java` | Nuevo | Acceso JPA |
| `backend/.../service/AuditService.java` | Nuevo | `registrarEvento(...)` reutilizable; resuelve el usuario autenticado |
| `frontend/src/app/roles/` | Nuevo | Feature module Angular: listado + formulario con matriz módulos/acciones |
| `frontend/src/app/usuarios/usuario-form/*` | Modificado | Dropdown rol desde API + checkboxes de overrides por usuario |
| `frontend/src/app/usuarios/usuario.service.ts` | Modificado | Payload con `rolId` + overrides |
| `frontend/src/app/core/{auth.service,auth.guard,models,constants}.ts` | Modificado | `hasPermission()`, `data.permissions`, refresh `/me`, tipos `Modulo`/`Permiso` |
| `frontend/src/app/core/has-permission.directive.ts` | Nuevo | Ocultar botones de acción por permiso |
| `frontend/src/app/shared/sidebar/*` | Modificado | Filtrado por `MODULO_VER` |
| `frontend/src/app/app-routing.module.ts` | Modificado | Ruta `/roles` lazy con guard |

## Risks

| Riesgo | Probabilidad | Mitigación |
|--------|--------------|------------|
| Migración `hasRole` → `hasAuthority` rompe accesos existentes (un rol pierde acceso que hoy tiene, o el admin se auto-bloquea) | Med | Matriz de seed respeta 1:1 las reglas URL actuales (productos/usuarios/reportes) y ADMIN recibe todos los permisos; test de integración que verifica acceso/403 por rol; verificación manual del login admin antes de merge |
| Contrato roto de usuarios rompe la UI de administración (pieza depende de esta corrección) | Alta (ya roto hoy) | Se arregla en el mismo cambio: frontend envía `rolId`, backend devuelve `UsuarioDTO`; test de integración del contrato; se valida crear/editar usuario desde UI como criterio de éxito |
| Seed: `spring.sql.init.mode=never` + `ddl-auto: update` → catálogo duplicado o roles sin permisos al reiniciar | Med | `CommandLineRunner` idempotente (consulta antes de insertar); test de idempotencia |
| Cambio de comportamiento: VENDEDOR/BODEGUERO pierden acceso a módulos que hoy ven (porque `authenticated()` los dejaba pasar) | Med (intencional) | Es el objetivo del cambio (enforcement real); la matriz **confirmada** (Decisión 2) define los accesos coherentes y los overrides por usuario cubren casos particulares; se valida con el usuario en la demo de aceptación |
| Drift entre catálogo dinámico y `@PreAuthorize`: un código usado en `hasAuthority('X_VER')` que no existe en el catálogo (o un permiso del catálogo sin anotación) | Med | Códigos generados por convención `<MODULO>_<ACCION>`; el seeder valida que todos los códigos referenciados existan en el catálogo; test de integración que recorre los `@PreAuthorize` y verifica consistencia con el seed |
| Staleness frontend: sessionStorage cachea solo `rol`; permisos desactualizados tras cambio de admin | Med | `refreshPermisos()` vía `/me` en **cada navegación** (Decisión 6); backend ya aplica cambios al siguiente request (filtro recarga de BD) |
| Superadmin se bloquea a sí mismo editando el rol ADMIN | Baja | Validación de negocio: al menos un usuario admin activo con permisos de administración; warning en UI al desmarcar permisos del rol propio |

## Rollback Plan

Como el cambio toca seguridad y esquema, el rollback depende de la fase:

- **Schema**: con `ddl-auto: update` las tablas nuevas (`modulos`, `permisos`, `rol_permisos`, `usuario_permisos`) se pueden eliminar con DROP manual; las columnas agregadas a tablas existentes se revierten igual (no hay migraciones formales; es un proyecto sin Flyway/Liquibase).
- **Código**: revertir el PR del cambio con `git revert` (o checkout del commit previo). Los archivos nuevos se eliminan y los modificados vuelven al estado `hasRole`/reglas URL hardcodeadas.
- **Datos**: al ser un seed reconstruido desde cero (proyecto en desarrollo), revertir implica limpiar las tablas nuevas (`modulos`, `permisos`, `rol_permisos`, `usuario_permisos`) y restaurar los INSERT manuales de `schema.sql`; los overrides en `usuario_permisos` solo existen si se usó la UI nueva antes del revert.
- **Regla de oro**: no mergear el cambio sin haber verificado manualmente que el admin puede loguearse y operar con la nueva matriz; eso elimina el escenario de "sistema bloqueado" post-deploy.

## Dependencies

- Ninguna externa. Interna: el arreglo del contrato de usuarios (In Scope, item 6) es prerrequisito lógico de los items 7-8; el orden de tareas lo definirá `tasks.md`.
- Se asume la arquitectura existente (layered, JWT, DTOs, feature modules Angular) sin cambios.

## Success Criteria

- [ ] Un admin crea un rol marcando módulos y acciones con checkboxes; un usuario con ese rol recibe **exactamente** esos permisos (verificado en backend: 403 en módulo sin permiso, 200 con permiso).
- [ ] Al crear/editar un usuario se elige rol base y se pueden **agregar y quitar** permisos individuales; el efecto aplica al siguiente request en backend y tras `refreshPermisos()` en frontend.
- [ ] CRUD de usuarios funciona end-to-end desde la UI (crear, editar rol + overrides) — el contrato `rolId`/DTO queda corregido.
- [ ] La matriz de seed **confirmada** (Decisión 2) aplica: ADMIN tiene todos los permisos; VENDEDOR y BODEGUERO reciben exactamente los accesos de la matriz, incluida la **pérdida deliberada** de módulos que hoy veían por `authenticated()` (verificado con 200/403 por rol).
- [ ] Los roles fantasma **CAJERO/SUPERVISOR no existen** en el frontend: la UI carga roles desde `/api/roles` y no hay listas hardcodeadas.
- [ ] Consistencia catálogo ↔ `@PreAuthorize`: todos los códigos de permiso usados en anotaciones existen en el catálogo sembrado (validado por test).
- [ ] Los 13 módulos del catálogo (12 del sidebar + ROLES) quedan gobernados: menú filtrado, rutas protegidas (`data.permissions`) y backend con `@PreAuthorize`.
- [ ] `/api/roles/**` queda protegido (hoy abierto a cualquier autenticado).
- [ ] Seed idempotente: reiniciar la app dos veces no duplica catálogo ni matriz.
- [ ] Tests mínimos pasan: resolución de autoridades, 403/200 de un endpoint representativo, idempotencia del seed.
- [ ] Auditoría (Decisión 7): crear/editar un usuario o un rol registra la fila en `auditoria` (entidad, entidad_id, accion, usuario_id, fecha, detalle); operaciones rechazadas no generan filas.
