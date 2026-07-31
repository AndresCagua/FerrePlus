# Design: Módulo de Roles y Permisos Granulares

## Technical Approach

Se introduce **enforcement real de permisos por módulo** sobre la arquitectura existente (controller → service → repository → entity, JWT stateless, `ddl-auto: update`). El enfoque es **catálogo dinámico en BD + tablas de unión + resolución de autoridades por request** (Opción C de la propuesta):

1. **Catálogo en BD**: nuevas entidades `Modulo` y `Permiso` (FK `permisos.modulo_id`), sembradas por un `CommandLineRunner` idempotente (`DataSeeder`) — fuente única de verdad, no código hardcodeado.
2. **Matrices**: `rol_permisos` (ManyToMany `Rol` ↔ `Permiso`) y `usuario_permisos` (`Usuario` ↔ `Permiso` con flag `concedido`, PK compuesta) para overrides de agregar/quitar por usuario.
3. **Resolución de autoridades**: `permisos_efectivos = permisos(rol) ∪ {concedido=true} ∖ {concedido=false}`, calculada por un componente compartido `PermisoResolver` e inyectada en `CustomUserDetailsService` (login) y `JwtAuthenticationFilter` (cada request, que ya recarga el usuario desde BD → los cambios aplican al siguiente request sin re-login). Se usa una consulta `JOIN FETCH` para evitar N+1.
4. **Enforcement**: migración de reglas URL hardcodeadas (`hasRole`) a `@EnableMethodSecurity` + `@PreAuthorize("hasAuthority('<CODIGO>')")` por endpoint en los 13 controllers. `SecurityConfig` queda con `permitAll` (auth + swagger/scalar) y `anyRequest().authenticated()` como fallback. El authority `ROLE_<NOMBRE>` se conserva transitoriamente junto a los códigos.
5. **Seed reconstruido**: 13 módulos, 42 permisos, 3 roles (ADMIN/VENDEDOR/BODEGUERO) con la matriz confirmada que **restringe de verdad**, y el usuario admin. Reemplaza los INSERT manuales de `schema.sql` como fuente de verdad (quedan como referencia ajustada).
6. **Contrato de usuarios corregido**: el backend devuelve `UsuarioDTO` (rolId/rolNombre a nivel raíz + permisos efectivos + overrides) y acepta `rolId` + overrides; el frontend carga roles desde `/api/roles` (se eliminan los roles fantasma CAJERO/SUPERVISOR).
7. **Frontend**: feature module `roles` (no-standalone, lazy), formulario de rol con matriz de checkboxes por módulo/acción, formulario de usuario con rol base + overrides, `AuthGuard` con refresh vía `/me` en cada navegación, sidebar filtrado por `MODULO_VER`, directiva `HasPermissionDirective`.
8. **Auditoría (infraestructura)**: tabla genérica `auditoria` + `AuditService.registrarEvento(...)`, atómico con la operación, instrumentada solo para usuarios/roles/permisos (el módulo completo de consulta queda para un spec futuro).

Las especificaciones (spec.md) definen 10 requerimientos (R1-R10) con 44 escenarios. Este diseño cubre todos ellos.

## Architecture Decisions

### Decision: Catálogo dinámico en BD (modulos + permisos) en lugar de JSON blob o enum hardcodeado

**Choice**: Tablas `modulos` y `permisos` con FK, referenciadas por `rol_permisos` y `usuario_permisos`. Códigos de permiso con patrón `<MODULO>_<ACCION>` únicos globalmente.
**Alternatives considered**: JSON blob en `usuarios`, `enum` en código, propiedades de config.
**Rationale**: Confirmado por el usuario (Decisión 1 de la propuesta). El JSON blob duplica datos, pierde integridad referencial, impide consultas sobre permisos y no expresa "quitar" limpiamente. Un enum/código hardcodeado no permite administrar el catálogo desde la UI sin deploy. El catálogo es **dato**, no código: agregar un módulo o permiso nuevo no exige cambios de esquema ni de clase.

### Decision: `PermisoResolver` como componente compartido para la resolución de autoridades

**Choice**: Nuevo componente `com.ferreplus.auth.PermisoResolver` con `Set<String> codigosEfectivos(Usuario)` y `List<GrantedAuthority> resolverAutoridades(Usuario)`, usado por `CustomUserDetailsService`, `JwtAuthenticationFilter`, `AuthService.login` y `UsuarioService` (para armar DTOs).
**Alternatives considered**: Duplicar la lógica en cada punto de autenticación; colocar el cálculo en `CustomUserDetailsService` y reusarlo desde el filtro.
**Rationale**: La semántica `∪ concedidos ∖ denegados` debe aplicarse idéntica en login, por request y al construir `UsuarioDTO.permisos`. Un solo componente evita drift entre implementaciones, es unit-testable de forma aislada (Mockito puro, sin dependencias de Spring) y mantiene el orden `∖ después de ∪` (el override `concedido=false` gana sobre el rol, edge case 10 de la spec) en un único lugar.

### Decision: Consulta `JOIN FETCH` única para evitar N+1 en la resolución por request

**Choice**: `UsuarioRepository.findWithPermisosByEmail(email)` con `JOIN FETCH` de `u.rol`, `r.permisos` y `u.overrides` (con `up.permiso`), más `findAllWithPermisos()` para listados.
**Alternatives considered**: Múltiples queries por request (usuario, rol, permisos del rol, overrides), `@EntityGraph`.
**Rationale**: El filtro JWT corre en **cada request**; una sola query con `JOIN FETCH` + `DISTINCT` resuelve usuario + rol + matriz + overrides en un round-trip. El volumen es acotado (≤ 42 permisos de catálogo, pocos overrides por usuario), por lo que el producto cartesiano es despreciable. Sigue la regla del especialista Spring Boot: `fetch = LAZY` + `JOIN FETCH` (nunca `EAGER` en colecciones). Se usa `LEFT JOIN FETCH` para no excluir usuarios sin permisos ni overrides.

### Decision: `@EnableMethodSecurity` + `@PreAuthorize` por endpoint (reglas URL mínimas en SecurityConfig)

**Choice**: Se reemplazan las reglas `hasRole` hardcodeadas por anotaciones `@PreAuthorize("hasAuthority('X_VER')")` en cada método de controller. `SecurityConfig` queda con `permitAll` (auth + swagger/scalar), `authenticated()` como fallback y un `AccessDeniedHandler` que devuelve 403 en formato JSON consistente con `GlobalExceptionHandler`.
**Alternatives considered**: Mantener y extender las reglas URL con `hasAuthority`; solo `@PreAuthorize` sin reglas URL.
**Rationale**: Las reglas URL no pueden expresar la granularidad por método (ej. `GET /api/roles` requiere `ROLES_VER` pero `POST` requiere `ROLES_EDITAR` en el mismo path) sin repetirse y volverse frágiles. Las anotaciones viven junto al endpoint (drift visible en review y cubierto por el drift test de R9.4). Mantener reglas URL "de defensa" duplicadas crearía una segunda fuente de verdad que debe sincronizarse a mano; la especificación lo permite ("si procede") pero no lo exige. Se conserva `anyRequest().authenticated()` como red de seguridad.

### Decision: Semántica de `ELIMINAR` para Ventas/Compras = anulación existente

**Choice**: En el catálogo, `VENTAS_ELIMINAR` y `COMPRAS_ELIMINAR` se declaran (R1) y se asignan en la matriz, pero se **enforcean** sobre los endpoints de anulación existentes: `PUT /api/ventas/{id}/anular` → `hasAuthority('VENTAS_ELIMINAR')` y `PUT /api/compras/{id}/anular` → `hasAuthority('COMPRAS_ELIMINAR')`. NO existe borrado físico de ventas/compras.
**Alternatives considered**: No declarar `ELIMINAR` en el catálogo para estos módulos; crear endpoints de borrado físico.
**Rationale**: R1 exige que Ventas y Compras declaren `ELIMINAR`; R8 de la spec (regla de negocio 8) fija que `ELIMINAR` corresponde a anulación, no borrado físico. El servicio `VentaService.anular`/`CompraService.anular` ya implementa esa semántica (revierte stock, marca estado ANULADA). El catálogo documenta la acción como "anular"; la UI debe rotular el botón como "Anular" para estos módulos. `VENTAS_EDITAR` se declara en el catálogo (R1) pero **no** tiene endpoint (no existe `PUT /api/ventas/{id}`) → entra en el allowlist del drift test (ver Testing Strategy).

### Decision: Protección de `/api/roles/**` con `ROLES_VER` (lecturas) y `ROLES_EDITAR` (escrituras)

**Choice**: `GET /api/roles` y `GET /api/roles/{id}` → `hasAuthority('ROLES_VER')`; `POST/PUT/DELETE /api/roles/**` → `hasAuthority('ROLES_EDITAR')`. Los códigos `ROLES_CREAR` y `ROLES_ELIMINAR` se declaran en el catálogo y la matriz (R1: el módulo ROLES declara las 4 acciones) pero **no** se usan en anotaciones: R3 fija que todas las escrituras de roles requieren `ROLES_EDITAR`.
**Alternatives considered**: `ROLES_CREAR`/`ROLES_ELIMINAR` como autoridades efectivas de POST/DELETE.
**Rationale**: R3 es explícito y vinculante: "Escrituras (POST/PUT/DELETE) DEBEN requerir `ROLES_EDITAR`". Declarar las 4 acciones en el catálogo cumple R1 y da a la matriz una vista completa del módulo, pero el enforcement granular de roles es deliberadamente VER/EDITAR (un rol no puede crearse sin poder editarse; la granularidad fina no aporta valor y añade complejidad). Se documenta la excepción en el drift test.

### Decision: `/api/usuarios/me` accesible para cualquier usuario autenticado (no `USUARIOS_VER`)

**Choice**: `GET /api/usuarios/me` → `@PreAuthorize("isAuthenticated()")` (sin código de catálogo). Devuelve `UsuarioDTO` con permisos efectivos.
**Alternatives considered**: Proteger `/me` con `USUARIOS_VER`; dejar la regla URL actual `hasRole("ADMIN")`.
**Rationale**: Decisión 6 de la propuesta (refresh vía `/me` en cada navegación) requiere que **todo** usuario autenticado consulte `/me`; si exigiera `USUARIOS_VER`, un vendedor no podría refrescar permisos y el guard del frontend fallaría. Hoy `/me` está tras `hasRole("ADMIN")` (regla URL `/api/usuarios/**`), lo que ya impediría el refresh. Este cambio de comportamiento es intencional y necesario.

### Decision: Contrato de usuarios corregido + password opcional en `UsuarioRequestDTO`

**Choice**: `UsuarioController` devuelve `UsuarioDTO` (ya existe, hoy sin uso) con `rolId`/`rolNombre` a nivel raíz + `permisos` (efectivos) + `overrides`; `UsuarioRequestDTO` acepta `rolId` (Long, obligatorio) + `overrides` y **password opcional** (se quita `@NotBlank`; la validación de creación queda en el servicio, que ya la hace).
**Alternatives considered**: Mantener el contrato actual (entidad anidada, `rolNombre` string).
**Rationale**: El contrato roto (frontend envía `rolNombre`, backend exige `rolId` → 400; backend devuelve entidad anidada → columna Rol vacía) es un prerrequisito de la administración de overrides (R8). Además, el `@NotBlank` actual sobre `password` rompe la **edición** de usuarios sin cambio de contraseña (el frontend omite el campo y el backend responde 400): se corrige en el mismo cambio. La validación de creación se mantiene en `UsuarioService.create` (ya existe: "La contraseña es obligatoria").

### Decision: `DataSeeder` (CommandLineRunner) idempotente como fuente única de verdad; `schema.sql` queda como referencia

**Choice**: Nuevo `DataSeeder` que: (1) inserta módulos/permisos faltantes por `codigo`; (2) inserta roles faltantes por `nombre`; (3) inserta pares `rol_permisos` faltantes de la matriz (semántica de **piso**: nunca remueve permisos otorgados luego por la UI); (4) crea el usuario admin por email si no existe. `schema.sql` conserva sus INSERT como referencia comentada (la fuente única es el seeder).
**Alternatives considered**: `data.sql`/`schema.sql` automáticos, `@PostConstruct` en un config.
**Rationale**: `spring.sql.init.mode=never` impide la ejecución automática de `schema.sql`/`data.sql`. Un `CommandLineRunner` con chequeo-antes-de-insertar es idempotente (R6), no depende del dialecto (H2 en tests, PostgreSQL en runtime), y el patrón "piso" preserva personalizaciones del admin tras reiniciar sin duplicar. El seeder corre al arrancar cada contexto de test (`@SpringBootTest`), lo que los tests de integración aprovechan.

### Decision: Infraestructura de auditoría genérica (`auditoria` + `AuditService`), atómica con la operación

**Choice**: Entidad `Auditoria` (`entidad`, `entidad_id`, `accion`, `usuario_id` nullable, `fecha`, `detalle` TEXT) + `AuditService.registrarEvento(entidad, entidadId, accion, detalle)` que resuelve el usuario autenticado desde `SecurityContextHolder`. Se invoca DENTRO del `@Transactional` del servicio (UsuarioService/RolService) → misma transacción (R10): operación rechazada no genera fila; fallo de auditoría revierte la operación.
**Alternatives considered**: Spring Data Envers, eventos de aplicación (`ApplicationEventPublisher`), auditoría asíncrona.
**Rationale**: Decisión 7 confirmada: infraestructura mínima para habilitar el módulo futuro sin migración. Envers impone su propio esquema/versionado y no encaja con la tabla genérica `entidad/entidad_id` pedida. Eventos asíncronos romperían la atomicidad (R10 escenario "Registro atómico"). El patrón de llamada directa dentro de la transacción es el más simple y cumple el requisito. `usuario_id` nullable cubre eventos de sistema/seed (no se audita el seed: es bootstrap idempotente, no una operación de usuario).

### Decision: `detalle` de auditoría como JSON string estructurado

**Choice**: `detalle` = JSON serializado (Jackson `ObjectMapper`) con resumen estructurado, p. ej. para rol: `{"nombre":"Contable","permisos":["VENTAS_VER"],"permisosAgregados":["GASTOS_VER"],"permisosQuitados":["COMPRAS_VER"]}`. Si la serialización falla, se guarda texto plano (fallback que no rompe la operación).
**Alternatives considered**: Columnas normalizadas por campo, texto libre plano.
**Rationale**: La spec permite texto o JSON (edge case 15) y el módulo futuro no depende del formato. JSON en una columna TEXT da resúmenes legibles y parseables sin reestructurar la tabla; las columnas normalizadas son overkill para la infraestructura actual y el módulo futuro puede consultar por `entidad/entidad_id/accion/fecha` sin parsear.

### Decision: Frontend conserva el patrón existente (feature modules no-standalone, Reactive Forms, Material)

**Choice**: El módulo `roles` sigue el patrón de `gestion-precios`/`usuarios`: NgModule no-standalone, lazy loading, Reactive Forms (FormBuilder), Angular Material + SweetAlert2. Los componentes nuevos usan `ChangeDetectionStrategy` consistente con el resto del proyecto.
**Alternatives considered**: Componentes standalone + Signal Forms (recomendación del especialista Angular para v21+).
**Rationale**: El proyecto entero es no-standalone con Reactive Forms (documentado en `openspec/config.yaml`: "Angular feature modules (not standalone)"). La regla de diseño es seguir los patrones existentes salvo que el cambio los aborde explícitamente; migrar a standalone/signals aquí ampliaría el blast radius sin aportar al objetivo del cambio. Se respeta `AGENTS.md`/config del proyecto sobre las preferencias del especialista.

## Data Flow

### Flujo 1: Resolución de autoridades por request (backend)

```
Request con Bearer token
  │
  └─→ JwtAuthenticationFilter.doFilterInternal()
        │  token válido → email
        ├─→ UsuarioRepository.findWithPermisosByEmail(email)   [1 query JOIN FETCH]
        │       Usuario + rol(EAGER) + rol.permisos + overrides(+permiso)
        ├─→ PermisoResolver.resolverAutoridades(usuario)
        │       codigos = rol.permisos ∪ overrides(true) ∖ overrides(false)
        │       authorities = [codigo1..codigoN] + [ROLE_<rol.nombre>]
        └─→ SecurityContextHolder ← UsernamePasswordAuthenticationToken(usuario, null, authorities)
              │
              └─→ @PreAuthorize("hasAuthority('X_VER')") en el controller
                     ├─ 200 si el authority está en el contexto
                     └─ 403 (AccessDeniedHandler → JSON) si no
```

### Flujo 2: Creación/edición de rol con auditoría (backend)

```
POST /api/roles  (RolRequestDTO { nombre, descripcion, permisos: [codigos] })
  │  @PreAuthorize("hasAuthority('ROLES_EDITAR')")
  └─→ RolService.create(dto)  [@Transactional]
        ├─→ Validar nombre único → 400 si existe
        ├─→ Validar códigos contra PermisoRepository → 400 si alguno no existe
        ├─→ Construir Rol + Set<Permiso>
        ├─→ rolRepository.save(rol)
        └─→ auditService.registrarEvento("ROL", rol.id, "CREAR", jsonDetalle)  [misma tx]

PUT /api/roles/{id}  →  RolService.update(id, dto)  [@Transactional]
        ├─→ getById → rol existente
        ├─→ Validaciones (nombre único si cambió, códigos válidos)
        ├─→ rol.getPermisos().clear(); addAll(nuevos)   [reemplazo completo de matriz]
        ├─→ save
        └─→ auditService.registrarEvento("ROL", id, "ACTUALIZAR",
                 {"permisosAgregados": [...], "permisosQuitados": [...]})
```

### Flujo 3: Creación de usuario con overrides y auditoría (backend)

```
POST /api/usuarios  (UsuarioRequestDTO { ..., rolId, overrides: [{permisoCodigo, concedido}] })
  │  @PreAuthorize("hasAuthority('USUARIOS_CREAR')")
  └─→ UsuarioService.create(dto)  [@Transactional]
        ├─→ Validar password (servicio), email único
        ├─→ Validar overrides: códigos existen; sin conflicto true/false por permiso → 400
        ├─→ rol = rolService.getById(rolId)
        ├─→ usuario.overrides ← Set<UsuarioPermiso> (concedido según payload)
        ├─→ usuarioRepository.save(usuario)
        └─→ auditService.registrarEvento("USUARIO", usuario.id, "CREAR", jsonDetalle)
```

### Flujo 4: Frontend — guard refresca permisos en cada navegación (Decisión 6)

```
Navegación a /gastos
  │
  └─→ AuthGuard.canActivate()  [asíncrono]
        ├─→ ¿token? no → redirect /auth
        ├─→ authService.refreshPermisos()  →  GET /api/usuarios/me  (Bearer token)
        │        └─→ UsuarioDTO { ..., permisos: [efectivos] }
        │              └─→ sessionStorage.ferreplus_permisos ← permisos
        ├─→ ¿route.data.permissions=['GASTOS_VER']?  → hasAnyPermission(permissions)
        │        ├─ sí → permitir navegación
        │        └─ no → redirect /dashboard
        └─→ Sidebar re-renderiza items filtrados por hasPermission('MODULO_VER')
```

## Data Model

### Nuevas entidades

```java
// Modulo.java — catálogo de módulos
@Entity
@Table(name = "modulos")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Modulo {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 50)
    private String nombre;                     // "Ventas"

    @Column(nullable = false, unique = true, length = 30)
    private String codigo;                     // "VENTAS" — estable, mayúsculas

    @Column(nullable = false)
    private Integer orden;                     // para ordenar en la UI (1..13)

    @OneToMany(mappedBy = "modulo", fetch = FetchType.LAZY)
    private List<Permiso> permisos = new ArrayList<>();
}

// Permiso.java — acción dentro de un módulo
@Entity
@Table(name = "permisos")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Permiso {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String codigo;                     // "VENTAS_VER" — único global

    @Column(nullable = false, length = 100)
    private String nombre;                     // "Ver ventas"

    @Column(nullable = false, length = 20)
    private String accion;                     // VER | CREAR | EDITAR | ELIMINAR

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "modulo_id", nullable = false)
    private Modulo modulo;
}

// UsuarioPermiso.java — override por usuario (PK compuesta)
@Entity
@Table(name = "usuario_permisos")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@IdClass(UsuarioPermisoId.class)
public class UsuarioPermiso {
    @Id @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    @Id @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "permiso_id", nullable = false)
    private Permiso permiso;

    @Column(nullable = false)
    private boolean concedido;                 // true = agregar, false = quitar
}

// UsuarioPermisoId.java — clase de PK compuesta
public class UsuarioPermisoId implements Serializable {
    private Long usuario;
    private Long permiso;
    // equals/hashCode sobre ambos campos
}

// Auditoria.java — tabla genérica para todo el sistema
@Entity
@Table(name = "auditoria")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Auditoria {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 50)
    private String entidad;                    // "USUARIO", "ROL", "VENTA", ... (extensible)

    @Column(name = "entidad_id")
    private Long entidadId;

    @Column(nullable = false, length = 20)
    private String accion;                     // CREAR | ACTUALIZAR | ELIMINAR

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id")           // nullable: eventos de sistema
    private Usuario usuario;

    @Column(nullable = false, updatable = false)
    private LocalDateTime fecha;

    @Column(columnDefinition = "TEXT")
    private String detalle;                    // JSON string estructurado

    @PrePersist
    protected void onCreate() { fecha = LocalDateTime.now(); }
}
```

### Entidades modificadas

```java
// Rol.java — se agrega la matriz de permisos
@Entity
@Table(name = "roles")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Rol {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String nombre;

    @Column(length = 200)
    private String descripcion;

    @ManyToMany(fetch = FetchType.LAZY)                          // tabla rol_permisos
    @JoinTable(name = "rol_permisos",
        joinColumns = @JoinColumn(name = "rol_id"),
        inverseJoinColumns = @JoinColumn(name = "permiso_id"))
    private Set<Permiso> permisos = new HashSet<>();             // matriz del rol
}

// Usuario.java — se agregan los overrides por usuario
@Entity
@Table(name = "usuarios")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Usuario {
    // ... campos existentes (id, nombre, email, password, telefono, activo, rol EAGER, fechas)
    // se conserva: @ManyToOne(fetch = FetchType.EAGER) Rol rol;  (EAGER ya existente)

    @OneToMany(mappedBy = "usuario", fetch = FetchType.LAZY,
               cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<UsuarioPermiso> overrides = new HashSet<>();     // overrides de permisos
}
```

### Resumen de esquema

```
modulos(id PK, nombre, codigo UNIQUE, orden)
permisos(id PK, modulo_id FK→modulos NOT NULL, codigo UNIQUE, nombre, accion)
rol_permisos(rol_id FK→roles, permiso_id FK→permisos)          -- PK compuesta, tabla de ManyToMany
usuario_permisos(usuario_id FK→usuarios, permiso_id FK→permisos, concedido BOOLEAN NOT NULL)  -- PK compuesta
auditoria(id PK, entidad, entidad_id, accion, usuario_id FK→usuarios NULL, fecha, detalle TEXT)
roles (+ nada nuevo: la matriz vive en rol_permisos)
usuarios (+ nada nuevo: los overrides viven en usuario_permisos)
```

Con `ddl-auto: update` (proyecto sin Flyway/Liquibase), Hibernate crea las tablas nuevas y la join table automáticamente. **No se agrega ninguna columna JSON/texto a `usuarios`** (R1: escenario "Los overrides NO se guardan como JSON blob").

### Restricciones clave

| Regla | Implementación |
|-------|----------------|
| Código de permiso único global | `@Column(unique = true)` en `permisos.codigo` (R1) |
| Un solo override por (usuario, permiso) | PK compuesta `(usuario_id, permiso_id)` (R4) |
| Nombre de rol único | `@Column(unique = true)` en `roles.nombre` + validación en servicio (400) |
| `concedido` obligatorio | `@Column(nullable = false)` |
| Catálogo es fuente única | permisos siempre por FK, nunca string libre |

## Security Design

### Algoritmo de resolución de autoridades

```
función resolverAutoridades(usuario):
    codigos = conjunto vacío

    # 1. Base: matriz del rol
    para cada p en usuario.rol.permisos:            # carga con JOIN FETCH (1 query)
        codigos.agregar(p.codigo)

    # 2. Overrides: agregar
    para cada up en usuario.overrides donde up.concedido == true:
        codigos.agregar(up.permiso.codigo)

    # 3. Overrides: quitar (∖ aplica DESPUÉS de ∪ — edge case 10)
    para cada up en usuario.overrides donde up.concedido == false:
        codigos.remover(up.permiso.codigo)

    authorities = [new SimpleGrantedAuthority(c) para c en codigos]
    authorities += [new SimpleGrantedAuthority("ROLE_" + usuario.rol.nombre)]   # transitorio

    retornar authorities
```

**Dónde se aplica** (R5):

| Punto | Clase | Cambio |
|-------|-------|--------|
| Login | `CustomUserDetailsService.loadUserByUsername` | Usar `findWithPermisosByEmail` + `PermisoResolver.resolverAutoridades` |
| Cada request | `JwtAuthenticationFilter.doFilterInternal` | Ídem; ya recarga el usuario desde BD → cambios aplican al siguiente request sin re-login |
| Login (DTO) | `AuthService.login` | `codigosEfectivos(usuario)` → `AuthResponseDTO.permisos` |
| DTOs | `UsuarioService` (toDTO) | `codigosEfectivos(usuario)` → `UsuarioDTO.permisos` |

**Anti N+1**: `UsuarioRepository`:

```java
@Query("""
    SELECT DISTINCT u FROM Usuario u
    JOIN FETCH u.rol r
    LEFT JOIN FETCH r.permisos
    LEFT JOIN FETCH u.overrides up
    LEFT JOIN FETCH up.permiso
    WHERE u.email = :email
    """)
Optional<Usuario> findWithPermisosByEmail(@Param("email") String email);

@Query("""
    SELECT DISTINCT u FROM Usuario u
    JOIN FETCH u.rol r
    LEFT JOIN FETCH r.permisos
    LEFT JOIN FETCH u.overrides up
    LEFT JOIN FETCH up.permiso
    """)
List<Usuario> findAllWithPermisos();
```

### SecurityConfig

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity                       // ← NUEVO: habilita @PreAuthorize
@RequiredArgsConstructor
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf(csrf -> csrf.disable())
            .exceptionHandling(ex -> ex
                .authenticationEntryPoint(jwtAuthenticationEntryPoint)
                .accessDeniedHandler(new JsonAccessDeniedHandler()))   // 403 JSON consistente
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/swagger-ui/**", "/swagger-ui.html", "/v3/api-docs/**",
                                 "/swagger-resources/**", "/webjars/**", "/scalar/**").permitAll()
                .anyRequest().authenticated())                          // fallback; el control fino son las anotaciones
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
    // ... corsConfigurationSource, passwordEncoder, authenticationManager sin cambios
}
```

`JsonAccessDeniedHandler` (nuevo, en `com.ferreplus.auth` o `config`): escribe `{"error": "Acceso denegado", "timestamp": ...}` con 403, consistente con `GlobalExceptionHandler` (NFR: mensaje genérico de acceso denegado).

### Mapeo @PreAuthorize por controller/módulo (13 módulos + auth)

El mapping completo de los **14 controllers** existentes (Auth + 13 de negocio). Regla general: `GET` → `X_VER`, `POST` → `X_CREAR`, `PUT` → `X_EDITAR`, `DELETE` → `X_ELIMINAR`, con las excepciones documentadas.

| Controller | Módulo | Endpoint | Anotación |
|------------|--------|----------|-----------|
| `AuthController` | — | `POST /api/auth/login`, `POST /api/auth/register` | `permitAll` (regla URL; sin anotación) |
| `ProductoController` | PRODUCTOS | `GET /api/productos`, `GET /api/productos/{id}`, `GET /api/productos/stock-bajo` | `PRODUCTOS_VER` |
| | | `POST /api/productos` | `PRODUCTOS_CREAR` |
| | | `PUT /api/productos/{id}` | `PRODUCTOS_EDITAR` |
| | | `DELETE /api/productos/{id}` | `PRODUCTOS_ELIMINAR` |
| `CategoriaController` | CATEGORIAS | `GET /api/categorias`, `GET /api/categorias/{id}` | `CATEGORIAS_VER` |
| | | `POST /api/categorias` | `CATEGORIAS_CREAR` |
| | | `PUT /api/categorias/{id}` | `CATEGORIAS_EDITAR` |
| | | `DELETE /api/categorias/{id}` | `CATEGORIAS_ELIMINAR` |
| `ProveedorController` | PROVEEDORES | `GET /api/proveedores`, `GET /api/proveedores/{id}` | `PROVEEDORES_VER` |
| | | `POST /api/proveedores` | `PROVEEDORES_CREAR` |
| | | `PUT /api/proveedores/{id}` | `PROVEEDORES_EDITAR` |
| | | `DELETE /api/proveedores/{id}` | `PROVEEDORES_ELIMINAR` |
| `ClienteController` | CLIENTES | `GET /api/clientes`, `GET /api/clientes/{id}` | `CLIENTES_VER` |
| | | `POST /api/clientes` | `CLIENTES_CREAR` |
| | | `PUT /api/clientes/{id}` | `CLIENTES_EDITAR` |
| | | `DELETE /api/clientes/{id}` | `CLIENTES_ELIMINAR` |
| `VentaController` | VENTAS | `GET /api/ventas`, `GET /api/ventas/{id}`, `GET /api/ventas/reportes/por-fecha` | `VENTAS_VER` |
| | | `POST /api/ventas` | `VENTAS_CREAR` |
| | | `PUT /api/ventas/{id}/anular` | `VENTAS_ELIMINAR` *(semántica: anular, no borrar)* |
| `CompraController` | COMPRAS | `GET /api/compras`, `GET /api/compras/{id}`, `GET /api/compras/reportes/por-fecha` | `COMPRAS_VER` |
| | | `POST /api/compras` | `COMPRAS_CREAR` |
| | | `PUT /api/compras/{id}` | `COMPRAS_EDITAR` |
| | | `PUT /api/compras/{id}/anular` | `COMPRAS_ELIMINAR` *(semántica: anular)* |
| `PrecioController` | PRECIOS | `GET /api/precios`, `GET /api/precios/{id}`, `GET /api/precios/{id}/historial` | `PRECIOS_VER` |
| | | `PUT /api/precios/{id}/venta` | `PRECIOS_EDITAR` |
| `MovimientoStockController` | MOVIMIENTOS | `GET /api/movimientos-stock` | `MOVIMIENTOS_VER` |
| | | `POST /api/movimientos-stock` | `MOVIMIENTOS_CREAR` |
| `GastoController` | GASTOS | `GET /api/gastos`, `GET /api/gastos/{id}` | `GASTOS_VER` |
| | | `POST /api/gastos` | `GASTOS_CREAR` |
| | | `PUT /api/gastos/{id}` | `GASTOS_EDITAR` |
| | | `DELETE /api/gastos/{id}` | `GASTOS_ELIMINAR` |
| `UsuarioController` | USUARIOS | `GET /api/usuarios`, `GET /api/usuarios/{id}` | `USUARIOS_VER` |
| | | `POST /api/usuarios` | `USUARIOS_CREAR` |
| | | `PUT /api/usuarios/{id}`, `PUT /api/usuarios/{id}/password` | `USUARIOS_EDITAR` |
| | | `DELETE /api/usuarios/{id}` | `USUARIOS_ELIMINAR` |
| | | `GET /api/usuarios/me` | `isAuthenticated()` — **excepción documentada** (Decisión 6: refresh `/me` para todo autenticado) |
| `RolController` | ROLES | `GET /api/roles`, `GET /api/roles/{id}` | `ROLES_VER` |
| | | `POST /api/roles`, `PUT /api/roles/{id}`, `DELETE /api/roles/{id}` | `ROLES_EDITAR` (R3: todas las escrituras) |
| `ReporteController` | DASHBOARD / REPORTES | `GET /api/reportes/dashboard` | `DASHBOARD_VER` |
| | | `GET /api/reportes/ventas`, `GET /api/reportes/inventario`, `GET /api/reportes/movimientos` | `REPORTES_VER` |
| `CatalogoController` (nuevo) | — | `GET /api/modulos`, `GET /api/permisos` | `hasAnyAuthority('ROLES_VER', 'USUARIOS_VER')` (R2) |

**Observación Dashboard/Reportes**: el módulo Dashboard comparte path con Reportes (`/api/reportes/**`). El dashboard del frontend consume `/api/reportes/dashboard` (métricas) y `/api/reportes/ventas` (gráfico por periodo). Con este mapeo, un usuario con solo `DASHBOARD_VER` (BODEGUERO) verá el dashboard con el gráfico de periodo **vacío** (el endpoint del gráfico exige `REPORTES_VER`; el componente ya degrada con gracia en error). Es la opción estricta: no filtra datos de reportes a quien no tiene `REPORTES_VER` (decisión documentada; ver Riesgos).

### Reglas URL (segunda capa)

`SecurityConfig` conserva solo `permitAll` (auth + swagger/scalar) y `anyRequest().authenticated()`. No se duplican reglas URL por módulo: las anotaciones son la fuente de verdad del enforcement fino y el drift test (R9.4) garantiza consistencia con el catálogo. `authenticated()` ya es la segunda capa para cualquier endpoint sin anotar.

## API Design

### Catálogo (R2) — `CatalogoController` (`/api`)

```
GET /api/modulos  → 200 ModuloDTO[]
GET /api/permisos → 200 PermisoDTO[]
Protección: hasAnyAuthority('ROLES_VER', 'USUARIOS_VER') — 403 sin ellos
```

```jsonc
// ModuloDTO
{ "id": 6, "nombre": "Ventas", "codigo": "VENTAS", "orden": 6,
  "permisos": [
    { "id": 20, "codigo": "VENTAS_VER",   "nombre": "Ver ventas",   "accion": "VER" },
    { "id": 21, "codigo": "VENTAS_CREAR", "nombre": "Crear ventas", "accion": "CREAR" },
    { "id": 22, "codigo": "VENTAS_EDITAR","nombre": "Editar ventas","accion": "EDITAR" },
    { "id": 23, "codigo": "VENTAS_ELIMINAR","nombre": "Anular ventas","accion": "ELIMINAR" }
  ] }

// PermisoDTO (plano)
{ "id": 20, "codigo": "VENTAS_VER", "nombre": "Ver ventas", "accion": "VER",
  "moduloId": 6, "moduloCodigo": "VENTAS", "moduloNombre": "Ventas" }
```

### Roles (R3) — `RolController` (`/api/roles`)

```
GET    /api/roles       → 200 RolDTO[]                (ROLES_VER)
GET    /api/roles/{id}  → 200 RolDTO                  (ROLES_VER)
POST   /api/roles       → 200 RolDTO                  (ROLES_EDITAR)
PUT    /api/roles/{id}  → 200 RolDTO                  (ROLES_EDITAR)
DELETE /api/roles/{id}  → 204                         (ROLES_EDITAR)
```

```jsonc
// RolDTO (respuesta)
{ "id": 5, "nombre": "Contable", "descripcion": "Contabilidad",
  "permisos": ["VENTAS_VER", "VENTAS_CREAR", "COMPRAS_VER", "COMPRAS_CREAR", "PRECIOS_VER"] }

// RolRequestDTO (request POST/PUT)
{ "nombre": "Contable", "descripcion": "Contabilidad",
  "permisos": ["VENTAS_VER", "VENTAS_CREAR", "COMPRAS_VER", "COMPRAS_CREAR", "PRECIOS_VER"] }
```

Validaciones y reglas de negocio (R3):
- `nombre` `@NotBlank` + único → 400 `BadRequestException` si ya existe.
- Códigos de `permisos` contra `PermisoRepository` → 400 si alguno no existe.
- `PUT` reemplaza la **matriz completa** (clear + addAll).
- `DELETE` → 409 `ConflictException` (nueva) si algún usuario activo tiene el rol (`UsuarioRepository.countByRolIdAndActivoTrue(id) > 0`). Se agrega `ConflictException` + handler en `GlobalExceptionHandler` (409) — la spec permite 400/409; 409 es semánticamente correcto para conflicto de estado.
- Rol con matriz vacía es válido (edge case 12).
- Auditoría en CREAR/ACTUALIZAR/ELIMINAR exitosos (R10).

### Usuarios (R4/R8) — `UsuarioController` (`/api/usuarios`)

```
GET    /api/usuarios          → 200 UsuarioDTO[]              (USUARIOS_VER)
GET    /api/usuarios/{id}     → 200 UsuarioDTO                (USUARIOS_VER)
GET    /api/usuarios/me       → 200 UsuarioDTO                (isAuthenticated())
POST   /api/usuarios          → 200 UsuarioDTO                (USUARIOS_CREAR)
PUT    /api/usuarios/{id}     → 200 UsuarioDTO                (USUARIOS_EDITAR)
DELETE /api/usuarios/{id}     → 204 (soft-delete)             (USUARIOS_ELIMINAR)
PUT    /api/usuarios/{id}/password → 200                      (USUARIOS_EDITAR)
```

```jsonc
// UsuarioDTO (respuesta) — rolId/rolNombre a nivel raíz (R8)
{ "id": 9, "nombre": "Juan", "email": "juan@ferreplus.com", "telefono": "09...",
  "activo": true, "rolId": 2, "rolNombre": "VENDEDOR",
  "permisos": ["DASHBOARD_VER","PRODUCTOS_VER","CLIENTES_VER","CLIENTES_CREAR",
               "CLIENTES_EDITAR","VENTAS_VER","VENTAS_CREAR","PRECIOS_VER","REPORTES_VER",
               "GASTOS_VER"],
  "overrides": [ { "permisoCodigo": "GASTOS_VER", "concedido": true } ] }

// UsuarioRequestDTO (request POST/PUT)
{ "nombre": "Juan", "email": "juan@ferreplus.com", "telefono": "09...",
  "password": "clave123",          // opcional en PUT (si se omite, no cambia)
  "rolId": 2,                      // Long, obligatorio (@NotNull)
  "overrides": [ { "permisoCodigo": "GASTOS_VER", "concedido": true },
                 { "permisoCodigo": "COMPRAS_VER", "concedido": false } ] }

// UsuarioPermisoRequestDTO
{ "permisoCodigo": "GASTOS_VER", "concedido": true }
```

Validaciones (R4):
- `rolId` `@NotNull`. `password` sin `@NotBlank` (solo `@Size(min = 6)` cuando viene) — creación valida en servicio.
- Overrides: códigos existen en catálogo → 400; mismo permiso con `concedido=true` y `false` en la misma petición → 400; duplicados exactos → 400.
- `PUT` reemplaza la **lista completa** de overrides (orphanRemoval elimina los que ya no vienen).
- `GET /api/usuarios/me` devuelve permisos **efectivos** (rol ∪ concedidos ∖ denegados).
- Auditoría en CREAR/ACTUALIZAR (incluye cambios de rol y overrides)/soft-DELETE/cambio de password exitosos.

### Login (R8) — `AuthResponseDTO` modificado

```jsonc
{ "token": "...", "email": "juan@ferreplus.com", "nombre": "Juan",
  "rol": "VENDEDOR", "usuarioId": 9,
  "permisos": ["DASHBOARD_VER","PRODUCTOS_VER","CLIENTES_VER","CLIENTES_CREAR",
               "CLIENTES_EDITAR","VENTAS_VER","VENTAS_CREAR","PRECIOS_VER","REPORTES_VER",
               "GASTOS_VER"] }
```

## Seed Matrix

### Catálogo (13 módulos, 42 permisos)

`DataSeeder` inserta por `codigo` (idempotente). `orden` define la posición en la UI:

| orden | Módulo | Código | Acciones |
|-------|--------|--------|----------|
| 1 | Dashboard | DASHBOARD | VER |
| 2 | Productos | PRODUCTOS | VER, CREAR, EDITAR, ELIMINAR |
| 3 | Categorías | CATEGORIAS | VER, CREAR, EDITAR, ELIMINAR |
| 4 | Proveedores | PROVEEDORES | VER, CREAR, EDITAR, ELIMINAR |
| 5 | Clientes | CLIENTES | VER, CREAR, EDITAR, ELIMINAR |
| 6 | Ventas | VENTAS | VER, CREAR, EDITAR, ELIMINAR |
| 7 | Compras | COMPRAS | VER, CREAR, EDITAR, ELIMINAR |
| 8 | Precios | PRECIOS | VER, EDITAR |
| 9 | Movimientos | MOVIMIENTOS | VER, CREAR |
| 10 | Gastos | GASTOS | VER, CREAR, EDITAR, ELIMINAR |
| 11 | Usuarios | USUARIOS | VER, CREAR, EDITAR, ELIMINAR |
| 12 | Roles | ROLES | VER, CREAR, EDITAR, ELIMINAR |
| 13 | Reportes | REPORTES | VER |

Nota: Ventas y Compras **no** tienen `PUT /{id}` de edición (excepto Compras); `VENTAS_EDITAR` queda declarado sin endpoint (allowlist del drift test). `ELIMINAR` en Ventas/Compras = anulación.

### Matriz de roles (R6 — Decisión 2 confirmada)

| Módulo | ADMIN | VENDEDOR | BODEGUERO |
|--------|-------|----------|-----------|
| Dashboard | todo | VER | VER |
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

Donde "todo" = todas las acciones declaradas del módulo.

**Resultado en códigos exactos** (69 pares `rol_permisos`):

- **ADMIN (42)**: todos los códigos del catálogo.
- **VENDEDOR (9)**: `DASHBOARD_VER`, `PRODUCTOS_VER`, `CLIENTES_VER`, `CLIENTES_CREAR`, `CLIENTES_EDITAR`, `VENTAS_VER`, `VENTAS_CREAR`, `PRECIOS_VER`, `REPORTES_VER`.
- **BODEGUERO (18)**: `DASHBOARD_VER`, `PRODUCTOS_VER`, `PRODUCTOS_CREAR`, `PRODUCTOS_EDITAR`, `CATEGORIAS_VER`, `CATEGORIAS_CREAR`, `CATEGORIAS_EDITAR`, `PROVEEDORES_VER`, `PROVEEDORES_CREAR`, `PROVEEDORES_EDITAR`, `CLIENTES_VER`, `VENTAS_VER`, `COMPRAS_VER`, `COMPRAS_CREAR`, `COMPRAS_EDITAR`, `PRECIOS_VER`, `MOVIMIENTOS_VER`, `MOVIMIENTOS_CREAR`.

**Restricciones deliberadas** (cambio de comportamiento intencional): VENDEDOR pierde Categorías, Proveedores, Compras, Gastos y Movimientos (hoy los ve por `anyRequest().authenticated()`); BODEGUERO pierde Clientes CREAR/EDITAR y Reportes. Los accesos con regla URL explícita actual (productos GET/POST/PUT, usuarios, reportes) se respetan 1:1.

### Usuario admin

`DataSeeder` crea `admin@ferreplus.com` (password por defecto `admin123`, BCrypt) con rol ADMIN, **solo si no existe** (idempotente; no sobreescribe password ni rol).

### Idempotencia

Cada paso consulta antes de insertar: módulos/permisos por `codigo`, roles por `nombre`, pares `rol_permisos` por (rol, permiso), admin por `email`. Segunda ejecución = cero cambios. La semántica de **piso** para `rol_permisos` (insertar faltantes, nunca remover) garantiza el escenario "doble ejecución sin duplicados" y preserva ajustes posteriores del admin. No se crean CAJERO ni SUPERVISOR (Decisión 3). El seeder **no** escribe filas de auditoría (bootstrap de sistema, no operación de usuario).

## Audit Design (R10)

### Estructura

Ver `Auditoria` en Data Model. Columnas: `id`, `entidad` (String 50), `entidad_id` (Long), `accion` (CREAR/ACTUALIZAR/ELIMINAR), `usuario_id` (FK `usuarios`, nullable), `fecha` (timestamp, `@PrePersist`), `detalle` (TEXT, JSON string).

### AuditService API

```java
@Service
@RequiredArgsConstructor
public class AuditService {
    private final AuditoriaRepository auditoriaRepository;

    /** Resuelve el usuario autenticado desde SecurityContextHolder (principal instanceof Usuario).
        Para eventos de sistema/seed el usuario_id queda null. */
    @Transactional(propagation = Propagation.MANDATORY)   // exige transacción del llamador
    public void registrarEvento(String entidad, Long entidadId, String accion, String detalle) {
        Long usuarioId = usuarioActualId();               // SecurityContextHolder → Usuario.id, o null
        auditoriaRepository.save(Auditoria.builder()
                .entidad(entidad).entidadId(entidadId).accion(accion)
                .usuario(usuarioActual())                 // null si no hay contexto
                .detalle(detalle).build());
    }
}
```

`Propagation.MANDATORY` garantiza que el registro ocurra **dentro** de la transacción del llamador (R10, escenario "Registro atómico"): si la operación falla y hace rollback, la fila de auditoría también revierte; si el save de auditoría falla, la operación completa revierte. Operaciones bloqueadas (400/409) lanzan antes de llegar a `registrarEvento` → no generan filas.

### Atomicidad

| Operación | Servicio | Auditoría |
|-----------|----------|-----------|
| Crear usuario | `UsuarioService.create` | `registrarEvento("USUARIO", id, "CREAR", json)` — última línea |
| Editar usuario (datos/rol/overrides) | `UsuarioService.update` | `("USUARIO", id, "ACTUALIZAR", json con overrides)` |
| Soft-delete usuario | `UsuarioService.delete` | `("USUARIO", id, "ELIMINAR", json)` |
| Cambiar password | `UsuarioService.cambiarPassword` | `("USUARIO", id, "ACTUALIZAR", {"cambioPassword":true})` |
| Crear rol | `RolService.create` | `("ROL", id, "CREAR", json con matriz)` |
| Editar rol (matriz) | `RolService.update` | `("ROL", id, "ACTUALIZAR", json con agregados/quitados)` |
| Eliminar rol | `RolService.delete` | `("ROL", id, "ELIMINAR", json)` — solo si no está en uso (si no, 409 y sin fila) |

El seed NO audita (bootstrap).

### Formato del detalle (JSON)

```jsonc
// ROL CREAR
{"nombre":"Contable","descripcion":"Contabilidad","permisos":["VENTAS_VER","PRECIOS_VER"]}
// ROL ACTUALIZAR (diff de matriz)
{"nombre":"Contable","permisos":["VENTAS_VER","PRECIOS_VER","GASTOS_VER"],
 "permisosAgregados":["GASTOS_VER"],"permisosQuitados":["COMPRAS_VER"]}
// USUARIO CREAR
{"nombre":"Juan","email":"juan@ferreplus.com","rolId":2,"rolNombre":"VENDEDOR",
 "overrides":[{"codigo":"GASTOS_VER","concedido":true}]}
// USUARIO ACTUALIZAR
{"nombre":"Juan","rolId":2,"rolNombre":"VENDEDOR",
 "overrides":[{"codigo":"GASTOS_VER","concedido":true},{"codigo":"COMPRAS_VER","concedido":false}]}
```

Serialización con Jackson `ObjectMapper`; fallback a texto plano si falla (no rompe la operación). El módulo futuro consulta por `entidad/entidad_id/accion/fecha` sin depender del formato (edge case 15).

## Frontend Design (R7, R8)

### Estructura de archivos nueva

```
frontend/src/app/roles/
├── roles.module.ts                 # NgModule no-standalone (patrón gestion-precios/usuarios)
├── roles-routing.module.ts         # rutas: '' list, 'nuevo', ':id/editar' (lazy desde AppRouting)
├── rol.service.ts                  # list/getById/create/update/delete → /api/roles
├── rol-list/rol-list.component.{ts,html,scss}    # MatTable: nombre, descripción, permisos (badges), acciones
└── rol-form/rol-form.component.{ts,html,scss}    # formulario + matriz módulo→acciones (mat-expansion-panel)
frontend/src/app/shared/permisos-matriz/permisos-matriz.component.{ts,html,scss}  # matriz reutilizable
frontend/src/app/core/has-permission.directive.ts # directiva estructural *appHasPermission
frontend/src/app/core/catalogo.service.ts          # getModulos() / getPermisos() → catálogo
```

### Rol form — matriz de checkboxes módulo → acciones

- Carga `GET /api/modulos` (13 módulos ordenados, cada uno con sus permisos).
- Por módulo: `mat-expansion-panel` con checkbox "seleccionar todo" (indeterminado) + un `mat-checkbox` por acción (`VER`/`CREAR`/`EDITAR`/`ELIMINAR`).
- Estado: `FormArray` de `FormGroup { permisoCodigo, checked }` construido con el catálogo.
- Al guardar: recolectar códigos chequeados → `RolRequestDTO { nombre, descripcion, permisos: [codigos] }`.
- En edición: precargar `checked` desde `rol.permisos`.
- Botones Nuevo/Editar/Eliminar visibles solo con `*appHasPermission="'ROLES_EDITAR'"`.

### Formulario de usuario — rol base + overrides

- Dropdown de rol base cargado desde `GET /api/roles` (sin hardcodeos; se elimina `['ADMIN','CAJERO','BODEGUERO','SUPERVISOR']`).
- Matriz de overrides: se carga el catálogo (`GET /api/modulos`); estado inicial `checked` = permisos del rol base (de `rolService.list()`, que ya trae `permisos`) **después** de aplicar los overrides del usuario (en edición).
- Semántica al togglear (relativa al rol base):
  - `checked` y el permiso **está** en el rol → sin override.
  - `checked` y el permiso **no está** en el rol → override `{ permisoCodigo, concedido: true }` (agregar).
  - `desmarcado` y el permiso **está** en el rol → override `{ permisoCodigo, concedido: false }` (quitar).
  - `desmarcado` y no está en el rol → sin override.
- Payload: `{ nombre, email, telefono, activo, rolId, password?, overrides: [...] }`. Al cambiar de rol base se recalcula el estado inicial de la matriz.
- En edición, al cargar el usuario (UsuarioDTO con `permisos` y `overrides`), el estado inicial se reconstruye aplicando los overrides sobre la matriz del rol base.

### AuthService

```typescript
// core/auth.service.ts — cambios
export interface CurrentUser {
  email: string; nombre: string; rol: string; usuarioId: number;
  permisos: string[];
}

// sessionStorage: nueva clave 'ferreplus_permisos' (JSON array)
login(...): guarda permisos desde AuthResponse.permisos
refreshPermisos(): Observable<Usuario>  // GET /api/usuarios/me → actualiza sessionStorage + subject
hasPermission(codigo: string): boolean
hasAnyPermission(codigos: string[]): boolean
```

### AuthGuard

```typescript
canActivate(route, state): Observable<boolean> {
  if (!this.authService.isLoggedIn()) { redirect('/auth', { returnUrl }); return of(false); }
  return this.authService.refreshPermisos().pipe(      // refresh en CADA navegación (Decisión 6)
    map(() => {
      const perms = route.data?.['permissions'] as string[] | undefined;
      if (perms && perms.length && !this.authService.hasAnyPermission(perms)) {
        this.router.navigate(['/dashboard']);
        return false;
      }
      return true;
    }),
    catchError(() => { redirect('/auth'); return of(false); })
  );
}
```

Se mantiene el chequeo de `data.roles` para compatibilidad transitoria (ninguna ruta actual lo usa).

### Rutas (app-routing.module.ts) — `data.permissions` por módulo

| Ruta | data.permissions |
|------|------------------|
| `/dashboard` | `['DASHBOARD_VER']` |
| `/productos` | `['PRODUCTOS_VER']` |
| `/categorias` | `['CATEGORIAS_VER']` |
| `/proveedores` | `['PROVEEDORES_VER']` |
| `/clientes` | `['CLIENTES_VER']` |
| `/ventas` | `['VENTAS_VER']` |
| `/compras` | `['COMPRAS_VER']` |
| `/gestion-precios` | `['PRECIOS_VER']` |
| `/movimientos` | `['MOVIMIENTOS_VER']` |
| `/gastos` | `['GASTOS_VER']` |
| `/usuarios` | `['USUARIOS_VER']` |
| `/roles` (nueva) | `['ROLES_VER']` |
| `/reportes` | `['REPORTES_VER']` |

### Sidebar (13 items, filtro por `MODULO_VER`)

`MenuItem` pasa de `roles?: string[]` a `permissions?: string[]`; se agrega el item Roles (icon `admin_panel_settings`, ruta `/roles`, `['ROLES_VER']`); el item Reportes pasa de `roles: ['ADMIN','SUPERVISOR']` a `permissions: ['REPORTES_VER']` (se elimina la referencia al rol fantasma). Filtrado: `hasAnyPermission(item.permissions)`.

### HasPermissionDirective

```typescript
@Directive({ selector: '[appHasPermission]' })
export class HasPermissionDirective {
  // *appHasPermission="'PRODUCTOS_CREAR'" o *appHasPermission="['A','B']" (any)
  // Elimina el elemento del DOM si el usuario no tiene el/los permiso(s).
}
```

Se declara y exporta en `SharedModule`; los feature modules que la usen importan `SharedModule`. Se aplica en este cambio a los botones de acción primarios de `productos` (Nuevo/Editar/Eliminar — escenario R7), `usuarios` y `roles`; el resto de módulos puede adoptarla incrementalmente.

### modelos (core/models.ts)

```typescript
export interface Modulo { id: number; nombre: string; codigo: string; orden: number; permisos: Permiso[]; }
export interface Permiso { id: number; codigo: string; nombre: string; accion: string;
                           moduloId?: number; moduloCodigo?: string; moduloNombre?: string; }
export interface Rol { id: number; nombre: string; descripcion: string; permisos: string[]; }
export interface RolRequest { nombre: string; descripcion: string; permisos: string[]; }
export interface UsuarioPermisoOverride { permisoCodigo: string; concedido: boolean; }
// Usuario: + permisos: string[]; + overrides: UsuarioPermisoOverride[];
// AuthResponse: + permisos: string[];
```

### usuario-list (badges genéricos)

`getRolClass` se simplifica: mapa genérico por `rolNombre` con fallback (`default`) y se eliminan los casos CAJERO/SUPERVISOR (R8).

## File Changes

### Backend — nuevos

| Archivo | Descripción |
|---------|-------------|
| `backend/src/main/java/com/ferreplus/entity/Modulo.java` | Entidad catálogo de módulos |
| `backend/src/main/java/com/ferreplus/entity/Permiso.java` | Entidad catálogo de permisos (FK modulo) |
| `backend/src/main/java/com/ferreplus/entity/UsuarioPermiso.java` | Override por usuario (PK compuesta, `concedido`) |
| `backend/src/main/java/com/ferreplus/entity/UsuarioPermisoId.java` | Clase de PK compuesta |
| `backend/src/main/java/com/ferreplus/entity/Auditoria.java` | Entidad genérica de auditoría |
| `backend/src/main/java/com/ferreplus/repository/ModuloRepository.java` | `findByCodigo`, `findAllByOrderByOrdenAsc` |
| `backend/src/main/java/com/ferreplus/repository/PermisoRepository.java` | `findByCodigo`, `findByCodigoIn` |
| `backend/src/main/java/com/ferreplus/repository/UsuarioPermisoRepository.java` | Acceso a overrides (asserts de tests, auditoría) |
| `backend/src/main/java/com/ferreplus/repository/AuditoriaRepository.java` | Acceso a auditoría |
| `backend/src/main/java/com/ferreplus/auth/PermisoResolver.java` | Resolución `rol ∪ concedidos ∖ denegados` |
| `backend/src/main/java/com/ferreplus/service/AuditService.java` | `registrarEvento(...)` con `Propagation.MANDATORY` |
| `backend/src/main/java/com/ferreplus/service/CatalogoService.java` | `getModulosConPermisos()`, `getPermisos()` |
| `backend/src/main/java/com/ferreplus/controller/CatalogoController.java` | `GET /api/modulos`, `GET /api/permisos` |
| `backend/src/main/java/com/ferreplus/config/DataSeeder.java` | `CommandLineRunner` idempotente (catálogo + roles + matriz + admin) |
| `backend/src/main/java/com/ferreplus/auth/JsonAccessDeniedHandler.java` | 403 JSON consistente |
| `backend/src/main/java/com/ferreplus/exception/ConflictException.java` | 409 (rol en uso) |
| `backend/src/main/java/com/ferreplus/dto/ModuloDTO.java` | Respuesta catálogo (con permisos agrupados) |
| `backend/src/main/java/com/ferreplus/dto/PermisoDTO.java` | Respuesta catálogo plano |
| `backend/src/main/java/com/ferreplus/dto/RolDTO.java` | Respuesta rol con códigos de permiso |
| `backend/src/main/java/com/ferreplus/dto/RolRequestDTO.java` | Request rol con matriz |
| `backend/src/main/java/com/ferreplus/dto/UsuarioPermisoRequestDTO.java` | Override: `permisoCodigo` + `concedido` |
| `backend/src/main/java/com/ferreplus/dto/UsuarioPermisoDTO.java` | Override en respuestas |

### Backend — modificados

| Archivo | Cambio |
|---------|--------|
| `backend/.../entity/Rol.java` | + `@ManyToMany Set<Permiso> permisos` (tabla `rol_permisos`) |
| `backend/.../entity/Usuario.java` | + `@OneToMany Set<UsuarioPermiso> overrides` (cascade ALL, orphanRemoval) |
| `backend/.../repository/UsuarioRepository.java` | + `findWithPermisosByEmail`, `findAllWithPermisos`, `countByRolIdAndActivoTrue` |
| `backend/.../auth/CustomUserDetailsService.java` | Usar `findWithPermisosByEmail` + `PermisoResolver` |
| `backend/.../auth/JwtAuthenticationFilter.java` | Ídem (recarga por request) |
| `backend/.../service/AuthService.java` | `AuthResponseDTO.permisos` vía resolver |
| `backend/.../service/UsuarioService.java` | Persistir overrides, validar, mapear `UsuarioDTO` (con permisos + overrides), audit |
| `backend/.../service/RolService.java` | DTOs, validar/reescribir matriz, 409 en uso, audit |
| `backend/.../controller/UsuarioController.java` | DTOs en respuestas, `/me` → `UsuarioDTO`, `@PreAuthorize` |
| `backend/.../controller/RolController.java` | DTOs, `@PreAuthorize` |
| `backend/.../controller/{Producto,Categoria,Proveedor,Cliente,Venta,Compra,Precio,MovimientoStock,Gasto,Reporte}Controller.java` | `@PreAuthorize` por endpoint (tabla de mapeo) |
| `backend/.../config/SecurityConfig.java` | `@EnableMethodSecurity`, reglas URL reducidas, AccessDeniedHandler |
| `backend/.../exception/GlobalExceptionHandler.java` | Handler para `ConflictException` (409) |
| `backend/.../dto/UsuarioDTO.java` | + `permisos` + `overrides` |
| `backend/.../dto/UsuarioRequestDTO.java` | + `overrides`; password sin `@NotBlank` |
| `backend/.../dto/AuthResponseDTO.java` | + `permisos` |
| `backend/src/main/resources/schema.sql` | Ajustar como referencia (comentario: `DataSeeder` es la fuente única) |
| `DOCUMENTACION_INTERNA.md` | Sección 4: matriz confirmada + nuevo modelo de permisos |

### Frontend — nuevos

| Archivo | Descripción |
|---------|-------------|
| `frontend/src/app/roles/roles.module.ts` | Feature module no-standalone |
| `frontend/src/app/roles/roles-routing.module.ts` | Rutas lazy internas |
| `frontend/src/app/roles/rol.service.ts` | CRUD roles |
| `frontend/src/app/roles/rol-list/rol-list.component.{ts,html,scss}` | Listado con MatTable |
| `frontend/src/app/roles/rol-form/rol-form.component.{ts,html,scss}` | Formulario + matriz de checkboxes |
| `frontend/src/app/shared/permisos-matriz/permisos-matriz.component.{ts,html,scss}` | Matriz reutilizable (rol/usuario) |
| `frontend/src/app/core/catalogo.service.ts` | Catálogo para forms |
| `frontend/src/app/core/has-permission.directive.ts` | Directiva de acción |

### Frontend — modificados

| Archivo | Cambio |
|---------|--------|
| `frontend/src/app/core/models.ts` | + `Modulo`, `Permiso`, `Rol`, `RolRequest`, `UsuarioPermisoOverride`; `Usuario`/`AuthResponse` + `permisos`; `Usuario` + `overrides` |
| `frontend/src/app/core/auth.service.ts` | + `permisos` en `CurrentUser`/sessionStorage, `refreshPermisos()`, `hasPermission()`, `hasAnyPermission()` |
| `frontend/src/app/core/auth.guard.ts` | Async + `data.permissions` + refresh `/me` por navegación |
| `frontend/src/app/core/core.module.ts` / `shared/shared.module.ts` | Exportar directive + PermisosMatrizComponent |
| `frontend/src/app/app-routing.module.ts` | `data.permissions` en 13 rutas + ruta `/roles` lazy con guard |
| `frontend/src/app/shared/sidebar/sidebar.component.{ts,html}` | 13 items con `permissions`, filtrado, item Roles |
| `frontend/src/app/usuarios/usuario-form/usuario-form.component.{ts,html}` | Dropdown roles desde API, matriz de overrides, payload `rolId` + `overrides` |
| `frontend/src/app/usuarios/usuario.service.ts` | Payload alineado al contrato corregido |
| `frontend/src/app/usuarios/usuario-list/usuario-list.component.ts` | Badges genéricos (sin CAJERO/SUPERVISOR) |
| `frontend/src/app/{productos,usuarios,...}/*-list.component.html` | `*appHasPermission` en botones de acción (módulos principales) |

### Tests — nuevos

| Archivo | Descripción |
|---------|-------------|
| `backend/src/test/java/com/ferreplus/auth/PermisoResolverTest.java` | Unitario (Mockito) — resolución de autoridades |
| `backend/src/test/java/com/ferreplus/security/SecurityEnforcementIntegrationTest.java` | 403/200 con tokens reales (MockMvc + H2) |
| `backend/src/test/java/com/ferreplus/config/DataSeederIntegrationTest.java` | Idempotencia del seed |
| `backend/src/test/java/com/ferreplus/security/PreAuthorizeDriftTest.java` | Consistencia catálogo ↔ anotaciones |
| `backend/src/test/java/com/ferreplus/service/UsuarioServiceIntegrationTest.java` | Contrato de usuarios + overrides |
| `backend/src/test/java/com/ferreplus/service/AuditoriaIntegrationTest.java` | Registro atómico + operaciones rechazadas |

## Testing Strategy

Patrones existentes: unitario con Mockito (`PrecioServiceTest`, `@ExtendWith(MockitoExtension.class)`), integración con H2 (`CompraServiceIntegrationTest`, `@SpringBootTest` + `@AutoConfigureTestDatabase` + `@ActiveProfiles("test")` + `application-test.properties`). `spring-security-test` ya está en el pom.

| Layer | Qué se prueba | Cómo |
|-------|---------------|------|
| Unit (PermisoResolver) | `permisos(rol) ∪ concedidos ∖ denegados` → exacto `[A,C,D]` (R9.1) | Mockito, entidades `Usuario`/`Rol`/`Permiso`/`UsuarioPermiso` armadas a mano; casos: deny gana a rol (edge 10), rol sin permisos, sin overrides, `ROLE_X` presente |
| Integration (Security) | Endpoint representativo: sin `GASTOS_VER` → 403, con → 200 (R9.2, R5) | `@SpringBootTest` + `@AutoConfigureMockMvc` + H2; el `DataSeeder` corre al arrancar; crear usuario VENDEDOR (por repo) → `authService.login` → token real → `mockMvc` con `Authorization: Bearer`; VENDEDOR `GET /api/gastos` → 403, `GET /api/productos` → 200; ADMIN → 200 en gastos |
| Integration (Seed) | Doble ejecución sin duplicados (R9.3, R6): 13 módulos, 3 roles, 69 pares rol_permisos | Autowire `DataSeeder`, invocar `run()` dos veces; assert conteos por repositorio |
| Integration (Drift) | Códigos de `@PreAuthorize` ∉ catálogo → fail (R9.4); permisos del catálogo sin anotación → allowlist | Reflexión sobre controllers (`ClassPathScanningCandidateComponentProvider` + `@RestController`), regex `hasAuthority\('([A-Z_]+)'\)` y `hasAnyAuthority`; allowlist documentada: `{VENTAS_EDITAR, ROLES_CREAR, ROLES_ELIMINAR}` |
| Integration (Contrato) | Crear usuario con `rolId` + overrides persiste; DTO con `rolId`/`rolNombre` + permisos efectivos (R9.5, R4, R8) | Servicio + repos H2; casos: add override, remove override, reemplazo completo en PUT, código inexistente → 400, conflicto true/false → 400 |
| Integration (Auditoría) | Crear usuario y editar matriz de rol → filas correctas; operación rechazada (rol en uso → 409) sin fila (R9.6, R10) | `SecurityContextHolder` con `Usuario` principal (usuario_id resuelto); assert `AuditoriaRepository`; `@AfterEach clearContext()` |

Nota de coherencia con tests existentes: `CompraServiceIntegrationTest.setUp()` borra roles/usuarios; el seeder corre una sola vez por contexto, así que no interfiere.

**Frontend**: no existe infraestructura de tests (sin karma/jest, sin spec files — `openspec/config.yaml` lo documenta). R9 cubre solo backend. Este cambio no agrega tests frontend; se entrega un checklist de verificación manual (login admin, crear rol con matriz, crear usuario con overrides, 403 visual/back), y la infraestructura de tests frontend queda anotada como mejora futura.

## Migration / Rollout

**No hay migraciones formales** (proyecto sin Flyway/Liquibase): `ddl-auto: update` crea `modulos`, `permisos`, `rol_permisos`, `usuario_permisos`, `auditoria` automáticamente.

**Orden de implementación**:
1. Backend: entidades (`Modulo`, `Permiso`, `UsuarioPermiso`, `Auditoria`) → repositorios → DTOs → `PermisoResolver` → `AuditService`/`CatalogoService` → `DataSeeder` → `SecurityConfig` (`@EnableMethodSecurity`) → modificar `CustomUserDetailsService`/`JwtAuthenticationFilter`/`AuthService`/`UsuarioService`/`RolService` → `@PreAuthorize` en controllers → `schema.sql`/`DOCUMENTACION_INTERNA.md`.
2. Tests backend (unit + integración).
3. Frontend: modelos → `CatalogoService` → `AuthService`/`AuthGuard` → `HasPermissionDirective` → sidebar → rutas → módulo `roles` → formulario de usuario → usuario-list.

**Verificación crítica previa al merge (regla de oro)**: loguear admin con la nueva matriz, crear/editar rol, crear/editar usuario con overrides, verificar 200/403 por rol. Sin esto no se mergea (elimina el escenario "sistema bloqueado").

**Rollback**: `git revert` del PR (o checkout previo); tablas nuevas se dropean manualmente (DDL a revisión del usuario); los INSERT de `schema.sql` originales se restauran para volver al seed viejo. Overrides en `usuario_permisos` solo existen si se usó la UI nueva antes del revert.

## Risks & Mitigations

| Riesgo | Probabilidad | Mitigación |
|--------|--------------|------------|
| **Migración `hasRole` → `hasAuthority` rompe accesos existentes** o el admin se auto-bloquea | Media | Matriz de seed respeta 1:1 las reglas URL actuales (productos/usuarios/reportes) y ADMIN recibe los 42 permisos; test de integración 200/403 por rol; verificación manual del login admin antes del merge (regla de oro) |
| **Contrato roto de usuarios rompe la UI de administración** | Alta (ya roto hoy) | Se arregla en el mismo cambio (`rolId` + DTO + password opcional en PUT); test de integración del contrato; validación end-to-end desde la UI como criterio de éxito |
| **Seed: `spring.sql.init.mode=never` + `ddl-auto: update` → duplicados o roles sin permisos** | Media | `CommandLineRunner` idempotente (consulta antes de insertar, semántica piso); test de doble ejecución; `schema.sql` queda solo como referencia |
| **VENDEDOR/BODEGUERO pierden módulos que hoy ven** (`authenticated()` los dejaba pasar) | Media (intencional) | Es el objetivo del cambio (enforcement real); matriz confirmada (Decisión 2) define los accesos; overrides por usuario cubren casos particulares; validar en la demo de aceptación |
| **Drift catálogo ↔ `@PreAuthorize`** (código sin respaldo o permiso sin anotación) | Media | Códigos por convención `<MODULO>_<ACCION>`; drift test por reflexión con allowlist documentada (`VENTAS_EDITAR`, `ROLES_CREAR`, `ROLES_ELIMINAR`) |
| **Staleness frontend: permisos desactualizados tras cambio de admin** | Media | `refreshPermisos()` vía `/me` en cada navegación (Decisión 6); backend aplica al siguiente request (filtro recarga de BD) |
| **Superadmin se auto-bloquea editando el rol/usuario propio** | Baja | El seeder garantiza ADMIN con todo; en la UI, warning al desmarcar permisos del rol propio en el formulario de roles (nota visual); backend no bloquea a propósito (Decisión 8) pero el riesgo queda mitigado por el warning + regla de oro |
| **Atomicidad: auditoría acoplada a la operación** | Baja | `AuditService` con `Propagation.MANDATORY` dentro del `@Transactional` del servicio; test que verifica que una operación rechazada (409) no genera fila |
| **Dashboard/Reportes comparten path `/api/reportes/**`** | Media | Mapeo por endpoint: `/dashboard` → `DASHBOARD_VER`, resto → `REPORTES_VER`; BODEGUERO ve dashboard con gráfico de periodo vacío (degradación controlada del componente); no se filtra data de reportes sin permiso |
| **`/me` pasa de ADMIN-only a cualquier autenticado** | Baja | Cambio intencional y necesario para Decisión 6; el endpoint solo expone datos del propio usuario; test del contrato lo cubre |
| **N+1 en resolución por request** | Baja | `JOIN FETCH` en una sola query (`findWithPermisosByEmail`); volumen acotado (≤42 permisos) |

## Open Questions

- [ ] **Confirmación menor (demo)**: BODEGUERO verá el dashboard con el gráfico de ventas por periodo vacío (endpoint del gráfico exige `REPORTES_VER`). Es la opción estricta de la matriz; alternativa (permitir `DASHBOARD_VER` en `/api/reportes/ventas`) filtraría data de reportes — no recomendada. Validar en la demo de aceptación.
- [ ] **Confirmación menor**: el password por defecto del admin sembrado sigue siendo `admin123` (igual al documentado hoy en `schema.sql`). ¿Se mantiene?
- [ ] La UI de roles/usuarios muestra los overrides como matriz de checkboxes de "permiso efectivo" (marcar/desmarcar relativo al rol base). Se descarta por ahora mostrar un estado visual "override activo" (p. ej. icono) — se puede agregar en una iteración futura sin cambio de contrato.

## Technical Learnings (durante implementación)

_(Sección para registrar hallazgos/errores que surjan durante la implementación, siguiendo el patrón del design de `modulo-gestion-precios-venta`.)_

- **Recordatorio**: tras generar componentes Angular, ejecutar `ng build` para detectar errores de compilación (NG8001/NG8002 por imports de Material faltantes).
- **Recordatorio**: `@IdClass` con `@Id @ManyToOne` requiere que los tipos de `UsuarioPermisoId` coincidan con los id de las entidades (`Long`); verificar `equals/hashCode` o Hibernate falla en merge/removal.
- **Recordatorio**: en tests de integración que auditan, `SecurityContextHolder` debe limpiarse en `@AfterEach` (`SecurityContextHolder.clearContext()`) para no filtrar autenticación entre tests.
