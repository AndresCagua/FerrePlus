# Tasks: Portal Publico y Gestion de Talento con Arquitectura Aislada

> **Change**: `portal-publico-talento-arquitectura-aislada`
> **Total tasks**: 89
> **PRs encadenados**: 8
> **Specialists**: `springboot` (admin-api / public-api), `angular` (frontend), `astro` (portal-publico), `infra` (Docker / Traefik / docs)
> **Commit rule**: cada tarea o sub-tarea es una unidad de trabajo **commiteable y revisable**. El usuario aprueba cada commit antes de crearlo; el mensaje sigue el formato acordado: `YYYYMMDD tipo(scope): bullets en español`.

---

## Resumen por PR

| PR | Foco | Tasks | Lineas estimadas | Requisitos principales |
|----|------|-------|------------------|------------------------|
| PR1 | Renombrar `backend/` a `admin-api/` | 8 | 450 | R1 (parcial), R2 |
| PR2 | Compose, Traefik, redes y entorno | 8 | 700 | R1, R2 |
| PR3 | Skeleton `public-api`, modelos, DTOs, ProblemDetail | 14 | 620 | R1, R2, R10, R14 |
| PR4 | MinIO, postulaciones, convocatorias, validacion CV | 11 | 770 | R4, R5, R6 |
| PR5 | Contactos, publicaciones, correo asincrono | 11 | 770 | R3, R7, R8, R9 |
| PR6 | Portal Astro SSG, SEO, formularios publicos y temas | 11 | 640 | R15 |
| PR7 | Modulo Angular de talento, RBAC, resiliencia | 13 | 770 | R13, R16, R17 |
| PR8 | S2S JWT, observabilidad, tests integrales, docs | 13 | 770 | R11, R12, R14, R18 |
| **Total** | | **89** | **5.490** | |

---

## PR 1: Renombrar `backend/` a `admin-api/` y ajustar referencias

> **Lineas estimadas**: 450
> **Requisitos**: R1 (infraestructura reproducible), R2 (ownership de datos)
> **Especialista**: `springboot` / `infra`

### T1.1: Inventariar referencias a `backend/`
- **Descripcion**: Buscar y documentar toda referencia a `backend/` en `docker-compose.yml`, Dockerfiles, README, CI/scripts, documentacion y paths generados.
- **Archivos afectados**: todos los archivos de infraestructura y documentacion.
- **Requisitos**: R1.
- **Verificacion**: Lista de referencias detectadas y plan de reemplazo.
- **Tamano estimado**: 30 lineas.
- **Dependencias**: ninguna.
- **Especialista**: infra.
- **Estado**: pending.

### T1.2: Ejecutar `git mv backend/ admin-api/`
- **Descripcion**: Renombrar el directorio preservando historial Git. No modificar paquetes Java.
- **Archivos afectados**: `backend/` -> `admin-api/`.
- **Requisitos**: R1, ADR-1.
- **Verificacion**: `git status` muestra rename sin cambios no funcionales.
- **Tamano estimado**: 100 lineas (diff del rename).
- **Dependencias**: T1.1.
- **Especialista**: springboot.
- **Estado**: pending.

### T1.3: Actualizar `admin-api/pom.xml`
- **Descripcion**: Cambiar `artifactId` y `<name>` a `ferreplus-admin-api`; conservar `groupId` `com.ferreplus`.
- **Archivos afectados**: `admin-api/pom.xml`.
- **Requisitos**: R1, ADR-1.
- **Verificacion**: `mvn -f admin-api/pom.xml validate` pasa.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T1.2.
- **Especialista**: springboot.
- **Estado**: pending.

### T1.4: Actualizar Dockerfile de `admin-api`
- **Descripcion**: Renombrar contexto de build, paths de copia, `container_name`, imagen y variables de entorno en el Dockerfile existente.
- **Archivos afectados**: `admin-api/Dockerfile`, `.dockerignore`.
- **Requisitos**: R1.
- **Verificacion**: `docker build -f admin-api/Dockerfile admin-api/` compila.
- **Tamano estimado**: 80 lineas.
- **Dependencias**: T1.2.
- **Especialista**: infra.
- **Estado**: pending.

### T1.5: Actualizar `docker-compose.yml` existente
- **Descripcion**: Renombrar servicio `backend` a `admin-api`, actualizar `context`, `container_name`, variables y volumenes.
- **Archivos afectados**: `docker-compose.yml`.
- **Requisitos**: R1.
- **Verificacion**: `docker compose config` no reporta errores.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: T1.2, T1.4.
- **Especialista**: infra.
- **Estado**: pending.

### T1.6: Actualizar README, CI y scripts
- **Descripcion**: Reemplazar rutas `backend/` por `admin-api/` en README, workflows de CI, scripts de build y documentacion.
- **Archivos afectados**: `README.md`, `.github/workflows/*`, scripts.
- **Requisitos**: R1, ADR-1.
- **Verificacion**: `grep -R "backend/"` (despues de excluir target/.git) solo muestra referencias historicas/documentadas.
- **Tamano estimado**: 70 lineas.
- **Dependencias**: T1.2.
- **Especialista**: infra.
- **Estado**: pending.

### T1.7: Verificar build Maven y tests H2
- **Descripcion**: Ejecutar `mvn test` y `mvn package` desde `admin-api/`; confirmar que PostgreSQL/H2 y esquema JPA siguen operativos.
- **Archivos afectados**: `admin-api/src/test/*`.
- **Requisitos**: R1, R18.
- **Verificacion**: `mvn -f admin-api/pom.xml test` verde.
- **Tamano estimado**: 30 lineas.
- **Dependencias**: T1.3, T1.4, T1.5.
- **Especialista**: springboot.
- **Estado**: pending.

### T1.8: Documentar rollback del rename
- **Descripcion**: Agregar nota en `docs/architecture/rename-rollback.md` con pasos para revertir PR1 sin borrar volumenes.
- **Archivos afectados**: `docs/architecture/rename-rollback.md`.
- **Requisitos**: R1 (rollback plan).
- **Verificacion**: El rollback puede ejecutarse con `git revert` + restaurar path `backend/`.
- **Tamano estimado**: 30 lineas.
- **Dependencias**: T1.2.
- **Especialista**: infra.
- **Estado**: pending.

### Criterios de "done" para PR1
- [ ] `admin-api/` contiene el backend completo sin paquetes Java renombrados.
- [ ] `mvn -f admin-api/pom.xml test` pasa.
- [ ] `docker compose config` es valido y no referencia `backend/`.
- [ ] README/CI/scripts actualizados.
- [ ] Rollback documentado.

---

## PR 2: Compose, Traefik, redes, profiles, healthchecks y `.env.example`

> **Lineas estimadas**: 700
> **Requisitos**: R1, R2
> **Especialista**: `infra`

### T2.1: Crear topologia de `docker-compose.yml`
- **Descripcion**: Definir 5 redes (`public_net`, `admin_net`, `public_data`, `admin_data`, `internal_services`), servicios, `depends_on` con `condition: service_healthy`, `restart: unless-stopped`, limits de recursos y sin `network_mode: host`.
- **Archivos afectados**: `docker-compose.yml`.
- **Requisitos**: R1, R2, ADR-2, ADR-3.
- **Verificacion**: `docker compose config` muestra todas las redes y servicios sin errores.
- **Tamano estimado**: 250 lineas.
- **Dependencias**: PR1.
- **Especialista**: infra.
- **Estado**: pending.

### T2.2: Crear `.env.example`
- **Descripcion**: Declarar variables sin secretos reales: DB, Mongo, Redis, MinIO, SMTP, S2S, CORS, limites y profiles. Comentar que secretos se montan con Compose secrets.
- **Archivos afectados**: `.env.example`.
- **Requisitos**: R1.
- **Verificacion**: `docker compose --env-file .env.example config` es valido.
- **Tamano estimado**: 80 lineas.
- **Dependencias**: T2.1.
- **Especialista**: infra.
- **Estado**: pending.

### T2.3: Crear configuracion de Traefik
- **Descripcion**: Crear `traefik/traefik.yml` (static), `traefik/dynamic.yml` (routers/services/middlewares), con `providers.docker.exposedByDefault=false`, entrypoints `web`/`websecure`, middlewares de seguridad y compresion.
- **Archivos afectados**: `traefik/traefik.yml`, `traefik/dynamic.yml`, `traefik/middlewares.yml`.
- **Requisitos**: R1, ADR-4.
- **Verificacion**: Traefik inicia y responde `/ping`.
- **Tamano estimado**: 120 lineas.
- **Dependencias**: T2.1.
- **Especialista**: infra.
- **Estado**: pending.

### T2.4: Crear Dockerfiles multi-stage de apps
- **Descripcion**: Dockerfiles para `admin-api`, `public-api`, `admin-web` (Angular) y `public-web` (Astro/nginx) con imagen base minima, usuario non-root y `.dockerignore`.
- **Archivos afectados**: `admin-api/Dockerfile`, `public-api/Dockerfile`, `frontend/Dockerfile`, `portal-publico/Dockerfile`, `.dockerignore` de cada uno.
- **Requisitos**: R1, ADR-1.
- **Verificacion**: `docker build` de cada imagen pasa.
- **Tamano estimado**: 120 lineas.
- **Dependencias**: T2.1.
- **Especialista**: infra.
- **Estado**: pending.

### T2.5: Configurar `cloudflared` opcional por profile
- **Descripcion**: Agregar servicio `cloudflared` con `profiles: ["tunnel"]`, sin token versionado, usando secret externo.
- **Archivos afectados**: `docker-compose.yml`.
- **Requisitos**: R1.
- **Verificacion**: `docker compose --profile tunnel config` incluye `cloudflared`; sin profile no inicia.
- **Tamano estimado**: 40 lineas.
- **Dependencias**: T2.1.
- **Especialista**: infra.
- **Estado**: pending.

### T2.6: Verificar `docker compose up -d`
- **Descripcion**: Levantar entorno completo en local y confirmar que todos los healthchecks reportan salud antes de aceptar trafico dependiente.
- **Archivos afectados**: N/A (verificacion).
- **Requisitos**: R1.
- **Verificacion**: `docker compose up -d` + `docker compose ps` muestra healthy.
- **Tamano estimado**: 30 lineas.
- **Dependencias**: T2.1, T2.2, T2.3, T2.4, T2.5.
- **Especialista**: infra.
- **Estado**: pending.

### T2.7: Smoke test de hosts locales
- **Descripcion**: Verificar que `public.localhost`, `admin.localhost`, `api.localhost` y `api-admin.localhost` enrutan correctamente y ningun servicio expone puerto HTTP alternativo.
- **Archivos afectados**: N/A (verificacion).
- **Requisitos**: R1.
- **Verificacion**: `curl -H Host:... localhost` responde 200/404 por servicio esperado.
- **Tamano estimado**: 30 lineas.
- **Dependencias**: T2.6.
- **Especialista**: infra.
- **Estado**: pending.

### T2.8: Pruebas negativas de conectividad entre redes
- **Descripcion**: Confirmar que `admin-api` no resuelve MongoDB/Redis/MinIO y `public-api` no resuelve PostgreSQL; bases de datos no publican puertos.
- **Archivos afectados**: scripts de smoke test.
- **Requisitos**: R2.
- **Verificacion**: `docker compose ps --format json` no muestra puertos publicos de DB/Redis/MinIO; `nc`/`ping` entre contenedores falla segun red.
- **Tamano estimado**: 30 lineas.
- **Dependencias**: T2.6.
- **Especialista**: infra.
- **Estado**: pending.

### Criterios de "done" para PR2
- [ ] `docker compose up -d` levanta todos los servicios con healthchecks healthy.
- [ ] Los cuatro hosts locales enrutan correctamente.
- [ ] PostgreSQL, MongoDB, Redis y MinIO no publican puertos.
- [ ] `cloudflared` solo inicia con `--profile tunnel`.
- [ ] Pruebas negativas de red confirman ownership.

---

## PR 3: Skeleton `public-api`, contratos, persistencia MongoDB/Redis

> **Lineas estimadas**: 620
> **Requisitos**: R1, R2, R10, R14
> **Especialista**: `springboot`

### T3.1: Crear `public-api/pom.xml` y estructura de paquetes
- **Descripcion**: Crear proyecto Spring Boot 3.x con `groupId=com.ferreplus`, `artifactId=ferreplus-public-api`, Java 21, starters web, data-mongodb, data-redis, validation, actuator, mail, minio, thymeleaf, lombok.
- **Archivos afectados**: `public-api/pom.xml`, `public-api/src/main/java/com/ferreplus/publico/PublicApiApplication.java`.
- **Requisitos**: R1, R2.
- **Verificacion**: `mvn -f public-api/pom.xml compile` pasa.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: PR2.
- **Especialista**: springboot.
- **Estado**: pending.

### T3.2: Configurar `application.yml` de `public-api`
- **Descripcion**: Configurar MongoDB, Redis, MinIO, SMTP, CORS, server.port, logging y perfiles `dev`/`test`.
- **Archivos afectados**: `public-api/src/main/resources/application.yml`, `application-dev.yml`, `application-test.yml`.
- **Requisitos**: R1, R2.
- **Verificacion**: Context load con perfil test.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T3.1.
- **Especialista**: springboot.
- **Estado**: pending.

### T3.3: Crear modelos MongoDB
> Tamano total estimado: 170 lineas. Se divide en sub-tareas.

#### T3.3.1: Modelos de contenido
- **Descripcion**: Crear `Publicacion`, `Convocatoria` y value objects `MetadataSEO`, `ImagenMedia`.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/model/Publicacion.java`, `Convocatoria.java`, `MetadataSEO.java`, `ImagenMedia.java`, `PostulacionEstado.java`.
- **Requisitos**: R3, R4.
- **Verificacion**: Compilacion + indices de campo unicos/compuestos documentados.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T3.1.
- **Especialista**: springboot.
- **Estado**: pending.

#### T3.3.2: Modelos de postulacion y estado
- **Descripcion**: Crear `Postulacion`, `CvMetadata`, `EstadoPostulacion` (enum) e historial embebido.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/model/Postulacion.java`, `CvMetadata.java`, `EstadoPostulacion.java`.
- **Requisitos**: R5, R6.
- **Verificacion**: Compilacion; unique index `convocatoriaId + idempotencyKey` documentado.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T3.3.1.
- **Especialista**: springboot.
- **Estado**: pending.

#### T3.3.3: Modelos de contacto, destinatarios, notificacion y claves
- **Descripcion**: Crear `Contacto`, `Destinatario`, `Notificacion` y `KeyDocument`.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/model/Contacto.java`, `Destinatario.java`, `Notificacion.java`, `KeyDocument.java`, `TipoDestinatario.java`, `EstadoNotificacion.java`.
- **Requisitos**: R7, R8, R9, R12.
- **Verificacion**: Compilacion + indices documentados.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T3.3.1.
- **Especialista**: springboot.
- **Estado**: pending.

### T3.4: Crear repositorios Spring Data MongoDB
- **Descripcion**: Interfaces para `Publicacion`, `Convocatoria`, `Postulacion`, `Contacto`, `Destinatario`, `Notificacion`, `KeyDocument` con metodos de consulta iniciales.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/repository/*.java`.
- **Requisitos**: R3, R4, R5, R8.
- **Verificacion**: Tests `@DataMongoTest` con embedded Mongo o Testcontainers cargan repositorios.
- **Tamano estimado**: 40 lineas.
- **Dependencias**: T3.3.1, T3.3.2, T3.3.3.
- **Especialista**: springboot.
- **Estado**: pending.

### T3.5: Crear DTOs separados por boundary
> Tamano total estimado: 100 lineas.

#### T3.5.1: DTOs publicos
- **Descripcion**: Records/clases para `PublicacionPublicaDTO`, `ConvocatoriaPublicaDTO`, `PostulacionRequestDTO`, `ContactoRequestDTO` con Bean Validation.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/dto/publico/*.java`.
- **Requisitos**: R3, R4, R8, R10.
- **Verificacion**: Tests de validacion con ValidatorFactory.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T3.3.1, T3.3.2, T3.3.3.
- **Especialista**: springboot.
- **Estado**: pending.

#### T3.5.2: DTOs internos (admin)
- **Descripcion**: Records/clases para `PublicacionAdminDTO`, `ConvocatoriaAdminDTO`, `PostulacionAdminDTO`, `ContactoAdminDTO`, `DestinatarioDTO` con validacion.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/dto/interno/*.java`.
- **Requisitos**: R3, R4, R8, R9.
- **Verificacion**: Compilacion + validacion basica.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T3.5.1.
- **Especialista**: springboot.
- **Estado**: pending.

### T3.6: Configurar manejo global de errores con ProblemDetail
- **Descripcion**: Crear `@RestControllerAdvice` que mapee excepciones a `ProblemDetail` RFC 7807 con `type`, `title`, `status`, `detail`, `instance`, `correlationId` y `errors`.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/exception/GlobalExceptionHandler.java`, excepciones de dominio.
- **Requisitos**: R10, ADR-11.
- **Verificacion**: Tests `@WebMvcTest` devuelven 400/404/409/429 con `application/problem+json`.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: T3.1.
- **Especialista**: springboot.
- **Estado**: pending.

### T3.7: Implementar filtro de correlation ID y MDC
- **Descripcion**: Filtro que obtiene/genere `X-Correlation-ID`, valida formato, lo coloca en MDC y lo devuelve en respuesta.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/config/CorrelationIdFilter.java`, `LoggingConfig.java`.
- **Requisitos**: R14.
- **Verificacion**: Header de respuesta coincide con request; MDC limpio en `finally`.
- **Tamano estimado**: 40 lineas.
- **Dependencias**: T3.1.
- **Especialista**: springboot.
- **Estado**: pending.

### T3.8: Configurar CORS restrictivo y headers de seguridad
- **Descripcion**: `SecurityConfig` con CORS allowlisted para Astro/Angular, headers CSP, HSTS (solo TLS), `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/security/SecurityConfig.java`.
- **Requisitos**: R10.
- **Verificacion**: Tests de headers en respuestas publicas.
- **Tamano estimado**: 40 lineas.
- **Dependencias**: T3.1.
- **Especialista**: springboot.
- **Estado**: pending.

### T3.9: Crear controllers base publicos e internos
> Tamano total estimado: 100 lineas.

#### T3.9.1: `PublicController` stubs y tests
- **Descripcion**: Crear `PublicController` con endpoints stub para publicaciones, convocatorias, postulaciones y contactos; `@WebMvcTest` de respuesta 200/404.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/controller/PublicController.java`, `PublicControllerTest.java`.
- **Requisitos**: R3, R4, R8.
- **Verificacion**: MockMvc responde 200 en stubs.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T3.5.1, T3.6.
- **Especialista**: springboot.
- **Estado**: pending.

#### T3.9.2: `InternalController` stubs y tests
- **Descripcion**: Crear `InternalController` con endpoints stub bajo `/api/internal/**` y tests de ruta.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/controller/InternalController.java`, `InternalControllerTest.java`.
- **Requisitos**: R12.
- **Verificacion**: MockMvc responde 200 en stubs.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T3.5.2, T3.6.
- **Especialista**: springboot.
- **Estado**: pending.

### T3.10: Verificar context load y propiedad de dependencias
- **Descripcion**: Test de contexto con perfil test; validar que `public-api` no tiene configuracion de PostgreSQL y no resuelve `postgres`.
- **Archivos afectados**: `public-api/src/test/java/com/ferreplus/publico/PublicApiApplicationTests.java`.
- **Requisitos**: R2.
- **Verificacion**: `mvn -f public-api/pom.xml test` verde.
- **Tamano estimado**: 30 lineas.
- **Dependencias**: T3.1, T3.2, T3.6, T3.7, T3.8.
- **Especialista**: springboot.
- **Estado**: pending.

### Criterios de "done" para PR3
- [ ] `public-api` compila y levanta contexto Spring.
- [ ] Modelos MongoDB, repositorios y DTOs creados.
- [ ] ProblemDetail, correlation ID, CORS y headers de seguridad funcionan.
- [ ] Controllers publicos e internos base responden.
- [ ] Tests unitarios/MVC pasan.
- [ ] `public-api` no depende de PostgreSQL.

---

## PR 4: MinIO, postulaciones, convocatorias y validacion de archivos

> **Lineas estimadas**: 770
> **Requisitos**: R4, R5, R6
> **Especialista**: `springboot`

### T4.1: Configurar cliente MinIO y buckets privados
- **Descripcion**: `MinioClient` bean, `MinioProperties`, creacion idempotente de `cv-bucket` y `media-bucket` con politica privada.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/config/MinioConfig.java`, `MinioProperties.java`, `storage/ObjectStorage.java`, `storage/MinioObjectStorage.java`.
- **Requisitos**: R6, ADR-6.
- **Verificacion**: Testcontainers/MinIO: buckets existen y son privados.
- **Tamano estimado**: 80 lineas.
- **Dependencias**: PR3.
- **Especialista**: springboot.
- **Estado**: pending.

### T4.2: Implementar `CvFileValidator`
- **Descripcion**: Validar extension allowlist (`.pdf`, `.doc`, `.docx`), tamano <= 5 MB, MIME real por magic bytes, mismatch devuelve error tipado.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/storage/CvFileValidator.java`, `CvValidationException.java`, `CvErrorCode.java`.
- **Requisitos**: R6.
- **Verificacion**: Tests unitarios con `.xlsx`, PDF valido, docx valido, MIME falso, >5 MB.
- **Tamano estimado**: 90 lineas.
- **Dependencias**: T3.1.
- **Especialista**: springboot.
- **Estado**: pending.

### T4.3: Implementar `ConvocatoriaService`
- **Descripcion**: CRUD, publicar/despublicar, cerrar manualmente, regla de periodo habilitado, listado publico solo abiertas.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/service/ConvocatoriaService.java`, `ConvocatoriaRepository.java`.
- **Requisitos**: R4.
- **Verificacion**: Tests unitarios e integracion de apertura/cierre.
- **Tamano estimado**: 80 lineas.
- **Dependencias**: T3.3.1, T3.4.
- **Especialista**: springboot.
- **Estado**: pending.

### T4.4: Implementar dominio y servicio de postulaciones
> Tamano total estimado: 150 lineas.

#### T4.4.1: Maquina de estados y transiciones
- **Descripcion**: Clase `PostulacionStateMachine` con tabla de transiciones permitidas (`RECEIVED -> UNDER_REVIEW -> ACCEPTED/REJECTED`, terminales).
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/service/PostulacionStateMachine.java`, `InvalidTransitionException.java`.
- **Requisitos**: R5, ADR-10.
- **Verificacion**: Tests property-based/unitarios de transiciones validas e invalidas.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T3.3.2.
- **Especialista**: springboot.
- **Estado**: pending.

#### T4.4.2: `PostulacionService`
- **Descripcion**: Recibir postulacion, validar convocatoria abierta ANTES de upload, guardar CV en MinIO, persistir postulacion con idempotencia, historial y metadata.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/service/PostulacionService.java`, `PostulacionRepository.java`.
- **Requisitos**: R5, R6, R10.
- **Verificacion**: Tests integracion con Testcontainers (valida, invalida, cerrada, idempotencia).
- **Tamano estimado**: 100 lineas.
- **Dependencias**: T4.1, T4.2, T4.3, T4.4.1.
- **Especialista**: springboot.
- **Estado**: pending.

### T4.5: Implementar endpoints publicos de postulaciones
- **Descripcion**: `POST /api/public/convocatorias/{id}/postulaciones` multipart con `Idempotency-Key` y honeypot.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/controller/PublicController.java`.
- **Requisitos**: R5, R10.
- **Verificacion**: MockMvc/integracion con archivo valido e invalido.
- **Tamano estimado**: 80 lineas.
- **Dependencias**: T4.4.2.
- **Especialista**: springboot.
- **Estado**: pending.

### T4.6: Implementar endpoints internos de convocatorias y postulaciones
- **Descripcion**: CRUD interno de convocatorias, listado/filtro de postulaciones, transicion de estado PATCH.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/controller/InternalController.java`.
- **Requisitos**: R4, R5, R12.
- **Verificacion**: Tests MockMvc de transiciones y listado.
- **Tamano estimado**: 80 lineas.
- **Dependencias**: T4.3, T4.4.2.
- **Especialista**: springboot.
- **Estado**: pending.

### T4.7: Implementar descarga autenticada de CV
- **Descripcion**: `GET /api/internal/postulaciones/{id}/cv` valida S2S (placeholder hasta PR8), registra descarga y streama objeto MinIO con `Content-Disposition`.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/controller/InternalController.java`, `storage/MinioObjectStorage.java`.
- **Requisitos**: R6.
- **Verificacion**: Descarga devuelve bytes; request publica/sin auth devuelve 401/403.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: T4.1, T4.6.
- **Especialista**: springboot.
- **Estado**: pending.

### T4.8: Tests de FSM, validador CV e integracion
> Tamano total estimado: 130 lineas.

#### T4.8.1: Tests unitarios de FSM y `CvFileValidator`
- **Descripcion**: JUnit5/Mockito para transiciones invalidas, reapertura, `.xlsx`, MIME falso, >5 MB.
- **Archivos afectados**: `public-api/src/test/java/com/ferreplus/publico/service/PostulacionStateMachineTest.java`, `storage/CvFileValidatorTest.java`.
- **Requisitos**: R5, R6.
- **Verificacion**: `mvn test` verde.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: T4.2, T4.4.1.
- **Especialista**: springboot.
- **Estado**: pending.

#### T4.8.2: Tests de integracion de postulacion
- **Descripcion**: Testcontainers/embedded Mongo+MinIO: postulacion valida, convocatoria cerrada, idempotencia, descarga.
- **Archivos afectados**: `public-api/src/test/java/com/ferreplus/publico/service/PostulacionServiceIntegrationTest.java`.
- **Requisitos**: R4, R5, R6.
- **Verificacion**: `mvn test` verde.
- **Tamano estimado**: 70 lineas.
- **Dependencias**: T4.4.2, T4.5, T4.7.
- **Especialista**: springboot.
- **Estado**: pending.

### T4.9: Implementar limpieza compensatoria de objetos huerfanos
- **Descripcion**: Al fallar persistencia MongoDB despues de guardar CV, borrar objeto; registrar orphan si el borrado falla.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/storage/ObjectCleanupService.java`.
- **Requisitos**: R6, R4.
- **Verificacion**: Test de simulacion de fallo Mongo; objeto no queda en bucket.
- **Tamano estimado**: 40 lineas.
- **Dependencias**: T4.4.2.
- **Especialista**: springboot.
- **Estado**: pending.

### Criterios de "done" para PR4
- [ ] CV valido se almacena en MinIO con metadata en MongoDB.
- [ ] `.xlsx`, MIME falso y >5 MB se rechazan sin almacenar.
- [ ] Convocatoria cerrada rechaza postulaciones sin objeto huerfano.
- [ ] FSM solo permite transiciones validas y audita actor/fecha/estados.
- [ ] Descarga de CV requiere autenticacion y no expone URL publica.
- [ ] Limpieza compensatoria registrada.

---

## PR 5: Contactos, publicaciones, correo asincrono y endpoints internos

> **Lineas estimadas**: 770
> **Requisitos**: R3, R7, R8, R9
> **Especialista**: `springboot`

### T5.1: Implementar publicaciones
> Tamano total estimado: 160 lineas.

#### T5.1.1: `PublicacionService`
- **Descripcion**: CRUD, estados `DRAFT`/`PUBLISHED`, portada/galeria/video/enlaces X, metadata SEO, listado publico solo publicados.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/service/PublicacionService.java`, `PublicacionRepository.java`.
- **Requisitos**: R3.
- **Verificacion**: Tests unitarios e integracion de borrador no publico.
- **Tamano estimado**: 80 lineas.
- **Dependencias**: T3.3.1, T3.4.
- **Especialista**: springboot.
- **Estado**: pending.

#### T5.1.2: Endpoints internos de publicaciones
- **Descripcion**: CRUD protegido `/api/internal/publicaciones`, previsualizacion, publicar/despublicar.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/controller/InternalController.java`.
- **Requisitos**: R3.
- **Verificacion**: MockMvc de CRUD y cambio de estado.
- **Tamano estimado**: 80 lineas.
- **Dependencias**: T5.1.1.
- **Especialista**: springboot.
- **Estado**: pending.

### T5.2: Implementar `ContactoService` con honeypot e idempotencia
- **Descripcion**: Validar contacto, honeypot vacio, idempotency key, persistir con estado `UNREAD`, hash de IP/fingerprint.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/service/ContactoService.java`, `ContactoRepository.java`.
- **Requisitos**: R8, R10.
- **Verificacion**: Tests de honeypot, idempotencia, contacto valido.
- **Tamano estimado**: 80 lineas.
- **Dependencias**: T3.3.3, T3.4.
- **Especialista**: springboot.
- **Estado**: pending.

### T5.3: Implementar `DestinatarioService`
- **Descripcion**: CRUD de destinatarios con tipo `JOB_APPLICATION`/`CONTACT_FORM`, activo/inactivo, unique `tipo + email`.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/service/DestinatarioService.java`, `DestinatarioRepository.java`.
- **Requisitos**: R9.
- **Verificacion**: Tests de CRUD y desactivacion.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: T3.3.3, T3.4.
- **Especialista**: springboot.
- **Estado**: pending.

### T5.4: Implementar eventos de dominio
- **Descripcion**: `PostulacionReceivedEvent` y `ContactoReceivedEvent` con id, tipo y correlation ID; publicar desde servicios.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/event/*.java`, ajustes en `PostulacionService`, `ContactoService`.
- **Requisitos**: R7.
- **Verificacion**: Tests de eventos publicados.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T4.4.2, T5.2.
- **Especialista**: springboot.
- **Estado**: pending.

### T5.5: Implementar correo asincrono
> Tamano total estimado: 140 lineas.

#### T5.5.1: Listener y executor de correo
- **Descripcion**: `@Async("mailTaskExecutor")` listener, crear `Notificacion` PENDING, enviar SMTP, reintentos con backoff, marcar SENT/FAILED.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/mail/MailEventListener.java`, `MailTaskExecutorConfig.java`, `NotificacionService.java`, `MailSenderAdapter.java`.
- **Requisitos**: R7, ADR-7.
- **Verificacion**: Tests con SMTP fake (GreenMail) y fallo simulado.
- **Tamano estimado**: 80 lineas.
- **Dependencias**: T5.3, T5.4.
- **Especialista**: springboot.
- **Estado**: pending.

#### T5.5.2: Plantillas Thymeleaf de correo
- **Descripcion**: Plantillas `postulacion-recibida.html`, `contacto-recibido.html`, confirmacion al visitante, con escape de variables.
- **Archivos afectados**: `public-api/src/main/resources/templates/mail/*.html`.
- **Requisitos**: R7.
- **Verificacion**: Renderizado de plantillas con datos de prueba.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: T5.5.1.
- **Especialista**: springboot.
- **Estado**: pending.

### T5.6: Implementar endpoints publicos de publicaciones y contactos
- **Descripcion**: `GET /api/public/publicaciones[/{slug}]`, `GET /api/public/convocatorias[/{id}]`, `POST /api/public/contactos`.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/controller/PublicController.java`.
- **Requisitos**: R3, R8.
- **Verificacion**: MockMvc/integracion de listado, detalle y contacto.
- **Tamano estimado**: 80 lineas.
- **Dependencias**: T5.1.1, T5.2.
- **Especialista**: springboot.
- **Estado**: pending.

### T5.7: Implementar endpoints internos de contactos, destinatarios y reenvio
- **Descripcion**: `/api/internal/contactos`, `/api/internal/destinatarios`, `/api/internal/notificaciones/{id}/reintentar`.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/controller/InternalController.java`.
- **Requisitos**: R8, R9.
- **Verificacion**: MockMvc de CRUD destinatarios y reenvio.
- **Tamano estimado**: 80 lineas.
- **Dependencias**: T5.2, T5.3, T5.5.1.
- **Especialista**: springboot.
- **Estado**: pending.

### T5.8: Tests de publicaciones, contacto y correo
> Tamano total estimado: 120 lineas.

#### T5.8.1: Tests unitarios de publicaciones y contacto
- **Descripcion**: Tests de borrador no publico, SEO metadata, honeypot, idempotencia.
- **Archivos afectados**: `public-api/src/test/java/com/ferreplus/publico/service/PublicacionServiceTest.java`, `ContactoServiceTest.java`.
- **Requisitos**: R3, R8, R10.
- **Verificacion**: `mvn test` verde.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T5.1.1, T5.2.
- **Especialista**: springboot.
- **Estado**: pending.

#### T5.8.2: Tests de integracion de correo
- **Descripcion**: Persist-first: postulacion/contacto persisten aunque SMTP falle; reintentos; destinatarios inactivos no reciben.
- **Archivos afectados**: `public-api/src/test/java/com/ferreplus/publico/mail/MailEventListenerIntegrationTest.java`.
- **Requisitos**: R7, R9.
- **Verificacion**: `mvn test` verde.
- **Tamano estimado**: 70 lineas.
- **Dependencias**: T5.5.1, T5.5.2.
- **Especialista**: springboot.
- **Estado**: pending.

### Criterios de "done" para PR5
- [ ] Publicaciones CRUD, estados DRAFT/PUBLISHED, borradores no publicos.
- [ ] Contacto persiste, confirma y notifica asincronicamente.
- [ ] Correo fallido no pierde registro; reintentos y reenvio funcionan.
- [ ] Destinatarios administrables con tipo y estado activo.
- [ ] Plantillas escapan variables y no hardcodean destinatarios.

---

## PR 6: Portal Astro SSG, SEO, rendimiento y formularios publicos

> **Lineas estimadas**: 620
> **Requisitos**: R15
> **Especialista**: `astro`

### T6.1: Inicializar proyecto Astro
- **Descripcion**: Crear `portal-publico/` con Astro 5.x, idioma español, output static, estructura de directorios.
- **Archivos afectados**: `portal-publico/package.json`, `tsconfig.json`, `src/env.d.ts`, `.gitignore`.
- **Requisitos**: R15.
- **Verificacion**: `npm install && npm run dev` inicia.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: PR2, PR5.
- **Especialista**: astro.
- **Estado**: pending.

### T6.2: Configurar `astro.config.mjs`
- **Descripcion**: `output: 'static'`, `@astrojs/sitemap`, `astro:assets`, base URL public-api en build-time por env.
- **Archivos afectados**: `portal-publico/astro.config.mjs`.
- **Requisitos**: R15.
- **Verificacion**: `npm run build` genera build sin errores.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T6.1.
- **Especialista**: astro.
- **Estado**: pending.

### T6.3: Crear layouts y componentes base
- **Descripcion**: `BaseLayout.astro` con `SeoHead` (title, description, canonical, Open Graph, robots, JSON-LD), `Header.astro`, `Footer.astro`, `Card.astro`.
- **Archivos afectados**: `portal-publico/src/layouts/*.astro`, `portal-publico/src/components/SeoHead.astro`, `Header.astro`, `Footer.astro`, `Card.astro`.
- **Requisitos**: R15.
- **Verificacion**: Inspeccion de HTML generado.
- **Tamano estimado**: 70 lineas.
- **Dependencias**: T6.2.
- **Especialista**: astro.
- **Estado**: pending.

### T6.4: Crear paginas de publicaciones
- **Descripcion**: `src/pages/publicaciones/index.astro` (listado) y `[slug].astro` (detalle) usando `getStaticPaths()` contra publicaciones publicadas.
- **Archivos afectados**: `portal-publico/src/pages/publicaciones/index.astro`, `[slug].astro`.
- **Requisitos**: R3, R15.
- **Verificacion**: Build genera HTML estatico con SEO.
- **Tamano estimado**: 80 lineas.
- **Dependencias**: T6.3, T6.7.
- **Especialista**: astro.
- **Estado**: pending.

### T6.5: Crear paginas de convocatorias
- **Descripcion**: `src/pages/convocatorias/index.astro` y `[id].astro` con detalle de convocatoria abierta.
- **Archivos afectados**: `portal-publico/src/pages/convocatorias/index.astro`, `[id].astro`.
- **Requisitos**: R4, R15.
- **Verificacion**: Build genera paginas solo de convocatorias abiertas.
- **Tamano estimado**: 70 lineas.
- **Dependencias**: T6.3, T6.7.
- **Especialista**: astro.
- **Estado**: pending.

### T6.6: Crear paginas de Trabaja con Nosotros y Contactanos
- **Descripcion**: `src/pages/trabajaconnosotros.astro` y `src/pages/contactanos.astro` con islands progresivas (`client:visible`), honeypot, validacion y fetch a public-api.
- **Archivos afectados**: `portal-publico/src/pages/trabajaconnosotros.astro`, `contactanos.astro`, `src/components/islands/ApplicationForm.ts`, `ContactForm.ts`.
- **Requisitos**: R5, R8, R10, R15.
- **Verificacion**: Formularios envian datos y manejan errores.
- **Tamano estimado**: 80 lineas.
- **Dependencias**: T6.3, T6.7.
- **Especialista**: astro.
- **Estado**: pending.

### T6.7: Implementar API client de public-api
- **Descripcion**: Cliente tipado en `src/lib/api-client/public-api.ts` con funciones para publicaciones, convocatorias, postulaciones y contactos; sin secretos.
- **Archivos afectados**: `portal-publico/src/lib/api-client/public-api.ts`, `types.ts`.
- **Requisitos**: R15.
- **Verificacion**: Tipos compilan; build-time no falla si API no responde (fixture/mock).
- **Tamano estimado**: 60 lineas.
- **Dependencias**: T6.1.
- **Especialista**: astro.
- **Estado**: pending.

### T6.8: Optimizar imagenes y cache
- **Descripcion**: Uso de `astro:assets` con WebP/AVIF, `loading=lazy`, `Cache-Control` headers en nginx.
- **Archivos afectados**: `portal-publico/src/components/*`, `portal-publico/nginx.conf`.
- **Requisitos**: R15.
- **Verificacion**: Lighthouse/inspeccion de headers.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T6.3.
- **Especialista**: astro.
- **Estado**: pending.

### T6.9: Generar sitemap y robots
- **Descripcion**: `@astrojs/sitemap` configurado para incluir solo paths publicos; `robots.txt` con `noindex` correcto para borradores (no se generan paginas).
- **Archivos afectados**: `portal-publico/astro.config.mjs`, `src/pages/robots.txt.ts`.
- **Requisitos**: R15.
- **Verificacion**: `sitemap.xml` no contiene borradores ni convocatorias cerradas.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T6.4, T6.5.
- **Especialista**: astro.
- **Estado**: pending.

### T6.10: Tests de build, SEO y sitemap
- **Descripcion**: Validar que el build SSG incluye SEO, no incluye borradores y los formularios funcionan con fixture.
- **Archivos afectados**: `portal-publico/src/tests/*`.
- **Requisitos**: R15, R18.
- **Verificacion**: `npm run build` + test fixture verde.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T6.4, T6.5, T6.6, T6.9.
- **Especialista**: astro.
- **Estado**: pending.

### Criterios de "done" para PR6
- [ ] `npm run build` genera sitio estatico.
- [ ] Paginas publicas incluyen title, description, canonical, Open Graph y JSON-LD.
- [ ] Sitemap/robots no incluyen borradores ni convocatorias cerradas.
- [ ] Formularios envian a `/api/public/**` con honeypot e idempotencia.
- [ ] Imagenes usan formatos optimizados y lazy loading.
- [ ] No se exponen secretos del backend en el cliente.

### T6.11: Correccion posterior — temas claro/oscuro del portal
- **Descripcion**: Incorporar selector accesible visible en Header, tokens CSS para modo claro y oscuro, persistencia en `localStorage`, preferencia del sistema y prevencion de flash mediante script inline temprano.
- **Archivos afectados**: `portal/src/layouts/BaseLayout.astro`, `portal/src/components/Header.astro`, `portal/src/styles/global.css`.
- **Requisitos**: R15, R18.
- **Verificacion**: `npm run check`, `npm run build`, inspeccion de HTML generado y prueba manual de ambos temas, foco y preferencia guardada.
- **Estado**: completed.

---

## PR 7: Modulo Angular de talento, RBAC y resiliencia

> **Lineas estimadas**: 770
> **Requisitos**: R13, R16, R17
> **Especialista**: `angular`

### T7.1: Crear modelos TypeScript del modulo
- **Descripcion**: Interfaces para `Publicacion`, `Convocatoria`, `Postulacion`, `Contacto`, `Destinatario` en `frontend/src/app/talento/models`.
- **Archivos afectados**: `frontend/src/app/talento/models/*.ts`.
- **Requisitos**: R16.
- **Verificacion**: Compilacion TypeScript.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: PR5.
- **Especialista**: angular.
- **Estado**: pending.

### T7.2: Crear `TalentoService`
- **Descripcion**: Servicio que consume `admin-api` (/api/admin/talento/...) con metodos para CRUD de publicaciones, convocatorias, postulaciones, contactos y destinatarios.
- **Archivos afectados**: `frontend/src/app/talento/services/talento.service.ts`.
- **Requisitos**: R16.
- **Verificacion**: Tests con `HttpTestingController`.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: T7.1.
- **Especialista**: angular.
- **Estado**: pending.

### T7.3: Crear `TalentoModule` y lazy routing
- **Descripcion**: NgModule, routing con `loadChildren`, rutas anidadas y `data.permissions`.
- **Archivos afectados**: `frontend/src/app/talento/talento.module.ts`, `talento-routing.module.ts`.
- **Requisitos**: R16, R17.
- **Verificacion**: `ng build` y navegacion lazy.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T7.1, T7.2.
- **Especialista**: angular.
- **Estado**: pending.

### T7.4: Registrar permisos y rutas en `RUTAS_POR_PERMISO`
- **Descripcion**: Mapear permisos `TALENTO_*` y `CONTABILIDAD_CONTACTOS_*` en `frontend/src/app/core/rutas-por-permiso.ts` y `app-routing.module.ts`.
- **Archivos afectados**: `frontend/src/app/core/rutas-por-permiso.ts`, `app-routing.module.ts`.
- **Requisitos**: R16, R17.
- **Verificacion**: Guard bloquea URL directa sin permiso.
- **Tamano estimado**: 30 lineas.
- **Dependencias**: T7.3.
- **Especialista**: angular.
- **Estado**: pending.

### T7.5: Implementar gestion de publicaciones en Angular
> Tamano total estimado: 130 lineas.

#### T7.5.1: `PublicacionListComponent`
- **Descripcion**: Tabla de publicaciones con estados, filtros, botones segun permisos.
- **Archivos afectados**: `frontend/src/app/talento/pages/publicaciones/publicacion-list/*`.
- **Requisitos**: R16.
- **Verificacion**: Tests de renderizado y permisos.
- **Tamano estimado**: 70 lineas.
- **Dependencias**: T7.2, T7.4.
- **Especialista**: angular.
- **Estado**: pending.

#### T7.5.2: `PublicacionFormComponent`
- **Descripcion**: Formulario reactivo para crear/editar/publicar/despublicar publicacion con SEO metadata y medios.
- **Archivos afectados**: `frontend/src/app/talento/pages/publicaciones/publicacion-form/*`.
- **Requisitos**: R3, R16.
- **Verificacion**: Tests de formulario y guardado.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: T7.5.1.
- **Especialista**: angular.
- **Estado**: pending.

### T7.6: Implementar gestion de convocatorias en Angular
> Tamano total estimado: 130 lineas.

#### T7.6.1: `ConvocatoriaListComponent`
- **Descripcion**: Tabla de convocatorias con apertura/cierre y estado.
- **Archivos afectados**: `frontend/src/app/talento/pages/convocatorias/convocatoria-list/*`.
- **Requisitos**: R16.
- **Verificacion**: Tests de listado.
- **Tamano estimado**: 70 lineas.
- **Dependencias**: T7.2, T7.4.
- **Especialista**: angular.
- **Estado**: pending.

#### T7.6.2: `ConvocatoriaFormComponent`
- **Descripcion**: Formulario para crear/editar/cerrar convocatoria.
- **Archivos afectados**: `frontend/src/app/talento/pages/convocatorias/convocatoria-form/*`.
- **Requisitos**: R4, R16.
- **Verificacion**: Tests de formulario.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: T7.6.1.
- **Especialista**: angular.
- **Estado**: pending.

### T7.7: Implementar gestion de postulaciones en Angular
> Tamano total estimado: 130 lineas.

#### T7.7.1: `PostulacionListComponent`
- **Descripcion**: Listado de postulaciones por convocatoria con filtros y boton de descarga CV.
- **Archivos afectados**: `frontend/src/app/talento/pages/postulaciones/postulacion-list/*`.
- **Requisitos**: R16.
- **Verificacion**: Tests de listado y permisos.
- **Tamano estimado**: 70 lineas.
- **Dependencias**: T7.2, T7.4.
- **Especialista**: angular.
- **Estado**: pending.

#### T7.7.2: `PostulacionDetailComponent` y descarga de CV
- **Descripcion**: Detalle, cambio de estado y descarga autenticada del CV (proxy por admin-api).
- **Archivos afectados**: `frontend/src/app/talento/pages/postulaciones/postulacion-detail/*`, `cv-download.component.*`.
- **Requisitos**: R5, R6, R16.
- **Verificacion**: Tests de transicion y descarga.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: T7.7.1.
- **Especialista**: angular.
- **Estado**: pending.

### T7.8: Implementar gestion de contactos y destinatarios
- **Descripcion**: Paginas de contactos (modulo contable) y CRUD de destinatarios, usando permisos correspondientes.
- **Archivos afectados**: `frontend/src/app/talento/pages/contactos/*`, `frontend/src/app/talento/pages/destinatarios/*`.
- **Requisitos**: R8, R9, R16.
- **Verificacion**: Tests de permisos y CRUD.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: T7.2, T7.4.
- **Especialista**: angular.
- **Estado**: pending.

### T7.9: Crear componente `IndisponibilidadTalentoComponent`
- **Descripcion**: Componente reutilizable que muestra exactamente `Servicio de postulaciones temporalmente no disponible` y permite reintentar sin duplicar POST.
- **Archivos afectados**: `frontend/src/app/talento/components/indisponibilidad/*`.
- **Requisitos**: R13.
- **Verificacion**: Test de texto exacto y reintento.
- **Tamano estimado**: 40 lineas.
- **Dependencias**: T7.2.
- **Especialista**: angular.
- **Estado**: pending.

### T7.10: Implementar estados loading/error/empty y fallback visual
- **Descripcion**: En cada pagina del modulo: loading skeleton/spinner, mensaje empty, error tipado y fallback de indisponibilidad.
- **Archivos afectados**: paginas de T7.5, T7.6, T7.7, T7.8.
- **Requisitos**: R13, R16.
- **Verificacion**: Checklist manual + tests de estado.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T7.5, T7.6, T7.7, T7.8, T7.9.
- **Especialista**: angular.
- **Estado**: pending.

### T7.11: Tests del modulo talento
- **Descripcion**: Tests de servicio, guards, formularios y componentes con Vitest/jsdom; verificar que usuario sin permiso no accede por URL.
- **Archivos afectados**: `frontend/src/app/talento/**/*.spec.ts`.
- **Requisitos**: R16, R17, R18.
- **Verificacion**: `npm test` verde.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: T7.2, T7.3, T7.4, T7.10.
- **Especialista**: angular.
- **Estado**: pending.

### Criterios de "done" para PR7
- [ ] Modulo `talento` lazy-loaded con rutas protegidas por RBAC.
- [ ] Usuario sin permiso no accede por URL directa.
- [ ] Admin gestiona publicaciones, convocatorias, postulaciones, contactos y destinatarios.
- [ ] Descarga de CV es autenticada y no expone almacenamiento.
- [ ] Fallback visual muestra literal `Servicio de postulaciones temporalmente no disponible`.
- [ ] `npm test` y `ng build` pasan.

---

## PR 8: S2S JWT, observabilidad, tests integrales y documentacion

> **Lineas estimadas**: 770
> **Requisitos**: R11, R12, R14, R18
> **Especialista**: `springboot` / `infra`

### T8.1: Implementar `S2sJwtFilter` y `KeyResolver`
- **Descripcion**: Filtro en `public-api` para `/api/internal/**` que valida firma RS256, `iss`, `aud`, `exp`, `kid`, `sub` y scope.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/security/S2sJwtFilter.java`, `KeyResolver.java`, `S2sSecurityConfig.java`.
- **Requisitos**: R12, ADR-5.
- **Verificacion**: Tests con JWT firmado de prueba.
- **Tamano estimado**: 80 lineas.
- **Dependencias**: PR3.
- **Especialista**: springboot.
- **Estado**: pending.

---

## Ronda 2: Judgment Day y CAPTCHA Turnstile

- [x] R2.1 Corregir proxy `/api/admin/talento` y `/api/internal`, mapeando DTOs y errores 401/403/503.
- [x] R2.2 Corregir bootstrap S2S por issuer, audience, `kid`, clave publica montada y redes internas.
- [x] R2.3 Verificar/agregar listados, transiciones de convocatorias/postulaciones y descarga autenticada de CV.
- [x] R2.4 Hacer idempotencia de contacto compatible con indice unico y recuperar notificaciones nulas en lotes acotados.
- [x] R2.5 Mantener rate limit por IP de proxy confiable, sin confiar en fingerprint arbitrario, con Retry-After.
- [x] R2.6 Implementar Turnstile server-side con fail-closed prod, DTOs sin persistencia del token y ProblemDetail.
- [x] R2.7 Integrar widget Turnstile accesible en contacto y postulacion, bloqueo de submit y reset.
- [ ] R2.8 Ejecutar suites completas, builds y smoke real de publicaciones/convocatorias (parcial: public-api, portal, compose, Mongo auth y aislamiento Actuator verificados; suite admin completa bloqueada por PostgreSQL local `localhost:5433` no disponible y falta smoke de datos funcionales).

### Evidencia de verificacion de la ronda final

- `docker compose --env-file .env config`: OK.
- Builds Docker `public-api` y `admin-api`: OK; `portal npm run check && npm run build`: OK.
- `public-api` unit/context suite: OK; `admin PublicApiClientTest`: OK.
- Compose: servicios criticos healthy; Actuator por `api.localhost` devuelve 404 y `127.0.0.1:8081` dentro de `public-api` devuelve UP.
- Mongo smoke autenticado con `ferreplus@127.0.0.1:27017`, database `ferreplus_public`, `authSource=admin`: `{ ok: 1 }`; no se modificaron datos.
- Turnstile: tests de token valido/invalido/fallo/produccion fail-closed OK; no se persiste ni loguea token. El banner oficial `For testing only` es esperado para claves de prueba.
- `git diff --check`: OK. No se ejecutaron `git add`, commits, push, `down -v` ni operaciones de datos.

### T8.2: Implementar endpoint interno de publicacion de claves
- **Descripcion**: `POST /api/internal/keys` para recibir public key con `kid`, expiracion y ventana de overlap; cache local de 5 min.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/controller/InternalController.java`, `KeyService.java`.
- **Requisitos**: R12, ADR-5.
- **Verificacion**: Tests de rotacion overlap.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T8.1.
- **Especialista**: springboot.
- **Estado**: pending.

### T8.3: Implementar `PublicApiClient` en `admin-api`
- **Descripcion**: `RestClient` con connect 1s/read 3s, generacion de JWT S2S, propagacion de correlation ID, mapeo de errores a excepciones tipadas.
- **Archivos afectados**: `admin-api/src/main/java/com/ferreplus/client/publico/PublicApiClient.java`, `S2sJwtProperties.java`, `PublicApiErrorMapper.java`.
- **Requisitos**: R12, R13, R14.
- **Verificacion**: Tests unitarios con MockRestServiceServer.
- **Tamano estimado**: 70 lineas.
- **Dependencias**: PR1, T8.1.
- **Especialista**: springboot.
- **Estado**: completed (tests focales `PublicApiClientTest` verdes).

### T8.4: Actualizar DataSeeder/RBAC con modulos nuevos
- **Descripcion**: Agregar modulos `TALENTO_PUBLICACIONES`, `TALENTO_CONVOCATORIAS`, `TALENTO_POSTULACIONES`, `TALENTO_DESTINATARIOS`, `CONTABILIDAD_CONTACTOS` con acciones VER/CREAR/EDITAR/ELIMINAR; rol ADMIN recibe todos automaticamente.
- **Archivos afectados**: `admin-api/src/main/java/com/ferreplus/config/DataSeeder.java`, permisos en `frontend/src/app/core/rutas-por-permiso.ts`.
- **Requisitos**: R9, R17.
- **Verificacion**: DataSeeder idempotente; admin tiene todos los permisos nuevos.
- **Tamano estimado**: 80 lineas.
- **Dependencias**: T7.4.
- **Especialista**: springboot / angular.
- **Estado**: pending.

### T8.5: Implementar logging estructurado y eventos de observabilidad
- **Descripcion**: JSON logs con `timestamp`, `level`, `service`, `correlationId`, `event`, `route`, `status`, `durationMs`; eventos obligatorios: `application.received`, `application.status_changed`, `contact.received`, `validation.rejected`, `rate_limit.activated`, `storage.failure`, `storage.download`, `mail.failure`, `mail.sent`, `s2s.rejected`, `dependency.unavailable`.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/config/StructuredLogging.java`, `ObservationService.java`; ajustes en `admin-api`.
- **Requisitos**: R14.
- **Verificacion**: Logs no contienen CV, tokens ni datos sensibles.
- **Tamano estimado**: 70 lineas.
- **Dependencias**: T3.7.
- **Especialista**: springboot.
- **Estado**: pending.

### T8.6: Implementar rate limiting Redis con fallback local
- **Descripcion**: Script Lua `INCR+EXPIRE` para limites confirmados (postulaciones 3/15min + 10/dia; contactos 5/15min + 20/dia), contadores complementarios fingerprint/email, 429 con `Retry-After`, fail-open local conservador.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/ratelimit/*.java`, `RateLimitFilter.java`.
- **Requisitos**: R11, ADR-8.
- **Verificacion**: Tests de 429 y Retry-After.
- **Tamano estimado**: 90 lineas.
- **Dependencias**: PR3.
- **Especialista**: springboot.
- **Estado**: completed (IP/proxy confiable + fingerprint/email HMAC obligatorio + Retry-After; tests unitarios verdes).

### T8.7: Configurar Actuator, metricas y healthchecks
- **Descripcion**: Endpoints `/actuator/health`, `/actuator/info`, `/actuator/metrics` solo por red interna; healthchecks de Mongo, Redis, MinIO.
- **Archivos afectados**: `public-api/src/main/java/com/ferreplus/publico/config/ActuatorConfig.java`, `HealthIndicators.java`; `admin-api` actuator.
- **Requisitos**: R1, R14.
- **Verificacion**: Healthchecks saludables en Compose.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: T2.1.
- **Especialista**: springboot.
- **Estado**: completed (Actuator funcional en puerto interno 8081/bind loopback; healthcheck Docker validado).

### T8.8: Tests integrales de seguridad, rate limit y resiliencia
> Tamano total estimado: 170 lineas.

#### T8.8.1: Tests S2S y seguridad
- **Descripcion**: JWT invalido, expirado, firma incorrecta, audience/issuer wrong, scope insuficiente devuelven 401/403.
- **Archivos afectados**: `public-api/src/test/java/com/ferreplus/publico/security/S2sJwtFilterTest.java`, `admin-api/src/test/java/com/ferreplus/client/publico/PublicApiClientTest.java`.
- **Requisitos**: R12.
- **Verificacion**: `mvn test` verde en ambos servicios.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: T8.1, T8.3.
- **Especialista**: springboot.
- **Estado**: completed para tests focales; suite admin completa queda condicionada a PostgreSQL local.

#### T8.8.2: Tests de rate limit y resiliencia
- **Descripcion**: 429 con Retry-After, contadores complementarios, fallback local, caida de public-api no bloquea admin-api.
- **Archivos afectados**: `public-api/src/test/java/com/ferreplus/publico/ratelimit/RateLimitIntegrationTest.java`, `admin-api/src/test/java/com/ferreplus/service/ResilienciaTalentoTest.java`.
- **Requisitos**: R11, R13.
- **Verificacion**: `mvn test` verde.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: T8.6, T8.3.
- **Especialista**: springboot.
- **Estado**: pending.

#### T8.8.3: Smoke test end-to-end del flujo completo
- **Descripcion**: Script/manual: crear publicacion/convocatoria, postularse desde portal, descargar CV, cambiar estado, enviar contacto, verificar correo y logs.
- **Archivos afectados**: scripts `smoke/`.
- **Requisitos**: R18.
- **Verificacion**: Checklist ejecutado exitosamente.
- **Tamano estimado**: 50 lineas.
- **Dependencias**: PR4, PR5, PR6, PR7.
- **Especialista**: infra.
- **Estado**: pending.

### T8.9: Documentar arquitectura y ADRs
> Tamano total estimado: 120 lineas.

#### T8.9.1: ADRs
- **Descripcion**: Documentar ADR-1 a ADR-12 en `docs/adr/` con contexto, decision, alternativas, consecuencias.
- **Archivos afectados**: `docs/adr/ADR-*.md`.
- **Requisitos**: R18, ADRs del design.
- **Verificacion**: Review de ADRs completos y trazables.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: PR1-PR7.
- **Especialista**: infra.
- **Estado**: pending.

#### T8.9.2: Documentacion operativa
- **Descripcion**: Diagrama de arquitectura, matriz de ownership de datos, matriz de redes, threat model, flujos S2S/correo/almacenamiento, runbook de rotacion de claves.
- **Archivos afectados**: `docs/architecture/*.md`.
- **Requisitos**: R18.
- **Verificacion**: Un revisor externo puede identificar ownership y trade-offs.
- **Tamano estimado**: 60 lineas.
- **Dependencias**: T8.9.1.
- **Especialista**: infra.
- **Estado**: pending.

### T8.10: Verificacion final cross-stack
- **Descripcion**: Ejecutar suites de backend (`admin-api` y `public-api`), frontend (`npm test`) y portal (`npm run build`); corregir regressiones.
- **Archivos afectados**: N/A.
- **Requisitos**: R18.
- **Verificacion**: Todos los checks verdes y escenarios de `spec.md` trazables a tests.
- **Tamano estimado**: 40 lineas.
- **Dependencias**: T8.8.1, T8.8.2, T7.11, T6.10.
- **Especialista**: infra / springboot / angular / astro.
- **Estado**: pending.

### Criterios de "done" para PR8
- [ ] `/api/internal/**` rechaza JWT invalido/expirado/firma incorrecta.
- [ ] Rotacion de claves S2S mantiene overlap controlado.
- [ ] Rate limiting devuelve 429 con `Retry-After` y falla abierta conservadora.
- [ ] Logging estructurado con correlation ID end-to-end y sin datos sensibles.
- [ ] DataSeeder asigna modulos nuevos al rol ADMIN.
- [ ] Tests de seguridad, rate limit y resiliencia pasan.
- [ ] Documentacion y ADRs completos.

---

## Orden de ejecucion recomendado

```text
PR1  -> PR2  -> PR3  -> PR4  -> PR5  -> PR6  -> PR7  -> PR8
rename   infra  public-api  talento  contenido/  portal  angular   S2S/obs/docs
backend  +      skeleton    + CV     contacto    Astro   + RBAC
         Traefik            FSM      + correo
```

### Dependencias criticas
- **PR1 debe fusionarse antes que PR2**: el Compose de PR2 referencia el servicio/imagen `admin-api`.
- **PR2 debe fusionarse antes que PR3**: `public-api` necesita redes, MongoDB, Redis y MinIO levantados.
- **PR3 debe fusionarse antes que PR4/PR5**: modelos, repositorios y DTOs son base de dominio.
- **PR4 debe fusionarse antes que PR5**: `PostulacionService` demuestra el patron de eventos que reutiliza `ContactoService` y correo.
- **PR5 debe fusionarse antes que PR6/PR7**: el portal y Angular consumen endpoints publicos/internos ya implementados.
- **PR6 y PR7 son independientes entre si** una vez PR5 esta listo; pueden desarrollarse en paralelo.
- **PR8 cierra la cadena**: requiere endpoints internos (PR5), cliente en `admin-api` (PR1), modulo Angular (PR7) y portal (PR6).

---

## Review Workload Forecast

| PR | Lineas estimadas | Riesgo de review | Notas |
|----|------------------|------------------|-------|
| PR1 | 450 | Bajo | Rename aislado; facil rollback. |
| PR2 | 700 | Medio | Configuracion de redes/Traefik; requiere smoke tests. |
| PR3 | 620 | Medio | Muchos stubs y configuracion base. |
| PR4 | 770 | Medio-Alto | Logica de archivos y FSM; tests criticos. |
| PR5 | 770 | Medio-Alto | Correo asincrono y eventos. |
| PR6 | 620 | Medio | SSG + SEO + islands. |
| PR7 | 770 | Medio-Alto | Modulo Angular grande con RBAC y estados. |
| PR8 | 770 | Medio-Alto | S2S, observabilidad, tests integrales y docs. |
| **Total** | **5.470** | | |

- **Cambios totales estimados**: ~5.470 lineas (dentro del rango 3.500-5.500 del proposal).
- **Chained PRs recommended**: Yes (8 PRs).
- **400-line budget risk**: No (presupuesto es 800 lineas/PR; maximo estimado 770).
- **Decision needed before apply**: No (el usuario ya confirmo C3 force-chained).
- **Riesgos de review principales**:
  - PR2: configuracion compleja de redes y labels de Traefik; riesgo de exposicion accidental.
  - PR4: validacion de archivos y cleanup de objetos; requiere tests negativos robustos.
  - PR5: correo asincrono; verificar persist-first y reintentos.
  - PR7: modulo Angular con muchas paginas; riesgo de duplicacion si no se reutiliza componentes.
  - PR8: seguridad S2S y rate limit; requiere revision cuidadosa de claves y logs.
