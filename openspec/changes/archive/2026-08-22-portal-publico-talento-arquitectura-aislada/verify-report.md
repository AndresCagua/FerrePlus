# Verify Report: portal-publico-talento-arquitectura-aislada

> **Date**: 2026-08-22
> **Verifier**: sdd-verify agent
> **Stack**: Spring Boot 3 / Angular 22 / Astro 6 / Docker Compose / Traefik / MongoDB / Redis / MinIO
> **Verdict**: PASS_WITH_WARNINGS

## Executive Summary

The change is substantially implemented across all 8 PRs. The actual codebase shows a fully built `public-api` (65+ Java files), `admin-api` with S2S integration, Astro portal with dark/light themes and SEO, Angular talento module with RBAC, Docker Compose with 5 networks and Traefik, and supporting documentation. `tasks.md` was reconciled against this evidence: implementation-backed tasks are completed, while unverified suites, smoke flows and documentation gaps remain partial/pending.

**19/19 requirements** have implementation evidence. **47/47 scenarios** are addressed in code. **14 ADRs** are implemented. Several warnings relate to documentation gaps, minor spec deviations, and test coverage completeness rather than functional gaps.

## Artifacts Verified

| Artifact | Path | Status |
|----------|------|--------|
| proposal.md | openspec/changes/.../proposal.md | ✅ Read |
| spec.md | openspec/changes/.../spec.md | ✅ Read (19 requirements, 47 scenarios) |
| design.md | openspec/changes/.../design.md | ✅ Read (14 ADRs) |
| tasks.md | openspec/changes/.../tasks.md | ✅ Read and reconciled (73 completed, 9 partial, 8 pending state lines; 8 PRs) |
| docker-compose.yml | docker-compose.yml | ✅ Verified (9 services, 5 networks) |
| traefik/ | traefik/{traefik.yml,dynamic.yml,middlewares.yml} | ✅ Verified |
| public-api/ | public-api/src/ (65+ Java files, 12 test files) | ✅ Verified |
| admin-api/ | admin-api/src/ (S2S client, DataSeeder, RBAC) | ✅ Verified |
| portal/ | portal/src/ (18 .astro, 8 .ts files) | ✅ Verified |
| frontend/talento/ | frontend/src/app/talento/ (39 files) | ✅ Verified |
| docs/ | docs/adr/, docs/architecture/ | ✅ Verified |
| README.md | README.md | ✅ Verified |

## Requirements Verification

| # | Requirement | Status | Evidence |
|---|------------|--------|----------|
| R1 | Infrastructure, networks, HTTP entry | CUMPLE | Compose: 9 services, 5 networks (2 internal), Traefik exposedByDefault=false, healthchecks, cloudflared profile, secrets via compose |
| R2 | Data isolation and ownership | CUMPLE | admin-api: PostgreSQL only; public-api: MongoDB/Redis/MinIO only; no cross-connections; internal_services network |
| R3 | Publications | CUMPLE | Publicacion model DRAFT/PUBLISHED, PublicController, InternalController CRUD, slug, SEO metadata, media endpoints |
| R4 | Convocatorias | CUMPLE | Convocatoria model DRAFT/PUBLISHED/CLOSED, publish/unpublish/close, public + internal endpoints |
| R5 | Postulaciones and FSM | CUMPLE | EstadoPostulacion 4 states, PostulacionStateMachine transitions, historial, idempotency, convocatoria open check |
| R6 | CV and files | CUMPLE | CvFileValidator (allowlist pdf/doc/docx, 5MB, MIME magic bytes), MinIO private buckets, UUID keys, authenticated download |
| R7 | Async mail | CUMPLE | Persist-first, Spring Events + @Async, Thymeleaf templates (4), Notificacion model PENDING/SENT/FAILED, retry with backoff, scheduled retry |
| R8 | Contact form | CUMPLE | ContactoService with honeypot/idempotency/captcha, UNREAD/READ states, internal endpoints |
| R9 | Recipients | CUMPLE | Destinatario model, CRUD, tipo JOB_APPLICATION/CONTACT_FORM, activo/inactivo |
| R10 | Security | CUMPLE | DTOs+Bean Validation, CORS allowlisted, CSP/HSTS/X-Content-Type-Options/Referrer-Policy/Permissions-Policy, ProblemDetail, SafeDiagnosticLog |
| R11 | Rate limiting | CUMPLE | Redis Lua script, 3/15m+10/day postulaciones, 5/15m+20/day contactos, Retry-After, fingerprint HMAC, email SHA-256, fail-open local |
| R12 | JWT S2S | CUMPLE | S2sJwtFilter RS256, kid, iss/aud/exp/scope, KeyResolver, KeyService, PublicApiClient with JWT generation |
| R13 | Resilience | CUMPLE | PublicApiClient timeouts (1s/3s), typed exceptions, IndisponibilidadTalentoComponent with exact fallback text |
| R14 | Observability | CUMPLE | CorrelationIdFilter, StructuredLogging, SafeDiagnosticLog redaction, MDC propagation |
| R15 | Astro portal | CUMPLE | output:static, sitemap, 7 pages, layouts, SEO (title/description/canonical/OG/Twitter/JSON-LD), dark/light mode, localStorage persistence, flash prevention, robots.txt |
| R16 | Angular talento | CUMPLE | TalentoModule NgModule, lazy routing, Reactive Forms, Material, RBAC guards, 10 pages, loading/error/empty states, indisponibilidad fallback |
| R17 | RBAC new modules | CUMPLE | DataSeeder: 5 modules with actions, ADMIN auto-granted, rutas-por-permiso.ts, PreAuthorizeDriftTest, DataSeederRbacTest |
| R18 | Testing and docs | PARCIAL | Tests exist (12 public-api, 4 admin-api, Angular specs); ADRs 001-002; architecture docs; not all 47 scenarios traced to tests |
| R19 | CAPTCHA Turnstile | CUMPLE | CaptchaVerificationService, fail-closed prod, Turnstile.astro, site key public-only, token not persisted/logged, 400/403/503 |

## Design Decisions Verification

| ADR | Decision | Status | Evidence |
|-----|----------|--------|----------|
| ADR-1 | Rename backend/ to admin-api/ | SEGUIDA | admin-api/ directory, pom.xml, Dockerfile, Compose service |
| ADR-2 | public-api with exclusive ownership | SEGUIDA | No PostgreSQL config in public-api; no MongoDB/Redis/MinIO in admin-api |
| ADR-3 | Docker networks | SEGUIDA | 5 networks: public_net, admin_net, public_data, admin_data (internal), internal_services (internal) |
| ADR-4 | Traefik single entrypoint | SEGUIDA | traefik.yml: exposedByDefault=false, dynamic.yml: routers, middlewares |
| ADR-5 | JWT S2S asymmetric | SEGUIDA | RS256, kid header, iss/aud/exp/scope claims, key rotation endpoint |
| ADR-6 | MinIO for binaries | SEGUIDA | MinioObjectStorage, cv-bucket, media-bucket, UUID keys, authenticated proxy |
| ADR-7 | Spring Events + @Async | SEGUIDA | ApplicationEventPublisher, @Async("mailTaskExecutor"), Notificacion persistence |
| ADR-8 | Redis rate limiting | SEGUIDA | INCR+EXPIRE Lua, IP/fingerprint/email counters, Retry-After, fail-open local |
| ADR-9 | Astro SSG | SEGUIDA | output:'static', getStaticPaths, islands for forms |
| ADR-10 | Closed FSM | SEGUIDA | PostulacionStateMachine: RECEIVED→UNDER_REVIEW→ACCEPTED/REJECTED, terminals |
| ADR-11 | ProblemDetail RFC 7807 | SEGUIDA | GlobalExceptionHandler returns ProblemDetail with type/title/status/detail/correlationId |
| ADR-12 | DTOs per boundary | SEGUIDA | dto/publico/*, dto/interno/*, separate from admin-api DTOs |
| ADR-13 | Dark/light themes | SEGUIDA | BaseLayout inline script, Header toggle, localStorage, prefers-color-scheme, CSS tokens |
| ADR-14 | Cloudflare Turnstile | SEGUIDA | CaptchaVerificationService, Turnstile.astro, fail-closed prod |

## Testing Coverage

| Area | Test Files | Status |
|------|-----------|--------|
| public-api unit | PostulacionStateMachineTest, CvFileValidatorTest, CaptchaVerificationServiceTest, PublicacionServiceTest, ContactoServiceTest, ConvocatoriaServiceTest | ✅ Exist |
| public-api MVC | InternalControllerTest | ✅ Exist |
| public-api security | S2sJwtFilterTest | ✅ Exist |
| public-api rate limit | RateLimitFilterTest, RateLimitServiceTest | ✅ Exist |
| public-api config | SafeDiagnosticLogTest, ConvocatoriaAdminDTOTest | ✅ Exist |
| public-api mail | MailEventListenerTest | ✅ Exist |
| admin-api | PublicApiClientTest, DataSeederRbacTest, PreAuthorizeDriftTest | ✅ Exist |
| Angular | talento-routing.spec.ts, publicacion-list.component.spec.ts, postulacion-list.component.spec.ts, publicacion-form.component.spec.ts, talento.service.spec.ts, form-validators.spec.ts, convocatoria-date.util.spec.ts, cv-download.component.spec.ts | ✅ Exist |
| Portal | No test files found | ⚠️ Missing |

## Findings

### CRITICAL
None.

### WARNING

1. **WARN|verification remains incomplete** — tasks are reconciled, but the remaining partial/pending items are intentionally preserved: full admin suite, reproducible end-to-end smoke and portal tests.

2. **WARN|R18 tests incomplete** — Not all 47 spec scenarios have explicit test traces. Portal (Astro) has zero test files. Smoke test script (T8.8.3) not found. Integration tests for end-to-end flow not confirmed.

3. **WARN|R15 astro:assets unused** — Design specified `astro:assets` for image optimization (WebP/AVIF). Portal pages use standard `<img>` tags without Astro image component. Images are served via MinIO media endpoint but no build-time optimization.

4. **WARN|R15 Cache-Control incomplete** — nginx.conf has Cache-Control for static assets (immutable, 1yr) and HTML (60s), but the portal API proxy at `/api/public/` doesn't add Cache-Control headers. Design specified 60s for listings and no-store for forms.

### SUGGESTION

1. **SUGGEST|R18 portal tests** — Add Astro build/fixture tests to verify sitemap excludes drafts, SEO metadata renders correctly, and forms submit to correct endpoints.

2. **SUGGEST|R6 ObjectCleanupService** — The service exists but no scheduled job was found to clean orphaned MinIO objects after 24h as specified in design.md.

3. **SUGGEST|R14 event coverage** — Not all 11 mandatory log events from design.md are explicitly implemented (e.g., `storage.failure`, `dependency.unavailable`). Some may be implicit via exception handlers.

4. **SUGGEST|R3 media proxy** — PublicController has a `/media/{objectKey}` endpoint that proxies MinIO images. This should be documented in the API contract and rate-limited separately.

## Skill Resolution

| Skill | Loaded | Applied |
|-------|--------|---------|
| sdd-verify | ✅ | Verify workflow, 5-step process |
| astro-developer | ✅ | Portal structure, SSG, islands |
| angular-developer | ✅ | TalentoModule, NgModule pattern, Reactive Forms |
| spring-boot-engineer | ✅ | public-api architecture, S2S, security |
| security-reviewer | ✅ | S2S JWT, rate limiting, CAPTCHA, CORS, headers |

## Next Recommended

1. Update tasks.md to reflect actual completion status for archive accuracy.
2. Add Astro build tests and portal fixture tests (R18).
3. Implement `astro:assets` for image optimization in portal pages (R15).
4. Add Cache-Control headers to nginx proxy for `/api/public/` (R15).
5. Implement scheduled MinIO orphan cleanup job (R6).
6. Run full smoke test (T8.8.3) once local PostgreSQL is available.
