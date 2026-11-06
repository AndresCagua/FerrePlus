# Capítulo 6 — Persistencia y almacenamiento

**Estado:** aprobado para producción  
**Idioma:** Español neutro internacional  
**Formato:** 1920×1080, 16:9, 30 fps  
**Regla:** No mostrar credenciales, tokens, API keys, secretos, datos personales ni archivos privados.

## Objetivo

Mostrar dónde viven los datos de FerrePlus y qué responsabilidad tiene cada sistema de almacenamiento.

## Alcance

La arquitectura general, las interfaces y los contratos API ya fueron cubiertos. Este capítulo se concentra en ownership, persistencia, almacenamiento de objetos y redes internas.

## Fuentes visuales

- Estado real de los servicios Docker Compose.
- Disponibilidad de PostgreSQL mediante `pg_isready`.
- Ping real de MongoDB.
- Ping autenticado de Redis sin imprimir la contraseña.
- Health endpoint real de MinIO.
- Diagrama explicativo de ownership y redes internas.

## Evidencia de implementación

- `docker-compose.yml`
- `admin-api/src/main/java/com/ferreplus/repository/ProductoRepository.java`
- `public-api/src/main/java/com/ferreplus/publico/repository/PublicacionRepository.java`
- `public-api/src/main/java/com/ferreplus/publico/ratelimit/RateLimitService.java`
- `public-api/src/main/java/com/ferreplus/publico/storage/MinioObjectStorage.java`

## Reglas de verificación

- Mostrar únicamente estados y healthchecks seguros.
- No mostrar contraseñas, documentos, CVs, objetos ni datos de colecciones.
- Capturar a 1920×1080.
- Silenciar Desktop Audio y Mic/Aux en OBS.
- Verificar cada MKV con decode estricto.
- Normalizar cada escena a la duración de su audio antes de ensamblar.
