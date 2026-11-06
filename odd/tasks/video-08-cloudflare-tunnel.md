# Video 8 — Cloudflare Tunnel

Produce the next FerrePlus technical video from the approved Chapter 9 plan, using safe local tunnel configuration evidence without exposing tunnel tokens or public URLs.

## Specs

1. **S1** — "vamos bien papi, continua con el siguiente video"
2. **S2** — "### Capítulo 9 — Cloudflare Tunnel"
3. **S3** — "Diferencia entre Quick Tunnel y named tunnel."
4. **S4** — "Perfil opcional `tunnel`."
5. **S5** — "Token montado como secreto."
6. **S6** — "Flujo Cloudflare → `cloudflared` → Traefik."
7. **S7** — "Actualización segura de `cloudflared`."
8. **S8** — Use real local captures and never expose tunnel tokens, public URLs, credentials or sensitive logs.

## Tasks

- T1 [S1-S2] Investigate Quick Tunnel, named tunnel, Compose profile, secret mount and update boundaries — commit pending.
- T2 [S2-S8] Create Chapter 9 planning, script, storyboard, subtitles, metadata and safe thumbnail — commit pending.
- T3 [S2-S8] Capture safe tunnel configuration behavior and generate verified narration audio — commit pending.
- T4 [S2-S8] Assemble, verify and deliver Video 8 — commit pending.

## Log

L1: vamos bien papi, continua con el siguiente video
L2: PLAN.md identifies Chapter 9 as Cloudflare Tunnel, covering Quick Tunnel versus named tunnel, optional tunnel profile, token secret mount, Cloudflare to cloudflared to Traefik flow, and safe cloudflared updates.
L3: Chapter 9 package, Edge narration, read-only tunnel configuration capture, strict scene decodes, synchronized MP4 assembly, final full decode, title-frame review and OBS shutdown completed. T4 was recaptured after correcting `.env.example` to `../.env.example`. Final media is H.264 1920x1080, AAC mono 24kHz, Spanish mov_text subtitles, 138.065 seconds.
L4: User reported the Cloudflare visual was incorrect. Added a tunnel-specific diagram renderer to `capture-scenes.mjs`, changed T5 to `tunnel-diagram`, recaptured only T5, rebuilt the MP4 and revalidated the full decode. The corrected visual now shows Cloudflare Edge → cloudflared → Traefik → Portal/APIs.
