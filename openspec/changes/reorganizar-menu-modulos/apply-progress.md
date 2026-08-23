# Apply progress: PR 1 — Menu y navegacion

```yaml
status: completed
change: reorganizar-menu-modulos
slice: pr1_menu
execution_mode: interactive
artifact_store: openspec
skill_resolution: fallback-path
branch: feature/reorganizar-menu-modulos
commits_created: false
push_performed: false
database_modified: false
```

## Completed

- Mapa jerarquico con Dashboard directo y los modulos Talento, Contabilidad, Bodega y Mantenimiento.
- Filtrado RBAC recursivo y `getHomeRoute()` sobre hojas accesibles.
- Accordion accesible con boton real, ARIA, teclado, foco visible y descendientes fuera del DOM al estar cerrado.
- Persistencia segura de expansion en `ferreplus_menu_v1`, con ruta activa prioritaria y fallback en memoria.
- Compatibilidad de login con URLs anidadas y conservacion de permisos de rutas hijas.
- Pruebas frontend y build ejecutados correctamente.

## Verification

- `npm test`: 19 archivos, 107 pruebas aprobadas.
- `npm run build`: aprobado.
- Warning existente: `sweetalert2` CommonJS produce un bailout de optimizacion.

## Scope boundary

PR 2–5 no implementados. No se modificaron publicaciones, slug, SEO, portal, backend ni bases de datos.

## Fresh review corrections — 2026-08-23

- Se agrego manejo explicito de `Enter` en `SidebarComponent.onModuleKeydown()`. El evento hace `preventDefault()` y alterna solo el grupo enfocado, sin navegacion ni submit implicito.
- Se agrego una prueba focalizada para `Enter`, conservando la prueba existente de `Space` y la persistencia del estado.
- Se corrigio la asercion de `AuthService.getHomeRoute()` a `/productos` y se ajusto el orden de los modulos para que Bodega preceda a Contabilidad, que es el orden esperado por la navegacion post-login.
- Se conservaron los cambios previos del Slice 1; PR 2–5 permanecen fuera de alcance.

## Fresh review verification

- `npm test -- --include=src/app/core/auth.service.spec.ts --include=src/app/shared/sidebar/sidebar.component.spec.ts`: 2 archivos, 17 pruebas aprobadas.
- `npm run build`: aprobado.
- `git diff --check`: aprobado.
- Warning existente: `sweetalert2` CommonJS produce un bailout de optimizacion.

```yaml
status: completed
skill_resolution: fallback-path
commits_created: false
push_performed: false
database_modified: false
```

## Slice 2 / PR 2 progress — 2026-08-23

```yaml
status: completed
change: reorganizar-menu-modulos
slice: pr2_talento_slug
execution_mode: interactive
artifact_store: openspec
skill_resolution: fallback-path
branch: feature/reorganizar-menu-modulos
commits_created: false
push_performed: false
database_modified: false
```

### Completed

- Se elimino exclusivamente portada del listado administrativo; formulario, modelo, contrato de respuesta, almacenamiento y portal no se modificaron funcionalmente.
- `PublicacionService` ahora normaliza/translitera el titulo, usa fallback `publicacion`, limita a 100 caracteres por tokens y genera candidatos deterministas hasta `-5`.
- El backend ignora el slug de entrada, conserva el slug en updates sin cambio de titulo y reintenta colisiones `DuplicateKeyException` contra el indice unico existente; agotamiento retorna `409` con `SLUG_UNAVAILABLE`.
- El formulario muestra una previsualizacion readonly sincronizada con el titulo y sigue enviando el valor informativo sin delegar unicidad al cliente.
- Se agregaron pruebas de normalizacion, fallback, colision determinista, autoridad backend y conservacion en update.

### Verification

- `npm test`: 19 archivos, 109 pruebas aprobadas.
- `npm run build`: aprobado; permanece warning existente de `sweetalert2` CommonJS.
- `public-api`: compilacion Maven en contenedor aprobada.
- `PublicacionServiceTest`: ejecutar focalizadamente en contenedor; la suite completa mantiene un fallo preexistente en `ConvocatoriaAdminDTOTest` por esperar `requisitos` en vez de `requisitos[0].<list element>`.
- `git diff --check`: aprobado.

### Scope boundary

PR 3–5 no implementados. No se tocaron SEO IA, menu, portal editorial ni bases de datos.

## Slice 2 warning corrections — 2026-08-23

```yaml
status: completed
change: reorganizar-menu-modulos
slice: pr2_talento_slug_warning_corrections
execution_mode: strict_tdd
artifact_store: openspec
skill_resolution: fallback-path
commits_created: false
push_performed: false
database_modified: false
```

### Completed

- Se ajusto `normalizarSlug` para respetar los 100 caracteres: conserva tokens completos cuando caben y solo corta un token cuando es inevitable; no deja guiones extremos. El candidato con sufijo mantiene tambien el maximo.
- Se reemplazo el `expect(true)` del test del listado por aserciones sobre la configuracion real de la clase, garantizando que no existen helpers ni estado de portada en el listado.
- Slice 3 no iniciado; comportamiento SEO, menu y portal intacto.

### TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-------|------------|-----|-------|-------------|----------|
| Correccion de slug | `public-api/src/test/java/com/ferreplus/publico/service/PublicacionServiceTest.java` | Unit | ✅ baseline focalizado disponible; Maven local no instalado | ✅ tests de limite/token escritos antes del cambio | ✅ `PublicacionServiceTest` aprobado en contenedor Maven | ✅ token largo + corte por limite | ✅ constante `MAX_SLUG_LENGTH` y candidato alineados |
| Test de listado | `frontend/src/app/talento/pages/publicaciones/publicacion-list/publicacion-list.component.spec.ts` | Unit | ✅ 1/1 previo (placeholder) | ✅ aserciones reales escritas antes de la correccion | ✅ 1/1 aprobado | ➖ comportamiento estructural sin ramas adicionales | ✅ sin placeholder |

### Verification

- `npm test -- --include=src/app/talento/pages/publicaciones/publicacion-list/publicacion-list.component.spec.ts`: 1 archivo, 1 prueba aprobada.
- `npm run build`: aprobado; permanece unicamente el warning previo de `sweetalert2` CommonJS.
- `mvn -q -Dtest=PublicacionServiceTest test` mediante contenedor `maven:3-eclipse-temurin-21`: aprobado.
- `mvn -q -DskipTests package` mediante contenedor Maven: aprobado.
- `git diff --check`: aprobado.

### Scope boundary

Solo se corrigieron los dos warnings solicitados del Slice 2. No se hicieron commits, push ni operaciones de base de datos.
