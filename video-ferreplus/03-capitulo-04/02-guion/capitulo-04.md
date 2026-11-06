# Capítulo 4 — Interfaces web de FerrePlus

**Estado:** aprobado para producción
**Idioma:** Español neutro internacional
**Formato:** 1920×1080, 16:9, 30 fps
**Regla:** No mostrar credenciales, tokens, API keys, secretos, datos personales ni logs sensibles.

## Objetivo

Mostrar el portal público Astro y el panel administrativo Angular desde la perspectiva del usuario: navegación, consumo de APIs, estados de carga, errores, autenticación y entrada visible del chat IA.

## Alcance

La arquitectura general y el arranque local ya fueron cubiertos en los videos anteriores. La explicación profunda de Jev, embeddings y RAG queda reservada para el capítulo de Chat IA.

## Fuentes visuales

- Portal real en `http://public.localhost:8088`.
- Páginas públicas reales de publicaciones.
- Login y dashboard reales de Angular.
- Módulo real de productos.
- Salida controlada de una solicitud HTTP sin tokens ni respuestas sensibles.
- Diagrama explicativo de estados de carga y error.
- Chat IA integrado en el panel.

## Reglas de verificación

- Usar datos locales ficticios.
- Ocultar credenciales y tokens antes de capturar.
- No enviar formularios que creen o modifiquen datos.
- Capturar a 1920×1080.
- Silenciar Desktop Audio y Mic/Aux en OBS.
- Verificar cada MKV con decode estricto.
- Normalizar cada escena a la duración de su audio antes de ensamblar.
