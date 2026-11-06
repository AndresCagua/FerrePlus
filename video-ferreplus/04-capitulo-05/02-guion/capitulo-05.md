# Capítulo 5 — APIs y límites de responsabilidad

**Estado:** aprobado para producción  
**Idioma:** Español neutro internacional  
**Formato:** 1920×1080, 16:9, 30 fps  
**Regla:** No mostrar credenciales, tokens, API keys, secretos, datos personales ni logs sensibles.

## Objetivo

Explicar cómo `admin-api` y `public-api` separan responsabilidades mediante contratos HTTP, autenticación, DTOs, validación y respuestas de error.

## Alcance

La arquitectura general y las interfaces ya fueron cubiertas en capítulos anteriores. El detalle de embeddings, RAG y persistencia profunda queda reservado para capítulos específicos.

## Fuentes visuales

- Ping real de `public-api`.
- Consulta administrativa sin token para mostrar el límite de autenticación.
- Solicitud inválida al login con cuerpo vacío y datos ficticios.
- Error controlado de recurso público inexistente.
- Diagrama explicativo de límites entre cliente, API, servicio y almacenamiento.
- Petición pública completa con respuesta controlada.

## Evidencia de implementación

- `admin-api/src/main/java/com/ferreplus/controller/AuthController.java`
- `admin-api/src/main/java/com/ferreplus/controller/ProductoController.java`
- `admin-api/src/main/java/com/ferreplus/exception/GlobalExceptionHandler.java`
- `public-api/src/main/java/com/ferreplus/publico/controller/PublicController.java`
- `public-api/src/main/java/com/ferreplus/publico/controller/InternalController.java`
- `public-api/src/main/java/com/ferreplus/publico/exception/GlobalExceptionHandler.java`

## Reglas de verificación

- Usar únicamente comandos locales y datos ficticios.
- No mostrar credenciales, tokens, encabezados de autorización ni respuestas personales.
- No ejecutar operaciones mutantes durante la captura.
- Capturar a 1920×1080.
- Silenciar Desktop Audio y Mic/Aux en OBS.
- Verificar cada MKV con decode estricto.
- Normalizar cada escena a la duración de su audio antes de ensamblar.
