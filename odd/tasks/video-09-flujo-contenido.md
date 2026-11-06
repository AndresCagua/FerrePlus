# Video 9 — Flujo completo: publicar contenido

Produce the next FerrePlus technical video from the selected Chapter 10 flow, using real local content publication behavior and safe fictitious data.

## Specs

1. **S1** — "belleza ahí quedó, continua con el siguiente video"
2. **S2** — "Publicar contenido desde Talento y verlo en el portal público."
3. **S3** — Use real local captures and fictitious content only.
4. **S4** — Do not expose credentials, tokens, personal data, private files or sensitive logs.
5. **S5** — Follow the content from administrative publication to public portal verification.

## Tasks

- T1 [S1-S5] Investigate the real publication and public verification boundaries — complete; commit deferred with the series.
- T2 [S2-S5] Create Chapter 10 planning, script, storyboard, subtitles, metadata and safe thumbnail — complete; commit deferred with the series.
- T3 [S2-S5] Capture fictitious publication behavior and generate verified narration audio — complete; commit deferred with the series.
- T4 [S2-S5] Assemble, verify and deliver Video 9 — complete; commit deferred with the series.

## Log

L1: belleza ahí quedó, continua con el siguiente video
L2: User selected the Chapter 10 flow: publish content from Talento and verify it in the public portal.
L3: Confirmed the real flow: create a DRAFT via multipart at `/api/admin/talento/publicaciones`, publish via `/api/admin/talento/publicaciones/{id}/publicar`, verify by slug at `/api/public/publicaciones/{slug}`, then delete the fictitious record. The first probe omitted the required `estado` field and returned HTTP 400; the corrected probe returned create 200, publish 200, public 200 and cleanup 204.
L4: Created and validated the Chapter 10 package under `video-ferreplus/09-capitulo-10/`, generated Edge `es-MX-DaliaNeural` narration at 24000 Hz mono, captured T1-T7, and passed strict `ffmpeg -v error -xerror` decode for every MKV.
L5: The final MP4 is `video-ferreplus/09-capitulo-10/08-exportados/09-capitulo-10.mp4`; it is H.264 1920x1080 at 30 fps, AAC mono 24000 Hz, Spanish `mov_text` subtitles, duration 128.665 s. Full decode passed and OBS was stopped. The capture cleanup left one fictitious record, which was deleted separately with HTTP 204 and verified absent.
