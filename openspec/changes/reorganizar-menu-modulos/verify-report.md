# Verify Report — Slice 2 (Talento listado y slug)

**Date**: 2026-08-23
**Change**: reorganizar-menu-modulos
**Slice**: Phase 2 — Talento listado y slug (PR 2)
**Verdict**: PASSED

## Tasks Completeness

All 12 tasks in Phase 2 marked [x]: 2.1.1–2.1.4, 2.2.1–2.2.3, 2.3.1–2.3.5, 2.4.1–2.4.3, 2.5.1–2.5.4.

## Requirements Verification

| Req | File | Check | Result |
|-----|------|-------|--------|
| Slug max 100 no extreme hyphens | PublicacionService.java:29,140-156 | `MAX_SLUG_LENGTH=100`, strip `^-+\|-$`, token-boundary loop, tests 93-108 | CUMPLE |
| Fallback | PublicacionService.java:144 | `normalized.isBlank() → "publicacion"`, test line 89 | CUMPLE |
| Retry/409 | PublicacionService.java:123-138 | `persist()` 5 attempts, `DuplicateKeyException` catch, `SLUG_UNAVAILABLE`, test lines 119-128 | CUMPLE |
| Unicidad | Publicacion.java:17 | `@Indexed(unique = true) private String slug` | CUMPLE |
| Update conserva slug | PublicacionService.java:55-58 | `titleChanged ? normalizarSlug() : existing.getSlug()`, test lines 130-141 | CUMPLE |
| Eliminación portada listado | publicacion-list.component.html:11 | Columnas `['titulo','estado','acciones']` — sin portada | CUMPLE |
| Sin helpers portada | publicacion-list.component.ts | Sin `portadaUrl()`, `portadaFailed()`, `failedPortadas` | CUMPLE |
| Backend autoritativo slug | PublicacionAdminDTO.java | Sin campo `slug`; `from()` no lee slug del DTO; `setSlug` solo en `persist()` | CUMPLE |
| Frontend preview slug | publicacion-form.component.ts:8-16, html:7 | `normalizarSlug()` espejo backend, campo `readonly` | CUMPLE |
| Form envía slug, backend ignora | publicacion-form.component.ts:35 | Payload incluye `slug`, DTO no lo recibe | CUMPLE |

## Scenarios Covered

| Scenario | Source | Test |
|----------|--------|------|
| Acentos y mayúsculas normalizados | seo-slug/spec R1 | `normalizarSlug("Talento: Niño Técnico / Bogotá")` → `talento-nino-tecnico-bogota` |
| Fallback símbolos | seo-slug/spec R1 | `normalizarSlug("***")` → `publicacion` |
| Límite 100 sin corte de token | seo-slug/spec R1 | `"a".repeat(120)` → tamaño 100 sin hyphens extremos |
| Token completo preservado | seo-slug/spec R1 | `"a".repeat(96) + " segundo-token"` → solo `"a".repeat(96)` |
| Colisión usa sufijo determinista | seo-slug/spec R2 | 1 DuplicateKeyException → `talento-nino-2` |
| Título sin cambio conserva slug | seo-slug/spec R2 | `actualizar("1", ...)` con mismo título → `slug-final` intacto |
| Listado sin portada | publicaciones/spec R1 | Template sin columna, sin helpers |

## Design Coherence

| Decision | Status |
|----------|--------|
| Slug backend autoritativo, DTO sin campo slug | SEGUIDA |
| `normalizarSlug()` centralizado en service | SEGUIDA |
| `@Indexed(unique=true)` en modelo | SEGUIDA |
| Frontend preview readonly, misma lógica | SEGUIDA |
| Portada eliminada solo del listado, no del modelo | SEGUIDA |

## Test Quality

| File | Type | Non-placeholder? |
|------|------|-----------------|
| publicacion-list.component.spec.ts | Unit | SÍ — verifica ausencia real de portada en template y prototype |
| publicacion-form.component.spec.ts | Unit | SÍ — verifica normalización, preservación portada, validación imagen |
| PublicacionServiceTest.java | Unit | SÍ — 8 tests: normalización, fallback, límite, tokens, colisión, update |

## ConvocatoriaAdminDTOTest

`git diff 1c91c028..HEAD -- ConvocatoriaAdminDTOTest.java` → vacío.
El test NO fue modificado por Slice 2. El fallo es **preexistente** y no relacionado.

## Issues

No CRITICAL, no WARNING.
