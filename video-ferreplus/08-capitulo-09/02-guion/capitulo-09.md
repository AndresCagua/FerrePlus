# Capítulo 9 — Cloudflare Tunnel

**Estado:** aprobado para producción  
**Idioma:** Español neutro internacional  
**Formato:** 1920×1080, 16:9, 30 fps  
**Regla:** No mostrar tokens de Cloudflare, URLs públicas activas, credenciales ni logs sensibles.

## Objetivo

Explicar la diferencia entre Quick Tunnel y named tunnel, y mostrar cómo el tráfico llega de Cloudflare a cloudflared, Traefik y los servicios locales.

## Tomas

1. Placa de capítulo.
2. Script de Quick Tunnels temporales.
3. Perfil opcional `tunnel` de Compose.
4. Montaje del token como Docker secret.
5. Diagrama Cloudflare → cloudflared → Traefik.
6. Imagen fijada y `--no-autoupdate`.
7. Cierre.

## Evidencia

- `scripts/start-local.sh`
- `docker-compose.yml`
- `.env.example`
- `traefik/dynamic.yml`

## Seguridad de captura

- No arrancar Quick Tunnels públicos para esta demostración.
- Mostrar únicamente nombres de variables, rutas internas y configuración sin valores.
- No imprimir Docker secrets, URLs `trycloudflare.com`, tokens ni logs completos.
- Verificar cada MKV con `ffmpeg -v error -xerror`.
