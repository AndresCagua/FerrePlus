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

## Slice 3 / PR 3 progress — 2026-08-23

```yaml
status: partially_verified
change: reorganizar-menu-modulos
slice: pr3_seo_ia
execution_mode: interactive
artifact_store: openspec
skill_resolution: fallback-path
commits_created: false
push_performed: false
database_modified: false
```

### Completed

- Se agregaron DTOs estrictos para solicitud/respuesta SEO con limites server-side de titulo, resumen y descripcion.
- `SeoSuggestionService` reutiliza `GeminiClient.generate()` y la configuracion Gemini existente, construye un prompt acotado a los tres campos, valida JSON y rechaza respuestas incompletas.
- Se agrego `POST /api/admin/talento/publicaciones/seo`, protegido con `TALENTO_PUBLICACIONES_EDITAR`, sin persistencia, con ProblemDetail para validacion/proveedor y correlation ID.
- El formulario de edicion incorpora Generar con IA, loading, bloqueo de duplicados, error/retry manual, validacion de respuesta y campos SEO editables; Guardar no depende de la IA.
- Se agregaron pruebas unitarias de servicio, MockMvc de exito/400 y pruebas frontend de exito, incompleto, error y duplicados.

### Verification

- `npm test`: 19 archivos, 112 pruebas aprobadas.
- `npm run build`: aprobado; permanece warning existente de `sweetalert2` CommonJS.
- `docker run --rm -v "$PWD":/app -w /app maven:3-eclipse-temurin-21 mvn -q -DskipTests package`: aprobado.
- Pruebas focalizadas nuevas de admin-api: aprobadas (servicio y controller).
- Prueba conjunta con chat: el chat no pudo iniciar porque el entorno no tiene PostgreSQL en `localhost:5433`; no se modifico el codigo del chat ni se ejecuto SQL.
- `git diff --check`: aprobado.

### Scope boundary

No se modificaron menu, slug, public-api, portal ni bases de datos. PR 4–5 permanecen fuera de alcance. Los artefactos generados previos (`public-api/target`) y `node_modules/` aparecen en el workspace y no forman parte de este Slice.

### Remaining / follow-up

- La verificacion end-to-end de 401/403 y la no regresion completa del chat requiere levantar la dependencia PostgreSQL documentada por el proyecto; queda para la verificacion/integracion posterior.

## Slice 3 review corrections — 2026-08-23

Se fusiona este avance con el progreso previo del Slice 3; no se reemplazan sus verificaciones ni su limite de alcance.

### Completed

- `SeoSuggestionService` conserva `502` solo para respuesta SEO incompleta tipada; respuestas invalidas, timeouts y fallos del proveedor se clasifican como `503`.
- `SeoSuggestionControllerTest` mantiene los filtros Spring Security activos y prueba `401` sin JWT, `403` sin autoridad de edicion, `200` con permiso, `400` autenticado y `502` para respuesta incompleta.
- La prueba frontend de fallo/reintento usa `throwError` y `of` reales, verificando el segundo intento y que Guardar permanece disponible.

### Verification

- Se ejecutaron pruebas focalizadas de admin-api y frontend, build y `git diff --check`.
- La suite completa del chat sigue bloqueada si PostgreSQL no esta disponible en `localhost:5433`; no se toca el codigo del chat ni se ejecuta SQL.

```yaml
status: partially_verified
skill_resolution: fallback-path
commits_created: false
push_performed: false
database_modified: false
slice_boundary: pr3_seo_ia_only
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

## Slice 4 / PR 4 progress — 2026-08-23

```yaml
status: completed
change: reorganizar-menu-modulos
slice: pr4_portal_editorial
execution_mode: interactive
artifact_store: openspec
skill_resolution: fallback-path
branch: feature/reorganizar-menu-modulos
commits_created: false
push_performed: false
database_modified: false
```

### Completed

- Se creo una columna editorial exclusiva para publicaciones con ancho maximo de 720px, padding movil y eje vertical consistente de 24px; convocatorias conserva su `.article` existente.
- Las imagenes de portada y galeria usan ancho maximo completo, altura automatica, `object-fit`, borde y radio consistentes.
- YouTube usa un iframe lazy de ancho completo con reserva `aspect-ratio: 16 / 9`, `title` accesible y enlace fallback mientras no confirma carga.
- Los embeds de X permanecen centrados, sin padding del wrapper, limitados al ancho oficial y con `overflow-wrap:anywhere` y fallback accesible.
- Se respetan los breakpoints existentes para 320px/768px/1440px, sin overflow horizontal del contenido editorial, y `prefers-reduced-motion` conserva la regla del portal.
- Se marco el aislamiento visual: solo las paginas de publicaciones reciben `.publication-article`; convocatorias, contacto y otras paginas no heredan la columna editorial.
- La generacion estatica existente continua excluyendo borradores al construir rutas desde el listado publico; sitemap se genera desde esas rutas.

### Verification

- `portal/npm run check`: aprobado, 0 errores, 0 warnings, 0 hints.
- `portal/npm run build`: aprobado; build estatico y sitemap generados correctamente.
- `git diff --check`: aprobado.
- No existen pruebas visuales automatizadas ni framework de browser en `portal`; no se agregaron dependencias ni un framework nuevo.

### Scope boundary

Solo se modificaron layout/CSS/responsive del portal editorial y la estructura minima del componente publico necesaria para embeds. No se modificaron backend, slug, SEO, menu, APIs ni bases de datos. PR 5 permanece fuera de alcance.

## Slice 5 / PR 5 progress — 2026-08-23

```yaml
status: partially_verified
change: reorganizar-menu-modulos
slice: pr5_testing
execution_mode: interactive
artifact_store: openspec
skill_resolution: fallback-path
branch: feature/reorganizar-menu-modulos
commits_created: false
push_performed: false
database_modified: false
```

### Completed

- Se agregaron pruebas reales del mapa RBAC y del sidebar renderizado con TestBed: asignacion exacta, padres virtuales, ruta bloqueada, localStorage, ARIA, Enter/Space, foco y colapsado sin descendientes enfocables.
- Se ampliaron pruebas de publicaciones/slug para agotamiento de candidatos con 409 y recalculo al cambiar titulo; las pruebas existentes cubren portada fuera del listado, normalizacion, fallback, limite, colision y conservacion.
- Se cubrieron 503 de proveedor SEO en MockMvc, manteniendo 502 exclusivamente para respuesta incompleta; chat se verifico con pruebas unitarias no persistentes.
- Se agrego `portal/scripts/verify-editorial.mjs` y `npm run test:editorial`, sin framework ni dependencias nuevas, para validar invariantes editoriales CSS/Astro.
- Se actualizaron tasks, decisiones cerradas en design y `verify-report-slice5.md`.

### Verification

- Frontend completo: 20 archivos, 116 pruebas aprobadas; build aprobado.
- Admin-api SEO focalizado aprobado (200/400/401/403/502/503).
- Public-api `PublicacionServiceTest` aprobado: 14 pruebas.
- Chat unitario no persistente aprobado.
- Portal: checks estaticos, `astro check` y build aprobados.
- `git diff --check` aprobado.

### Blocked / deferred

- 5.2.6 carrera real MongoDB/Testcontainers y 5.5.4 suite backend completa no se ejecutaron para respetar la prohibicion de modificar datos persistentes; requieren base efimera aislada/autorizacion expresa.
- Las verificaciones runtime de viewport 320/768/1440 no existen en el portal actual; se cubrieron invariantes estaticos sin inventar framework de browser.
- PostgreSQL del chat no se toco; una prueba de integracion que requiera `localhost:5433` queda bloqueada por infraestructura.

## Slice 5 verifier correction — 2026-08-23

- Se reemplazo el check combinado con `&&` de `verify-editorial.mjs` por dos validaciones estaticas independientes: `justify-content:center` para `.x-preview` y `overflow-wrap:anywhere` para `.x-preview-url`.
- Se ejecuto `portal/npm run test:editorial` y `git diff --check`, ambos aprobados.
- No se modificaron estilos, funcionalidad del portal, dependencias, bases de datos, commits ni push.
