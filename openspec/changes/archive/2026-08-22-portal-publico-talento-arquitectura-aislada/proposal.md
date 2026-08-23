# Proposal: Portal Publico y Gestion de Talento con Arquitectura Aislada

## Resumen ejecutivo

Este change incorpora un portal corporativo publico en Astro y un modulo administrativo de Gestion de Talento en Angular, respaldados por un nuevo `public-api` Spring Boot. El portal permitira publicar contenido corporativo, convocatorias, recibir postulaciones con CV y atender contactos; el modulo administrativo permitira gestionar ese contenido y el ciclo de las postulaciones.

La arquitectura adopta aislamiento real: `admin-api` sera el nombre del backend Spring Boot existente y continuara siendo dueno de PostgreSQL; `public-api` sera dueno exclusivo de MongoDB, Redis y MinIO. Traefik, Docker Compose, redes separadas, autenticacion service-to-service, rate limiting, correo asincrono y observabilidad completan la base operativa. La aplicacion movil Flutter no participa en este change.

## Intent

Ferreplus necesita una presencia corporativa publica y un flujo profesional para atraer talento sin exponer ni acoplar el backend administrativo existente a los datos publicos. Hoy no existen portal Astro, modulo de talento, almacenamiento de archivos, correo, reverse proxy ni controles de abuso, y el Compose solo levanta el backend mediante `network_mode: host`.

El change resuelve esa brecha mediante limites claros de responsabilidad y de red. El portal consumira solo `/api/public/**`; las operaciones administrativas de talento usaran Angular y `admin-api`, que accedera a `public-api` unicamente por `/api/internal/**`. No se agregara un bridge service ni se permitira acceso directo de `admin-api` a MongoDB, Redis o MinIO.

## Scope

### In Scope

1. **Infraestructura reproducible**: renombrar `backend/` a `admin-api/`; crear Compose con Traefik, `admin-api`, `public-api`, Astro, Angular, PostgreSQL, MongoDB, Redis y MinIO; redes `public_net`, `admin_net`, `public_data`, `admin_data` e `internal_services`; healthchecks, limites de recursos, restart policies, profiles y secretos fuera de Git. `cloudflared` sera opcional mediante profile.
2. **Nuevo `public-api` Spring Boot**: arquitectura por capas, DTOs explicitos, Bean Validation, manejo global de errores, CORS restrictivo, headers de seguridad, timeouts, logging estructurado y correlation IDs. `/api/public/**` sera publico con controles de abuso; `/api/internal/**` exigira identidad service-to-service y solo sera accesible desde `admin-api` por la red interna.
3. **Ownership de datos**: `public-api` sera el unico servicio con acceso a MongoDB, Redis y MinIO; `admin-api` conservara PostgreSQL como unico almacenamiento administrativo. Las bases de datos no tendran puertos publicados a Internet y Redis/MinIO no tendran acceso publico directo.
4. **Publicaciones/cartelera**: modelo y API para contenido administrable con estado de borrador/publicado, portada, galeria, video, enlaces X y metadatos SEO solo cuando correspondan al contenido real. Los campos definitivos se validaran en el design/spec y no se inventaran atributos sin necesidad funcional.
5. **Convocatorias y postulaciones**: vacantes publicables, cierre de convocatorias, formulario publico y carga de CV. El archivo usara claves UUID en MinIO y metadata en MongoDB (`objectKey`, `fileName`, `mimeType`, `size`, `createdAt`), con validacion del MIME real, limite de tamano, acceso administrativo autenticado y sin URL publica permanente.
6. **Gestion Angular de talento**: listado y edicion de publicaciones/convocatorias, consulta de postulaciones, descarga autenticada del CV y transiciones de estado (nombres exactos por confirmar) con auditoria de quien, cuando, estado anterior y nuevo. Se reutilizara el RBAC existente para que el modulo contable administre los mensajes de contacto.
7. **Trabaja con Nosotros y Contactanos**: paginas Astro y formularios publicos validados. Contactos y postulaciones se persistiran, tendran confirmacion al usuario y notificacion por correo; el modulo contable gestionara los mensajes de contacto mediante `admin-api` y endpoints internos.
8. **Correo resiliente**: envio asincrono con Spring Events + `@Async` o mecanismo equivalente; la falla SMTP no perdera la postulacion/contacto. Habra plantillas profesionales separadas del controller y destinatarios administrables, nunca hardcodeados.
9. **Seguridad y resiliencia**: rate limiting con Redis, honeypot, idempotencia, limites de payload/archivo, sanitizacion, logs sin datos sensibles, timeouts y fallback visual en Angular cuando `public-api` no este disponible. Se documentara el mecanismo S2S y sus rotaciones.
10. **Astro orientado a rendimiento**: prerender estatico cuando sea viable, islands solo para interactividad necesaria, minimo JavaScript, imagenes WebP/AVIF con `astro:assets`, lazy loading, cache HTTP y layouts/componentes reutilizables. SEO con title, description, canonical, Open Graph, sitemap, robots y structured data; borradores no indexables.
11. **Calidad y documentacion**: tests unitarios e integracion para flujos validos/invalidos, convocatoria cerrada, archivos invalidos/grandes, rate limiting, cambios de estado, contacto y caida de `public-api`; tests de componentes/formularios/estados Angular; documentacion de arquitectura y ADRs.
12. **Operabilidad**: `docker compose up -d` levantara el entorno completo; la solucion sera stateless-friendly para una futura migracion, pero Kubernetes queda fuera de este change.

### Out of Scope

- Aplicacion movil `flutter/`, sus APIs, pantallas o despliegue.
- Kubernetes, Helm, operadores, service mesh o despliegue cloud especifico; solo se documentara compatibilidad stateless-friendly.
- Redisenar el admin existente, migrar todo Angular a standalone/signals o reescribir modulos no relacionados; solo se modificara lo necesario para renombrar `backend/`, integrar talento y consumir el contrato interno.
- Acceso directo de `admin-api` a MongoDB, Redis o MinIO; no se creara un bridge service.
- CMS general, multi-tenant, internacionalizacion, portal autenticado para candidatos o seguimiento publico de postulaciones.
- RabbitMQ u otro broker: no se incorporara sin una necesidad demostrada y un ADR posterior.
- Integraciones externas de ATS, LinkedIn, X, CRM o proveedores de correo concretos mas alla de un puerto/configuracion SMTP.
- Analitica avanzada, campanas de marketing y redisenos de marca no necesarios para los flujos definidos.

## Objetivos medibles

- `docker compose up -d` inicia todos los servicios definidos y cada contenedor critico reporta healthcheck saludable.
- No existen puertos publicos para PostgreSQL, MongoDB, Redis ni MinIO; Traefik es el unico entrypoint HTTP del entorno.
- Las rutas publicas no requieren autenticacion, pero `/api/internal/**` rechaza solicitudes sin identidad S2S valida.
- Una postulacion valida conserva metadata y CV en MinIO, y una postulacion invalida por MIME/tamano o convocatoria cerrada es rechazada sin objeto huerfano.
- La falla del correo no elimina postulaciones/contactos y queda registrada con correlation ID.
- Los tests de backend y frontend configurados por el proyecto pasan, incluyendo los escenarios de seguridad, abuso y resiliencia.
- Astro entrega contenido publico prerenderizado sin JavaScript innecesario y los borradores no aparecen en sitemap/robots/metadata indexable.

## Approach

Se implementara la **Opcion A confirmada: aislamiento real por servicios y ownership de datos**, en cinco fases secuenciales. Cada fase debe dejar un slice desplegable y testeable, con PRs encadenados para mantener el presupuesto de revision bajo 800 lineas por PR.

### Fase 1 — Infraestructura y redes

Renombrar `backend/` a `admin-api/` sin redisenar su dominio; crear Dockerfiles multi-stage con imagen minima y usuario non-root; definir Compose, Traefik, redes separadas, healthchecks, limites, profiles y `.env.example`. Las rutas de desarrollo seran `public.localhost`, `admin.localhost`, `api.localhost` y `api-admin.localhost`. `cloudflared` usara profile y token por secret, nunca Git.

### Fase 2 — `public-api`, almacenamiento y protecciones

Crear el servicio Spring Boot con ownership exclusivo de MongoDB/Redis/MinIO. Implementar primero modelos y contratos para publicaciones, convocatorias, postulaciones y contactos; despues MinIO, metadata, validacion, rate limiting, idempotencia, endpoints publicos/internos, auditoria y correo asincrono. La disponibilidad degradada debera preservar la postulacion aunque falle SMTP.

### Fase 3 — Portal Astro

Crear una app Astro separada con SSG/prerender por defecto y consumo de la API publica. Usar layouts tipados, componentes `.astro`, content collections para contenido local Markdown/MDX cuando aplique, `astro:assets`, SEO y `@astrojs/sitemap`; hidratar solo formularios o islas que requieran interaccion. El contenido remoto publicado se resolvera sin exponer credenciales del backend.

### Fase 4 — Modulo Angular de talento

Agregar el feature module respetando la compatibilidad del admin actual (NgModule, lazy loading, Reactive Forms y Angular Material/Bootstrap existentes), sin iniciar una migracion transversal. Separar servicios/DTOs, estado de pantallas y componentes; proteger rutas con el RBAC existente y mantener accesibles los formularios, estados y mensajes de indisponibilidad.

### Fase 5 — S2S y observabilidad

Cerrar la integracion `admin-api` → `public-api` con autenticacion rotatable, timeouts y propagacion de correlation ID; completar logging estructurado, metricas/logs de eventos relevantes y documentacion/ADRs. Verificar que una caida de `public-api` no impide que `admin-api` siga atendiendo sus dominios propios.

### Razonamiento y trade-offs

La separacion aumenta contenedores, configuracion y costo operativo frente a un monolito, pero evita que el portal publico amplie la superficie del sistema administrativo y hace explicito quien es dueno de cada dato. MongoDB se mantiene para contenido flexible y metadata de postulaciones; PostgreSQL no se replica porque el admin sigue siendo su dueño. Redis se limita a rate limiting/controles efimeros, y MinIO evita guardar binarios en MongoDB o PostgreSQL.

Para correo se prefiere Spring Events + `@Async` porque cubre el volumen esperado sin introducir un broker adicional; el trade-off es que la entrega no es durable ante una caida prolongada del proceso, por lo que el design debera definir reintentos, estado de envio y una operacion de reenvio. Para Astro se prioriza SSG/zero-JS; si el contenido dinamico impide prerender completo, se usara SSR o islands de forma puntual y justificada.

## Decisiones clave ya tomadas

| Decision | Resolucion | Motivo |
|---|---|---|
| Topologia | Renombrar `backend/` a `admin-api/` y crear `public-api/` separado | Aislamiento real y ownership claro |
| Datos | `admin-api` solo PostgreSQL; `public-api` solo MongoDB, Redis y MinIO | Evitar acoplamiento y accesos cruzados |
| Integracion | Angular → `admin-api` → HTTP interno → `public-api` | No existe bridge service |
| Redes | `public_net`, `admin_net`, `public_data`, `admin_data`, `internal_services` | Reducir alcance de movimiento lateral |
| Exposicion | Traefik como entrypoint; Cloudflare/Tunnel opcional | Unico punto de entrada y despliegue local reproducible |
| Archivos | MinIO para CV y MongoDB para metadata | Separar binario, metadata y acceso autenticado |
| Anti-spam | Redis + rate limit + honeypot + idempotencia | Defensa en profundidad sin broker adicional |
| Correo | Eventos y procesamiento asincrono | No bloquear ni perder el registro por fallo SMTP |
| Flutter | Fuera de este change | Se trabajara en una iniciativa independiente |

## Decisiones que requieren input del usuario

1. **Autenticacion S2S**: se recomienda **JWT firmado asimetricamente (RS256/EdDSA) con audiencia, issuer, expiracion corta, `kid` y rotacion de claves**. Es mas auditable y escalable que compartir un secreto HMAC; una credencial estatica es mas simple pero mas dificil de rotar y limita la trazabilidad. HMAC sigue siendo una alternativa valida para un entorno pequeno si se acepta compartir y rotar un secreto.
2. **Estados exactos de postulacion**: propuesta inicial `RECEIVED`, `UNDER_REVIEW`, `ACCEPTED`, `REJECTED`. Confirmar nombres, si `REJECTED` permite reabrir y si se requiere `WITHDRAWN`/`HIRED`.
3. **Rate limiting**: confirmar limites iniciales. Sugerencia: postulaciones `3/IP/15 min` y `10/IP/dia`, contactos `5/IP/15 min` y `20/IP/dia`, con limites complementarios por fingerprint/correo y respuestas `429` con `Retry-After`. No se debe tratar IP como identidad unica.
4. **Destinatarios administrables**: confirmar quienes pueden modificarlos con el RBAC existente y si se necesita historial/auditoria de cambios.
5. **Politica de CV**: confirmar extensiones permitidas y limite inicial sugerido de 5 MB; el sistema debe validar MIME real, no solo extension.

## Affected Areas

| Area | Impact | Description |
|---|---|---|
| `backend/` → `admin-api/` | Renamed/Modified | Renombre controlado del backend existente, rutas, Compose y referencias de build |
| `public-api/` | New | Servicio Spring Boot, DTOs, capas, seguridad S2S, MongoDB/Redis/MinIO, correo y endpoints public/internal |
| `portal-publico/` o `public-portal/` | New | App Astro, layouts, paginas corporativas, formularios, SEO, sitemap e imagenes optimizadas |
| `frontend/src/app/talento/` | New | Feature Angular administrativo de publicaciones, convocatorias, postulaciones y contactos |
| `frontend/src/app/core/` y RBAC existente | Modified | Cliente interno, permisos/rutas y manejo de timeouts/indisponibilidad, solo donde sea necesario |
| `docker-compose.yml`, `docker-compose.override.yml`, `.env.example` | New/Modified | Servicios, redes, profiles, healthchecks, limites, secretos y rutas Traefik |
| `traefik/`, `cloudflared/` | New | Configuracion declarativa del proxy y tunnel opcional sin tokens versionados |
| `docs/architecture/`, `docs/adr/` | New | Diagrama, ownership, threat model, flujos, S2S, correo, almacenamiento y ADRs |
| `admin-api/src/test/`, `public-api/src/test/`, `frontend/src/app/**/*.spec.ts` | New/Modified | Cobertura de contratos, seguridad, archivos, rate limiting, estados, formularios y resiliencia |

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Renombrar `backend/` rompe rutas, Docker o CI | High | Slice exclusivo, busqueda de referencias, build desde Compose y rollback por PR antes de funcionalidad |
| Configuracion de redes permite acceso cruzado accidental | High | `exposedByDefault=false`, puertos internos, pruebas negativas de conectividad y matriz de ownership documentada |
| CV malicioso o archivo falsificado por extension | High | MIME real, limite de bytes, UUID key, validacion de contenido, no URL publica permanente y descarga autenticada |
| Spam, abuso o duplicacion de formularios | High | Redis rate limit, honeypot, idempotency key, validacion, limites y observabilidad de `429` |
| Falla de SMTP bloquea o pierde postulaciones | Med | Persistir primero, evento asincrono, estado de envio, reintentos y reenvio administrativo |
| `public-api` caido bloquea operaciones administrativas | Med | Timeouts cortos, errores tipados, fallback visual y circuit behavior sin acoplar la transaccion PostgreSQL |
| Drift entre DTOs Astro/Angular y APIs | Med | Contratos versionados/documentados, integration tests y tipos centralizados por cliente sin compartir runtime |
| Migracion Angular inconsistente | Med | No migrar el admin existente; respetar NgModule/lazy loading/Reactive Forms en este feature y documentar excepciones |
| Datos publicos sensibles quedan en logs o metadata | Med | Logging estructurado con redaccion, correlation ID sin CV/contenido, retencion y controles de acceso |
| SSG muestra borradores o contenido obsoleto | Med | API solo entrega publicados, `noindex` en borradores, invalidacion/rebuild definido y tests de sitemap |

## Rollback Plan

- Ejecutar rollback por PR encadenado, empezando por deshabilitar rutas Traefik y el portal publico sin tocar el dominio administrativo existente.
- Si falla la Fase 1, restaurar la ruta anterior de `backend/` y el Compose previo; no mezclar el renombre con cambios funcionales irreversibles.
- Si falla `public-api`, retirar sus rutas/publicacion y dejar `admin-api` operativo; los datos publicos permanecen aislados en sus volúmenes y no se eliminan automaticamente.
- Revertir configuracion de red, profiles y variables mediante el commit del slice correspondiente. No borrar volumenes PostgreSQL/MongoDB/MinIO como parte del rollback.
- Si se requiere limpiar datos de prueba, hacerlo mediante procedimiento revisado manualmente; el change no ejecuta operaciones destructivas de base de datos de forma automatica.

## Dependencies

- Docker Compose y Docker Engine compatibles con healthchecks, profiles, secrets/configs y redes definidas.
- Imagenes/artefactos de Java 21, Node/Angular 22 y Astro disponibles para builds multi-stage.
- MongoDB, Redis y MinIO provisionados exclusivamente dentro de `public_data`/`internal_services`.
- SMTP configurable y credenciales gestionadas fuera de Git.
- DNS/Cloudflare solo para despliegue; el desarrollo local funciona con hosts/rutas `*.localhost`.
- Aprobacion del mecanismo S2S, estados de postulacion y limites iniciales antes del design detallado.

## Estimacion preliminar y estrategia de revision

El change completo se estima en **3.500–5.500 lineas cambiadas** entre codigo, configuracion, tests y documentacion. No se debe entregar como un PR unico: el presupuesto de revision es **800 lineas por PR**.

Se propone un minimo de **8 PRs encadenados** de aproximadamente 400–750 lineas cada uno:

1. Renombre `backend/` → `admin-api/`, Dockerfiles y referencias.
2. Compose, Traefik, redes, profiles, healthchecks, limites y `.env.example`.
3. Esqueleto/contratos de `public-api` y persistencia MongoDB/Redis.
4. MinIO, postulaciones, convocatorias y validacion de archivos.
5. Contactos, publicaciones, correo asincrono y endpoints internos.
6. Portal Astro, SEO, rendimiento y formularios publicos.
7. Modulo Angular de talento, RBAC y resiliencia.
8. S2S, observabilidad, tests integrales, documentacion y ADRs.

El conteo es preliminar y debera recalibrarse en `design.md` y `tasks.md`; ningun slice debe superar 800 lineas sin dividirse nuevamente.

## Success Criteria

- [ ] El portal publico permite consultar solo publicaciones/convocatorias publicadas y ofrece Trabaja con Nosotros y Contactanos.
- [ ] Un admin gestiona publicaciones, convocatorias, postulaciones, contactos y destinatarios segun RBAC, sin acceso directo a datos de `public-api`.
- [ ] Una postulacion valida guarda metadata en MongoDB y CV en MinIO con acceso administrativo autenticado; archivos invalidos/grandes no quedan almacenados.
- [ ] La maquina de estados de postulaciones rechaza transiciones invalidas y audita actor, fecha, estado anterior y nuevo.
- [ ] El correo es asincrono y una falla SMTP no pierde la postulacion ni el contacto.
- [ ] Rate limiting, honeypot, idempotencia, CORS, validacion, timeouts y logs seguros estan probados.
- [ ] `/api/public/**` y `/api/internal/**` tienen controles distintos; S2S, rotacion y correlation IDs funcionan de extremo a extremo.
- [ ] Las redes impiden exposicion de bases/MinIO y `docker compose up -d` levanta el entorno con healthchecks y limites.
- [ ] Astro cumple SEO y rendimiento definidos, incluyendo sitemap/robots y noindex de borradores.
- [ ] Tests backend, Angular e integracion pasan; la caida de `public-api` deja operativo el resto del admin.
- [ ] La documentacion incluye arquitectura, ownership, amenazas, flujos y ADRs con trade-offs.
