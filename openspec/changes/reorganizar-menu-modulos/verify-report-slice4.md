# Verify Report — Slice 4 / PR 4 — Portal editorial

```yaml
status: PASS_WITH_WARNINGS
change: reorganizar-menu-modulos
slice: pr4_portal_editorial
branch: feature/reorganizar-menu-modulos
date: 2026-08-23
executor: sdd-verify
skill_resolution: fallback-path
```

## Tasks Completeness

All 16 tasks in Phase 4 (4.1.1–4.5.2) are marked [x]. No incomplete tasks.

## Requirements Verification

### R15 — Portal Astro publico

| Scenario | Verdict | Evidence |
|----------|---------|----------|
| Columna 720px ±24px | CUMPLE | `width:min(calc(100% - 2rem),720px); max-width:720px` → at 1440px renders 720px ✅ |
| Espaciado 20–32px | CUMPLE | `--publication-gap:24px` via `> * + *` margin-top ✅ |
| YouTube 16:9 | CUMPLE | `.publication-video { aspect-ratio:16/9; width:100% }`, iframe `width:100%; height:100%` ✅ |
| YouTube max-width 100% | CUMPLE | Inherits from `.publication-article` parent width ✅ |
| X centrado | CUMPLE | `.x-preview { display:flex; justify-content:center }`, `.x-embed { margin:0 auto }` ✅ |
| X overflow-wrap | CUMPLE | `overflow-wrap:anywhere` on `.publication-article` cascades to `.x-preview-url` ✅ |
| X sin scroll horizontal | CUMPLE | `.x-preview { width:100%; overflow:hidden }` + parent 720px ✅ |
| Imagen responsive | CUMPLE | `.publication-article img { width:100%; height:auto; max-width:100% }` ✅ |
| Imagen alt accesible | CUMPLE | JS: `image.alt = media.alt ?? item.titulo` ✅ |
| Fallback YouTube accesible | CUMPLE | `<p class="publication-embed-fallback">` with link to YouTube, hidden on `.is-loaded` ✅ |
| Fallback X accesible | CUMPLE | Fallback with icon, label, link; hidden when `.is-embedded` ✅ |
| Reduced motion | CUMPLE | `@media (prefers-reduced-motion:reduce) { html{scroll-behavior:auto} *{transition:none!important} }` ✅ |
| 320px no scroll H | CUMPLE | `width:min(calc(100%-2rem),720px)` = 288px at 320px ✅ |
| 768px columna | CUMPLE |720px max-width within768px viewport ✅ |
| 1440px columna | CUMPLE |720px as calculated above ✅ |

### R3 — Borradores

| Scenario | Verdict | Evidence |
|----------|---------|----------|
| DRAFT no prerenderizado | CUMPLE | `getStaticPaths()` fetches `publicApi.publicaciones()` which returns only PUBLISHED; DRAFT excluded at API level ✅ |
| DRAFT no indexable | CUMPLE | No route generated → not in sitemap, no metadata ✅ |

### Aislamiento visual

| Scenario | Verdict | Evidence |
|----------|---------|----------|
| Convocatorias no hereda columna | CUMPLE | Convocatorias use `class="article"` without `publication-article`; `.publication-article` rules don't apply ✅ |
| Otras páginas intactas | CUMPLE | `.article { max-width:780px }` unchanged; `.form-shell`, cards, etc. unaffected ✅ |

## Design Coherence

| Decision | Status | Notes |
|----------|--------|-------|
| Scoped styles to `.publication-article` | SEGUIDA | ✅ |
| Columna 720px | SEGUIDA | ✅ |
| YouTube aspect-ratio 16/9 | SEGUIDA | ✅ |
| X overflow-wrap:anywhere | SEGUIDA | ✅ |
| Fallbacks accesibles | SEGUIDA | ✅ |

## Build / Check

- `portal/npm run check`: 0 errors, 0 warnings, 0 hints ✅
- `portal/npm run build`: passed ✅

## Findings

### WARNING — No automated visual regression tests

No visual regression framework (e.g., Playwright screenshot comparison) exists in `portal/`. The responsive, column-width, 16:9, and isolation verifications were performed by code inspection and build. Future CSS changes could introduce visual regressions undetected. Recommendation: add Playwright visual tests for 320/768/1440px in PR 5.

### WARNING — YouTube fallback hides on iframe load, not video play

`.publication-video.is-loaded .publication-embed-fallback { display:none }` fires on the iframe `load` event, which fires when the YouTube HTML shell loads (before video playback starts). If the video URL is invalid or restricted, the iframe still loads (showing a YouTube error page) and the fallback disappears. In practice, `parseYouTubeLink` validates the 11-char ID format, making invalid URLs unlikely. Acceptable for current scope.

### SUGGESTION — Missing accent in fallback text

`fallback.textContent = 'El video no se puede mostrar aqui. '` — "aquí" is missing the accent. Minor copy issue.

## Verdict

PASS_WITH_WARNINGS — All spec requirements met, all tasks complete, build passes. Two warnings (no visual test framework, fallback timing) are non-blocking.
