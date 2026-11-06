# Video 4 — APIs y límites de responsabilidad

Produce the next FerrePlus technical video from the approved Chapter 5 plan, using real local API behavior and safe fictitious data.

## Specs

1. **S1** — "vamos con el siguiente video"
2. **S2** — "### Capítulo 5 — APIs y límites de responsabilidad"
3. **S3** — "- Responsabilidad de `admin-api`."
4. **S4** — "- Responsabilidad de `public-api`."
5. **S5** — "- DTOs, validación y respuestas de error."
6. **S6** — "- Flujo de una petición completa."

## Tasks

- T1 [S1-S2] Investigate current API routes, DTOs, validation and error responses — commit pending.
- T2 [S2-S6] Create Chapter 5 planning, script, storyboard, subtitles, metadata and safe thumbnail — commit pending.
- T3 [S2-S6] Capture real API flows and generate verified narration audio — commit pending.
- T4 [S2-S6] Assemble, verify and deliver Video 4 — commit pending.

## Log

L1: vamos con el siguiente video
L2: Repository mapping confirms `admin-api` owns authenticated `/api/*` controllers with authority checks, `public-api` exposes unauthenticated `/api/public/*` endpoints plus internal service-to-service routes, and both services have distinct validation/error response handlers. Representative evidence: `admin-api/src/main/java/com/ferreplus/controller/AuthController.java`, `ProductoController.java`, `exception/GlobalExceptionHandler.java`; `public-api/src/main/java/com/ferreplus/publico/controller/PublicController.java`, `InternalController.java`, `exception/GlobalExceptionHandler.java`.
