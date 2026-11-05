# YouTube publication package — Chapter 1

## Title

**FerrePlus: qué es y cómo se conectan sus partes | Capítulo 1**

## Description

En este primer capítulo recorremos la arquitectura de FerrePlus y la relación entre sus principales componentes.

Veremos:

- La separación entre el portal público, el panel administrativo y las APIs.
- El papel de Traefik como punto de entrada y enrutamiento local.
- Los hostnames utilizados para probar el entorno.
- La responsabilidad de PostgreSQL, MongoDB, Redis y MinIO.
- El recorrido de una petición desde el navegador hasta la API y el almacenamiento.
- El uso opcional de Cloudflare Tunnel para pruebas temporales.

Todo el material visual relacionado con el software corresponde a capturas del entorno local de FerrePlus. Las capturas administrativas utilizan datos locales de prueba; no se incluyen credenciales, tokens ni secretos.

Repositorio del proyecto:

https://github.com/AndresCagua/FerrePlus

## Suggested tags

`FerrePlus`, `software`, `arquitectura`, `Docker Compose`, `Traefik`, `Angular`, `APIs`, `PostgreSQL`, `MongoDB`, `Redis`, `MinIO`, `Cloudflare Tunnel`

## Thumbnail

Use `09-assets/thumbnail-capitulo-01.png` as the YouTube thumbnail. It is verified at 1280×720.

## Local production artifact

The rendered video is intentionally excluded from Git because it is a large binary. Generate or distribute it separately from:

`08-exportados/capitulo-01-ferreplus.mp4`
