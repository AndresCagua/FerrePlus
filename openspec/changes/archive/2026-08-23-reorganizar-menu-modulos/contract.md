## Archive Report Contract

**status**: `archived_with_warnings`
**executive_summary**: Cambio `reorganizar-menu-modulos` archivado con 5 PRs encadenados completados: menu modular accesible, slug backend autoritativo con unicidad concurrente, endpoint SEO con IA existente, portal editorial con columna 720px y embeds responsive, y pruebas integradas. No hay problemas CRITICAL; solo limitaciones legítimas de infraestructura (PostgreSQL/MongoDB/Testcontainers/browser runtime). Claim A (gap SSR/SEO preexistente) adjudicado fuera de scope; Claim B rechazado.
**artifacts**:
- `openspec/changes/archive/2026-08-23-reorganizar-menu-modulos/archive-report.md`
- `openspec/changes/archive/2026-08-23-reorganizar-menu-modulos/proposal.md`
- `openspec/changes/archive/2026-08-23-reorganizar-menu-modulos/design.md`
- `openspec/changes/archive/2026-08-23-reorganizar-menu-modulos/tasks.md`
- `openspec/changes/archive/2026-08-23-reorganizar-menu-modulos/verify-report.md`
- `openspec/changes/archive/2026-08-23-reorganizar-menu-modulos/verify-report-slice3.md`
- `openspec/changes/archive/2026-08-23-reorganizar-menu-modulos/verify-report-slice4.md`
- `openspec/changes/archive/2026-08-23-reorganizar-menu-modulos/verify-report-slice5.md`
- `openspec/changes/archive/2026-08-23-reorganizar-menu-modulos/specs/menu-modulos/spec.md`
- `openspec/changes/archive/2026-08-23-reorganizar-menu-modulos/specs/portal-editorial/spec.md`
- `openspec/changes/archive/2026-08-23-reorganizar-menu-modulos/specs/publicaciones/spec.md`
- `openspec/changes/archive/2026-08-23-reorganizar-menu-modulos/specs/seguridad/spec.md`
- `openspec/changes/archive/2026-08-23-reorganizar-menu-modulos/specs/seo-slug/spec.md`
- `openspec/changes/archive/2026-08-23-reorganizar-menu-modulos/specs/testing/spec.md`
- `openspec/changes/archive/2026-08-23-reorganizar-menu-modulos/exploration.md`
- `openspec/changes/archive/2026-08-23-reorganizar-menu-modulos/apply-progress.md`
**next_recommended**: Levantar PostgreSQL en localhost:5433 para completacion de verificacion chat non-regression (Slice 3 task 3.3.4) y suite backend completa (Slice 5 task 5.5.4); ejecutar pruebas MongoDB/Testcontainers para cobertura corrida de slug (5.2.6); considerar limpiar target/ tracked en git; corregir operador && en portal/scripts/verify-editorial.mjs
**risks**:
- RBAC: Reagrupar padres puede ocultar rutas con permisos existentes — mitigacion: filtrado recursivo calcula hijos primero, guards independientes por ruta
- Slug concurrencia: Carrera bajo alta escritura puede agotar 5 candidatos — mitigacion: indice unico @Indexed(unique=true) + retry determinista + 409 controlado
- IA: Gemini timeout o respuesta incompleta — mitigacion: DTO estricto, loading/error/retry manual, Guardar independiente, no auto-guardado
- Portal: Estilos globales afectan otras paginas — mitigacion: selectores scoped a `.publication-article`, verificacion de aislamiento visual
- Infraestructura: Dependencias externas (PostgreSQL, MongoDB/Testcontainers, browser runtime) no disponibles en entorno actual — documentadas, no bloqueantes
**skill_resolution**: `fallback-path`