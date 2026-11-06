# Capítulo 8 — Seguridad

**Estado:** aprobado para producción  
**Idioma:** Español neutro internacional  
**Formato:** 1920×1080, 16:9, 30 fps  
**Regla:** No mostrar credenciales, JWTs, claves privadas, tokens Turnstile, datos personales, CVs ni logs sensibles.

## Objetivo

Mostrar las defensas reales de FerrePlus sin convertir secretos ni datos personales en material audiovisual.

## Alcance

- JWT y autorización backend.
- Tokens S2S RS256 entre APIs.
- Secretos fuera de Git.
- CORS, headers defensivos y validación.
- Rate limiting con Redis y fallback conservador.
- Cloudflare Turnstile en formularios públicos.
- Campos seguros para observabilidad.

## Tomas

1. Placa de capítulo.
2. Login administrativo y frontera de autenticación.
3. Petición anónima a ruta protegida mostrando solo status.
4. Preflight CORS y headers defensivos.
5. Código real de rate limiting sin ejecutar solicitudes mutantes.
6. Formulario público y componente Turnstile.
7. `git check-ignore` y logging seguro, sin imprimir valores.
8. Cierre.

## Evidencia

- `admin-api/src/main/java/com/ferreplus/config/SecurityConfig.java`
- `admin-api/src/main/java/com/ferreplus/auth/JwtAuthenticationFilter.java`
- `public-api/src/main/java/com/ferreplus/publico/security/SecurityConfig.java`
- `public-api/src/main/java/com/ferreplus/publico/ratelimit/RateLimitFilter.java`
- `public-api/src/main/java/com/ferreplus/publico/ratelimit/RateLimitService.java`
- `portal/src/components/Turnstile.astro`
- `public-api/src/main/java/com/ferreplus/publico/controller/PublicController.java`
- `docs/architecture/pr8-security-operations.md`

## Seguridad de captura

- Usar únicamente comandos de lectura o validación.
- No mostrar `.env`, secretos montados, JWTs ni respuestas con datos reales.
- Usar status codes, headers filtrados y código fuente seguro.
- Silenciar Desktop Audio y Mic/Aux en OBS.
- Verificar cada MKV con `ffmpeg -v error -xerror`.
