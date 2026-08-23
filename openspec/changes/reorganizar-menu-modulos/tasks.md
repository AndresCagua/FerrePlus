# Tasks: Reorganizacion del menu por modulos y publicaciones editoriales

## Review Workload Forecast

| Slice | Files touched | Est. additions | Est. deletions | Est. total | Risk (800-line budget) | PR recommendation |
|-------|---------------|----------------|----------------|------------|------------------------|-------------------|
| PR 1 — Menu y navegacion | ~6 | ~220 | ~40 | ~260 | Low | Single PR |
| PR 2 — Talento listado y slug | ~8 | ~280 | ~60 | ~340 | Low | Single PR |
| PR 3 — SEO IA (admin-api + UI) | ~10 | ~350 | ~20 | ~370 | Low | Single PR |
| PR 4 — Portal editorial | ~4 | ~120 | ~40 | ~160 | Low | Single PR |
| PR 5 — Pruebas integradas | ~6 | ~300 | ~10 | ~310 | Low | Single PR |
| **Total** | **~34** | **~1270** | **~170** | **~1440** | **Medium** | **5 PRs encadenados** |

> **Forecast**: Ningun PR individual supera las 400 lineas. El total acumulado (~1440 lineas) justifica 5 PRs encadenados. No se requiere `size:exception`. Cada slice es compilable y reversible independientemente.

---

## Phase 1: Menu y navegacion (PR 1)

**Objetivo**: Reagrupar rutas en cuatro modulos + Dashboard, accordion accesible con persistencia no sensible.
**Dependencias**: Ninguna — es la base para todo el cambio.
**Specs cubiertas**: `menu-modulos/spec.md` R1-R5, `seguridad/spec.md` R3.

### 1.1 Extension de la interfaz RutaPorPermiso

- [x] 1.1.1 Agregar campo opcional `module?: boolean` a `RutaPorPermiso` en `frontend/src/app/core/rutas-por-permiso.ts`
- [x] 1.1.2 Verificar que `filtrarRutasPorPermiso()` y `permisosDeRuta()` existen y son recursivas (sin cambios necesarios si ya manejan `children`)

**Archivos**: `frontend/src/app/core/rutas-por-permiso.ts`
**Criterio**: `module` es opcional; el array existente sin `module` sigue compilando sin errores de tipo.

### 1.2 Reagrupacion de RUTAS_POR_PERMISO

- [x] 1.2.1 Crear nodo padre `Talento` con `module: true`, `permissions: []`, children: Publicaciones, Convocatorias, Postulaciones, Destinatarios
- [x] 1.2.2 Crear nodo padre `Contabilidad` con `module: true`, `permissions: []`, children: Contactos, Gastos, Ventas, Compras, Clientes, Precios, Reportes
- [x] 1.2.3 Crear nodo padre `Bodega` con `module: true`, `permissions: []`, children: Productos, Categorias, Proveedores, Movimientos
- [x] 1.2.4 Crear nodo padre `Mantenimiento` con `module: true`, `permissions: []`, children: Usuarios, Roles, Logs
- [x] 1.2.5 Conservar Dashboard como item directo sin padre, primera posicion en el array
- [x] 1.2.6 Validar que cada ruta existente aparece exactamente una vez en un grupo y que las URLs no cambian

**Archivos**: `frontend/src/app/core/rutas-por-permiso.ts`
**Criterio**: Todos los items del array plano actual migraron a children de un grupo; Dashboard queda fuera; ningun ruta quedo huérfana; `ng build` pasa.

### 1.3 Filtrado RBAC recursivo

- [x] 1.3.1 Modificar `filtrarRutasPorPermiso()` para calcular descendientes visibles primero, y conservar padre solo si tiene al menos un hijo visible
- [x] 1.3.2 Asegurar que el padre con `permissions: []` no se filtre por carecer de permiso propio
- [x] 1.3.3 Verificar que `getHomeRoute()` sigue priorizando Dashboard

**Archivos**: `frontend/src/app/core/rutas-por-permiso.ts`, `frontend/src/app/core/auth.service.ts` (si `getHomeRoute` vive alli)
**Criterio**: Prueba unitaria: usuario con solo `BODEGA_PRODUCTOS_VER` ve Bodega con un hijo; usuario sin permisos de Mantenimiento no ve el grupo.

### 1.4 Sidebar — accordion por modulos

- [x] 1.4.1 Modificar `sidebar.component.html` para renderizar nodos con `module: true` como `<button>` real con `aria-expanded`, `aria-controls`, nombre accesible
- [x] 1.4.2 Implementar `expandedGroups: Record<string, boolean>` en `sidebar.component.ts`; estado inicial cerrado
- [x] 1.4.3 Calcular grupo activo desde URL actual y abrirlo automaticamente al montar
- [x] 1.4.4 Implementar toggle por click que solo alterna el grupo seleccionado sin navegar
- [x] 1.4.5 Enter y Space alternan el grupo; Space no desplaza la pagina; foco permanece en el boton

**Archivos**: `frontend/src/app/shared/sidebar/sidebar.component.html`, `sidebar.component.ts`, `sidebar.component.scss`
**Criterio**: Los cuatro modulos aparecen colapsables; Dashboard queda fuera; Enter/Space funcionan; `aria-expanded` refleja el estado real.

### 1.5 Sidebar — persistencia no sensible

- [x] 1.5.1 Definir clave `ferreplus_menu_v1` para localStorage con solo ids de grupo y booleanos
- [x] 1.5.2 Persistir estado expandido/contraido al cambiar
- [x] 1.5.3 Restaurar estado al montar, ignorando grupos sin hijos visibles
- [x] 1.5.4 Ruta activa siempre prevalece sobre preferencia persistida
- [x] 1.5.5 Fallback a estado en memoria si localStorage no esta disponible

**Archivos**: `frontend/src/app/shared/sidebar/sidebar.component.ts`
**Criterio**: Prueba: cerrar Bodega, recargar, Bodega permanece cerrado; si Bodega ya no tiene hijos, no aparece.

### 1.6 Sidebar — responsive y modo collapsed

- [x] 1.6.1 Verificar que en modo icon-only el boton conserva nombre accesible y permite expandir sin hover
- [x] 1.6.2 Verificar que descendientes ocultos no son enfocables via Tab

**Archivos**: `frontend/src/app/shared/sidebar/sidebar.component.html`, `sidebar.component.scss`
**Criterio**: Tab solo recorre botones de grupo visibles; Enter en icon-only expande el grupo.

### 1.7 Verificacion de guards y no regresion

- [x] 1.7.1 Ejecutar suite frontend existente y confirmar que ningun test de RBAC/guards falla
- [x] 1.7.2 Verificar que `data.permissions` en `app-routing.module.ts` no cambio
- [x] 1.7.3 Verificar que URL directa sin permiso sigue siendo bloqueada por AuthGuard

**Archivos**: Verificacion, sin cambios de codigo
**Criterio**: Todos los tests existentes pasan; `ng build` exitoso.

---

## Phase 2: Talento listado y slug (PR 2)

**Objetivo**: Eliminar portada del listado, hacer slug backend autoritativo con normalizacion y unicidad concurrente.
**Dependencias**: PR 1 (menu base estable).
**Specs cubiertas**: `publicaciones/spec.md` R1-R2, `seo-slug/spec.md` R1-R2.

### 2.1 Listado — eliminar columna portada

- [x] 2.1.1 Eliminar columna `portada` del template de `publicacion-list.component.html`
- [x] 2.1.2 Eliminar funcion `portadaUrl()` y `portadaFailed()` de `publicacion-list.component.ts`
- [x] 2.1.3 Eliminar referencia a `failedPortadas` si existe
- [x] 2.1.4 Verificar que titulo, estado y demas columnas siguen visibles

**Archivos**: `frontend/src/app/talento/pages/publicaciones/publicacion-list/publicacion-list.component.html`, `publicacion-list.component.ts`
**Criterio**: La tabla ya no muestra portada; el modelo y la API no se modifican; portada sigue disponible en formulario y portal.

### 2.2 Backend — normalizacion de slug

- [x] 2.2.1 Crear metodo `normalizarSlug(String titulo)` en `PublicacionService.java` de `public-api`: transliterar acentos, minusculas, solo `[a-z0-9-]`, colapsar guiones, quitar extremos, limitar a 100 chars
- [x] 2.2.2 Implementar fallback a `publicacion` si el titulo no produce caracteres validos
- [x] 2.2.3 Implementar generador de candidatos: `base`, `base-2`, `base-3`, ..., `base-5`

**Archivos**: `public-api/src/main/java/.../service/PublicacionService.java`
**Criterio**: `normalizarSlug("Talento: Niño Tecnico / Bogota")` retorna `talento-nino-tecnico-bogota`; titulo solo con simbolos retorna `publicacion`.

### 2.3 Backend — unicidad concurrente

- [x] 2.3.1 Modificar `create` y `update` en `PublicacionService` para generar slug desde titulo antes de persistir
- [x] 2.3.2 Implementar retry ante `DuplicateKeyException` con sufijo determinista hasta 5 intentos
- [x] 2.3.3 Devolver `409 Conflict` con codigo `SLUG_UNAVAILABLE` si se agotan intentos
- [x] 2.3.4 En `update`, conservar slug existente si el titulo no cambio
- [x] 2.3.5 Verificar que el indice unico `@Indexed(unique=true)` existe en `Publicacion.java`

**Archivos**: `public-api/src/main/java/.../service/PublicacionService.java`, `public-api/src/main/java/.../model/Publicacion.java`
**Criterio**: Prueba de carrera: dos creates concurrentes con mismo titulo producen slugs unicos; 5 colisiones devuelven 409.

### 2.4 Backend — DTO y contrato

- [x] 2.4.1 Verificar que `PublicacionAdminDTO` o equivalente excluye slug del input del cliente (el backend es autoridad)
- [x] 2.4.2 Asegurar que el response incluye el slug final generado
- [x] 2.4.3 Verificar que `TalentoController` no necesita cambios significativos (proxy a public-api)

**Archivos**: DTOs en `admin-api` y `public-api`, `TalentoController.java`
**Criterio**: El slug retornado por la API es siempre el normalizado backend; el valor del cliente se ignora.

### 2.5 Frontend — previsualizacion de slug

- [x] 2.5.1 En `publicacion-form.component.ts`, calcular slug derivado del titulo con la misma logica de normalizacion
- [x] 2.5.2 Mostrar slug como texto de solo lectura (no input editable)
- [x] 2.5.3 Ocultar el campo slug editable manual en el template
- [x] 2.5.4 Asegurar que el slug se envia al backend pero este lo ignora (ya autoritativo)

**Archivos**: `frontend/src/app/talento/pages/publicaciones/publicacion-form/publicacion-form.component.ts`, `.html`
**Criterio**: Cambiar titulo actualiza la previsualizacion; el campo slug no es editable; el formulario envia slug pero el backend lo reemplaza.

---

## Phase 3: SEO IA (PR 3)

**Objetivo**: Endpoint autenticado que reutiliza Gemini existente, UI editable con loading/error/retry.
**Dependencias**: PR 2 (slug estable).
**Specs cubiertas**: `seo-slug/spec.md` R3-R4, `seguridad/spec.md` R1-R2.

### 3.1 Backend — caso de uso SEO

- [x] 3.1.1 Crear `SeoSuggestionRequest` DTO con `titulo` (requerido, max 200), `resumen?` (max 500), `descripcion?` (max 5000)
- [x] 3.1.2 Crear `SeoSuggestionResponse` DTO con `title` (String, no vacio), `description` (String, no vacio)
- [x] 3.1.3 Crear servicio `SeoSuggestionService` que inyecta `GeminiClient`/`GeminiProperties` del chat existente
- [x] 3.1.4 Implementar prompt seguro: solo titulo/resumen/descripcion, sin credenciales, sin contenido completo
- [x] 3.1.5 Validar respuesta del proveedor; si incompleta (falta title o description), lanzar excepcion tipada
- [x] 3.1.6 Configurar timeout reutilizando la configuracion Gemini existente

**Archivos**: `admin-api/src/main/java/.../service/seo/SeoSuggestionService.java`, DTOs en `admin-api/src/main/java/.../dto/`
**Criterio**: Servicio genera title y description a partir de titulo+resumen+descripcion; timeout configurable; respuesta incompleta lanza error.

### 3.2 Backend — endpoint autenticado

- [x] 3.2.1 Crear `POST /api/admin/talento/publicaciones/seo` en `TalentoController` o controlador dedicado
- [x] 3.2.2 Proteger con `@PreAuthorize` equivalente a editar publicaciones (`TALENTO_PUBLICACIONES_EDITAR`)
- [x] 3.2.3 Validar entrada antes de invocar IA: 400 si excede limites o campos requeridos faltantes
- [x] 3.2.4 Devolver 503 si el proveedor IA falla o excede timeout
- [x] 3.2.5 No persistir la sugerencia; no loguear prompt completo ni tokens
- [x] 3.2.6 Usar ProblemDetail para errores, con correlation ID

**Archivos**: `admin-api/src/main/java/.../controller/TalentoController.java` (o nuevo controller)
**Criterio**: 200 con DTO valido en exito; 401 sin JWT; 403 sin permiso; 400 con entrada invalida; 503 con timeout/proveedor.

### 3.3 Backend — pruebas

- [x] 3.3.1 Prueba unitaria del servicio: mock de GeminiClient, verificar construccion de prompt y parseo de respuesta
- [x] 3.3.2 Prueba MockMvc del endpoint: exito (200), entrada invalida (400); autorizacion JWT/RBAC conserva la cadena existente y la falla de proveedor se cubre en servicio (503)
- [x] 3.3.3 Prueba de respuesta incompleta del proveedor: verificar que no se retorna DTO incompleto
- [ ] 3.3.4 Verificar que chat existente no cambia: pruebas existentes de chat pasan

**Archivos**: `admin-api/src/test/java/.../service/seo/SeoSuggestionServiceTest.java`, test del controller
**Criterio**: Todos los escenarios de la spec R3 cubiertos; suite de chat no regresa.

### 3.4 Frontend — integracion SEO en formulario

- [x] 3.4.1 Agregar boton "Generar con IA" en `publicacion-form.component.html` cerca de los campos SEO
- [x] 3.4.2 Implementar llamada HTTP al endpoint SEO desde el componente o servicio de talento
- [x] 3.4.3 Implementar estados: loading (spinner/deshabilitado), error (mensaje + retry), exito (rellena campos editables)
- [x] 3.4.4 Bloquear solicitudes duplicadas mientras carga
- [x] 3.4.5 La sugerencia rellena `seoTitle` y `seoDescription` sin sobrescribir cambios posteriores del usuario
- [x] 3.4.6 Retry solo por click del usuario; no hay retry automatico
- [x] 3.4.7 Guardar permanece disponible independientemente del estado de la IA

**Archivos**: `frontend/src/app/talento/pages/publicaciones/publicacion-form/publicacion-form.component.ts`, `.html`, `frontend/src/app/talento/services/talento.service.ts`
**Criterio**: Boton visible solo en edicion; loading muestra spinner; error muestra mensaje y retry; exito rellena campos; Guardar funciona sin IA.

### 3.5 Frontend — pruebas

- [x] 3.5.1 Prueba: boton genera SEO y campos se rellenan
- [x] 3.5.2 Prueba: timeout/error muestra mensaje y retry
- [x] 3.5.3 Prueba: respuesta incompleta no se trata como valida
- [x] 3.5.4 Prueba: Guardar funciona cuando IA falla
- [x] 3.5.5 Prueba: no se envian solicitudes duplicadas durante loading

**Archivos**: Tests de `publicacion-form.component.spec.ts` o archivo dedicado
**Criterio**: Cobertura de loading/error/retry/incompleto/independencia de Guardar.

### 3.6 Correcciones de revision del Slice 3

- [x] 3.6.1 Preservar `502 BAD_GATEWAY` exclusivamente para respuesta SEO incompleta tipada y mapear fallos de proveedor a `503 SERVICE_UNAVAILABLE`
- [x] 3.6.2 Mantener filtros Spring Security activos en `SeoSuggestionControllerTest` y cubrir `401` sin JWT, `403` sin permiso, `200` valido y `400` de validacion
- [x] 3.6.3 Usar Observables RxJS reales en la prueba frontend de error/reintento

**Archivos**: `admin-api/src/main/java/.../service/seo/SeoSuggestionService.java`, `admin-api/src/test/java/.../controller/SeoSuggestionControllerTest.java`, `frontend/src/app/talento/pages/publicaciones/publicacion-form/publicacion-form.component.spec.ts`
**Criterio**: Los hallazgos de la revision quedan cubiertos sin desactivar seguridad ni tocar slices posteriores.

---

## Phase 4: Portal editorial (PR 4)

**Objetivo**: Columna ~720px, media responsive, YouTube 16:9, X centrado, espaciado 20-32px.
**Dependencias**: PR 2 (slug estable para URL publica).
**Specs cubiertas**: `portal-editorial/spec.md` R3-R15, Aislamiento visual.

### 4.1 Layout editorial — columna y espaciado

- [x] 4.1.1 Ajustar la columna editorial aislada a `max-width: 720px` en `portal/src/styles/global.css`
- [x] 4.1.2 Verificar espaciado vertical entre bloques de 20px a 32px
- [x] 4.1.3 Verificar que las imagenes editoriales usan `max-width: 100%`, altura automatica y son responsive

**Archivos**: `portal/src/styles/global.css`
**Criterio**: A 1440px, la columna mide entre 696px y 744px; imagenes no exceden la columna.

### 4.2 Embeds — YouTube y X

- [x] 4.2.1 Verificar wrapper YouTube con `aspect-ratio: 16/9` y reserva de espacio
- [x] 4.2.2 Verificar que YouTube nunca excede la columna ni el viewport
- [x] 4.2.3 Verificar que cada embed X esta centrado dentro de la columna
- [x] 4.2.4 Verificar `overflow-wrap: anywhere` o equivalente para URLs largas en X
- [x] 4.2.5 Verificar fallback accesible cuando X o YouTube no carga

**Archivos**: `portal/src/styles/global.css`, `portal/src/components/islands/PublicContent.ts` (si aplica)
**Criterio**: YouTube mantiene 16:9; X centrado sin overflow; fallback accesible.

### 4.3 Responsive — movil

- [x] 4.3.1 Verificar a 320px: `scrollWidth <= clientWidth` (cero scroll horizontal)
- [x] 4.3.2 Verificar que imagenes y embeds respetan `max-width: 100%`
- [x] 4.3.3 Verificar que `prefers-reduced-motion` se respeta
- [x] 4.3.4 Verificar a 768px y 1440px

**Archivos**: `portal/src/styles/global.css`
**Criterio**: No scroll horizontal en 320px; imagenes y embeds responsive; reduced-motion respetado.

### 4.4 Aislamiento visual

- [x] 4.4.1 Verificar que estilos editoriales solo aplican a pagina de publicaciones
- [x] 4.4.2 Verificar que convocatorias, contacto y otras paginas no heredan la columna

**Archivos**: `portal/src/styles/global.css`, `portal/src/pages/publicaciones/[slug].astro`
**Criterio**: Otras paginas no cambian su ancho ni comportamiento.

### 4.5 Verificacion de borradores

- [x] 4.5.1 Verificar que publicacion DRAFT no se prerenderiza en portal
- [x] 4.5.2 Verificar que borradores no aparecen en sitemap ni metadata indexable

**Archivos**: `portal/src/pages/publicaciones/[slug].astro`
**Criterio**: DRAFT = 404; PUBLISHED = contenido + metadata SEO.

---

## Phase 5: Pruebas integradas y verificacion (PR 5)

**Objetivo**: Cobertura cruzada, no regresion, auditoria de permisos y documentacion.
**Dependencias**: PRs 1-4 completados.
**Specs cubiertas**: `testing/spec.md` R1-R5, `seguridad/spec.md` R1-R3.

### 5.1 Pruebas menu y RBAC

- [x] 5.1.1 Prueba: todos los items asignados a un grupo exacto; ningun huérfano
- [x] 5.1.2 Prueba: padre visible por descendiente autorizado
- [x] 5.1.3 Prueba: padre oculto cuando no hay hijos visibles
- [x] 5.1.4 Prueba: grupo activo se abre automaticamente
- [x] 5.1.5 Prueba: ruta directa sin permiso bloqueada por AuthGuard
- [x] 5.1.6 Prueba: persistencia localStorage restaura estado correctamente
- [x] 5.1.7 Verificacion ARIA: `aria-expanded`, `aria-controls`, foco visible, Enter/Space

**Archivos**: Tests en `frontend/src/app/shared/sidebar/` y `frontend/src/app/core/`
**Criterio**: Todos los escenarios de `menu-modulos/spec.md` R1-R5 cubiertos.

### 5.2 Pruebas publicaciones y slug

- [x] 5.2.1 Prueba: listado sin portada; portada conservada en modelo/formulario
- [x] 5.2.2 Prueba: normalizacion de slug (acentos, mayusculas, caracteres especiales)
- [x] 5.2.3 Prueba: fallback a `publicacion` cuando titulo sin caracteres validos
- [x] 5.2.4 Prueba: limite de 100 caracteres sin cortar token
- [x] 5.2.5 Prueba: colision secuencial usa sufijo determinista
- [ ] 5.2.6 Prueba: carrera concurrente no produce duplicados *(bloqueada: requiere MongoDB/Testcontainers; no se ejecuta por restriccion de no modificar datos)*
- [x] 5.2.7 Prueba: reintento agotado devuelve 409 con `SLUG_UNAVAILABLE`
- [x] 5.2.8 Prueba: update sin cambio de titulo conserva slug

**Archivos**: Tests en `public-api/src/test/java/` y `frontend/src/app/talento/`
**Criterio**: Todos los escenarios de `seo-slug/spec.md` R1-R2 y `publicaciones/spec.md` cubiertos.

### 5.3 Pruebas SEO IA

- [x] 5.3.1 Prueba contrato: exito retorna title+description no vacios
- [x] 5.3.2 Prueba: 400 con entrada invalida
- [x] 5.3.3 Prueba: 401 sin JWT
- [x] 5.3.4 Prueba: 403 sin permiso
- [x] 5.3.5 Prueba: 503 con timeout/falla proveedor
- [x] 5.3.6 Prueba: respuesta incompleta no se retorna como exito
- [x] 5.3.7 Prueba: chat existente no regresa (contrato inmutable)

**Archivos**: Tests en `admin-api/src/test/java/`
**Criterio**: Todos los escenarios de `seo-slug/spec.md` R3-R4 cubiertos; chat sin cambios.

### 5.4 Pruebas portal responsive

- [ ] 5.4.1 Verificacion a 320px: scrollWidth <= clientWidth *(no hay runtime browser en portal)*
- [ ] 5.4.2 Verificacion a 768px: columna within 696-744px *(no hay runtime browser en portal)*
- [ ] 5.4.3 Verificacion a 1440px: columna within 696-744px *(no hay runtime browser en portal)*
- [x] 5.4.4 Verificacion YouTube: aspect-ratio 16/9, max-width 100%
- [x] 5.4.5 Verificacion X: centrado, wrap de URLs largas, sin overflow
- [x] 5.4.6 Verificacion imagenes: responsive, alt util, max-width 100%
- [x] 5.4.7 Verificacion borradores: DRAFT = 404, no indexable

**Archivos**: Tests/checks de portal
**Criterio**: Todos los escenarios de `portal-editorial/spec.md` R3-R15 y `testing/spec.md` R4 cubiertos.

### 5.5 Auditoria de seguridad y no regresion

- [x] 5.5.1 Verificar que admin-api es unico borde autenticado para SEO
- [x] 5.5.2 Verificar que public-api no recibe credenciales administrativas
- [x] 5.5.3 Verificar que errores no filtran stack traces, prompts ni tokens
- [ ] 5.5.4 Ejecutar suite completa backend (admin-api + public-api) y confirmar exito *(bloqueada por restriccion de no modificar datos; requiere PostgreSQL/MongoDB aislados)*
- [x] 5.5.5 Ejecutar suite completa frontend y confirmar exito
- [x] 5.5.6 Verificar que chat existente mantiene autenticacion, contrato y proveedor

**Archivos**: Verificacion cruzada, sin cambios de codigo
**Criterio**: Todos los escenarios de `seguridad/spec.md` R1-R3 y `testing/spec.md` R5 cubiertos.

### 5.6 Documentacion de decisiones

- [x] 5.6.1 Confirmar que `design.md` refleja las decisiones tomadas
- [x] 5.6.2 Verificar que Open Questions del design estan cerradas o documentadas

**Archivos**: `openspec/changes/reorganizar-menu-modulos/design.md`
**Criterio**: Decisiones documentadas; open questions resueltas.

---

## Contracts

```yaml
status: tasks_created
executive_summary: >
  5 PRs encadenados de bajo riesgo individual (max ~370 lineas cada uno).
  PR1: Menu modular con accordion accesible y persistencia.
  PR2: Portada removida del listado, slug backend autoritativo con unicidad concurrente.
  PR3: Endpoint SEO con Gemini existente, UI editable resilient.
  PR4: Portal editorial con columna 720px, embeds responsive, aislamiento visual.
  PR5: Pruebas integradas, auditoria RBAC/seguridad, no regresion.
artifacts:
  - openspec/changes/reorganizar-menu-modulos/tasks.md
next_recommended: sdd-apply (iniciar PR1 — menu y navegacion)
risks:
  - area: RBAC
    risk: Reagrupar padres puede ocultar rutas con permisos existentes
    mitigation: Filtrado recursivo calcula hijos primero; guards independientes
  - area: Slug concurrencia
    risk: Carrera bajo alta escritura puede agotar 5 candidatos
    mitigation: Indice unico + retry determinista + 409 controlado
  - area: IA
    risk: Gemini timeout o respuesta incompleta
    mitigation: DTO estricto, loading/error/retry manual, Guardar independiente
  - area: Portal
    risk: Estilos globales afectan otras paginas
    mitigation: Selectores scoped a .article y pagina de publicaciones
skill_resolution: fallback-path
review_workload_forecast:
  total_estimated_lines: 1440
  max_single_pr_lines: 370
  budget: 800
  risk_level: low
  chained_prs_recommended: true
  size_exception_required: false
  slice_limits:
    pr1_menu: 260
    pr2_slug: 340
    pr3_seo: 370
    pr4_portal: 160
    pr5_testing: 310
```
