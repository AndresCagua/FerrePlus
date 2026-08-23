# Archive Report: Portal Publico y Gestion de Talento

**Change**: `portal-publico-talento-arquitectura-aislada`
**Archive date**: 2026-08-22
**Verdict**: `PASS_WITH_WARNINGS`
**Artifact backend**: `openspec`

## Executive Summary

The change is ready to archive as an implemented change with documented verification warnings. The isolated `admin-api`/`public-api` boundary, Astro portal, Angular talent module, S2S security, CAPTCHA, storage, notifications and Compose topology are present. Archive does not imply that every planned verification is complete.

## Implementation Summary

- `public-api` owns MongoDB, Redis and MinIO; `admin-api` remains PostgreSQL-only.
- Public and internal contracts are separated, with S2S JWT validation, correlation IDs, ProblemDetail errors and safe diagnostics.
- Publications, convocatorias, applications, CV validation/private storage, contacts, recipients and asynchronous mail flows are implemented.
- Angular talent management uses NgModule/lazy routing, RBAC, typed admin client, forms, CV proxy download and the required unavailable-service fallback.
- Astro provides public content pages, SEO metadata, sitemap/robots behavior, progressive forms, Turnstile integration and accessible light/dark themes.
- Docker Compose and Traefik define isolated networks, healthchecks, resource limits, profiles and non-public data services.

## Verification Evidence

- `docker compose --env-file .env config`: passed.
- Docker builds for `public-api` and `admin-api`: passed according to the verification evidence.
- Portal `npm run check && npm run build`: passed according to the verification evidence.
- Focused `public-api`, `PublicApiClientTest`, Angular and security/rate-limit tests: present and reported passing.
- Compose critical services reported healthy; internal Actuator health reported `UP`.
- Authenticated Mongo smoke check passed without modifying data.
- `git diff --check`: passed.
- No commits, database writes, destructive volume operations or secret output were performed.

## Known Limitations

- Full `admin-api` suite is blocked by unavailable local PostgreSQL at `localhost:5433`.
- No reproducible `smoke/` end-to-end flow was found; publication, application, CV download, state transition, contact, mail and log tracing were not verified together.
- Astro has no dedicated automated test files/fixtures for SEO, sitemap exclusion and form behavior.
- `astro:assets` optimization and API-proxy cache policy are incomplete relative to the design.
- Scheduled orphan-object cleanup was not confirmed.
- The repository contains only ADRs 001-002 for this change; the full ADR-1..12 set and a complete threat/ownership/network documentation set were not found.

## Task Status

`tasks.md` now records 73 implementation-backed tasks as `completed`, 9 as `partial`, and 8 as `pending` state lines. Partial and pending states are deliberate and preserve the verification gaps; they are not treated as successful test results.

## Next Steps

1. Provide PostgreSQL on the configured local test endpoint and run the complete `admin-api` suite.
2. Execute and preserve a reproducible end-to-end smoke test with non-secret test data.
3. Add Astro fixture/build tests, including draft exclusion, SEO, forms and themes.
4. Complete `astro:assets`, API cache headers, orphan cleanup scheduling and the missing architecture/ADR documentation.

## Archive Contents

- `proposal.md`
- `spec.md`
- `design.md`
- `tasks.md` (reconciled status)
- `verify-report.md`
- `archive-report.md`

## Skill Resolution

| Skill | Loaded | Applied |
|---|---:|---:|
| `sdd-archive` | yes | openspec merge, archive and post-move checks |
| `sdd-verify` | yes | evidence-based task and verification status |
| `cognitive-doc-design` | yes | outcome-first, scannable archive report |

## Result Contract

```yaml
status: archived_with_warnings
executive_summary: Implementacion archivada; advertencias de pruebas y documentacion preservadas.
artifacts:
  - openspec/changes/archive/2026-08-22-portal-publico-talento-arquitectura-aislada/
  - openspec/specs/portal-publico-talento/spec.md
next_recommended: Ejecutar las verificaciones pendientes antes de declarar el change completamente validado.
risks:
  - Suite completa de admin-api no ejecutada por dependencia PostgreSQL local.
  - Smoke end-to-end y pruebas Astro ausentes.
```
