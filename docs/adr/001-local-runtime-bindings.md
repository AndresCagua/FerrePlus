# ADR-001: Bindings locales para frontends y almacenamiento

- **Estado:** Aceptada
- **Fecha:** 2026-08-21

## Contexto

El entorno local necesita servir Angular en `localhost:4200`, la consola MinIO
en `localhost:9001` y permitir inspeccion autenticada de MongoDB desde DataGrip,
sin publicar esos servicios en todas las interfaces.

## Decision

`admin-web` se construye como artefacto Angular estatico servido por nginx y
publica `127.0.0.1:4200:80`, ademas de la ruta Traefik `admin.localhost`.
MinIO publica sus puertos API/Console y MongoDB su puerto solo en loopback.
Los volumenes persistentes se conservan y cualquier recreacion operativa es
por servicio, nunca con `docker compose down -v`.

## Consecuencias

La URI sin credenciales `mongodb://127.0.0.1:27017/ferreplus_public` no puede
autenticar contra esta instalacion porque MongoDB mantiene `authSource=admin`.
DataGrip debe usar el usuario `ferreplus`, la password del `.env`, la base
`ferreplus_public` y `authSource=admin`; esos valores no se versionan ni se
imprimen en diagnosticos.
