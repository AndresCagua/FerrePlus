# Video 5 — Persistencia y almacenamiento

Produce the next FerrePlus technical video from the approved Chapter 6 plan, using real local storage boundaries and safe fictitious data.

## Specs

1. **S1** — "si esta bien vamos con el siguiente, de aqui el commit final lo hacemos cuando terminemos todos los videos, pero ya sabes al finalizar todos los videos me das el mensaje del commit en el formato, continua con el siguiente video"
2. **S2** — "### Capítulo 6 — Persistencia y almacenamiento"
3. **S3** — "- PostgreSQL para la operación administrativa."
4. **S4** — "- MongoDB para contenido público."
5. **S5** — "- Redis para límites y estado auxiliar."
6. **S6** — "- MinIO para medios y archivos."
7. **S7** — "- Ownership de datos y redes internas."

## Tasks

- T1 [S1-S2] Investigate current persistence services, repositories, storage boundaries and internal networks — commit pending.
- T2 [S2-S7] Create Chapter 6 planning, script, storyboard, subtitles, metadata and safe thumbnail — commit pending.
- T3 [S2-S7] Capture real storage and persistence evidence and generate verified narration audio — commit pending.
- T4 [S2-S7] Assemble, verify and deliver Video 5 — commit pending.

## Log

L1: si esta bien vamos con el siguiente, de aqui el commit final lo hacemos cuando terminemos todos los videos, pero ya sabes al finalizar todos los videos me das el mensaje del commit en el formato, continua con el siguiente video
L2: Repository mapping confirms PostgreSQL-backed JPA repositories in `admin-api`, MongoRepository-backed public content repositories in `public-api`, Redis-backed rate limiting with bounded in-memory fallback, MinIO object storage for CV/media buckets, and separated Docker networks including public_data, admin_data and internal_services.
