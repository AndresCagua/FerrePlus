# Video 7 — Seguridad

Produce the next FerrePlus technical video from the approved Chapter 8 plan, using real local security boundaries and safe validation commands.

## Specs

1. **S1** — "vamos bien papi, continua con el siguiente video"
2. **S2** — "### Capítulo 8 — Seguridad"
3. **S3** — "JWT y autorización backend."
4. **S4** — "Secretos fuera de Git."
5. **S5** — "CORS, validación y rate limiting."
6. **S6** — "Cloudflare Turnstile."
7. **S7** — "Qué no debe exponerse en una demostración."
8. **S8** — Use real local captures and do not expose credentials, tokens, keys, personal data or sensitive logs.

## Tasks

- T1 [S1-S2] Investigate backend security, secrets, CORS, rate limiting and Turnstile boundaries — commit pending.
- T2 [S2-S8] Create Chapter 8 planning, script, storyboard, subtitles, metadata and safe thumbnail — commit pending.
- T3 [S2-S8] Capture safe security validation behavior and generate verified narration audio — commit pending.
- T4 [S2-S8] Assemble, verify and deliver Video 7 — commit pending.

## Log

L1: vamos bien papi, continua con el siguiente video
L2: PLAN.md identifies Chapter 8 as Seguridad, covering JWT and backend authorization, secrets outside Git, CORS, validation, rate limiting, Cloudflare Turnstile and demonstration hygiene.
L3: Chapter 8 package, Edge narration, safe JWT/CORS probes, eight scene captures, strict decodes, synchronized MP4 assembly, final full decode, title-frame review and OBS shutdown completed. Final media is H.264 1920x1080, AAC mono 24kHz, Spanish mov_text subtitles, 163.931 seconds.
L4: User reported a 404 while the subtitle described public forms and Cloudflare Turnstile. The capture used `/contacto`, but the real portal route is `/contactanos/`. T6 was recaptured using `/contactanos/` with per-scene `domcontentloaded` navigation because Turnstile prevents `networkidle`; Video 7 was rebuilt and fully decoded successfully.
