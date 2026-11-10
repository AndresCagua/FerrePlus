# Security review remediations

Source: reviewer recommendations from the FerrePlus security audit; implementation is limited to code-local fixes selected by the user.

## Specs

1. **S1** — "compa arregla las recomendaciones dadas por el reviewer"
2. **S2** — "Código seguro primero"
3. **S3** — "Corregir autenticación/autorización, chat, Flutter, JSON-LD, claves y bootstrap; no tocar Compose/Traefik."

## Tasks

- T1 — S1-S3 — Harden admin/public API authentication, authorization, bootstrap, and outbound secret handling — commit: HEAD
- T2 — S1-S3 — Harden portal JSON-LD serialization and Flutter offline integrity/replay — commit: HEAD
- T3 — S1-S3 — Run focused tests and record verification evidence — commit: pending
- T4 — S1-S3 — Update audit artifacts with remediation status — commit: external audit run-1

## Log

L1: compa arregla las recomendaciones dadas por el reviewer
L2: User selected: Código seguro primero — Corregir autenticación/autorización, chat, Flutter, JSON-LD, claves y bootstrap; no tocar Compose/Traefik.
L3: Implemented code-local remediations: exact S2S scope/cache handling, fail-closed admin bootstrap, inactive-user preservation, explicit CHAT_VER gating, Gemini header transport, safe JSON-LD, strict encrypted offline payloads, and closed offline endpoint mapping. Maven backend verification remains unavailable; Flutter has one environment-only libsqlite3.so failure.
