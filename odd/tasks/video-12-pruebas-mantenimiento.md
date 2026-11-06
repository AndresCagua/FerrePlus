# Video 12 — Pruebas y mantenimiento

## Specs

1. **S1** — "si ahí está bien, ahora con el flujo de la convocatoria desde que se la crea y luego cuando alguien aplica"
2. **S2** — "ya ahí está bien, ahora falta el último video verdad. El de pruebas y mantenimiento. Vamos con ese ya para terminar"

## Tasks

- T1 [S1-S2] Investigar pruebas, builds, healthchecks, logs, troubleshooting, dependencias y rollback; route: repository evidence; commit: pending — evidence: README.md development/tests sections, docker-compose.yml healthchecks and depends_on, scripts/start-local.sh, admin-api/public-api test trees. DONE.
- T2 [S1-S2] Create Chapter 12 production package with safe fictitious evidence; route: video-ferreplus/12-capitulo-13; commit: pending. DONE.
- T3 [S1-S2] Capture, assemble, strictly verify and clean the final maintenance video; route: video-ferreplus/12-capitulo-13; commit: pending. DONE — all T1-T8 MKVs and final MP4 pass strict ffmpeg decode; final streams are H.264 1920x1080/30, AAC mono 24000 Hz, mov_text; OBS stopped.

## Log

- E1: Repository evidence confirms backend Maven suites, frontend CI tests, Docker Compose rebuilds, service healthchecks, dependency readiness, logs and safe local stop/restart procedures. The final capture must distinguish observed command results from documented procedures and must not expose secrets.
- E2: Frontend CI verification passed with 20 spec files and 123 tests. Backend focused ChatIntentClassifierTest and PermisoResolverTest passed; the full backend suite remains environment-sensitive because some Spring contexts require JWT test configuration, so the video does not claim it is green.
- E3: Chapter 13 final export is video-ferreplus/12-capitulo-13/08-exportados/12-capitulo-13.mp4, duration 107.698 seconds, strictly decoded with ffmpeg -v error -xerror.
- L1: "si ahí está bien, ahora con el flujo de la convocatoria desde que se la crea y luego cuando alguien aplica"
- L2: "ya ahí está bien, ahora falta el último video verdad. El de pruebas y mantenimiento. Vamos con ese ya para terminar"
