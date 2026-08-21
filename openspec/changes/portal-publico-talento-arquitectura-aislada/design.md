# Design: Portal Publico y Gestion de Talento con Arquitectura Aislada

## Technical Approach

Se implementa la opcion A del proposal: dos servicios Spring Boot con ownership de
datos no solapado, un portal Astro publico y el modulo Angular existente como
cliente administrativo. `admin-api` conserva el dominio transaccional y
PostgreSQL; `public-api` concentra contenido publico, postulaciones, contactos,
notificaciones, MongoDB, Redis y MinIO. No existe acceso directo entre una API y
el almacenamiento de la otra.

La frontera administrativa sera un anti-corruption layer HTTP: Angular conoce
solamente el contrato de `admin-api`; `admin-api` traduce ese contrato al
contrato `/api/internal/**` de `public-api`. Los controllers permanecen delgados,
los casos de uso contienen las invariantes y los adaptadores ocultan MongoDB,
Redis, MinIO, SMTP y HTTP. En `public-api` se aplica RFC 7807 mediante
`ProblemDetail`; el `admin-api` mantiene inicialmente su handler compatible y no
se fuerza una migracion transversal.

El diseño sigue R1-R18 de `spec.md`, las convenciones reales del repositorio
(Spring MVC/JPA/Lombok/DTOs manuales, Angular NgModule/Reactive Forms y
`ddl-auto:update`) y deja `flutter/` fuera del change.

## Architecture Decisions

### ADR-1: Renombrar `backend/` a `admin-api/`

**Status:** Accepted

**Contexto:** El backend actual posee PostgreSQL, autenticacion, RBAC y todos los
modulos administrativos, pero su nombre no expresa su boundary. Mezclar el nuevo
servicio publico en ese directorio ocultaria el ownership y haria ambiguo el
Compose.

**Decision:** Ejecutar un rename estructural `backend/` → `admin-api/`, conservar
`groupId` `com.ferreplus`, cambiar `artifactId`/nombre descriptivo a
`ferreplus-admin-api` y renombrar el servicio Compose, imagen y referencias de
CI/documentacion. No se redisenan paquetes de negocio durante el rename.

**Alternativas consideradas:** Mantener `backend/` (menor cambio, boundary
ambiguo); renombrar tambien paquetes Java (alto riesgo y sin beneficio).

**Consecuencias:** La topologia queda explicita y los nuevos paths son estables;
se requiere una busqueda de referencias completa y un PR de rollback sencillo.

### ADR-2: `public-api` separado y ownership exclusivo

**Status:** Accepted

**Contexto:** El portal publico recibe trafico no confiable y necesita contenido,
rate limiting y binarios sin ampliar la superficie del sistema administrativo.

**Decision:** Crear `public-api/` Spring Boot independiente. Solo `admin-api` usa
PostgreSQL; solo `public-api` usa MongoDB, Redis y MinIO. La integracion
Angular → `admin-api` → HTTP S2S → `public-api` evita bridge service y acceso
cruzado.

**Alternativas consideradas:** Un monolito con dos modulos (menos operacion,
mayor blast radius); `admin-api` accediendo Mongo/MinIO (acoplamiento y ruptura
del ownership); bridge service (tercer componente sin necesidad actual).

**Consecuencias:** Aumentan contenedores, DTOs duplicados y contratos que
mantener, pero un incidente publico no obtiene credenciales ni conexiones del
admin. La frontera se verifica con pruebas negativas de red y dependencias.

### ADR-3: Redes Docker separadas y abandono de `network_mode: host`

**Status:** Accepted

**Contexto:** El Compose actual usa host networking, lo que elimina el control
de alcance y permite colisiones de puertos.

**Decision:** Usar cinco redes bridge internas: `public_net`, `admin_net`,
`public_data`, `admin_data` e `internal_services`. `traefik` conecta a las redes
de entrada; `public-api` a `public_net`, `public_data` e `internal_services`;
`admin-api` a `admin_net`, `admin_data` e `internal_services`; PostgreSQL solo a
`admin_data`; MongoDB/Redis/MinIO solo a `public_data`; los frontends solo a su
red de entrada e `internal_services` no se publica. No se publican puertos de
databases, Redis ni MinIO.

**Alternativas consideradas:** `network_mode: host` (facil de iniciar, sin
aislamiento); una sola red bridge (mejor que host, pero movimiento lateral
innecesario).

**Consecuencias:** Los servicios deben usar nombres DNS Compose y puertos
internos, y healthchecks deben contemplar readiness. Se gana least privilege y
se pueden probar prohibiciones de conectividad.

### ADR-4: Traefik como unico entrypoint

**Status:** Accepted

**Contexto:** Se necesitan cuatro hosts locales, un unico punto de headers/CORS
y una ruta compatible con Cloudflare Tunnel.

**Decision:** Traefik publica solo `80` (y `443` opcional) y usa el provider
Docker con `providers.docker.exposedByDefault=false`. Labels enrutan
`public.localhost` → `public-web`, `admin.localhost` → `admin-web`,
`api.localhost` → `public-api` y `api-admin.localhost` → `admin-api`.

**Alternativas consideradas:** Nginx manual (configuracion duplicada y menos
descubrimiento); publicar cada contenedor (superficie y CORS dispersos).

**Consecuencias:** Labels son parte del contrato de despliegue y deben probarse;
TLS local sera opcional. Cloudflared se activa solo con profile y usa secret
externo.

### ADR-5: JWT S2S asimetrico con issuer, audience, `kid` y rotacion

**Status:** Accepted

**Contexto:** `/api/internal/**` debe distinguir al servicio, no a un usuario,
sin compartir un secreto que exponga ambos lados.

**Decision:** `admin-api` emite JWT RS256 por defecto (EdDSA es una opcion
configurable si el runtime/proveedor la soporta). Claims obligatorios:
`iss=ferreplus-admin-api`, `aud=ferreplus-public-api`, `sub=admin-api`, `scope`
limitado, `iat` y `exp` de 120 segundos; header `kid`. El private key vive en
secret montado exclusivamente en `admin-api`; `public-api` recibe la public key
por el endpoint interno de rotacion y conserva las claves publicas activas en
MongoDB/cache. No se almacenan claves privadas en Git.

**Alternativas consideradas:** HMAC (simple pero exige compartir el secreto y
no permite separar firmante/verificador); API key estatica (sin claims ni
rotacion controlada); OAuth server (seguro, pero fuera de escala del change).

**Consecuencias:** Se requiere sincronizacion de reloj, manejo de `kid` y una
ventana de overlap. La verificacion es local y no depende de una llamada por
request. El cambio de algoritmo se hace como migracion configurada, no mezclando
RS256 y EdDSA sin soporte de libreria.

### ADR-6: MinIO para binarios y MongoDB para metadata

**Status:** Accepted

**Contexto:** Los CV son binarios privados, limitados a 5 MB, y necesitan
descarga autenticada sin contaminar documentos ni PostgreSQL.

**Decision:** Buckets privados `cv-bucket` y `media-bucket`; MongoDB conserva
`objectKey`, nombre, MIME, tamano y fecha. Keys UUID v4 no contienen email,
documento ni id secuencial. La descarga administrativa se hace por proxy
autorizado de `public-api` (`GET /api/internal/postulaciones/{id}/cv`), no por
URL presigned entregada al navegador. El proxy controla permisos y streams el
objeto; asi no se expone endpoint MinIO ni URL reutilizable.

**Alternativas consideradas:** Blob en PostgreSQL/MongoDB (backup y memoria mas
costosos); URL presigned (reduce carga de API, pero filtra un bearer temporal y
complica auditoria/revocacion); bucket publico (prohibido).

**Consecuencias:** `public-api` asume el streaming y se debe definir timeout,
limite de respuesta y limpieza compensatoria de objetos.

### ADR-7: Correo con Spring Events + `@Async`, sin RabbitMQ

**Status:** Accepted

**Contexto:** El registro debe confirmarse antes del SMTP y el volumen esperado
no justifica otro broker.

**Decision:** El caso de uso persiste primero y publica un evento Spring con
correlation ID. Un listener `@Async("mailTaskExecutor")` crea/actualiza un
registro de `notificaciones`, renderiza Thymeleaf y envia SMTP. Los reintentos
son acotados y visibles; un endpoint interno permite reenvio.

**Alternativas consideradas:** RabbitMQ (durabilidad y backpressure superiores,
pero otro servicio, credenciales, operaciones y scope); envio sincrono (bloquea
y pierde disponibilidad); evento sin persistencia (pierde el intento al caer el
proceso).

**Consecuencias:** `@Async` no es una cola durable frente a perdida total del
proceso; la persistencia de `notificaciones` y un job de reintento al arrancar
reducen la brecha. RabbitMQ se reconsidera si el volumen o SLA excede este
diseño.

### ADR-8: Rate limiting Redis con ventanas fijas atomicas

**Status:** Accepted

**Contexto:** Los limites confirmados deben funcionar con varias replicas y
devolver `Retry-After` determinista.

**Decision:** Redis usa `INCR` + `EXPIRE` atomico mediante script Lua para dos
ventanas por operacion: postulaciones `3/900s` y `10/86400s`; contactos `5/900s`
y `20/86400s`. Keys principales: `application-rate:{ip}:15m`,
`application-rate:{ip}:day`, `contact-rate:{ip}:15m` y `contact-rate:{ip}:day`.
Se agregan contadores de baja cardinalidad por `fingerprint` y email hash,
sin guardar email plano en la key. `/api/internal/**` se excluye.

**Alternativas consideradas:** Sliding window (mas preciso, mas memoria y
complejidad); token bucket (mejor para burst, menos directo para limites de
calendario); memoria local (no distribuida).

**Consecuencias:** Una ventana fija permite burst en el borde, aceptable para el
volumen inicial. Si Redis cae se aplica fail-open con un limitador Caffeine/local
por instancia, conservando un limite conservador y registrando degradacion; no
se bloquea todo el portal por una dependencia de proteccion.

### ADR-9: Astro SSG inicial

**Status:** Accepted

**Contexto:** El portal es principalmente contenido SEO y la API publica solo
expone recursos publicados.

**Decision:** Astro `output: static`/prerender por defecto, `getStaticPaths()`
para detalles y build configurado contra `public-api`. Formularios son islas
pequenas que hacen `fetch` al endpoint publico. Si se requiere contenido nuevo
sin rebuild, personalizacion por request o volumen de publicaciones que haga
inviable el build, se cambia solo ese punto a SSR con adapter Node; no se
introduce SSR preventivamente.

**Alternativas consideradas:** SSR desde el primer dia (frescura inmediata,
mayor coste y runtime); SPA Angular publica (peor HTML inicial/SEO y JS).

**Consecuencias:** Publicar una convocatoria requiere rebuild/revalidate del
portal; la API no devuelve borradores y el pipeline elimina stale pages. No se
inyectan secretos al bundle.

### ADR-10: Maquina de estados cerrada de postulacion

**Status:** Accepted

**Contexto:** El contrato confirma cuatro estados y no permite reapertura.

**Decision:** El dominio solo admite `RECEIVED`, `UNDER_REVIEW`, `ACCEPTED` y
`REJECTED`. La transicion se valida en el servicio, no en el controller, y se
persiste junto con historial en una operacion atomica. `REJECTED` y `ACCEPTED`
son terminales; no existen `WITHDRAWN`, `HIRED` ni transiciones inversas.

**Alternativas consideradas:** Enum abierto (permite estados accidentales); FSM
con reapertura (contradice spec); estado almacenado solo como string sin regla
(inconsistente).

**Consecuencias:** Una caida durante la transicion deja el documento en el
estado anterior o completamente nuevo, nunca medio auditado. Reintentar una
misma solicitud requiere idempotencia interna o devuelve conflicto.

### ADR-11: ProblemDetail RFC 7807 solo en `public-api`

**Status:** Accepted

**Contexto:** El handler actual de `admin-api` devuelve `Map.of`, mientras el
portal publico necesita errores tipados y campos de validacion consistentes.

**Decision:** `public-api` usa `spring-boot-starter-web` y
`ResponseEntityExceptionHandler`/`ProblemDetail` con `type`, `title`, `status`,
`detail`, `instance`, `correlationId` y `errors` solo para validacion. Nunca
incluye stack trace. `admin-api` conserva el contrato actual para no romper
clientes y podra migrarse en otro change.

**Consecuencias:** Hay dos formatos durante la transicion; el cliente interno
traduce ambos a errores tipados y la documentacion lo deja explicito.

### ADR-12: DTOs separados por boundary

**Status:** Accepted

**Contexto:** Astro, Angular e internal API evolucionan a ritmos distintos y no
hay monorepo de tipos compartidos.

**Decision:** DTOs Java separados para `Public...DTO`, `Internal...DTO` y
`Admin...DTO`; interfaces TypeScript se mantienen en cada cliente. El contrato
se documenta con OpenAPI y tests de integracion, sin compartir entidades ni un
jar comun.

**Consecuencias:** Se evita fuga de campos internos y acoplamiento de build, a
cambio de duplicacion controlada y necesidad de contract tests.

### ADR-13: Temas claro y oscuro controlados en el portal

**Status:** Accepted

**Contexto:** El portal publico debe ofrecer la misma adaptabilidad visual que el
admin sin reemplazar su identidad ni hacer depender la legibilidad de JavaScript.

**Decision:** `BaseLayout` ejecuta un script inline temprano que aplica `data-theme`
con la eleccion valida de `localStorage` (`ferreplus-theme`) o, en su ausencia, la
preferencia `prefers-color-scheme`. `Header` muestra un boton toggle visible, con
etiqueta accionable y `aria-pressed`, que cambia el atributo y persiste la eleccion
sin recargar. `global.css` concentra tokens semanticos para superficie, texto,
muted, borde, foco, estados y controles; el tema oscuro y el fallback del sistema
se resuelven con variables CSS. Las transiciones se anulan para
`prefers-reduced-motion: reduce`.

**Alternativas consideradas:** Solo detectar el sistema (no permite control
explicito); selector separado de tres estados (agrega carga cognitiva); cambiar
clases desde JavaScript despues del render (produce flash).

**Consecuencias:** El portal conserva el diseño existente y añade una superficie
de tokens mantenible. La preferencia guardada prevalece sobre cambios posteriores
del sistema hasta que el visitante la cambie desde el selector.

## Architecture Components and Topology

```text
Internet
   |
Cloudflare DNS/WAF (produccion)
   |
cloudflared [profile tunnel, opcional]
   |
Traefik :80/:443  (exposedByDefault=false)
   |---------------- public.localhost ------> public-web (Astro :4321)
   |---------------- api.localhost ----------> public-api (Spring :8080)
   |---------------- admin.localhost --------> admin-web (Angular :80)
   `---------------- api-admin.localhost ---> admin-api (Spring :8080)

public_net: public-web, public-api, traefik
admin_net:  admin-web, admin-api, traefik
internal_services: admin-api <----JWT S2S----> public-api
public_data: public-api ---> mongodb:27017, redis:6379, minio:9000
admin_data:  admin-api ---> postgres:5432

Angular -> admin-api -> internal HTTP/JWT -> public-api -> MongoDB/Redis/MinIO
Astro (build/runtime) -> /api/public/** -> public-api -> MongoDB
public-api -> SMTP (salida controlada, timeout)
```

Los puertos de base de datos no aparecen en `ports:`. Solo Traefik publica
puertos. `public-api` no resuelve PostgreSQL y `admin-api` no resuelve MongoDB,
Redis ni MinIO por red ni por configuracion.

### Capas de `public-api`

* `controller`: REST publico e interno, validacion de request y mapeo a DTO.
* `service`: casos de uso transaccionales, invariantes de estados, idempotencia
  y orquestacion; nunca construye respuestas HTTP.
* `model`: agregados/documentos y value objects (`PostulacionEstado`, tipos de
  destinatario y envio).
* `repository`: puertos Spring Data Mongo; no se exponen documentos directamente.
* `storage`, `mail`, `ratelimit`: adaptadores de MinIO, SMTP/Thymeleaf y Redis.
* `security`, `config`: JWT S2S, CORS, headers, properties y filtros.
* `event`: eventos de dominio/listeners asincronos.

## public-api: estructura, contratos y flujo

```text
public-api/src/main/java/com/ferreplus/publico/
├── controller/{PublicController,InternalController,AdminContentController}.java
├── dto/{publico,interno,admin}/*.java
├── service/{PublicacionService,ConvocatoriaService,PostulacionService,
│           ContactoService,DestinatarioService,NotificacionService}.java
├── repository/{PublicacionRepository,...}.java
├── model/{Publicacion,Convocatoria,Postulacion,Contacto,Destinatario,
│          Notificacion,KeyDocument,PostulacionEstado}.java
├── security/{S2sJwtFilter,KeyResolver,SecurityConfig}.java
├── config/{MongoConfig,RedisConfig,MinioProperties,MailProperties}.java
├── event/{PostulacionReceivedEvent,ContactoReceivedEvent,MailEventListener}.java
├── mail/{MailSender,ThymeleafMailRenderer,MailTaskExecutor}.java
├── storage/{ObjectStorage,MinioObjectStorage,CvFileValidator}.java
└── ratelimit/{RateLimitService,RedisRateLimitService,LocalFallbackRateLimit}.java
```

La regla de dependencia es `controller → service → ports/repository`; los
adaptadores concretos son inyectados en el borde. Se usa constructor injection,
`@ConfigurationProperties`, `@Validated`, `@Transactional` cuando exista una
secuencia multi-documento que deba coordinarse mediante mecanismo Mongo
disponible; la transicion se implementa con update condicional para evitar
lost updates.

### Endpoints principales

```text
GET  /api/public/publicaciones[/{slug}]              listado/detalle publicados
GET  /api/public/convocatorias[/{id}]               abiertas y detalle
POST /api/public/convocatorias/{id}/postulaciones    multipart + Idempotency-Key
POST /api/public/contactos                           JSON + Idempotency-Key

GET/POST/PUT/DELETE /api/internal/publicaciones      CRUD protegido
GET/POST/PUT/DELETE /api/internal/convocatorias      CRUD protegido
GET/PATCH           /api/internal/postulaciones      consulta/transicion
GET/POST/PATCH      /api/internal/contactos          modulo contable
GET/POST/PUT/DELETE /api/internal/destinatarios      administrable
GET                 /api/internal/postulaciones/{id}/cv  stream autenticado
POST                /api/internal/notificaciones/{id}/reintentar
POST                /api/internal/keys                publicar clave publica
```

Los listados administrativos se paginan (`page` 0-based, `size` maximo 100) y
usan filtros allowlisted. Las respuestas no exponen documentos Mongo ni
`ip/fingerprint` salvo que el contrato interno de contabilidad lo requiera.
Los formularios publicos aceptan `Idempotency-Key` valido y honeypot vacio.

### Seguridad transversal

`S2sJwtFilter` solo se aplica a `/api/internal/**`; valida firma, `iss`, `aud`,
`exp`, `nbf` si existe, `kid`, `sub=admin-api` y scope por endpoint. `/api/public/**`
queda sin autenticacion S2S. CORS permite unicamente origins configurados de
Astro y Angular; no usa `*` con credenciales. Se agregan CSP, HSTS fuera de
localhost, `X-Content-Type-Options`, `Content-Security-Policy`,
`Referrer-Policy`, `Permissions-Policy` y `Cache-Control` segun recurso.

Todos los inputs usan DTOs record o clases explicitas con Bean Validation:
longitudes, email, enum, fechas, URL allowlist (`https` y hosts configurados),
multipart maximo 5 MB y extension allowlist. Markdown/HTML enriquecido no se
acepta como HTML libre: se almacena texto/estructura permitida y se escapa en
la salida; campos SEO son texto plano. Mongo usa repositorios parametrizados.

Un filtro temprano obtiene o genera `X-Correlation-ID`, valida formato y lo
coloca en MDC. El valor se devuelve en respuesta y se propaga por `admin-api`.
El handler global mapea: 400 validacion/archivo, 401 S2S ausente/expirado, 403
scope, 404 no encontrado, 409 transicion/idempotencia, 429 limite y 5xx generico.

## Modelos MongoDB

Se crean indices por estado/fecha y claves de idempotencia. Los documentos solo
contienen los campos funcionales siguientes; `createdAt`/`updatedAt` son
necesarios para auditoria operativa y ordenamiento.

### `publicaciones`

```json
{
  "_id": "ObjectId",
  "slug": "string",
  "titulo": "string",
  "resumen": "string",
  "descripcion": "string",
  "portada": { "objectKey": "string", "alt": "string" },
  "galeria": [{ "objectKey": "string", "alt": "string" }],
  "videoUrl": "string|null",
  "enlacesX": ["string"],
  "categoria": "string",
  "estado": "DRAFT|PUBLISHED",
  "fechaPublicacion": "datetime|null",
  "fechaVencimiento": "datetime|null",
  "autor": { "sub": "string", "nombre": "string" },
  "metadataSEO": { "title": "string", "description": "string", "canonical": "string", "openGraph": { "title": "string", "description": "string", "imageObjectKey": "string" } },
  "contenidoEnriquecido": "string|null",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

`slug` es necesario para la ruta SEO; `contenidoEnriquecido` solo se permite
como texto sanitizado cuando el editor lo necesita. `categoria`, medios y
enlaces son los unicos campos de presentacion solicitados. Indices: unique
`slug`, `{estado,fechaPublicacion}`, `{estado,fechaVencimiento}`.

### `convocatorias`

```json
{
  "_id": "ObjectId",
  "titulo": "string",
  "descripcion": "string",
  "requisitos": ["string"],
  "ubicacion": "string",
  "modalidad": "string",
  "fechaApertura": "datetime",
  "fechaCierre": "datetime",
  "estado": "DRAFT|PUBLISHED|CLOSED",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

No se agrega salario, departamento ni contador porque no son necesarios en R4.
Una convocatoria publica se entrega solo si `fechaApertura <= now < fechaCierre`
y `estado=PUBLISHED`; cerrar manualmente usa `CLOSED`.

### `postulaciones`

```json
{
  "_id": "ObjectId",
  "convocatoriaId": "ObjectId",
  "nombres": "string",
  "apellidos": "string",
  "email": "string",
  "telefono": "string",
  "ciudad": "string",
  "cv": { "objectKey": "uuid.ext", "fileName": "string", "mimeType": "string", "size": "number", "createdAt": "datetime" },
  "estado": "RECEIVED|UNDER_REVIEW|ACCEPTED|REJECTED",
  "historial": [{ "actor": "string", "fecha": "datetime", "anterior": "string", "nuevo": "string" }],
  "idempotencyKey": "string",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

Unique compound index `convocatoriaId + idempotencyKey`; index por estado y
fecha. `actor` es `admin-api:{sub}` en transiciones internas y `system` en la
creacion.

### `contactos`

```json
{
  "_id": "ObjectId",
  "nombre": "string",
  "email": "string",
  "telefono": "string|null",
  "asunto": "string",
  "mensaje": "string",
  "estado": "UNREAD|READ",
  "ip": "string|null",
  "fingerprint": "string|null",
  "idempotencyKey": "string",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

IP/fingerprint se cifran o hashean segun la politica de despliegue y nunca se
devuelven al portal. Se conservan porque son necesarios para abuso y soporte.

### `destinatarios`

```json
{ "_id": "ObjectId", "tipo": "JOB_APPLICATION|CONTACT_FORM", "email": "string", "activo": "boolean" }
```

No se requiere nombre ni preferencias. Unique compuesto `tipo + email`.
CRUD solo por endpoints internos con permiso RBAC en `admin-api`.

### `notificaciones` (necesaria para R7)

```json
{
  "_id": "ObjectId",
  "tipo": "JOB_APPLICATION|CONTACT_FORM",
  "referenciaId": "ObjectId",
  "destinatarios": ["string"],
  "estado": "PENDING|SENT|FAILED",
  "intentos": "number",
  "ultimoError": "string|null",
  "nextAttemptAt": "datetime|null",
  "correlationId": "string",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

Es imprescindible para conservar fallo SMTP y reintentar sin duplicar el
registro funcional. No almacena cuerpo completo ni CV.

### `keys`

```json
{ "_id": "ObjectId", "kid": "string", "publicKey": "string", "expiracion": "datetime", "activa": "boolean" }
```

Se elige MongoDB para public keys porque pertenece a `public-api`, permite
overlap y no requiere redeploy para rotar. La primera clave se inyecta como
secret/config de bootstrap y el endpoint interno la publica; el private key
nunca entra a Mongo. Cache local de 5 minutos evita consultar Mongo por token.
Indices unique `kid` y `{activa,expiracion}`.

## MinIO y ciclo de CV

Buckets privados: `cv-bucket` para CV y `media-bucket` para portada/galeria.
Lifecycle de limpieza para objetos no referenciados tras 24 horas y retencion
segun politica de datos. `public-api` usa credenciales de MinIO solo por env/secret
montado.

1. Validar extension antes de leer/guardar; allowlist inicial `.pdf`, `.doc`,
   `.docx`. `.xlsx` devuelve 400 `CV_EXTENSION_NOT_ALLOWED` y no se escribe.
2. Rechazar `Content-Length > 5 MiB`; leer con limite para evitar bypass.
3. Inspeccionar magic bytes/MIME real (PDF signature y ZIP/OOXML solo para docx),
   comparar con extension y `Content-Type`; mismatch devuelve
   `CV_MIME_INVALID`.
4. Generar `UUID.randomUUID() + extension`, guardar stream privado con metadata
   MIME, checksum y correlation ID. El checksum solo sirve para integridad y no
   se expone al publico.
5. Crear postulacion con metadata del objeto en una operacion posterior. Si
   Mongo falla, borrar el objeto; si el borrado falla, registrar orphan para
   cleanup. Si la convocatoria esta cerrada, validar ANTES del upload.
6. `GET /api/internal/.../cv` valida JWT/scope, registra descarga y hace stream
   MinIO con timeout; el cliente recibe bytes y `Content-Disposition`, nunca la
   URL ni credenciales.

## Maquina de estados y consistencia

```text
                 +----------------+
                 |   RECEIVED     |
                 +-------+--------+
                         |
                         v
                 +-------+--------+
                 | UNDER_REVIEW   |
                 +-------+---+----+
                         |   |
                 ACCEPTED|   |REJECTED
                         v   v
                   +-----+  +-----+
                   |     |  |     |
                   +-----+  +-----+
                   terminal terminal
```

El servicio mantiene tabla de transiciones permitidas. Cambia con update
condicional `id + estadoAnterior`; si modifica cero documentos devuelve 409.
Despues agrega un elemento de historial con actor, fecha, anterior y nuevo.
Mongo documenta la escritura de estado e historial en una unica operacion
`findAndModify`/pipeline; si el proceso cae antes de confirmar, el estado queda
anterior; si confirma, historial acompana al estado. No se registra auditoria
para una transicion rechazada.

## Correo asincrono

`PostulacionService` y `ContactoService` guardan primero y publican
`PostulacionReceivedEvent`/`ContactoReceivedEvent` con id, tipo y correlation ID.
El listener obtiene destinatarios activos en ese momento, crea una notificacion
PENDING y delega al executor `mailTaskExecutor` (`corePoolSize=2`,
`maxPoolSize=8`, `queueCapacity=200`, `CallerRunsPolicy` solo como proteccion).

Se usa Thymeleaf (`src/main/resources/templates/mail/`) porque ya es familiar en
Spring MVC y permite plantillas HTML/text separadas, variables escapadas y tests
de render. Plantillas: `postulacion-recibida.html`, `contacto-recibido.html` y
confirmacion al candidato/contactante. `JavaMailSender` tiene connect/read
timeouts de 5s.

El sender marca SENT solo tras respuesta SMTP; ante error incrementa intentos,
guarda error sanitizado, correlation ID y `nextAttemptAt` con backoff 1/5/30
minutos, hasta 3 reintentos. Un scheduler recupera PENDING/FAILED al arrancar y
el endpoint interno permite reenvio. El fallo no afecta el HTTP 201 ni elimina
postulacion/contacto.

## S2S JWT y rotacion

```text
admin-api private key (secret, kid=k2)
       |
       +--> firma JWT corto (iss/aud/sub/scope/correlation)
       |
       +--> POST /api/internal/keys con public key k2 (token k1 durante overlap)

public-api: keys Mongo + cache
       |
       +--> S2sJwtFilter resuelve kid, valida firma/iss/aud/exp/sub/scope
       +--> rechaza key retirada o expirada
```

Rotacion: publicar nueva public key `k2`, activar cache, comenzar tokens `k2`,
mantener `k1` valida 10 minutos (mas TTL de token), retirar `k1`, marcar activa
false y purgar cache. Si la publicacion falla, `admin-api` sigue firmando `k1`
hasta su expiracion operativa y alerta; nunca continua con key desconocida.
Tokens de `/api/public/**` no requieren JWT S2S ni se mezclan con el JWT de
usuarios del admin.

## Rate limiting Redis

La IP se obtiene del proxy confiable configurado, ignorando `X-Forwarded-For`
arbitrario. Se normaliza fingerprint entregado por cliente como hash HMAC del
servidor (no se acepta como identidad fuerte) y email como SHA-256 normalizado.
Cada intento se cuenta despues de validacion basica y antes de persistencia; si
se excede cualquiera de las ventanas, no se hace upload ni save. Respuesta:

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 417
Content-Type: application/problem+json
```

`Retry-After` es el menor TTL restante de las keys excedidas. Redis falla:
fail-open con Caffeine/local por IP de 1 minuto, limite conservador 1 intento,
log `rate_limit.degraded=true`; `/api/internal/**` nunca pasa por este filtro.

## Resiliencia de `admin-api` y Angular

Se agrega `spring-boot-starter-web` ya existente y un `RestClient` nombrado
`PublicApiClient` con `connectTimeout=1s`, `readTimeout=3s`; no se usa WebClient
para no mezclar stack reactivo con Spring MVC/JPA. Cada llamada crea o propaga
correlation ID y agrega JWT S2S. Errores se traducen a
`PublicApiUnavailableException`, `PublicApiValidationException` o
`PublicApiConflictException`.

El servicio Angular muestra loading/error/empty/success. Timeout, 502/503 y
connection refused muestran exactamente `Servicio de postulaciones
temporalmente no disponible`; reintento manual no duplica un POST idempotente.
El cliente HTTP interno se ejecuta FUERA de cualquier `@Transactional` de
PostgreSQL: una falla publica nunca hace rollback ni bloquea una transaccion
administrativa propia.

## Cambios de `admin-api` y Angular

El rename conserva `com.ferreplus.auth`, `client`, `config`, `controller`,
`dto`, `entity`, `exception`, `repository`, `service`. Se agregan solo
`client/publico`, `dto/talento`, propiedades S2S, mapeadores y permisos. Se
mantiene `GlobalExceptionHandler` Map-based. No se comparte un DTO Java con
`public-api`: los DTOs internos se duplican para desacoplar releases.

```text
frontend/src/app/talento/
├── talento.module.ts                 # NgModule, ReactiveForms, Material
├── talento-routing.module.ts         # lazy + data.permissions
├── models/{publicacion,convocatoria,postulacion,contacto,destinatario}.ts
├── services/talento.service.ts       # admin-api, no URL public-api
├── pages/{publicaciones,convocatorias,postulaciones,contactos,destinatarios}/
├── components/{estado-postulacion,cv-download,indisponibilidad}.component.*
└── shared/{talento-error.mapper,form-validators}.ts
```

Rutas usan `TALENTO_PUBLICACIONES_VER`, `TALENTO_CONVOCATORIAS_VER`,
`TALENTO_POSTULACIONES_VER`, `CONTABILIDAD_CONTACTOS_VER` y
`TALENTO_DESTINATARIOS_VER`, mas acciones CREAR/EDITAR/ELIMINAR aplicables.
Se integran lazy `loadChildren`, `data.permissions`, `RUTAS_POR_PERMISO` y
`*appHasPermission`; el guard sigue cargando permisos desde `/me`. `DataSeeder`
agrega estos modulos al catalogo y da al rol `ADMIN` todas sus acciones de forma
idempotente. Reactive Forms, Material, Bootstrap y tests Vitest/jsdom siguen el
patron existente; no se migra a standalone/signals.

## Astro: portal publico

```text
portal-publico/
├── src/pages/index.astro
├── src/pages/publicaciones/index.astro
├── src/pages/publicaciones/[slug].astro
├── src/pages/convocatorias/index.astro
├── src/pages/convocatorias/[id].astro
├── src/pages/trabajaconnosotros.astro
├── src/pages/contactanos.astro
├── src/layouts/{BaseLayout,ContentLayout}.astro
├── src/components/{SeoHead,Header,Footer,Card,JobForm,ContactForm}.astro
├── src/components/islands/{ApplicationForm,ContactForm}.ts
├── src/lib/api-client/{public-api.ts,types.ts}
├── src/content/config.ts            # solo contenido local Markdown/MDX si aplica
├── astro.config.mjs                 # sitemap + assets
└── Dockerfile
```

Las rutas dinamicas usan `getStaticPaths()` y solo datos publicados devueltos por
la API. `BaseLayout` incluye `title`, `description`, canonical, Open Graph,
robots y JSON-LD (`Article`/`JobPosting` cuando corresponda). `@astrojs/sitemap`
incluye solo paths generados; robots no apunta a borradores. `astro:assets`
procesa imagenes locales y el proxy/media API entrega variantes permitidas; se
usa `loading=lazy` excepto hero. Respuestas publicas agregan `Cache-Control`
(`publicaciones` 60s, detalles 60s, formularios `no-store`); Astro no cachea
POST. Formularios son islands con `client:visible`, progressive enhancement y
`fetch` solo a `/api/public/**`; no conocen JWT, SMTP ni MinIO.

El sistema visual usa tokens CSS semanticos para los temas `light` y `dark`.
El script inline de `BaseLayout` aplica la preferencia antes de que el navegador
muestre el contenido; si no existe una preferencia guardada, consulta el sistema.
El selector del `Header` cambia el tema inmediatamente, persiste en
`localStorage` y mantiene estado accesible. Sin JavaScript, el fallback CSS de
`prefers-color-scheme` conserva contraste y legibilidad.

## Docker Compose

Servicios y redes previstas:

| Servicio | Imagen/build | Redes | Limite inicial | Healthcheck |
|---|---|---|---|---|
| `traefik` | `traefik:v3.3` | public_net, admin_net | 0.50 CPU/256 MB | `/ping` |
| `admin-api` | `./admin-api`, JRE21 | admin_net, admin_data, internal_services | 1 CPU/768 MB | actuator health |
| `public-api` | `./public-api`, JRE21 | public_net, public_data, internal_services | 1 CPU/768 MB | actuator health |
| `admin-web` | `./frontend`, nginx | admin_net | 0.50 CPU/128 MB | nginx health |
| `public-web` | `./portal-publico`, nginx | public_net | 0.50 CPU/128 MB | nginx health |
| `postgres` | `postgres:16-alpine` | admin_data | 1 CPU/512 MB | `pg_isready` |
| `mongodb` | `mongo:8` | public_data | 1 CPU/768 MB | `mongosh ping` |
| `redis` | `redis:7-alpine` | public_data | 0.50 CPU/256 MB | `redis-cli ping` |
| `minio` | `minio:RELEASE...` | public_data | 1 CPU/512 MB | `/minio/health/live` |
| `cloudflared` | `cloudflare/cloudflared:<pin>` | public_net, admin_net | 0.25 CPU/128 MB | proceso/tunnel | 

Los valores son limites iniciales para desarrollo reproducible, no capacity
planning de produccion: API/DB reciben mas memoria por JVM y cache; frontends y
Traefik son estaticos. Todos usan `restart: unless-stopped`, excepto
cloudflared que usa `no` bajo profile. `depends_on` usa
`condition: service_healthy` para PostgreSQL, Mongo, Redis, MinIO antes de sus
APIs, y APIs saludables antes de frontends/Traefik. Dockerfiles son multi-stage,
base JRE/node/nginx minima, usuario non-root y `.dockerignore` excluye `.git`,
`node_modules`, targets y `.env`.

`.env.example` declara sin secretos reales: `POSTGRES_*`, `MONGO_*`,
`MINIO_*`, `REDIS_URL`, `PUBLIC_API_URL`, `ADMIN_API_URL`, `APP_CORS_*`,
`SMTP_*`, `S2S_ISSUER`, `S2S_AUDIENCE`, `S2S_PRIVATE_KEY_FILE`,
`S2S_INITIAL_PUBLIC_KEY_FILE`, `CLOUDFLARED_TOKEN_FILE`, limites y perfiles.
Secretos se montan con Compose secrets o archivos ignorados.

## Traefik labels y middlewares

Cada servicio web/API tiene `traefik.enable=true`, router con `Host(...)`,
service con puerto interno (`80` para nginx, `8080` para Spring) y red explicita.
Middlewares comunes: `security-headers` (HSTS solo TLS), `compress`, y
`cors-public` solo para API publica. Rate limit de Traefik es una defensa basica
opcional, no sustituye el rate limiting Redis por formulario. CORS del backend
es la autoridad final. TLS local usa entrypoint `websecure` y certificado
dev-mounted opcional; produccion termina en Cloudflare/TLS y no versiona claves.

## Observabilidad

Ambas APIs escriben JSON a stdout con `timestamp`, `level`, `service`,
`environment`, `correlationId`, `event`, `route`, `status`, `durationMs` y
`outcome`. MDC se limpia en `finally`. Se propaga `X-Correlation-ID` en
Angular → admin-api → public-api y eventos async.

Eventos obligatorios: `application.received`, `application.status_changed`,
`contact.received`, `validation.rejected`, `rate_limit.activated`,
`storage.failure`, `storage.download`, `mail.failure`, `mail.sent`,
`s2s.rejected`, `dependency.unavailable`. Se redaccionan nombres completos,
mensaje, CV, token, Authorization, email en claro, IP cuando no sea necesaria y
credenciales; se loguean ids opacos, tipo, estado, motivo seguro y tamanos.
Actuator expone health/info/metrics solo por red interna. Un futuro collector
puede consumir stdout sin cambiar el contrato.

## Estrategia exacta de migracion del rename

1. Verificar `git status`, inventariar referencias con busqueda de `backend` en
   Compose, Dockerfiles, README, CI, scripts y paths generados.
2. Ejecutar `git mv backend admin-api` en el PR de rename (no funcional).
3. Cambiar `artifactId`, `<name>`, contexto de build, `container_name`, variables
   `SERVER_PORT/DB_*` y rutas del Dockerfile; `groupId` permanece `com.ferreplus`.
4. Actualizar workflows/scripts/docs y excluir `backend/` solo donde sea una
   ruta antigua; no tocar imports Java.
5. Ejecutar build Maven desde `admin-api/`, test H2 y build de Compose; verificar
   que PostgreSQL conserva volumen y esquema.
6. Fusionar/validar este slice antes de agregar public-api. Rollback: revertir
   el PR y restaurar la ruta Compose/CI `backend/`; no borrar volumenes ni hacer
   migracion destructiva. Si ya se publico una imagen, mantener alias/tag
   temporal hasta completar el rollout.

## Plan de implementacion por PRs

| PR | Componentes/archivos concretos | Dependencia y verificacion |
|---|---|---|
| 1 | `backend/`→`admin-api/`, `admin-api/pom.xml`, Dockerfile, README/CI | Ninguna. `mvn test`, build Docker y referencias sin `backend/`. |
| 2 | `docker-compose.yml`, `.env.example`, `traefik/`, Dockerfiles de apps, redes/healthchecks/profiles | PR1. `compose config`, `up -d`, hosts y pruebas negativas de puertos/red. |
| 3 | `public-api/pom.xml`, application config, `model`, `repository`, DTOs, controllers base, Mongo/ProblemDetail/correlation | PR2. Context load, repositorios, 400/404/5xx RFC7807 y ownership de dependencias. |
| 4 | `storage/*`, validadores CV, `Postulacion*`, `Convocatoria*`, endpoints public/internal y FSM | PR3. CV valido, `.xlsx`, MIME falso, >5 MB, convocatoria cerrada, transiciones y orphan cleanup. |
| 5 | `Contacto*`, `Destinatario*`, `Notificacion*`, events/mail/templates, endpoints internos contables | PR4. persist-first, SMTP caido, reintentos, destinatarios activos y CRUD protegido. |
| 6 | `portal-publico/` completo, Astro config, paginas/layouts/client, Dockerfile | PR3-5. build SSG, sitemap sin borradores, SEO, formularios y no credenciales. |
| 7 | `frontend/src/app/talento/`, modelos/servicio, routing, RUTAS_POR_PERMISO, RBAC UI y fallback | PR5. Vitest componentes/forms, guard por URL, estados UI y descarga autenticada. |
| 8 | S2S keys/filter/client, DataSeeder/RBAC, logs/MDC, tests E2E/contract, docs/ADR | PR1-7. rotacion overlap, 401/403, correlation end-to-end, resiliencia y suite completa. |

Cada PR se mantiene bajo 800 lineas revisables; si los contratos o tests lo
exceden, se parte el PR sin cambiar el orden de dependencias.

## File Changes

| Archivo/ruta | Accion | Descripcion |
|---|---|---|
| `backend/` | Rename | Se convierte en `admin-api/` sin renombrar paquetes Java. |
| `admin-api/pom.xml`, `src/main/resources/application.yml` | Modify | Nombre, cliente interno, S2S, timeouts y properties externas. |
| `docker-compose.yml`, `.env.example` | Modify/Create | Topologia aislada, secretos, limits, healthchecks y profiles. |
| `traefik/` | Create | Static/dynamic config y middlewares/labels. |
| `public-api/` | Create | Servicio Spring MVC, paquetes `com.ferreplus.publico.*`, tests y Dockerfile. |
| `portal-publico/` | Create | Astro SSG, pages, layouts, API client, SEO, tests y Dockerfile. |
| `frontend/src/app/talento/` | Create | Feature NgModule, paginas, servicios, modelos y componentes. |
| `frontend/src/app/core/{rutas-por-permiso,models,auth.service}.ts` | Modify | Permisos, rutas y contrato del feature. |
| `admin-api/src/main/java/com/ferreplus/{config,client,dto,service}` | Modify/Create | DataSeeder/RBAC, RestClient, DTOs y anti-corruption mapping. |
| `docs/architecture/`, `docs/adr/` | Create | ownership, redes, threat model, S2S, storage, mail y decisiones. |

## Testing Strategy

| Capa | Cobertura | Enfoque |
|---|---|---|
| Unit `public-api` | FSM, validacion MIME/extension, sanitizacion, idempotencia, Retry-After, mappers, ProblemDetail | JUnit5/Mockito sin Mongo/Redis/MinIO; property tests para transiciones. |
| MVC slice | DTOs, CORS, headers, 400/401/403/404/409/429 y no filtracion | `@WebMvcTest`, MockMvc y JWT firmado de prueba. |
| Integracion | Mongo, Redis, MinIO, SMTP fake, persist-first, rotacion y correlation | Testcontainers cuando Docker este disponible; perfiles test aislados. |
| `admin-api` | RestClient timeout/error mapping, seeder idempotente, permisos TALENTO y no transaccion bloqueada | Mockito, H2 y tests de seguridad existentes. |
| Angular | services, guards, permiso, Reactive Forms, estados loading/error/empty, fallback literal | Vitest/jsdom, HttpTestingController y componentes existentes. |
| Astro | API client, `getStaticPaths`, SEO, sitemap/noindex y formularios | unit tests de funciones y build SSG con fixture sin drafts. |
| Infra/E2E | Compose saludable, hosts Traefik, puertos, ownership, flujo candidato/admin, caida public-api | `docker compose config`, curl/MockMvc/Playwright o smoke scripts; pruebas negativas de DNS/conexion. |

La matriz de pruebas se traza a los 45 escenarios de `spec.md`, especialmente
`.xlsx`, >5 MB, convocatoria cerrada, 429, SMTP, keys overlap, 401/403,
correlation y fallback Angular.

## Riesgos tecnicos y mitigaciones

| Riesgo | Impacto | Mitigacion |
|---|---|---|
| Drift entre DTOs public/internal/admin | Integracion rota silenciosamente | DTOs separados, OpenAPI, contract tests y versionado aditivo. |
| `ddl-auto:update` no renombra tablas/columnas de forma segura | Perdida o schema incorrecto | Rename sin cambios JPA, backup/verificacion previa, checks de schema y migracion manual futura; no DDL destructivo automatico. |
| Labels Traefik apuntan a red/puerto equivocado | 404/502 o exposicion accidental | `exposedByDefault=false`, `compose config`, smoke por cuatro hosts y no `ports` en apps. |
| Cache de keys mantiene una clave retirada | Aceptacion de token invalido | TTL menor que overlap, invalidacion al publicar, test de retiro y clock skew acotado. |
| Rotacion no sincroniza reloj | 401 intermitentes | NTP, tolerancia de 30s, `iat/exp` observables sin secretos y alerta de skew. |
| SSG muestra contenido vencido | SEO incorrecto | API filtra estado/fechas, rebuild tras publicar, sitemap fixture y Cache-Control corto. |
| Limpieza compensatoria MinIO falla | Objeto huerfano | registro de orphan, job de reconciliation por objectKey y alerta; nunca ocultar fallo. |
| `@Async` satura executor por SMTP lento | Memoria/latencia | pool y queue limitados, timeouts, backoff y metricas; RabbitMQ queda como evolucion. |
| Fail-open local permite abuso durante caida Redis | Spam temporal | limite local conservador, alarma inmediata y controles fingerprint/email. |
| Mongo update concurrente pierde historial | Auditoria incompleta | update condicional con version/estado anterior y test concurrente. |
| Proxy recibe IP falsificada | Rate limit evadido | confiar solo en headers de Traefik/Cloudflare configurados y registrar source. |
| Multipart se procesa antes de comprobar convocatoria | CV huerfano | validar convocatoria y rate limit antes de crear objeto; cleanup compensatorio. |
| Cambio de contrato ProblemDetail rompe Angular | Pantallas sin mensaje | mapper de errores tipado y pruebas de 400/409/503; admin handler no migra ahora. |
| Build de Astro necesita API no disponible | Deploy bloqueado | fixture/mock de build, healthcheck de API previo y fallback controlado; no usar runtime secret. |
| Resource limits demasiado bajos para JVM | Reinicios | limites iniciales medidos, healthcheck/start period, profiling y ajuste por entorno. |
| Rename deja referencias generadas en IDE/CI | Build roto | busqueda global, build desde raiz y rollback del PR aislado. |

## Migration / Rollout

El rollout es incremental por los ocho PRs. Primero se estabiliza el rename y el
Compose; despues se habilitan rutas Traefik de `public-api` y Astro. Antes de
publicar formularios se cargan secrets SMTP, MinIO, Mongo y la public key inicial.
La feature Angular se activa solo cuando existen permisos seed y el endpoint
internal saludable. Rollback deshabilita routers publicos y cloudflared, pero
mantiene `admin-api` y sus volumenes; nunca se borran PostgreSQL, MongoDB o
MinIO automaticamente.

## Open Questions

No hay decisiones bloqueantes: S2S, estados, limites, RBAC y politica CV fueron
confirmados por el usuario. Queda como seguimiento operativo no bloqueante medir
volumen real para decidir si el executor asincrono debe evolucionar a RabbitMQ y
si Astro debe pasar parcialmente a SSR.
