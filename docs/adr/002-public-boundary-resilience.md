# ADR-002: Boundary publico, proxy confiable y reintentos acotados

- **Estado:** Aceptada
- **Fecha:** 2026-08-21

## Decision

Los endpoints internos devuelven DTOs de respuesta explicitos y nunca entidades
Mongo completas, claves de idempotencia, huellas, IPs ni metadata de almacenamiento.
El rate limit usa la IP remota como identidad base; `X-Forwarded-For` y
`X-Real-IP` solo se aceptan cuando la conexion inmediata pertenece a una red
privada de proxy. El fingerprint enviado por el cliente no es una identidad
confiable y no puede evadir el limite cambiando su valor.

Las notificaciones persistidas en `PENDING`/`FAILED` se reintentan mediante un
scheduler acotado a 20 registros por ciclo y un maximo de tres intentos. El
registro funcional se persiste antes del envio; los estados `SENT` no se reenvian
automaticamente.

## Consecuencias

La disponibilidad del servicio publico se traduce a `503` en el admin y los
errores de validacion/conflicto conservan `400`/`409`, evitando que Angular vea
un `500` generico. HSTS se activa solo mediante configuracion explicita de
HTTPS/produccion y no se fuerza en localhost.
