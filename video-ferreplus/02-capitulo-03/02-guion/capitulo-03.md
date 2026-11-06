# Capítulo 3 — Levantar FerrePlus localmente

**Estado:** aprobado para producción
**Idioma:** Español neutro internacional
**Formato:** 1920×1080, 16:9, 30 fps
**Regla:** No mostrar secretos, tokens, contraseñas ni datos personales.

## Objetivo

Mostrar cómo preparar, iniciar, comprobar, diagnosticar y detener de forma segura el entorno local de FerrePlus sin repetir la arquitectura general explicada en el capítulo 1.

## Escenas

La narración aprobada y el storyboard operativo están en:

- `01-planificacion/storyboard.json`
- `02-guion/narraciones-escenas.json`

## Tomas

- Requisitos y versiones desde terminal.
- Nombres de variables con valores ocultos.
- Arranque mediante `docker compose up -d --build`.
- Diagrama de dependencias.
- Estado real de `docker compose ps`.
- Logs recientes y limitados de `admin-api`.
- Dashboard real autenticado.
- Portal público real.
- Detención segura mediante `./scripts/start-local.sh --stop`.

## Reglas de verificación

- No ejecutar comandos destructivos.
- No mostrar `.env`, `secrets/`, API keys, JWT ni claves S2S.
- Capturar a 1920×1080.
- Silenciar Desktop Audio y Mic/Aux en OBS.
- Verificar cada grabación con `ffprobe` antes de ensamblar.
- Verificar que video, audio y subtítulos tengan duraciones compatibles.
