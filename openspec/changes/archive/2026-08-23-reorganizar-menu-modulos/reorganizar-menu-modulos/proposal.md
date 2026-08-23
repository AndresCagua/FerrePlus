# Proposal: Reorganizacion del menu por modulos y mejora editorial de publicaciones

## Intent

El menu administrativo actualmente mezcla rutas de dominios distintos en una lista plana y solo Talento tiene un submenu parcial. Esto dificulta encontrar funciones, no expresa la organizacion del negocio y puede producir inconsistencias entre visibilidad de menu, permisos y guards. Ademas, el flujo de publicaciones expone una portada innecesariamente en el listado, exige slug manual, no aprovecha la IA existente para preparar SEO y necesita una presentacion editorial mas consistente en el portal publico.

El cambio reorganiza la navegacion en cuatro modulos principales —Talento, Contabilidad, Bodega y Mantenimiento— sin cambiar URLs ni debilitar RBAC, y mejora slug, SEO y layout editorial con el menor cambio backend necesario.

## Scope

### In Scope

1. **Menu administrativo y RBAC**
   - Reagrupar la fuente unica `RUTAS_POR_PERMISO` en los cuatro modulos confirmados, conservando Dashboard como acceso directo y las rutas existentes.
   - Mantener filtrado recursivo: un padre de modulo se muestra solamente si tiene al menos un descendiente visible; el padre no requiere permiso operativo propio.
   - Implementar expansion/contraccion por click con estado cerrado inicialmente, apertura automatica del grupo de la ruta activa y persistencia local por usuario/dispositivo solo cuando no exponga permisos.
   - Hacer el control accesible con boton real, `aria-expanded`, `aria-controls`, nombre accesible, foco visible, teclado y soporte del sidebar colapsado.
   - Mantener guards y permisos por ruta hija; ocultar no sustituye la autorizacion backend.
   - La asignacion definitiva de rutas legacy que no tengan modulo confirmado se cerrara en `sdd-spec`/`sdd-design`; no se crea un quinto modulo `Operaciones` en este change.

2. **Publicaciones en Talento**
   - Eliminar solamente la columna y logica de `portada` del listado; conservar portada en modelo, formulario, API y portal publico.
   - Convertir el slug en un valor derivado del titulo: frontend muestra una previsualizacion no editable y backend es la autoridad final.
   - Normalizar slug en backend (minusculas, transliteracion de acentos, caracteres permitidos, guiones colapsados y limites definidos), generar sufijo determinista ante colision y respaldarlo con el indice unico MongoDB, incluyendo reintento seguro ante carreras.
   - No exigir que el usuario escriba slug manualmente; las ediciones que cambien titulo recalculan el valor antes de guardar.

3. **SEO con la IA existente**
   - Reutilizar el cliente/configuracion Gemini y el flujo de IA del chat en `admin-api`; no agregar proveedor, API key ni dependencia nueva.
   - Exponer un caso de uso administrativo autenticado para generar inicialmente `title` y `description` SEO a partir del contenido de la publicacion, con DTO estructurado, timeout y limites de entrada/salida.
   - Mantener ambos campos editables: generar solo propone valores, no sobrescribe cambios del usuario sin accion explicita y nunca guarda automaticamente.
   - Cubrir estados loading, error, retry y respuesta incompleta; el guardado manual sigue disponible si el servicio de IA falla, sujeto a las validaciones actuales.

4. **Portal publico editorial**
   - Ajustar CSS/SCSS, layout y presentacion para una columna central de aproximadamente 720px.
   - Aplicar un ancho de referencia coherente a imagenes y embeds, YouTube en relacion 16:9 y X centrado sin overflow.
   - Usar espaciado consistente de 20–32px y estrategia mobile-first sin scroll horizontal, preservando SSR/SEO, sanitizacion y media existente.
   - No rediseñar backend, CMS, analitica ni la identidad visual completa del portal; solo tocar API si slug o SEO lo requieren.

5. **Pruebas y entrega**
   - Agregar pruebas unitarias de filtrado jerarquico, visibilidad de padres, estado/persistencia del menu y accesibilidad observable.
   - Agregar pruebas de slug normalizado, colisiones, actualizacion y concurrencia/conflicto de unicidad; pruebas del endpoint IA con exito, timeout, error, retry y salida invalida.
   - Verificar que RBAC, guards, contratos de publicaciones, layout responsive y no-regresion del chat sigan funcionando.
   - Entregar mediante PRs encadenados y pequenos, alineados con `force-chained`.

### Out of Scope

- Crear un proveedor nuevo de IA, exponer credenciales al navegador o mover la propiedad del chat existente.
- Cambiar URLs de Angular, permisos existentes, roles, modelo general de RBAC o reglas de autorizacion del backend.
- Eliminar portada del modelo, formulario, almacenamiento o portal; se retira unicamente del listado administrativo.
- Rediseño integral del portal, nuevo sistema de diseño, nuevas paginas publicas, CMS general o analitica editorial.
- Migrar Angular de NgModule a standalone; se conserva la convencion actual de Angular 22 con feature modules y Reactive Forms.
- Crear un modulo `Operaciones`; el mapeo de rutas legacy sin agrupacion confirmada queda como decision previa a specs/design.

## Approach

### Limites por fase

1. **PR 1 — Menu y navegacion**: modificar solo el mapa de rutas, sidebar, estilos y pruebas de RBAC/navegacion. No mezclar cambios de publicaciones.
2. **PR 2 — Talento listado y slug**: retirar portada del listado y hacer backend autoritativo el slug, incluyendo contrato, indice/reintento y pruebas.
3. **PR 3 — SEO IA**: agregar el caso de uso en `admin-api`, endpoint autenticado, UI de propuesta editable y estados de loading/error/retry.
4. **PR 4 — Portal editorial**: cambios aislados de Astro/CSS/SCSS/layout y pruebas responsive/embeds. Solo incluir ajustes de DTO/API si son imprescindibles para slug/SEO.
5. **PR 5 — Integracion y verificacion**: pruebas cruzadas, builds, auditoria de permisos y documentacion de decisiones; depende de los cuatro PR anteriores.

### Decisiones de arquitectura

- **Fuente unica y dependencia hacia el dominio**: `RUTAS_POR_PERMISO` continua siendo el mapa compartido por sidebar, `AuthService` y `AuthGuard`. La agrupacion es una preocupacion de navegacion, no una segunda lista de permisos.
- **Padres sin permiso operativo**: el filtrado calcula primero los descendientes y despues conserva el padre si el conjunto visible no esta vacio. `permissions` del padre puede quedar vacio; cada ruta protegida mantiene su `data.permissions` y autorizacion server-side.
- **Estado del menu**: estado local del componente, persistencia de expansion en `localStorage` con claves no sensibles y restauracion condicionada a que el grupo siga teniendo hijos visibles. La ruta activa tiene prioridad sobre la preferencia guardada.
- **Slug**: el dominio de publicaciones en `public-api` genera y valida el slug dentro del servicio de aplicacion; el controller permanece delgado, el DTO no confia en el valor del cliente y el indice unico MongoDB es la ultima barrera. Se debe definir en design si el sufijo usa contador (`-2`) o hash corto; se recomienda contador determinista legible.
- **IA**: `admin-api` es el borde autenticado que reutiliza el cliente del chat/Gemini existente. `public-api` conserva ownership de publicaciones y no recibe una credencial nueva. El endpoint devuelve una sugerencia tipada; la persistencia solo ocurre cuando el usuario guarda la publicacion.
- **Resiliencia**: timeout corto, error tipado y retry explicito para IA; no retry automatico que duplique costos. Se registra correlation ID y metadatos seguros, nunca prompt completo sensible, token o credencial. Un fallo de IA no bloquea la edicion manual.
- **Frontend**: seguir NgModules, Reactive Forms, Material/Bootstrap y `ChangeDetectionStrategy.OnPush` donde ya aplique; no introducir una migracion arquitectonica oportunista. Los controles interactivos deben cumplir WCAG AA, keyboard navigation y estados loading/error/empty.
- **Presentacion**: la columna de lectura y la consistencia de embeds se resuelven con CSS/layout responsive, preservando contenido y contratos existentes. Se priorizan reserva de espacio para media, `max-width: 100%`, `aspect-ratio` para YouTube y prevencion explicita de overflow en X.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `frontend/src/app/core/rutas-por-permiso.ts` | Modified | Agrupacion en cuatro modulos, permisos agregados solo para visibilidad derivada y preservacion de URLs/prioridad. |
| `frontend/src/app/shared/sidebar/` | Modified | Accordion de modulos, estado inicial/persistencia, ruta activa, ARIA, teclado y estilos. |
| `frontend/src/app/app-routing.module.ts`, `frontend/src/app/core/auth.service.ts` | Verified/possibly modified | Mantener `data.permissions`, redirect post-login y compatibilidad con padres virtuales. |
| `frontend/src/app/talento/pages/publicaciones/publicacion-list/` | Modified | Retirar columna `portada` y helpers asociados sin tocar el modelo. |
| `frontend/src/app/talento/pages/publicaciones/publicacion-form/`, `frontend/src/app/talento/services/` | Modified | Previsualizacion de slug, generacion SEO, estados de IA y contrato de guardado. |
| `admin-api/src/main/java/.../service/chat/` y controller/DTOs de Talento | Modified | Reutilizar IA Gemini existente mediante caso de uso autenticado para sugerencias SEO; sin proveedor nuevo. |
| `public-api/src/main/java/.../service/PublicacionService.java`, DTOs, repository/model | Modified | Normalizacion/unicidad de slug y contrato minimo para SEO si el diseño confirma que el ownership requiere este borde. |
| `portal/src/pages/publicaciones/[slug].astro`, `portal/src/components/islands/PublicContent.ts`, `portal/src/styles/global.css` | Modified | Columna ~720px, media consistente, YouTube 16:9, X centrado y responsive sin overflow. |
| `frontend/src/app/**/**.spec.ts`, `admin-api/src/test/**`, `public-api/src/test/**`, portal checks | New/Modified | Cobertura de RBAC, menu, slug, IA, resiliencia y layout. |
| `openspec/changes/reorganizar-menu-modulos/` | New/Modified | Proposal actual y siguientes artefactos spec/design/tasks. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Reagrupar padres altera la prioridad de home o deja rutas sin modulo | Medium | Conservar orden de hijos, validar matriz completa y cerrar el mapeo legacy antes de `sdd-spec`; probar `getHomeRoute()` y URL directa. |
| Un padre visible revela la existencia de un modulo a un usuario sin permiso propio | Low | Renderizar padre solo despues del filtrado recursivo de hijos; no calcular visibilidad por nombre de rol. |
| Colisiones de slug bajo escrituras concurrentes | Medium | Normalizacion centralizada, indice unico, sufijo determinista y retry acotado ante duplicate key; probar create/update concurrente. |
| IA lenta, caida o devuelve contenido inseguro/incompleto | Medium | DTO estricto, limites, timeout, validacion, loading/error/retry, sin auto-guardado y fallback a edicion manual. |
| Mezclar ownership admin-api/public-api rompe aislamiento | Medium | Mantener IA en admin-api y publicaciones en public-api; documentar contrato y no agregar conexiones de datos cruzadas. |
| Embeds X o contenido largo generan overflow/CLS en movil | Medium | `max-width: 100%`, wrapper aislado, aspect ratio, reserva de espacio y pruebas en viewport movil; respetar reduced motion. |
| PRs demasiado acoplados dificultan rollback | Low | Force-chained por fase, cada PR compilable y con pruebas de su limite; PR de integracion al final. |

## Rollback Plan

Revertir los PRs en orden inverso, comenzando por integracion, portal, IA, slug/listado y finalmente menu. El rollback de menu restaura el mapa plano y sidebar previo sin cambiar permisos ni URLs. El rollback de IA elimina solo el endpoint y UI de sugerencias; no afecta el chat existente. El rollback de slug restaura el contrato anterior, pero no revierte slugs ya persistidos: los documentos modificados conservaran sus valores hasta una migracion/revision explicita. No se ejecutan operaciones de base de datos automaticamente; cualquier correccion de datos o indice se entrega como script revisable por el usuario.

## Dependencies

- Exploracion existente en `openspec/changes/reorganizar-menu-modulos/exploration.md`.
- Configuracion OpenSpec y especificaciones vigentes de `portal-publico-talento` y `chat-analiticas`.
- Angular 22 existente con NgModules, Angular Material, Bootstrap y Reactive Forms.
- Spring Boot 3.5.16/Java 21, MongoDB para publicaciones y el indice unico existente de `slug`.
- Cliente/configuracion Gemini y controles de autenticacion, RBAC, ProblemDetail y correlation ID ya presentes en `admin-api`.
- No se agrega proveedor externo, migracion de esquema obligatoria ni dependencia de infraestructura nueva.

## Success Criteria

- [ ] El menu muestra Talento, Contabilidad, Bodega y Mantenimiento como grupos colapsables; un padre sin hijos visibles no aparece y cada ruta hija conserva su RBAC/guard.
- [ ] Los grupos inician cerrados salvo el grupo de la ruta activa, permiten click/teclado, exponen ARIA correcto y persisten/restauran preferencia sin mostrar permisos indebidos.
- [ ] La tabla de publicaciones ya no contiene `portada`, mientras formulario, modelo, API y portal siguen soportandola.
- [ ] Crear o editar una publicacion produce un slug normalizado y unico desde backend sin entrada manual; colisiones y carreras no generan duplicados.
- [ ] La IA existente genera una propuesta de titulo y descripcion SEO con loading/error/retry; el usuario puede editarla y guardar solo tras confirmacion manual; una falla de IA no bloquea el formulario.
- [ ] El portal usa una columna editorial cercana a 720px, media coherente, YouTube 16:9, X centrado sin overflow, espaciado 20–32px y cero scroll horizontal en movil.
- [ ] Las pruebas unitarias, de contrato, RBAC, resiliencia y responsive definidas por fase pasan; no se agregan proveedores, secretos, permisos globales ni cambios fuera del alcance.
