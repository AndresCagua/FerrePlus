# Capítulo 10 — Flujo completo: publicar contenido

**Estado:** aprobado para producción  
**Idioma:** Español neutro internacional  
**Formato:** 1920×1080, 16:9, 30 fps  
**Regla:** Usar contenido ficticio y no mostrar credenciales, tokens, datos personales ni respuestas sensibles.

## Objetivo

Seguir una publicación desde el módulo Talento hasta su verificación en el portal público.

## Flujo

1. Abrir Talento → Publicaciones.
2. Revisar el formulario de nueva publicación.
3. Crear un borrador ficticio vía multipart.
4. Publicar mediante la acción administrativa.
5. Verificar el slug en la API pública.
6. Eliminar el dato ficticio de demostración.

## Evidencia

- `frontend/src/app/talento/talento-routing.module.ts`
- `frontend/src/app/talento/services/talento.service.ts`
- `admin-api/src/main/java/com/ferreplus/controller/TalentoController.java`
- `public-api/src/main/java/com/ferreplus/publico/controller/PublicController.java`
- `portal/src/pages/publicaciones/index.astro`

## Seguridad de captura

- Usar solo el título y texto ficticio definidos en el storyboard.
- Inyectar credenciales mediante variables de entorno.
- No imprimir JWTs ni respuestas completas.
- Eliminar la publicación al finalizar la captura.
- Verificar cada MKV con `ffmpeg -v error -xerror`.
