# Tasks: Módulo de Roles y Permisos Granulares

> **Change**: `modulo-roles-permisos`
> **Total tasks**: 55
> **Fases**: 8 (Backend Foundation → Backend Security → Backend Services → Seed → Frontend Roles Module → Frontend User Form & Wiring → Backend Tests → Verification)
> **Specialists**: cada tarea marca su especialista (`springboot` | `angular` | `ambos`) — el especialista indica también el stack al que pertenece. El especialista correspondiente debe cargar sus skills obligatorias (ver `especialista_springboot.md` / `especialista_angular.md`) antes de implementar.
> **TDD**: backend usa RED→GREEN para la lógica pura (PermisoResolver, T2.1→T2.2). El frontend **no tenía infraestructura de tests** (sin karma/jest/spec files — documentado en `openspec/config.yaml`); **DECISIÓN del usuario (sesión de apply F3)**: agregar infraestructura de tests frontend como parte de STACK 2 — builder `@angular/build:unit-test` (EXPERIMENTAL) con runner `vitest` + `jsdom` (`npm test` en `frontend/`). La verificación del frontend pasa a ser: `ng build` limpio + `npm test` verde + checklist manual (T8.2).

---

## ⚠️ ENTREGA POR STACKS — el usuario revisa y commitea; el agente NO ejecuta git

- La implementación avanza **por stacks**, no por PRs: primero el **backend completo**, luego el **frontend completo**.
- El agente **no ejecuta ninguna operación git** (ni commits, ni push, ni PRs). El usuario hace todos los commits/chequeos manualmente.
- **Al completar cada stack y pasar su verificación, el agente se DETIENE y notifica al usuario** para review + commit antes de continuar con el siguiente stack.
- Flujo: **STACK 1 (backend completo, tandas B1..B5) → STOP → review/commit del usuario → STACK 2 (frontend completo, tandas F1..F3) → STOP → review/commit del usuario.**
- El especialista de cada tarea (`springboot`/`angular`) es quien la implementa; `ambos` indica tareas de verificación transversal (Phase 8).

---

## STACK 1: BACKEND (tandas B1..B5) — backend completo

> **Regla del stack**: al completar **B5** (todos los tests backend en verde, incluyendo `mvn test` y `mvn package`), **STOP y notificar al usuario para revisar y commitear** antes de iniciar STACK 2.

| Tanda | Fase | Tareas | Salida verificable |
|-------|------|--------|--------------------|
| B1 | Phase 1 — Foundation | T1.1–T1.12 | Entidades/repos/DTOs/excepciones compilan y son consistentes con el design |
| B2 | Phase 2 — Security | T2.1–T2.13 | `PermisoResolverTest` verde; `@PreAuthorize` aplicado en 13 controllers |
| B3 | Phase 3 — Services | T3.1–T3.2 | Validaciones de overrides/matriz; auditoría atómica |
| B4 | Phase 4 — Seed | T4.1–T4.3 | `DataSeeder` idempotente; schema.sql y DOCUMENTACION_INTERNA actualizados |
| B5 | Phase 7 — Tests backend | T7.1–T7.5 | `mvn test` 100% verde (incluye tests preexistentes) |

### Phase 1: Backend — Foundation (entities, repositories, DTOs, exceptions)

#### T1.1: Create `Modulo` and `Permiso` catalog entities
- **Description**: Create JPA entities `com.ferreplus.entity.Modulo` (tabla `modulos`: `id`, `nombre` length 50, `codigo` unique length 30, `orden` Integer, `@OneToMany(mappedBy="modulo", LAZY) List<Permiso>`) and `com.ferreplus.entity.Permiso` (tabla `permisos`: `id`, `codigo` unique global length 50, `nombre` length 100, `accion` length 20, `@ManyToOne(LAZY, optional=false) Modulo modulo` with `@JoinColumn(name="modulo_id")`). Lombok: `@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder`.
- **Dependencies**: None
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/entity/Modulo.java` (create)
  - `backend/src/main/java/com/ferreplus/entity/Permiso.java` (create)
- **Acceptance criteria**:
  - `permisos.codigo` tiene constraint de unicidad global (R1: escenario "código único").
  - FK `permisos.modulo_id` NOT NULL hacia `modulos`.
  - Colecciones LAZY (nunca EAGER) — regla del especialista Spring Boot.

#### T1.2: Create `UsuarioPermiso` + `UsuarioPermisoId` entities (composite PK)
- **Description**: Create `com.ferreplus.entity.UsuarioPermiso` (tabla `usuario_permisos`, `@IdClass(UsuarioPermisoId.class)`: `@Id @ManyToOne Usuario usuario` (`usuario_id`), `@Id @ManyToOne Permiso permiso` (`permiso_id`), `@Column(nullable=false) boolean concedido`) and `com.ferreplus.entity.UsuarioPermisoId` (Serializable, campos `Long usuario` y `Long permiso`, equals/hashCode sobre ambos).
- **Dependencies**: T1.1
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/entity/UsuarioPermiso.java` (create)
  - `backend/src/main/java/com/ferreplus/entity/UsuarioPermisoId.java` (create)
- **Acceptance criteria**:
  - PK compuesta `(usuario_id, permiso_id)` impide overrides duplicados (R4: "no puede existir más de un override por (usuario, permiso)").
  - `concedido` NOT NULL (R4: flag obligatorio).
  - Recordatorio design.md: tipos de `UsuarioPermisoId` (`Long`) deben coincidir con los ids; equals/hashCode correctos o Hibernate falla en merge/removal.

#### T1.3: Create `Auditoria` entity
- **Description**: Create `com.ferreplus.entity.Auditoria` (tabla `auditoria`: `id`, `entidad` length 50, `entidad_id` Long, `accion` length 20, `@ManyToOne(LAZY) Usuario usuario` nullable, `fecha` LocalDateTime con `@PrePersist` y `updatable=false`, `detalle` `@Column(columnDefinition="TEXT")`).
- **Dependencies**: None (referencia a `Usuario` existente)
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/entity/Auditoria.java` (create)
- **Acceptance criteria**:
  - Tabla genérica `entidad`/`entidad_id` (R10: extensible a VENTA, COMPRA, etc. sin migración).
  - `usuario_id` nullable (eventos de sistema/seed, R10).

#### T1.4: Modify `Rol` — add permission matrix
- **Description**: Add to `com.ferreplus.entity.Rol`: `@ManyToMany(fetch = FetchType.LAZY) @JoinTable(name = "rol_permisos", joinColumns = @JoinColumn(name = "rol_id"), inverseJoinColumns = @JoinColumn(name = "permiso_id")) private Set<Permiso> permisos = new HashSet<>();`. Conservar `nombre` unique y `descripcion` existentes.
- **Dependencies**: T1.1
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/entity/Rol.java` (modify)
- **Acceptance criteria**:
  - `rol_permisos` creada por Hibernate (`ddl-auto: update`); matriz LAZY.
  - Sin cambios de comportamiento en código que usa `Rol` hoy (compila).

#### T1.5: Modify `Usuario` — add overrides
- **Description**: Add to `com.ferreplus.entity.Usuario`: `@OneToMany(mappedBy = "usuario", fetch = FetchType.LAZY, cascade = CascadeType.ALL, orphanRemoval = true) private Set<UsuarioPermiso> overrides = new HashSet<>();`. Conservar `@ManyToOne(EAGER) Rol rol` existente.
- **Dependencies**: T1.2
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/entity/Usuario.java` (modify)
- **Acceptance criteria**:
  - `orphanRemoval` permite el reemplazo completo de overrides en PUT (R4: "la lista de overrides DEBE reemplazar la anterior completa").
  - NO se agrega ninguna columna JSON/texto a `usuarios` (R1: escenario "Los overrides NO se guardan como JSON blob").

#### T1.6: Create catalog/audit repositories
- **Description**: Create interfaces Spring Data JPA:
  - `com.ferreplus.repository.ModuloRepository` extends `JpaRepository<Modulo, Long>` con `Optional<Modulo> findByCodigo(String codigo)` y `List<Modulo> findAllByOrderByOrdenAsc()`.
  - `com.ferreplus.repository.PermisoRepository` con `Optional<Permiso> findByCodigo(String codigo)` y `List<Permiso> findByCodigoIn(Collection<String> codigos)`.
  - `com.ferreplus.repository.UsuarioPermisoRepository` extends `JpaRepository<UsuarioPermiso, UsuarioPermisoId>`.
  - `com.ferreplus.repository.AuditoriaRepository` extends `JpaRepository<Auditoria, Long>`.
- **Dependencies**: T1.1, T1.2, T1.3
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/repository/ModuloRepository.java` (create)
  - `backend/src/main/java/com/ferreplus/repository/PermisoRepository.java` (create)
  - `backend/src/main/java/com/ferreplus/repository/UsuarioPermisoRepository.java` (create)
  - `backend/src/main/java/com/ferreplus/repository/AuditoriaRepository.java` (create)
- **Acceptance criteria**:
  - Todos los métodos de consulta del catálogo disponibles (necesarios para DataSeeder, CatalogoService, RolService, UsuarioService y tests de auditoría).

#### T1.7: Modify `UsuarioRepository` — JOIN FETCH queries (anti N+1) + count for rol usage
- **Description**: Add to `com.ferreplus.repository.UsuarioRepository`:
  - `@Query("SELECT DISTINCT u FROM Usuario u JOIN FETCH u.rol r LEFT JOIN FETCH r.permisos LEFT JOIN FETCH u.overrides up LEFT JOIN FETCH up.permiso WHERE u.email = :email") Optional<Usuario> findWithPermisosByEmail(@Param("email") String email);`
  - `@Query("SELECT DISTINCT u FROM Usuario u JOIN FETCH u.rol r LEFT JOIN FETCH r.permisos LEFT JOIN FETCH u.overrides up LEFT JOIN FETCH up.permiso") List<Usuario> findAllWithPermisos();`
  - `long countByRolIdAndActivoTrue(Long rolId);`
- **Dependencies**: T1.4, T1.5
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/repository/UsuarioRepository.java` (modify)
- **Acceptance criteria**:
  - Una sola query resuelve usuario + rol + matriz + overrides (anti N+1, decisión del design; `LEFT JOIN` para no excluir usuarios sin permisos/overrides).
  - `countByRolIdAndActivoTrue` alimenta el 409 de `DELETE /api/roles/{id}` (R3).

#### T1.8: Create `ModuloDTO` + `PermisoDTO`
- **Description**: Create DTOs (sin Lombok, getters/setters manuales — consistente con DTOs existentes):
  - `com.ferreplus.dto.ModuloDTO`: `id`, `nombre`, `codigo`, `orden`, `List<PermisoDTO> permisos`.
  - `com.ferreplus.dto.PermisoDTO`: `id`, `codigo`, `nombre`, `accion`, `moduloId`, `moduloCodigo`, `moduloNombre`.
- **Dependencies**: T1.1
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/dto/ModuloDTO.java` (create)
  - `backend/src/main/java/com/ferreplus/dto/PermisoDTO.java` (create)
- **Acceptance criteria**:
  - Contrato JSON de `GET /api/modulos` y `GET /api/permisos` coincide con el diseño API (R2).

#### T1.9: Create `RolDTO` + `RolRequestDTO`
- **Description**: Create DTOs:
  - `com.ferreplus.dto.RolDTO`: `id`, `nombre`, `descripcion`, `List<String> permisos` (códigos).
  - `com.ferreplus.dto.RolRequestDTO`: `@NotBlank nombre`, `descripcion`, `List<String> permisos`.
- **Dependencies**: None
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/dto/RolDTO.java` (create)
  - `backend/src/main/java/com/ferreplus/dto/RolRequestDTO.java` (create)
- **Acceptance criteria**:
  - `RolDTO` expone matriz como array de códigos; `RolRequestDTO` la acepta igual (R3).

#### T1.10: Create `UsuarioPermisoRequestDTO` + `UsuarioPermisoDTO`
- **Description**: Create DTOs:
  - `com.ferreplus.dto.UsuarioPermisoRequestDTO`: `permisoCodigo` (String), `concedido` (boolean).
  - `com.ferreplus.dto.UsuarioPermisoDTO`: `permisoCodigo`, `concedido` (respuesta).
- **Dependencies**: None
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/dto/UsuarioPermisoRequestDTO.java` (create)
  - `backend/src/main/java/com/ferreplus/dto/UsuarioPermisoDTO.java` (create)
- **Acceptance criteria**:
  - Override con `permisoCodigo` + `concedido` obligatorio (R4).

#### T1.11: Modify `UsuarioDTO`, `UsuarioRequestDTO`, `AuthResponseDTO` — contract fix
- **Description**: Modify:
  - `com.ferreplus.dto.UsuarioDTO`: add `List<String> permisos` (efectivos) y `List<UsuarioPermisoDTO> overrides`. Mantener `rolId`/`rolNombre` a nivel raíz (ya existen, R8).
  - `com.ferreplus.dto.UsuarioRequestDTO`: add `List<UsuarioPermisoRequestDTO> overrides`; **quitar `@NotBlank` de `password`** (dejar solo `@Size(min = 6)` — en PUT se omite; validación de creación en servicio). Mantener `rolId @NotNull`.
  - `com.ferreplus.dto.AuthResponseDTO`: add `List<String> permisos`.
- **Dependencies**: T1.10
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/dto/UsuarioDTO.java` (modify)
  - `backend/src/main/java/com/ferreplus/dto/UsuarioRequestDTO.java` (modify)
  - `backend/src/main/java/com/ferreplus/dto/AuthResponseDTO.java` (modify)
- **Acceptance criteria**:
  - Editar usuario sin `password` ya NO devuelve 400 (R8: password opcional en PUT).
  - `UsuarioDTO` con `rolId`/`rolNombre` raíz + `permisos` + `overrides`; `AuthResponseDTO` con `permisos` (R8 login).

#### T1.12: Create `ConflictException` + 409 handler
- **Description**: Create `com.ferreplus.exception.ConflictException` (extends RuntimeException, message constructor) y registrar handler en `com.ferreplus.exception.GlobalExceptionHandler` devolviendo `ProblemDetail` 409.
- **Dependencies**: None
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/exception/ConflictException.java` (create)
  - `backend/src/main/java/com/ferreplus/exception/GlobalExceptionHandler.java` (modify)
- **Acceptance criteria**:
  - `DELETE /api/roles/{id}` con rol en uso devuelve 409 semántico (R3, NFR 4).

---

### Phase 2: Backend — Security (resolución de autoridades + enforcement)

#### T2.1: Write `PermisoResolverTest` (RED — unit, Mockito)
- **Description**: Create `com.ferreplus.auth.PermisoResolverTest` con `@ExtendWith(MockitoExtension.class)` (patrón `PrecioServiceTest`). Entidades `Usuario`/`Rol`/`Permiso`/`UsuarioPermiso` armadas a mano (sin Spring). Casos mínimos:
  1. Rol `[A,B,C]` + overrides `concedido=true: [D]` + `concedido=false: [B]` → exactamente `[A,C,D]` (R9.1).
  2. Edge case 10: rol concede `X` y override `concedido=false` lo quita → `X` NO está (∖ después de ∪).
  3. Rol sin permisos → solo `ROLE_X` (edge case 12).
  4. Sin overrides → exactamente los del rol.
  5. Authorities incluyen `ROLE_<nombre>` transitorio (R5, escenario "Autoridad ROLE_<NOMBRE>").
- **Dependencies**: T1.4, T1.5
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/test/java/com/ferreplus/auth/PermisoResolverTest.java` (create)
- **Acceptance criteria**:
  - Test compila y FALLA (RED) porque `PermisoResolver` no existe — define el contrato del componente.

#### T2.2: Create `PermisoResolver` (GREEN)
- **Description**: Create `com.ferreplus.auth.PermisoResolver` (componente compartido, sin dependencias Spring): `Set<String> codigosEfectivos(Usuario)` y `List<GrantedAuthority> resolverAutoridades(Usuario)` implementando `permisos(rol) ∪ {concedido=true} ∖ {concedido=false}` (∖ aplica DESPUÉS de ∪) y agregando `ROLE_<rol.nombre>`.
- **Dependencies**: T2.1
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/auth/PermisoResolver.java` (create)
- **Acceptance criteria**:
  - `PermisoResolverTest` pasa (GREEN) — escenarios R9.1 y edge cases 10/12.

#### T2.3: Create `AuditService` (Propagation.MANDATORY)
- **Description**: Create `com.ferreplus.service.AuditService` (`@Service`, `@RequiredArgsConstructor`, inyecta `AuditoriaRepository`). Método `@Transactional(propagation = Propagation.MANDATORY) void registrarEvento(String entidad, Long entidadId, String accion, String detalle)` que resuelve el usuario desde `SecurityContextHolder` (null si no hay contexto autenticado) y persiste la entidad.
- **Dependencies**: T1.3, T1.6
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/service/AuditService.java` (create)
- **Acceptance criteria**:
  - `Propagation.MANDATORY` exige transacción del llamador → atomicidad con la operación (R10, escenario "Registro atómico").
  - `usuario_id` queda null para eventos de sistema (seed no audita).

#### T2.4: Create `CatalogoService`
- **Description**: Create `com.ferreplus.service.CatalogoService` (`@Service`, `@Transactional(readOnly = true)`): `List<ModuloDTO> getModulosConPermisos()` (vía `findAllByOrderByOrdenAsc`, mapeando permisos) y `List<PermisoDTO> getPermisos()` (plano con `moduloId`/`moduloCodigo`/`moduloNombre`).
- **Dependencies**: T1.6, T1.8
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/service/CatalogoService.java` (create)
- **Acceptance criteria**:
  - `getModulosConPermisos()` retorna módulos ordenados por `orden` con sus permisos agrupados (R2).

#### T2.5: Modify `SecurityConfig` + create `JsonAccessDeniedHandler`
- **Description**: Modify `com.ferreplus.config.SecurityConfig`:
  - Agregar `@EnableMethodSecurity`.
  - Eliminar las reglas URL hardcodeadas (`requestMatchers` de productos/usuarios/reportes con `hasRole`).
  - Dejar `permitAll` solo para `/api/auth/**` y swagger/scalar; `anyRequest().authenticated()` como fallback.
  - En `exceptionHandling`: mantener `authenticationEntryPoint` y agregar `accessDeniedHandler(new JsonAccessDeniedHandler())`.
  - Create `com.ferreplus.auth.JsonAccessDeniedHandler` (implementa `AccessDeniedHandler`) escribiendo JSON `{"error": "Acceso denegado", "timestamp": ...}` con 403, consistente con `GlobalExceptionHandler` (NFR 1).
- **Dependencies**: None
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/config/SecurityConfig.java` (modify)
  - `backend/src/main/java/com/ferreplus/auth/JsonAccessDeniedHandler.java` (create)
- **Acceptance criteria**:
  - `@PreAuthorize` queda habilitado (R5).
  - 403 en formato JSON consistente; sin reglas URL por módulo duplicadas (decisión del design).

#### T2.6: Modify `CustomUserDetailsService` + `JwtAuthenticationFilter` — resolver autoridades
- **Description**: Modify ambos para usar `UsuarioRepository.findWithPermisosByEmail(email)` + `PermisoResolver.resolverAutoridades(usuario)` (el filtro ya recarga el usuario de BD por request → los cambios de rol/overrides aplican al siguiente request sin re-login, R5).
- **Dependencies**: T2.2, T1.7
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/auth/CustomUserDetailsService.java` (modify)
  - `backend/src/main/java/com/ferreplus/auth/JwtAuthenticationFilter.java` (modify)
- **Acceptance criteria**:
  - Login y cada request producen authorities = códigos efectivos + `ROLE_<nombre>` (R5, escenario "Cambio de permisos aplica sin re-login").

#### T2.7: Modify `AuthService.login` — permisos en `AuthResponseDTO`
- **Description**: Modify `com.ferreplus.service.AuthService` para poblar `AuthResponseDTO.permisos` con `PermisoResolver.codigosEfectivos(usuario)`.
- **Dependencies**: T2.2, T1.11
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/service/AuthService.java` (modify)
- **Acceptance criteria**:
  - Login devuelve permisos efectivos (R8, escenario "Login inicializa permisos del frontend").

#### T2.8: Create `CatalogoController`
- **Description**: Create `com.ferreplus.controller.CatalogoController` (`@RestController`, `@RequestMapping("/api")`): `GET /api/modulos` → `List<ModuloDTO>` y `GET /api/permisos` → `List<PermisoDTO>`, ambos con `@PreAuthorize("hasAnyAuthority('ROLES_VER', 'USUARIOS_VER')")`.
- **Dependencies**: T2.4, T2.5
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/controller/CatalogoController.java` (create)
- **Acceptance criteria**:
  - Usuario con `ROLES_VER` o `USUARIOS_VER` → 200; otro autenticado → 403 (R2, escenario "Usuario sin permiso de catálogo recibe 403").

#### T2.9: Modify `UsuarioController` — DTOs, `/me` → `isAuthenticated()`, `@PreAuthorize`
- **Description**: Modify `com.ferreplus.controller.UsuarioController`:
  - Respuestas con `UsuarioDTO` (no entidad anidada) — armar permisos/overrides vía `UsuarioService`.
  - `GET /api/usuarios/me` → `@PreAuthorize("isAuthenticated()")` (excepción documentada: refresh `/me` para todo autenticado, Decisión 6).
  - `GET` listado/`{id}` → `USUARIOS_VER`; `POST` → `USUARIOS_CREAR`; `PUT` (`{id}`, `{id}/password`) → `USUARIOS_EDITAR`; `DELETE` → `USUARIOS_ELIMINAR`.
- **Dependencies**: T2.5, T1.11, T3.1
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/controller/UsuarioController.java` (modify)
- **Acceptance criteria**:
  - `/me` accesible para cualquier autenticado (R5, decisión "protección `/me`"); contrato `UsuarioDTO` a nivel raíz (R8).
  - Enforcement por método según mapeo (R5).

#### T2.10: Modify `RolController` — DTOs + `@PreAuthorize`
- **Description**: Modify `com.ferreplus.controller.RolController`:
  - `GET /api/roles` y `GET /api/roles/{id}` → `@PreAuthorize("hasAuthority('ROLES_VER')")`, devolviendo `RolDTO` (con códigos).
  - `POST /api/roles`, `PUT /api/roles/{id}`, `DELETE /api/roles/{id}` → `@PreAuthorize("hasAuthority('ROLES_EDITAR')")` (R3: todas las escrituras con `ROLES_EDITAR`; `ROLES_CREAR`/`ROLES_ELIMINAR` NO se usan en anotaciones → allowlist del drift test).
- **Dependencies**: T2.5, T1.9, T3.2
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/controller/RolController.java` (modify)
- **Acceptance criteria**:
  - Usuario con `ROLES_VER` sin `ROLES_EDITAR` lista roles pero recibe 403 al crear/editar/eliminar (R3, escenario "Protección de escritura de roles").

#### T2.11: Add `@PreAuthorize` to Producto/Categoria/Proveedor/Cliente controllers
- **Description**: Add `@PreAuthorize("hasAuthority('X_VER')" | 'X_CREAR' | 'X_EDITAR' | 'X_ELIMINAR')` por método en `ProductoController`, `CategoriaController`, `ProveedorController`, `ClienteController` (GET→VER, POST→CREAR, PUT→EDITAR, DELETE→ELIMINAR, incluyendo `GET /api/productos/stock-bajo`→`PRODUCTOS_VER`).
- **Dependencies**: T2.5
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/controller/ProductoController.java` (modify)
  - `backend/src/main/java/com/ferreplus/controller/CategoriaController.java` (modify)
  - `backend/src/main/java/com/ferreplus/controller/ProveedorController.java` (modify)
  - `backend/src/main/java/com/ferreplus/controller/ClienteController.java` (modify)
- **Acceptance criteria**:
  - Cada endpoint protegido según la tabla de mapeo (R5); módulos hoy abiertos pasan a requerir permiso (enforcement real, R5 escenario 403 real).

#### T2.12: Add `@PreAuthorize` to Venta/Compra/Precio controllers (anulación → ELIMINAR)
- **Description**: `VentaController` (GET→`VENTAS_VER`, POST→`VENTAS_CREAR`, `PUT /{id}/anular`→`VENTAS_ELIMINAR` — semántica anular, no borrado físico), `CompraController` (GET→`COMPRAS_VER`, POST→`COMPRAS_CREAR`, `PUT /{id}`→`COMPRAS_EDITAR`, `PUT /{id}/anular`→`COMPRAS_ELIMINAR`), `PrecioController` (GET→`PRECIOS_VER`, `PUT /{id}/venta`→`PRECIOS_EDITAR`).
- **Dependencies**: T2.5
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/controller/VentaController.java` (modify)
  - `backend/src/main/java/com/ferreplus/controller/CompraController.java` (modify)
  - `backend/src/main/java/com/ferreplus/controller/PrecioController.java` (modify)
- **Acceptance criteria**:
  - `VENTAS_ELIMINAR`/`COMPRAS_ELIMINAR` enforced sobre los endpoints de anulación existentes (decisión "semántica de ELIMINAR").
  - `VENTAS_EDITAR` declarado en catálogo pero sin endpoint → permitido por allowlist del drift test (T7.3).

#### T2.13: Add `@PreAuthorize` to MovimientoStock/Gasto/Reporte controllers
- **Description**: `MovimientoStockController` (GET→`MOVIMIENTOS_VER`, POST→`MOVIMIENTOS_CREAR`), `GastoController` (GET→`GASTOS_VER`, POST→`GASTOS_CREAR`, PUT→`GASTOS_EDITAR`, DELETE→`GASTOS_ELIMINAR`), `ReporteController` (`GET /api/reportes/dashboard`→`DASHBOARD_VER`; `/ventas`, `/inventario`, `/movimientos`→`REPORTES_VER`).
- **Dependencies**: T2.5
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/controller/MovimientoStockController.java` (modify)
  - `backend/src/main/java/com/ferreplus/controller/GastoController.java` (modify)
  - `backend/src/main/java/com/ferreplus/controller/ReporteController.java` (modify)
- **Acceptance criteria**:
  - Dashboard (`DASHBOARD_VER`) y Reportes (`REPORTES_VER`) separados por endpoint pese a compartir path `/api/reportes/**` (decisión documentada; BODEGUERO ve dashboard con gráfico de periodo vacío).

---

### Phase 3: Backend — Services (usuarios + roles)

#### T3.1: Modify `UsuarioService` — overrides, DTO con permisos, auditoría
- **Description**: Modify `com.ferreplus.service.UsuarioService`:
  - `create`: validar password en servicio (ya existe), email único, validar overrides (códigos existen → 400; mismo permiso con `concedido=true` y `false` → 400; duplicados → 400), persistir `rolId` + `Set<UsuarioPermiso>`, mapear `UsuarioDTO` con permisos efectivos (`PermisoResolver.codigosEfectivos`) y overrides, y `auditService.registrarEvento("USUARIO", id, "CREAR", jsonDetalle)` como última línea.
  - `update`: reemplazo completo de overrides (orphanRemoval), password opcional (si viene, re-encode; si no, no cambia), auditoría `"ACTUALIZAR"` con diff de overrides.
  - `delete` (soft): auditoría `"ELIMINAR"`.
  - `cambiarPassword`: auditoría `"ACTUALIZAR"` con `{"cambioPassword":true}`.
  - `toDTO`: expone `rolId`/`rolNombre` raíz + `permisos` + `overrides`.
  - Detalle JSON serializado con Jackson `ObjectMapper`; fallback a texto plano.
- **Dependencies**: T2.2, T2.3, T1.10, T1.11, T1.7
- **Status**: pending
- **Effort**: L
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/service/UsuarioService.java` (modify)
- **Acceptance criteria**:
  - Escenarios R4 (add/remove override, reemplazo en PUT, permiso inexistente → 400, conflicto true/false → 400) y R8 (contrato DTO).
  - Auditoría atómica en CREAR/ACTUALIZAR/soft-DELETE/password (R10); operación rechazada → sin fila.
  - `/me` y listado devuelven permisos efectivos (R4).

#### T3.2: Modify `RolService` — matriz, validaciones, 409, auditoría
- **Description**: Modify `com.ferreplus.service.RolService`:
  - `create`: nombre único → `BadRequestException` 400 si existe; códigos de matriz contra `PermisoRepository.findByCodigoIn` → 400 si alguno no existe; guardar; auditoría `("ROL", id, "CREAR", jsonConMatriz)`.
  - `update`: mismo `id`; nombre único si cambió; reemplazo completo de matriz (`permisos.clear(); addAll(nuevos)`); auditoría `"ACTUALIZAR"` con `permisosAgregados`/`permisosQuitados`.
  - `delete`: si `usuarioRepository.countByRolIdAndActivoTrue(id) > 0` → `ConflictException` 409 (sin fila de auditoría); si no, eliminar y auditar `"ELIMINAR"`.
  - Respuestas `RolDTO` (códigos), request `RolRequestDTO`.
  - Rol con matriz vacía es válido (edge case 12).
- **Dependencies**: T2.3, T1.9, T1.6, T1.7, T1.12
- **Status**: pending
- **Effort**: L
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/service/RolService.java` (modify)
- **Acceptance criteria**:
  - Escenarios R3: rol con matriz, nombre duplicado → 400/409, código inexistente → 400, edición reemplaza matriz completa, rol en uso → 409 y sigue existiendo.
  - Auditoría atómica (R10) en CREAR/ACTUALIZAR/ELIMINAR exitosos.

---

### Phase 4: Backend — Seed

#### T4.1: Create `DataSeeder` (CommandLineRunner idempotente)
- **Description**: Create `com.ferreplus.config.DataSeeder` implementando `CommandLineRunner` con `@Component` y `@Order`. Inserta consultando antes (fuente única de verdad):
  1. **Catálogo**: 13 módulos (orden 1-13: Dashboard, Productos, Categorías, Proveedores, Clientes, Ventas, Compras, Precios, Movimientos, Gastos, Usuarios, Roles, Reportes) y 42 permisos por `codigo` (acciones por módulo según seed matrix: Dashboard/Reportes solo VER; Precios VER+EDITAR; Movimientos VER+CREAR; resto 4 acciones).
  2. **Roles**: ADMIN (42 permisos), VENDEDOR (9: `DASHBOARD_VER, PRODUCTOS_VER, CLIENTES_VER, CLIENTES_CREAR, CLIENTES_EDITAR, VENTAS_VER, VENTAS_CREAR, PRECIOS_VER, REPORTES_VER`), BODEGUERO (18: matriz exacta de seed matrix) → 69 pares `rol_permisos`.
  3. **Usuario admin**: `admin@ferreplus.com` con password por defecto `admin123` BCrypt y rol ADMIN, solo si no existe (no sobreescribe password/rol).
  - Semántica **piso** en `rol_permisos`: inserta faltantes, nunca remueve (preserva ajustes posteriores de la UI).
  - NO crea CAJERO ni SUPERVISOR; NO escribe filas de auditoría (bootstrap).
- **Dependencies**: T1.1-T1.7
- **Status**: pending
- **Effort**: L
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/java/com/ferreplus/config/DataSeeder.java` (create)
- **Acceptance criteria**:
  - Segunda ejecución = cero cambios (R6, escenario "Seed idempotente — doble ejecución sin duplicados": 13 módulos, 3 roles, 69 pares).
  - Matriz confirmada restringe de verdad: VENDEDOR sin `GASTOS_VER`; BODEGUERO sin `REPORTES_VER`/`GASTOS_VER`/USUARIOS/ROLES (R6 escenarios).

#### T4.2: Adjust `schema.sql` as reference (seed = source of truth)
- **Description**: Modify `backend/src/main/resources/schema.sql`: mantener los INSERT de roles/admin como referencia ajustada, agregando comentario claro de que `DataSeeder` (CommandLineRunner) es la fuente única de verdad y que estos INSERT no deben ejecutarse en runtime (`spring.sql.init.mode=never`).
- **Dependencies**: T4.1
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/main/resources/schema.sql` (modify)
- **Acceptance criteria**:
  - No hay duplicación de fuentes de verdad; el archivo documenta el nuevo modelo (R6).

#### T4.3: Update `DOCUMENTACION_INTERNA.md` — sección 4 (matriz confirmada)
- **Description**: Modify `DOCUMENTACION_INTERNA.md` sección 4 para reflejar la matriz confirmada (ADMIN/VENDEDOR/BODEGUERO), el nuevo modelo de permisos (catálogo, overrides, enforcement) y la eliminación de CAJERO/SUPERVISOR.
- **Dependencies**: T4.1
- **Status**: pending
- **Effort**: S
- **Specialist**: springboot
- **Files affected**:
  - `DOCUMENTACION_INTERNA.md` (modify)
- **Acceptance criteria**:
  - No queda una matriz obsoleta como referencia (R6).

---

### Phase 7: Tests — Backend (integración H2 + drift)

> Patrones existentes: `@SpringBootTest` + `@AutoConfigureTestDatabase(replace = Replace.ANY)` + `@ActiveProfiles("test")` + `application-test.properties` (H2). El `DataSeeder` corre al arrancar cada contexto. `spring-security-test` ya está en el pom.

#### T7.1: Create `SecurityEnforcementIntegrationTest` (403/200 con tokens reales)
- **Description**: Create `com.ferreplus.security.SecurityEnforcementIntegrationTest` (`@SpringBootTest` + `@AutoConfigureMockMvc` + H2):
  - Usuario VENDEDOR creado por repo → `authService.login` → token real → `mockMvc` con `Authorization: Bearer`.
  - Assert: VENDEDOR `GET /api/gastos` → **403**; VENDEDOR `GET /api/productos` → **200**; ADMIN `GET /api/gastos` → **200**; VENDEDOR `POST /api/roles` → **403**.
- **Dependencies**: T2.5-T2.13, T4.1
- **Status**: pending
- **Effort**: L
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/test/java/com/ferreplus/security/SecurityEnforcementIntegrationTest.java` (create)
- **Acceptance criteria**:
  - Escenarios R9.2 y R5 ("Usuario sin permiso recibe 403 real", "Admin accede a todo") y R2 (403 catálogo).

#### T7.2: Create `DataSeederIntegrationTest` (idempotencia)
- **Description**: Create `com.ferreplus.config.DataSeederIntegrationTest`: autowire `DataSeeder`, invocar `run()` dos veces; assert `ModuloRepository` 13 filas, `RolRepository` 3 filas (ADMIN/VENDEDOR/BODEGUERO), 69 pares `rol_permisos`, sin duplicados.
- **Dependencies**: T4.1
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/test/java/com/ferreplus/config/DataSeederIntegrationTest.java` (create)
- **Acceptance criteria**:
  - Escenario R9.3/R6 "Seed ejecutado dos veces no duplica"; verifica que CAJERO/SUPERVISOR no existen.

#### T7.3: Create `PreAuthorizeDriftTest` (catálogo ↔ anotaciones)
- **Description**: Create `com.ferreplus.security.PreAuthorizeDriftTest` (`@SpringBootTest`): reflexión sobre controllers (`ClassPathScanningCandidateComponentProvider` filtrando `@RestController`), regex `hasAuthority\('([A-Z_]+)'\)` y `hasAnyAuthority(...)`; assert todo código de anotación existe en el catálogo sembrado; assert todo permiso del catálogo está referenciado por al menos una anotación salvo **allowlist documentada**: `{VENTAS_EDITAR, ROLES_CREAR, ROLES_ELIMINAR}`.
- **Dependencies**: T2.8-T2.13, T4.1
- **Status**: pending
- **Effort**: M
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/test/java/com/ferreplus/security/PreAuthorizeDriftTest.java` (create)
- **Acceptance criteria**:
  - Escenario R9.4 ("Drift test — código en @PreAuthorize sin respaldo en catálogo"): falla si alguien introduce `hasAuthority('INVENTADO_VER')`; allowlist exacta de 3 códigos documentada.

#### T7.4: Create `UsuarioServiceIntegrationTest` (contrato + overrides)
- **Description**: Create `com.ferreplus.service.UsuarioServiceIntegrationTest` (H2, servicio + repos; `SecurityContextHolder` con `Usuario` principal en tests de auditoría y `@AfterEach clearContext()`):
  1. Create con `rolId` + override add → permisos efectivos = rol ∪ agregado (R9.5, R4).
  2. Create con override remove → rol ∖ quitado.
  3. PUT con lista de overrides vacía → reemplazo completo (vuelve al rol base).
  4. Override con código inexistente → 400 (`BadRequestException`).
  5. Conflicto `concedido=true` y `false` mismo permiso en la misma petición → 400.
  6. `UsuarioDTO` expone `rolId`/`rolNombre` raíz + `permisos` efectivos + `overrides`.
- **Dependencies**: T3.1, T4.1
- **Status**: pending
- **Effort**: L
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/test/java/com/ferreplus/service/UsuarioServiceIntegrationTest.java` (create)
- **Acceptance criteria**:
  - Escenarios R4 y R9.5 completos (contrato de usuarios).

#### T7.5: Create `AuditoriaIntegrationTest` (registro atómico + rechazos)
- **Description**: Create `com.ferreplus.service.AuditoriaIntegrationTest` (H2; `SecurityContextHolder` con `Usuario` admin autenticado, `@AfterEach clearContext()`):
  1. Crear usuario → 1 fila `USUARIO`/`CREAR` con `usuario_id` correcto.
  2. `PUT /api/roles/{id}` (editar matriz) → 1 fila `ROL`/`ACTUALIZAR` con `detalle` JSON de agregados/quitados.
  3. `DELETE` rol en uso → 409 **sin** fila `ROL`/`ELIMINAR`.
  4. Verificar atomicidad: auditoría dentro de la misma transacción (si la operación falla, la fila revierte).
- **Dependencies**: T3.1, T3.2, T4.1
- **Status**: pending
- **Effort**: L
- **Specialist**: springboot
- **Files affected**:
  - `backend/src/test/java/com/ferreplus/service/AuditoriaIntegrationTest.java` (create)
- **Acceptance criteria**:
  - Escenarios R9.6 y R10 (crear usuario audita, editar matriz audita, operación bloqueada no audita, registro atómico).

---

## STACK 2: FRONTEND (tandas F1..F3) — frontend completo

> **Regla del stack**: al completar **F3** (`ng build` limpio + checklist manual T8.2 aprobado), **STOP y notificar al usuario para revisar y commitear**.
> ⚠️ **Requisito**: el STACK 1 debe estar completado y commiteado por el usuario (el backend y el contrato de la API deben estar disponibles). La parte de `mvn test` de T8.1 ya quedó validada en el exit de B5.

| Tanda | Fase | Tareas | Salida verificable |
|-------|------|--------|--------------------|
| F1 | Phase 5 — Roles Module | T5.1–T5.8 | Módulo `roles` lazy + matriz de checkboxes funcional (list + form) |
| F2 | Phase 6 — User Form & Wiring | T6.1–T6.10 | Guard/sidebar/permisos; formulario de usuario con rol base + overrides |
| F3 | Phase 8 — Verification | T8.1–T8.2 | `ng build` limpio + checklist manual end-to-end aprobado |

### Phase 5: Frontend — Roles Module

#### T5.1: Update `core/models.ts` — nuevos tipos y contrato de usuario
- **Description**: Modify `frontend/src/app/core/models.ts` agregando: `Modulo`, `Permiso`, `Rol`, `RolRequest`, `UsuarioPermisoOverride`; `Usuario` + `permisos: string[]` + `overrides: UsuarioPermisoOverride[]`; `AuthResponse` + `permisos: string[]`.
- **Dependencies**: None
- **Status**: done
- **Effort**: S
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/core/models.ts` (modify)
- **Acceptance criteria**:
  - Tipos reflejan el contrato de la API (R7 modelos, R8).

#### T5.2: Create `CatalogoService`
- **Description**: Create `frontend/src/app/core/catalogo.service.ts` (`@Injectable({providedIn:'root'})`): `getModulos(): Observable<Modulo[]>` (`GET ${apiUrl}/modulos`) y `getPermisos(): Observable<Permiso[]>` (`GET ${apiUrl}/permisos`).
- **Dependencies**: T5.1
- **Status**: done
- **Effort**: S
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/core/catalogo.service.ts` (create)
- **Acceptance criteria**:
  - Servicio consume el endpoint protegido por `ROLES_VER`/`USUARIOS_VER` (R2).

#### T5.3: Create `RolService`
- **Description**: Create `frontend/src/app/roles/rol.service.ts` (`@Injectable({providedIn:'root'})`): `list()`, `getById(id)`, `create(dto: RolRequest)`, `update(id, dto)`, `delete(id)` contra `/api/roles`.
- **Dependencies**: T5.1
- **Status**: done
- **Effort**: S
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/roles/rol.service.ts` (create)
- **Acceptance criteria**:
  - CRUD roles completo (R3) con tipado `Rol`/`RolRequest`.

#### T5.4: Create `PermisosMatrizComponent` (reutilizable rol/usuario)
- **Description**: Create `frontend/src/app/shared/permisos-matriz/permisos-matriz.component.{ts,html,scss}` (NgModule no-standalone, Angular Material):
  - Inputs: `modulos: Modulo[]`, `checked: string[]` (códigos), `modo: 'rol' | 'usuario'` (usuario: señala visualmente overrides add/remove vs rol base — comportamiento relativo al rol base).
  - Render: por módulo `mat-expansion-panel` con `mat-checkbox` "seleccionar todo" (estado indeterminado) + un `mat-checkbox` por acción (`VER`/`CREAR`/`EDITAR`/`ELIMINAR`).
  - Output: `change` emite `string[]` de códigos chequeados.
- **Dependencies**: T5.1, T5.2
- **Status**: done
- **Effort**: L
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/shared/permisos-matriz/permisos-matriz.component.ts` (create)
  - `frontend/src/app/shared/permisos-matriz/permisos-matriz.component.html` (create)
  - `frontend/src/app/shared/permisos-matriz/permisos-matriz.component.scss` (create)
- **Acceptance criteria**:
  - Matriz módulo → acciones expandible (R7: "cada módulo expandible para marcar/desmarcar acciones específicas").
  - Funciona para matriz de rol y para overrides de usuario.

#### T5.5: Create `RolesModule` + `RolesRoutingModule`
- **Description**: Create `frontend/src/app/roles/roles.module.ts` (NgModule NO-standalone — patrón `gestion-precios`/`usuarios`; declaraciones: `RolListComponent`, `RolFormComponent`; imports: Material + `SharedModule`) y `frontend/src/app/roles/roles-routing.module.ts` (rutas: `''` → list, `'nuevo'` → form, `':id/editar'` → form).
- **Dependencies**: T5.6, T5.7
- **Status**: done
- **Effort**: M
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/roles/roles.module.ts` (create)
  - `frontend/src/app/roles/roles-routing.module.ts` (create)
- **Acceptance criteria**:
  - Módulo lazy-loadable; rutas internas definidas (R7).

#### T5.6: Create `RolListComponent`
- **Description**: Create `frontend/src/app/roles/rol-list/rol-list.component.{ts,html,scss}`: `MatTable` (nombre, descripción, permisos como badges, acciones), carga `rolService.list()`, botones Nuevo/Editar/Eliminar envueltos en `*appHasPermission="'ROLES_EDITAR'"`.
- **Dependencies**: T5.3, T6.3 (directiva)
- **Status**: done
- **Effort**: M
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/roles/rol-list/rol-list.component.ts` (create)
  - `frontend/src/app/roles/rol-list/rol-list.component.html` (create)
  - `frontend/src/app/roles/rol-list/rol-list.component.scss` (create)
- **Acceptance criteria**:
  - El rol creado desde la UI aparece en el listado con su matriz (R7, escenario "Admin crea un rol desde la UI").

#### T5.7: Create `RolFormComponent`
- **Description**: Create `frontend/src/app/roles/rol-form/rol-form.component.{ts,html,scss}` (Reactive Forms, patrón existente):
  - Carga `catalogoService.getModulos()` (13 módulos ordenados).
  - Form: `nombre`, `descripcion` + `PermisosMatrizComponent`.
  - Guardar → `RolRequest { nombre, descripcion, permisos: codigosChequeados }` → `create`/`update`.
  - Edición: precargar `checked` desde `rol.permisos`; en edición del rol propio del usuario logueado mostrar warning visual al desmarcar permisos (riesgo mitigado).
- **Dependencies**: T5.2, T5.3, T5.4
- **Status**: done
- **Effort**: L
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/roles/rol-form/rol-form.component.ts` (create)
  - `frontend/src/app/roles/rol-form/rol-form.component.html` (create)
  - `frontend/src/app/roles/rol-form/rol-form.component.scss` (create)
- **Acceptance criteria**:
  - Escenario R7 "Admin crea un rol desde la UI": checkboxes Ventas(VER,CREAR)+Precios(VER) → POST con `VENTAS_VER, VENTAS_CREAR, PRECIOS_VER`.

#### T5.8: Register `/roles` lazy route with guard
- **Description**: Modify `frontend/src/app/app-routing.module.ts`: agregar `{ path: 'roles', loadChildren: () => import('./roles/roles.module').then(m => m.RolesModule), canActivate: [AuthGuard], data: { permissions: ['ROLES_VER'] } }`.
- **Dependencies**: T5.5
- **Status**: done
- **Effort**: S
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/app-routing.module.ts` (modify)
- **Acceptance criteria**:
  - `/roles` lazy + protegida por `ROLES_VER` (R7); usuario sin permiso redirige/bloquea.

---

### Phase 6: Frontend — User Form & Wiring (auth, guard, sidebar, permisos)

#### T6.1: Modify `AuthService` — permisos en sessionStorage + refresh `/me`
- **Description**: Modify `frontend/src/app/core/auth.service.ts`:
  - `CurrentUser` + `permisos: string[]`.
  - `login()`: guardar `ferreplus_permisos` (JSON array) en sessionStorage desde `AuthResponse.permisos`.
  - Nuevo `refreshPermisos(): Observable<Usuario>` → `GET /api/usuarios/me` que actualiza sessionStorage + `currentUserSubject`.
  - Nuevos `hasPermission(codigo): boolean` y `hasAnyPermission(codigos: string[]): boolean` (lee de sessionStorage).
  - `logout()`: limpiar `ferreplus_permisos`.
- **Dependencies**: T5.1
- **Status**: done
- **Effort**: M
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/core/auth.service.ts` (modify)
- **Acceptance criteria**:
  - Login inicializa permisos (R8, escenario "Login inicializa permisos del frontend"); API `hasPermission`/`hasAnyPermission` disponible (R7).

#### T6.2: Modify `AuthGuard` — async, `data.permissions`, refresh por navegación
- **Description**: Modify `frontend/src/app/core/auth.guard.ts` para retornar `Observable<boolean>`:
  - Sin token → redirect `/auth` con `returnUrl`.
  - Con token → `authService.refreshPermisos()` (GET `/me`) **en cada navegación** (Decisión 6).
  - `route.data['permissions']` presente → `hasAnyPermission`; si no → redirect a la **primera ruta permitida** (`AuthService.getHomeRoute()`, mapa centralizado `RUTAS_POR_PERMISO`), no al dashboard hardcodeado.
  - Sin ninguna ruta accesible (`getHomeRoute()` null) → `logout()` + redirect `/auth` (elimina el escenario "sistema bloqueado").
  - `catchError` → redirect `/auth` y false.
  - Conservar chequeo de `data.roles` para compatibilidad transitoria.
- **Dependencies**: T6.1
- **Status**: done
- **Effort**: M
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/core/auth.guard.ts` (modify)
  - `frontend/src/app/core/rutas-por-permiso.ts` (create — mapa ruta→permiso, fuente única de verdad)
  - `frontend/src/app/auth/login/login.component.ts` (modify — destino post-login vía `getHomeRoute()` + respeto de `returnUrl` si el usuario tiene permiso)
  - `frontend/src/app/app-routing.module.ts` (modify — `data.permissions` derivado de `permisosDeRuta()`)
- **Acceptance criteria**:
  - Navegación por URL directa a módulo sin permiso → bloqueada y redirigida a la primera ruta permitida (R7, escenario "Navegación por URL directa"); cambio de permisos aplica sin re-login (R7, escenario refresh por navegación).
  - Login de usuario sin `DASHBOARD_VER` navega a su primera ruta permitida (no a pantalla en blanco); usuario sin permisos ve mensaje claro en login.

#### T6.3: Create `HasPermissionDirective`
- **Description**: Create `frontend/src/app/core/has-permission.directive.ts`: directiva estructural `*appHasPermission="'PRODUCTOS_CREAR'"` o `*appHasPermission="['A','B']"` (any); elimina el elemento del DOM si el usuario no tiene el/los permiso(s). Declarar y exportar en `SharedModule` (y registrarla en el module que la use).
- **Dependencies**: T6.1
- **Status**: done
- **Effort**: M
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/core/has-permission.directive.ts` (create)
  - `frontend/src/app/shared/shared.module.ts` (modify — exportar)
  - `frontend/src/app/core/core.module.ts` (modify si aplica)
- **Acceptance criteria**:
  - Botón oculto sin permiso específico (R7, escenario "Botón de acción oculto sin permiso").

#### T6.4: Modify sidebar — 13 items, filtrado por `permissions`
- **Description**: Modify `frontend/src/app/shared/sidebar/sidebar.component.ts` (y `.html` si aplica): `MenuItem.roles?: string[]` → `permissions?: string[]`; agregar item Roles (`icon: 'admin_panel_settings'`, `/roles`, `['ROLES_VER']`) después de Usuarios; item Reportes pasa de `roles: ['ADMIN','SUPERVISOR']` a `permissions: ['REPORTES_VER']`; filtrado con `authService.hasAnyPermission(item.permissions)`.
- **Dependencies**: T6.1
- **Status**: done
- **Effort**: M
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/shared/sidebar/sidebar.component.ts` (modify)
  - `frontend/src/app/shared/sidebar/sidebar.component.html` (modify si aplica)
- **Acceptance criteria**:
  - Sidebar oculta módulos sin permiso VER (R7, escenario "Sidebar oculta módulos sin permiso VER"); sin referencias a CAJERO/SUPERVISOR (R7 REMOVED).

#### T6.5: Add `data.permissions` to the 13 routes
- **Description**: Modify `frontend/src/app/app-routing.module.ts` agregando `data: { permissions: ['X_VER'] }` a las rutas existentes (dashboard→`DASHBOARD_VER`, productos→`PRODUCTOS_VER`, categorias, proveedores, clientes, ventas, compras, gestion-precios→`PRECIOS_VER`, movimientos, gastos, usuarios, reportes→`REPORTES_VER`) + la ruta roles de T5.8.
- **Dependencies**: T6.2, T5.8
- **Status**: done
- **Effort**: S
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/app-routing.module.ts` (modify)
- **Acceptance criteria**:
  - Las 13 rutas protegidas con `data.permissions` (R7).

#### T6.6: Modify `UsuarioFormComponent` — dropdown de roles desde API + matriz de overrides
- **Description**: Modify `frontend/src/app/usuarios/usuario-form/usuario-form.component.ts` y `.html`:
  - **Eliminar** la lista hardcodeada `['ADMIN', 'CAJERO', 'BODEGUERO', 'SUPERVISOR']` (línea ~21) y el control `rolNombre`; el dropdown de rol base se carga desde `rolService.list()` (`GET /api/roles`).
  - Matriz de overrides con `PermisosMatrizComponent` en modo usuario: estado inicial `checked` = permisos del rol base + overrides del usuario (edición); al cambiar el rol base se recalcula.
  - Semántica del toggle relativa al rol base (R7): checked en rol → sin override; checked fuera de rol → `{permisoCodigo, concedido:true}`; unchecked en rol → `{permisoCodigo, concedido:false}`; unchecked fuera → sin override.
  - Payload: `{ nombre, email, telefono, activo, rolId, password?, overrides }`.
- **Dependencies**: T5.2, T5.3, T5.4
- **Status**: done
- **Effort**: L
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/usuarios/usuario-form/usuario-form.component.ts` (modify)
  - `frontend/src/app/usuarios/usuario-form/usuario-form.component.html` (modify)
- **Acceptance criteria**:
  - Sin valores hardcodeados de roles (R7, escenario "Dropdown de roles sin valores hardcodeados"); payload con `rolId` numérico + overrides (R8, escenario "Crear usuario desde la UI funciona end-to-end").
  - Edición de usuario sin password no rompe (password opcional).

#### T6.7: Modify `UsuarioService` (frontend) — payload alineado
- **Description**: Modify `frontend/src/app/usuarios/usuario.service.ts` para enviar `rolId` (numérico) y `overrides` en create/update, alineado al contrato corregido.
- **Dependencies**: T6.6
- **Status**: done
- **Effort**: S
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/usuarios/usuario.service.ts` (modify)
- **Acceptance criteria**:
  - La petición ya no envía `rolNombre` string → no devuelve 400 (R8).

#### T6.8: Modify `UsuarioListComponent` — badges genéricos
- **Description**: Modify `frontend/src/app/usuarios/usuario-list/usuario-list.component.ts`: simplificar `getRolClass(rolNombre)` a un mapa genérico por `rolNombre` con fallback `default`, eliminando los casos `SUPERVISOR`/`CAJERO` (R8). La columna Rol usa `rolNombre` a nivel raíz.
- **Dependencies**: T5.1
- **Status**: done
- **Effort**: S
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/usuarios/usuario-list/usuario-list.component.ts` (modify)
- **Acceptance criteria**:
  - Listado muestra rol correctamente sin objeto anidado ni roles fantasma (R8, escenario "Listado de usuarios muestra el rol correctamente").

#### T6.9: Apply `*appHasPermission` to action buttons (productos, usuarios, roles)
- **Description**: Modify templates: `frontend/src/app/productos/*-list.component.html` (Nuevo/Editar/Eliminar → `PRODUCTOS_CREAR/EDITAR/ELIMINAR`), `frontend/src/app/usuarios/usuario-list/usuario-list.component.html` (→ `USUARIOS_*`), `frontend/src/app/roles/rol-list/rol-list.component.html` (→ `ROLES_EDITAR`). Asegurar imports de `SharedModule` en los módulos.
- **Dependencies**: T6.3
- **Status**: done
- **Effort**: M
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/productos/productos-list/productos-list.component.html` (modify — verificar ruta exacta del listado)
  - `frontend/src/app/usuarios/usuario-list/usuario-list.component.html` (modify)
  - `frontend/src/app/roles/rol-list/rol-list.component.html` (modify)
  - módulos declarantes (imports `SharedModule`) según aplique
- **Acceptance criteria**:
  - Escenario R7 "Botón de acción oculto sin permiso específico": sin `PRODUCTOS_CREAR` el botón "Nuevo producto" no se renderiza.

#### T6.10: Verify module wiring (SharedModule/CoreModule/AppModule)
- **Description**: Verify/ajustar `frontend/src/app/shared/shared.module.ts` (exporta `PermisosMatrizComponent`, `HasPermissionDirective`), `frontend/src/app/core/core.module.ts` y `frontend/src/app/app.module.ts` (roles module NO en app.module — lazy; verificar que no haya registros duplicados). Ejecutar `ng build` para detectar NG8001/NG8002.
- **Dependencies**: T5.4, T6.3
- **Status**: done
- **Effort**: S
- **Specialist**: angular
- **Files affected**:
  - `frontend/src/app/shared/shared.module.ts` (modify si aplica)
  - `frontend/src/app/core/core.module.ts` (modify si aplica)
  - `frontend/src/app/app.module.ts` (modify si aplica)
- **Acceptance criteria**:
  - `ng build` compila sin errores de imports de Material ni de directivas (NG8001/NG8002).

---

### Phase 8: Verification

#### T8.1: Full build + all backend tests + frontend compile
- **Description**: Ejecutar `mvn test` en `backend/` (todos los tests verdes, incluidos los preexistentes `PrecioServiceTest`/`CompraServiceIntegrationTest`) y `ng build` en `frontend/` (sin errores NG8001/NG8002). Verificar `mvn package` OK.
- **Dependencies**: Todas las anteriores
- **Status**: done
- **Effort**: M
- **Specialist**: ambos
- **Files affected**: n/a (comandos de build)
- **Acceptance criteria**:
  - Build verde end-to-end antes de considerar la implementación completa.

#### T8.2: Manual end-to-end verification (regla de oro previa al merge)
- **Description**: Checklist manual con la app corriendo (backend + frontend + BD):
  1. Login admin (`admin@ferreplus.com` / `admin123`) con la nueva matriz → sin bloqueo.
  2. Crear/editar rol con matriz de checkboxes → aparece en listado; un usuario con ese rol recibe exactamente esas autoridades.
  3. Crear/editar usuario con rol base + overrides (add/remove) → columna Rol visible, permisos efectivos correctos.
  4. Verificar 200/403 por rol (VENDEDOR en gastos → 403; ADMIN en gastos → 200).
   5. Sidebar filtra por `MODULO_VER`; refresh `/me` por navegación aplica cambios sin re-login.
   6. Verificación de auditoría (filas en `auditoria` tras operaciones de usuarios/roles).
   7. Navegación post-login: usuario sin `DASHBOARD_VER` (ej. VENDEDOR) aterriza en su primera ruta permitida (no pantalla en blanco); usuario sin permisos ve mensaje claro en login; `returnUrl` se respeta solo si el usuario tiene permiso para la ruta.
- **Dependencies**: T8.1
- **Status**: pending
- **Effort**: L
- **Specialist**: ambos
- **Files affected**: n/a
- **Acceptance criteria**:
  - Sin la verificación manual NO se mergea (elimina el escenario "sistema bloqueado", regla de oro del design).

---

## Dependency Graph Summary

```
STACK 1 — BACKEND
  Phase 1 (foundation): T1.1→T1.2→T1.5  │  T1.1→T1.4  │  T1.3  │  T1.6/T1.7 dependen de entidades
        │
  Phase 2 (security):  T2.1(RED)→T2.2(GREEN)  T2.3(←T1.3)  T2.4(←T1.6,T1.8)
                       T2.5(config)  T2.6(←T2.2,T1.7)  T2.7(←T2.2)  T2.8-T2.13(←T2.5)
        │
  Phase 3 (services):  T3.1(←T2.2,T2.3,T1.11)  T3.2(←T2.3,T1.12)
        │
  Phase 4 (seed):      T4.1(←T1.x)  T4.2/T4.3(←T4.1)
        │
  Phase 7 (tests):     T7.1(←Phase 2+4)  T7.2(←T4.1)  T7.3(←Phase 2+4)  T7.4(←T3.1)  T7.5(←T3.1,T3.2)
        │  [exit: mvn test 100% verde → STOP → review/commit del usuario]

STACK 2 — FRONTEND
  Phase 5 (roles FE):  T5.1→T5.2/T5.3→T5.4→T5.7  T5.6(←T5.3,T6.3)  T5.5(←T5.6,T5.7)  T5.8(←T5.5)
        │
  Phase 6 (wiring FE): T6.1→T6.2/T6.3  T6.4/T6.5(←T6.1,T6.2)  T6.6(←T5.2,T5.3,T5.4)  T6.7(←T6.6)  T6.9(←T6.3)
        │
  Phase 8 (verif):     T8.1(←todo)  T8.2(←T8.1)
        │  [exit: ng build limpio + checklist manual → STOP → review/commit del usuario]
```

**Orden de ejecución**: **STACK 1 (B1→B2→B3→B4→B5) → STOP → review/commit del usuario → STACK 2 (F1→F2→F3) → STOP → review/commit del usuario.**

**Nota test-first**: `T2.1` (RED) escribe el test de `PermisoResolver` ANTES de su implementación (`T2.2`, GREEN) — es la lógica pura más valiosa de cubrir primero. Los tests de integración (Phase 7) requieren el stack completo por naturaleza. El frontend no tiene infraestructura de tests; su verificación es compilación + checklist manual (T8.2) — la infraestructura de tests frontend queda anotada como mejora futura.

---

## Review Workload Forecast (entregable por stacks)

> **Entregable por stacks — el usuario revisa y commitea; el agente no ejecuta git.**
> El cambio se entrega en **2 stacks**, no en PRs encadenadas. Cada stack termina con un **STOP** para review + commit manual del usuario.

### Estimated Changed Lines

| Stack | Tandas (fases) | Files Changed | Est. Líneas Nuevas | Est. Líneas Modificadas | Total Est. |
|-------|----------------|---------------|--------------------|-------------------------|------------|
| **STACK 1 — BACKEND** (B1-B5) | B1 (Phase 1) + B2 (Phase 2) + B3 (Phase 3) + B4 (Phase 4) + B5 (Phase 7) | ~50 | ~1,535 (new ~900 + tests ~890 − tests en modified... ver detalle) | ~675 (modified ~630 + docs ~45) | **~2,465** |
| **STACK 2 — FRONTEND** (F1-F3) | F1 (Phase 5) + F2 (Phase 6) + F3 (Phase 8, verificación) | ~26 | ~845 | ~435 | **~1,280** |
| **Total** | | **~76 files** | **~2,635** | **~1,110** | **~3,745** |

Detalle STACK 1: backend nuevo ~900 (22 files: entities, repos, DTOs, resolver, handler, services, controllers, seeder, exception) + backend modificado ~630 (21 files: Rol, Usuario, UsuarioRepository, SecurityConfig, 3 auth services, 3 DTOs, 13 controllers, GlobalExceptionHandler, schema.sql) + tests backend ~890 (6 files) + docs ~45 (1 file).
Detalle STACK 2: frontend nuevo ~845 (14 files: roles module, 2 services, 3 components ×3 files, matriz, directiva) + frontend modificado ~435 (12 files: models, auth, guard, sidebar, routing, usuario-form/service/list, templates, modules). Phase 8 (verificación) no agrega líneas de código.

### Review Budget Risk Assessment (budget de esta sesión: 800 líneas)

| Risk | Assessment |
|------|------------|
| **Total vs budget** | 🔴 **HIGH RISK** — ~3,745 líneas ≈ **4.7×** el presupuesto de 800 líneas. |
| **STACK 1 BACKEND solo** | 🟡 ~2,465 líneas — excede el presupuesto por sí solo. |
| **STACK 2 FRONTEND solo** | 🟡 ~1,280 líneas — excede el presupuesto. |

### Límites de entrega (2 stacks — decisión del usuario)

**`Chained PRs recommended: No`** — la entrega NO es por PRs; el usuario decidió **2 stacks** (sin operaciones git del agente):

1. **STACK 1 — BACKEND COMPLETO** (~2,465 líneas / ~50 files): tandas **B1** (Phase 1: T1.1-T1.12) → **B2** (Phase 2: T2.1-T2.13) → **B3** (Phase 3: T3.1-T3.2) → **B4** (Phase 4: T4.1-T4.3) → **B5** (Phase 7: T7.1-T7.5).
   - **Exit criteria**: `mvn test` 100% verde + `mvn package` OK → **STOP y notificar al usuario para review + commit** antes de iniciar STACK 2.
   - Racional: el backend es autocontenido (catálogo, enforcement, auditoría y sus tests); define el contrato de la API que consume el frontend.
2. **STACK 2 — FRONTEND COMPLETO** (~1,280 líneas / ~26 files): tandas **F1** (Phase 5: T5.1-T5.8) → **F2** (Phase 6: T6.1-T6.10) → **F3** (Phase 8: T8.1-T8.2 verificación).
   - **Exit criteria**: `ng build` limpio + checklist manual T8.2 aprobado → **STOP y notificar al usuario para review + commit final**.
   - Nota: la parte de `mvn test` de T8.1 ya quedó validada en el exit de B5; T8.2 (manual end-to-end) requiere ambos stacks corriendo.

### Decision Needed Before Apply

**`Decision needed before apply: Yes`**

1. ~~Confirmar estrategia de PRs encadenadas~~ → **DECIDIDO por el usuario**: entrega por **2 stacks** (BACKEND → FRONTEND); el agente no ejecuta git; el usuario revisa y commitea tras cada stack.
2. ~~Confirmar el split de PR 5~~ → **No aplica** (no hay PRs). Las tandas internas (B1..B5, F1..F3) son puntos de chequeo del implementador dentro de cada stack.
3. **Open questions del design (confirmación menor, demo)**: BODEGUERO verá el dashboard con gráfico de ventas por periodo vacío (opción estricta de la matriz); el password del admin sembrado sigue siendo `admin123`. ¿Se mantienen?
4. ~~Frontend sin infraestructura de tests~~ → **DECIDIDO por el usuario (apply F3)**: se agrega infraestructura de tests frontend en STACK 2 (`@angular/build:unit-test` + vitest + jsdom; `frontend/tsconfig.spec.json`; script `npm test`). Tests creados: `auth.service.spec.ts`, `auth.guard.spec.ts`, `has-permission.directive.spec.ts`, `permisos-matriz.component.spec.ts` (29 tests en verde). Nota: builder `unit-test` es EXPERIMENTAL en @angular/build 22.
