# Portal Publico y Gestion de Talento — Especificacion

## Proposito

Este cambio agrega un portal publico SEO-friendly y un modulo administrativo de talento, manteniendo una frontera de datos y red entre el backend administrativo existente y un nuevo `public-api`. La especificacion define el comportamiento observable, las reglas de seguridad, los contratos funcionales y los escenarios verificables. `flutter/` queda fuera de alcance.

## Requisitos

### R1: Infraestructura, redes y entrada HTTP

El sistema DEBE renombrar `backend/` a `admin-api/` y levantar mediante Docker Compose los servicios necesarios para `admin-api`, `public-api`, Astro, Angular, PostgreSQL, MongoDB, Redis, MinIO y Traefik. DEBE usar las redes `public_net`, `admin_net`, `public_data`, `admin_data` e `internal_services`, `providers.docker.exposedByDefault=false`, healthchecks, limites de recursos, politicas de reinicio y profiles. Traefik DEBE ser el unico entrypoint HTTP. En desarrollo DEBE soportar `public.localhost`, `admin.localhost`, `api.localhost` y `api-admin.localhost`. `cloudflared` DEBE ser opcional mediante profile y su token DEBE provenir de secrets fuera de Git.

#### Scenario: El entorno completo inicia con servicios saludables

- GIVEN Docker Engine y Docker Compose compatibles con la configuracion
- WHEN se ejecuta `docker compose up -d`
- THEN los servicios criticos quedan iniciados
- AND cada servicio critico reporta healthcheck saludable antes de aceptar trafico dependiente

#### Scenario: Traefik enruta los cuatro hosts de desarrollo

- GIVEN el entorno local levantado
- WHEN se solicita cada host `public.localhost`, `admin.localhost`, `api.localhost` y `api-admin.localhost`
- THEN Traefik enruta la solicitud al servicio correspondiente
- AND ningun servicio de aplicacion necesita publicar un puerto HTTP alternativo al entrypoint

#### Scenario: Cloudflared no se inicia ni expone tokens por defecto

- GIVEN el profile de tunnel no esta activado y el repositorio se inspecciona
- WHEN se inicia Compose sin dicho profile
- THEN `cloudflared` no se inicia
- AND no existe ningun token real versionado en Compose, `.env.example` ni configuracion del repositorio

### R2: Aislamiento y ownership de datos

`admin-api` DEBE ser propietario exclusivo de PostgreSQL y no DEBE conectarse a MongoDB, Redis ni MinIO. `public-api` DEBE ser propietario exclusivo de MongoDB, Redis y MinIO y no DEBE conectarse a PostgreSQL. PostgreSQL, MongoDB, Redis y MinIO NO DEBEN publicar puertos a Internet; Redis y MinIO NO DEBEN tener acceso publico directo. Las rutas `/api/public/**` seran publicas con controles de abuso y `/api/internal/**` solo sera accesible por `admin-api` mediante S2S valido en la red interna.

#### Scenario: Las bases de datos no tienen puertos publicos

- GIVEN Compose esta levantado
- WHEN se inspeccionan los puertos publicados y se intenta conectar desde fuera de las redes de datos
- THEN PostgreSQL, MongoDB, Redis y MinIO no tienen puertos publicados a Internet
- AND Redis y MinIO rechazan trafico que no provenga de los servicios autorizados

#### Scenario: `admin-api` no puede acceder a MongoDB

- GIVEN `admin-api` esta conectado a sus redes permitidas
- WHEN intenta resolver o abrir una conexion hacia MongoDB
- THEN la red y la configuracion de ownership impiden la conexion
- AND `admin-api` continua usando PostgreSQL para sus datos administrativos

#### Scenario: `public-api` no puede acceder a PostgreSQL

- GIVEN `public-api` esta conectado a sus redes permitidas
- WHEN intenta resolver o abrir una conexion hacia PostgreSQL
- THEN la red y la configuracion de ownership impiden la conexion
- AND `public-api` usa MongoDB, Redis y MinIO para sus datos y controles efimeros

### R3: Publicaciones y cartelera

`public-api` DEBE permitir a usuarios administrativos autorizados crear, consultar, editar y eliminar publicaciones, con estado `DRAFT` o `PUBLISHED`. Una publicacion DEBE poder contener solamente los campos necesarios para presentarla: titulo, resumen/contenido, portada, galeria, video, enlaces externos X cuando existan y metadata SEO (`title`, `description`, `canonical` y datos Open Graph cuando correspondan). El listado publico DEBE entregar exclusivamente publicaciones publicadas; el listado administrativo DEBE permitir gestionar borradores y publicados.

#### Scenario: Un administrador crea y publica una cartelera

- GIVEN un usuario administrativo con permisos de talento para crear y publicar contenido
- WHEN crea una publicacion valida en `DRAFT` y luego la publica
- THEN el endpoint administrativo devuelve la publicacion con estado `PUBLISHED`
- AND el portal publico puede consultarla

#### Scenario: Un borrador no se expone publicamente

- GIVEN existe una publicacion `DRAFT`
- WHEN el portal consulta publicaciones publicas o se genera el sitemap
- THEN la publicacion no aparece en la respuesta publica, sitemap ni metadata indexable

#### Scenario: Campos no funcionales no se agregan al contrato

- GIVEN se diseña el DTO de publicacion
- WHEN se revisan sus atributos
- THEN solo se incluyen campos necesarios para contenido, medios, enlaces y SEO definido
- AND no se agregan campos de CMS, marketing, multi-tenant o analitica fuera de este change

### R4: Convocatorias

El sistema DEBE permitir crear, editar, publicar, despublicar, abrir y cerrar convocatorias, con titulo, descripcion, fecha de apertura, fecha de cierre y estado suficiente para determinar si acepta postulaciones. Una convocatoria publicada DEBE ser visible publicamente solo durante su periodo habilitado; una convocatoria cerrada NO DEBE aceptar nuevas postulaciones.

#### Scenario: Se publica una convocatoria dentro de su periodo

- GIVEN una convocatoria valida con fecha de apertura alcanzada y fecha de cierre futura
- WHEN un administrador la publica y el portal consulta convocatorias
- THEN aparece como convocatoria publica abierta
- AND el formulario de postulacion puede enviarse para ella

#### Scenario: Una convocatoria cerrada rechaza postulaciones

- GIVEN una convocatoria publicada cuyo cierre ya ocurrio o fue cerrado manualmente
- WHEN un candidato intenta enviar una postulacion
- THEN la API responde con error de convocatoria cerrada
- AND no persiste postulacion, metadata ni archivo huerfano

### R5: Postulaciones y maquina de estados

El portal DEBE ofrecer un formulario publico de postulacion asociado a una convocatoria abierta. Una postulacion valida DEBE persistirse antes de iniciar notificaciones y DEBE conservar sus datos necesarios, referencia al CV e idempotency key procesada. Sus unicos estados validos son `RECEIVED`, `UNDER_REVIEW`, `ACCEPTED` y `REJECTED`. Las transiciones permitidas son `RECEIVED → UNDER_REVIEW → ACCEPTED` y `RECEIVED → UNDER_REVIEW → REJECTED`; toda transicion invalida DEBE rechazarse. NO DEBE existir reapertura de `REJECTED`, ni estados `WITHDRAWN` o `HIRED`. Cada cambio DEBE auditar actor, fecha, estado anterior y nuevo.

#### Scenario: Postulacion valida queda recibida

- GIVEN una convocatoria abierta, datos validos, CV permitido y limites de abuso disponibles
- WHEN el candidato envia el formulario
- THEN la API responde exito y persiste la postulacion en estado `RECEIVED`
- AND el CV queda asociado a su metadata y la notificacion se programa de forma asincrona

#### Scenario: Postulacion con validacion invalida es rechazada

- GIVEN faltan datos obligatorios o un campo no cumple sus restricciones
- WHEN se envia la postulacion
- THEN la API responde error de validacion con campos identificables
- AND no persiste la postulacion ni almacena el CV

#### Scenario: Transicion a revision y aceptacion se audita

- GIVEN una postulacion `RECEIVED` y un administrador autorizado
- WHEN la mueve a `UNDER_REVIEW` y posteriormente a `ACCEPTED`
- THEN ambas operaciones tienen exito
- AND cada una registra actor, fecha, estado anterior y estado nuevo

#### Scenario: Rechazo es terminal y transiciones invalidas fallan

- GIVEN una postulacion `UNDER_REVIEW` o `REJECTED`
- WHEN se intenta una transicion no definida, incluida reabrir `REJECTED` o usar `WITHDRAWN`/`HIRED`
- THEN la API rechaza la operacion con error de transicion invalida
- AND conserva el estado anterior y no registra una auditoria de cambio inexistente

### R6: CV y archivos

Los CV DEBEN almacenarse como objetos privados en MinIO y su metadata DEBE persistirse en MongoDB con, como minimo, `objectKey`, `fileName`, `mimeType`, `size` y `createdAt`. La `objectKey` DEBE usar UUID y no contener identificadores predecibles. El sistema DEBE aceptar solo extensiones configuradas como permitidas, validar el MIME real y limitar el archivo a 5 MB. Una extension no permitida DEBE rechazarse explicitamente con mensaje claro antes de almacenar; por ejemplo, `.xlsx` DEBE fallar y NO DEBE aceptarse ni almacenarse. La descarga DEBE requerir autenticacion administrativa y no DEBE existir URL publica permanente.

#### Scenario: CV permitido se almacena con metadata

- GIVEN una postulacion valida y un CV de extension permitida cuyo MIME real coincide y cuyo tamano es menor o igual a 5 MB
- WHEN se envia el archivo
- THEN se persiste el objeto privado en MinIO bajo una key UUID
- AND MongoDB conserva la metadata requerida

#### Scenario: Extension `.xlsx` se rechaza explicitamente

- GIVEN un candidato intenta adjuntar un archivo con extension `.xlsx`
- WHEN se procesa la postulacion
- THEN la API responde error indicando que la extension no esta permitida
- AND el archivo no se acepta, no se persiste en MinIO y no queda metadata huerfana

#### Scenario: MIME real que no coincide se rechaza

- GIVEN un archivo con extension permitida pero contenido/MIME real incompatible
- WHEN se valida el CV
- THEN la API lo rechaza con error de tipo de archivo invalido
- AND no almacena el objeto

#### Scenario: CV mayor de 5 MB se rechaza

- GIVEN un CV cuyo tamano supera 5 MB
- WHEN se envia la postulacion
- THEN la API responde error claro de limite de tamano
- AND no persiste el objeto ni la postulacion incompleta

#### Scenario: Descarga administrativa no expone almacenamiento

- GIVEN un usuario administrativo autenticado consulta un CV
- WHEN solicita su descarga
- THEN obtiene el archivo mediante una operacion autorizada
- AND una solicitud publica o sin autorizacion recibe 401/403 y no recibe URL publica permanente

### R7: Correo asincrono y persistencia primero

El sistema DEBE persistir postulaciones y contactos antes de intentar enviar correo. DEBE emitir eventos de dominio y procesarlos asincronamente con Spring Events y `@Async` o equivalente, usando plantillas separadas de los controllers. Los destinatarios DEBEN ser administrables y no hardcodeados. Una falla SMTP NO DEBE perder el registro original y DEBE dejar un resultado observable para reintento o reenvio administrativo.

#### Scenario: Postulacion persiste aunque SMTP falle

- GIVEN una postulacion valida y un servidor SMTP no disponible
- WHEN se recibe la postulacion y se procesa su evento de correo
- THEN la postulacion y su CV permanecen persistidos
- AND el fallo de envio queda registrado con su correlation ID y estado de envio fallido/reintentable

#### Scenario: Correo de postulacion usa plantilla y destinatarios vigentes

- GIVEN existen destinatarios activos para `JOB_APPLICATION`
- WHEN se persiste una postulacion
- THEN se genera el correo con la plantilla correspondiente
- AND se envia asincronamente a los destinatarios activos sin bloquear la respuesta publica

### R8: Formulario de contacto y modulo contable

El sistema DEBE ofrecer un formulario publico de contacto con validacion, honeypot, idempotencia y rate limiting. Un contacto valido DEBE persistirse, confirmar la recepcion al usuario y notificar a destinatarios activos. La consulta y administracion de mensajes DEBE pertenecer al modulo contable, protegido por el RBAC existente y consumiendo `admin-api` el contrato interno; no se DEBE crear un bridge service.

#### Scenario: Contacto valido se confirma y notifica

- GIVEN un formulario con datos validos, honeypot vacio y limites disponibles
- WHEN el visitante lo envia
- THEN la API persiste el contacto
- AND devuelve confirmacion al visitante y programa la notificacion asincrona al modulo contable

#### Scenario: Usuario contable gestiona un contacto

- GIVEN un usuario con el permiso del modulo contable
- WHEN consulta o actualiza un mensaje mediante Angular y `admin-api`
- THEN la operacion se autoriza mediante el RBAC existente y `admin-api` consulta `public-api` por `/api/internal/**`
- AND un usuario sin el permiso recibe 403

### R9: Destinatarios de notificaciones

El sistema DEBE permitir CRUD administrativo de destinatarios con tipo `JOB_APPLICATION` o `CONTACT_FORM`, direccion, estado activo/inactivo y los atributos estrictamente necesarios para enrutar notificaciones. Solo destinatarios activos DEBEN recibir correo. El acceso DEBE concederse por rol al crear el usuario, igual que el RBAC existente de modulos y acciones `VER`, `CREAR`, `EDITAR`, `ELIMINAR`. Todo modulo nuevo DEBE otorgarse automaticamente al rol `ADMIN` mediante el DataSeeder/RBAC, sin intervencion manual.

#### Scenario: Se desactiva un destinatario

- GIVEN un destinatario activo para `CONTACT_FORM`
- WHEN un administrador con permiso lo desactiva
- THEN queda persistido como inactivo
- AND los contactos posteriores no se envian a esa direccion

#### Scenario: Permiso se asigna por rol y admin lo recibe automaticamente

- GIVEN se crea un modulo nuevo del change y se ejecuta el DataSeeder/RBAC
- WHEN se crea un usuario con un rol autorizado y se consulta el rol `ADMIN`
- THEN el modulo dispone de sus acciones RBAC definidas
- AND `ADMIN` posee automaticamente el permiso de ver y las acciones administrativas aplicables sin edicion manual

### R10: Seguridad de `public-api`

`public-api` DEBE usar DTOs explicitos, Bean Validation, sanitizacion/escape de entradas y salidas, limites de payload, allowlists de URLs y extensiones, CORS restrictivo a los frontends conocidos, headers de seguridad, timeouts y errores genericos sin stack traces ni datos sensibles. DEBE implementar honeypot e idempotencia para formularios publicos. Los logs NO DEBEN incluir CV, contenido sensible, credenciales ni tokens.

#### Scenario: Entrada peligrosa no se persiste sin sanitizar

- GIVEN un visitante envia contenido con etiquetas o valores no permitidos
- WHEN la API valida y procesa el formulario
- THEN rechaza o sanitiza el valor segun el campo
- AND no persiste contenido ejecutable ni construye consultas con entrada sin parametrizar

#### Scenario: Reenvio con la misma idempotency key no duplica

- GIVEN una solicitud publica ya procesada con una idempotency key
- WHEN se reenvia la misma solicitud con esa key
- THEN la API devuelve el resultado idempotente o una respuesta equivalente
- AND no crea una segunda postulacion ni un segundo contacto

#### Scenario: Honeypot detecta automatizacion

- GIVEN el campo honeypot contiene un valor
- WHEN se envia el formulario publico
- THEN la API rechaza o descarta la operacion sin persistirla
- AND no revela reglas internas adicionales al cliente

### R11: Rate limiting publico

El sistema DEBE aplicar limites distribuidos mediante Redis: postulaciones `3/IP/15min` y `10/IP/dia`; contactos `5/IP/15min` y `20/IP/dia`. IP NO DEBE tratarse como identidad unica, por lo que DEBEN existir controles complementarios por fingerprint y/o email. Al exceder un limite, la respuesta DEBE ser HTTP 429 e incluir `Retry-After` calculado para el limite aplicable.

#### Scenario: Exceso de postulaciones devuelve 429

- GIVEN una IP ya realizo 3 postulaciones en 15 minutos o 10 en el dia
- WHEN intenta otra postulacion
- THEN la API responde HTTP 429
- AND incluye el header `Retry-After`
- AND no persiste una nueva postulacion

#### Scenario: Exceso de contactos devuelve 429

- GIVEN una IP ya realizo 5 contactos en 15 minutos o 20 en el dia
- WHEN intenta otro contacto
- THEN la API responde HTTP 429 con `Retry-After`
- AND los contadores complementarios de fingerprint/email tambien pueden impedir el abuso aunque cambie la IP

### R12: JWT S2S e endpoints internos

Las rutas `/api/internal/**` DEBEN exigir un JWT S2S firmado asimetricamente con RS256 o EdDSA, validando `issuer`, `audience`, expiracion corta, `kid` y firma. Las claves DEBEN poder rotarse sin compartir un secreto HMAC ni almacenar claves privadas en Git. Solo `admin-api` autenticado como servicio autorizado DEBE invocar esas rutas; las rutas `/api/public/**` DEBEN conservar su contrato publico separado.

#### Scenario: Solicitud interna sin JWT valido se rechaza

- GIVEN una solicitud a `/api/internal/**` sin token, con token mal firmado o con audiencia/issuer incorrectos
- WHEN llega a `public-api`
- THEN responde HTTP 401/403
- AND no ejecuta el caso de uso ni expone datos internos

#### Scenario: JWT S2S expirado se rechaza

- GIVEN un JWT con firma correcta pero expirado
- WHEN `admin-api` invoca una ruta interna
- THEN `public-api` responde HTTP 401
- AND no acepta la operacion

#### Scenario: Rotacion por `kid` mantiene la continuidad controlada

- GIVEN una clave nueva publicada con `kid` distinto y la clave anterior aun dentro de su ventana de validacion
- WHEN se reciben tokens firmados con ambos `kid` validos
- THEN ambos se validan solo durante la ventana definida
- AND un token firmado con una clave retirada se rechaza

### R13: Resiliencia y degradacion del portal administrativo

La integracion Angular → `admin-api` → `public-api` DEBE usar timeouts, errores tipados y comportamiento de degradacion. Una caida de `public-api` NO DEBE impedir que `admin-api` atienda sus propios modulos PostgreSQL. El modulo de talento DEBE mostrar el texto visual: `Servicio de postulaciones temporalmente no disponible` cuando la consulta o accion dependiente no pueda completarse.

#### Scenario: `public-api` caido muestra fallback y admin sigue operativo

- GIVEN `public-api` no responde o excede el timeout
- WHEN un usuario abre el modulo de talento y otro usuario consulta un modulo propio de `admin-api`
- THEN Angular muestra `Servicio de postulaciones temporalmente no disponible` en talento
- AND el modulo propio de `admin-api` continua respondiendo normalmente
- AND no se pierde ni corrompe una transaccion PostgreSQL independiente

### R14: Observabilidad y correlation IDs

Todas las solicitudes publicas, internas y administrativas relacionadas DEBEN propagar o generar un correlation ID. `public-api` y `admin-api` DEBEN emitir logging estructurado con eventos relevantes: postulacion recibida, contacto recibido, rechazo de validacion, rate limit 429, transicion de estado, descarga de CV, fallo SMTP, fallo S2S y caida de dependencia. Los registros DEBEN redactar datos sensibles.

#### Scenario: Flujo de postulacion es trazable sin exponer el CV

- GIVEN una postulacion valida que dispara persistencia y correo
- WHEN se procesan la solicitud y el evento asincrono
- THEN ambos registros contienen el mismo correlation ID
- AND ningun registro contiene el binario, token, CV completo ni credenciales

#### Scenario: Rechazo de seguridad queda observable

- GIVEN una solicitud con JWT S2S invalido o limite excedido
- WHEN la API la rechaza
- THEN registra el evento con resultado, ruta y correlation ID
- AND no registra secretos ni datos personales innecesarios

### R15: Portal Astro publico

El portal DEBE ser Astro con SSG/prerender por defecto cuando sea viable, layouts y componentes reutilizables, minimo JavaScript e islands solo para interactividad necesaria. DEBE ofrecer publicaciones, convocatorias, Trabaja con Nosotros y Contactanos. DEBE generar `title`, `description`, `canonical`, Open Graph, sitemap, robots y structured data; borradores NO DEBEN ser indexables. Las imagenes DEBEN optimizarse a WebP/AVIF cuando aplique, usar lazy loading y cache HTTP adecuado. No DEBE exponer credenciales del backend en el cliente.

#### Scenario: Pagina publicada cumple SEO y rendimiento

- GIVEN una publicacion publicada
- WHEN se construye y sirve su pagina Astro
- THEN entrega HTML prerenderizado con title, description, canonical, Open Graph y structured data validos
- AND las imagenes usan formatos optimizados/lazy loading cuando corresponda
- AND no envia JavaScript ni credenciales innecesarias

#### Scenario: Borrador no aparece en indexacion

- GIVEN existe un borrador en `public-api`
- WHEN se genera el portal, sitemap y robots
- THEN el borrador no se prerenderiza como pagina publica ni aparece en sitemap
- AND no tiene metadata indexable

### R16: Modulo Angular de talento

Angular DEBE agregar un feature module NgModule lazy-loaded, compatible con Reactive Forms, Material y Bootstrap existentes. DEBE permitir listar, crear, editar, previsualizar, publicar, despublicar, programar y expirar publicaciones/convocatorias; consultar postulaciones, descargar CV autenticado, cambiar estados validos y administrar contactos/destinatarios segun permisos. Las rutas y acciones DEBEN reutilizar RBAC existente (`data.permissions`, `*appHasPermission` o equivalente). Cada pantalla DEBE representar estados loading, error, empty y exito, incluido el fallback de R13.

#### Scenario: Usuario autorizado gestiona una publicacion desde Angular

- GIVEN un usuario con permisos de talento correspondientes
- WHEN navega al modulo lazy y crea, previsualiza y publica una publicacion valida
- THEN la UI envia el contrato administrativo correcto y refleja el estado publicado
- AND la ruta y los botones se muestran conforme a sus permisos

#### Scenario: Usuario sin permiso no puede operar por URL directa

- GIVEN un usuario autenticado sin el permiso requerido
- WHEN intenta abrir directamente una ruta de talento o ejecutar una accion protegida
- THEN el guard bloquea la navegacion o la accion
- AND no basta con ocultar visualmente el boton para autorizar la operacion

### R17: RBAC para modulos nuevos

Los modulos nuevos de publicaciones, convocatorias, postulaciones, contactos y destinatarios DEBEN integrarse al catalogo RBAC existente con las acciones `VER`, `CREAR`, `EDITAR` y `ELIMINAR` solo donde tengan sentido funcional. El DataSeeder/RBAC DEBE otorgar automaticamente todos los modulos nuevos al rol `ADMIN` de pruebas y la UI DEBE cargar permisos desde el backend, sin listas hardcodeadas de roles o permisos.

#### Scenario: Seed de admin contiene todos los modulos nuevos

- GIVEN una instalacion nueva o una ejecucion idempotente del DataSeeder
- WHEN se consultan los permisos efectivos del usuario admin de pruebas
- THEN incluye `VER` y las acciones aplicables de todos los modulos nuevos
- AND no requiere intervencion manual posterior

#### Scenario: Usuario con solo VER no ve acciones de escritura

- GIVEN un usuario con `TALENTO_VER` pero sin `TALENTO_EDITAR`
- WHEN abre el listado administrativo
- THEN puede consultar los registros
- AND no puede crear, editar, publicar ni eliminar, tanto en UI como en backend

### R18: Testing y documentacion

El cambio DEBE incluir tests unitarios e integracion para contratos y reglas criticas de `public-api`, tests del modulo Angular y pruebas de integracion de los flujos de seguridad, infraestructura y resiliencia. DEBE documentar arquitectura, ownership, matriz de redes, amenazas, S2S, rotacion de claves, almacenamiento, correo y trade-offs mediante ADRs. Los escenarios de este documento DEBEN ser trazables a pruebas o verificaciones automatizadas.

#### Scenario: Flujos criticos quedan cubiertos

- GIVEN la suite del proyecto configurada para backend, `public-api`, Angular e integracion
- WHEN se ejecutan las pruebas
- THEN cubren postulacion valida/invalida, convocatoria cerrada, `.xlsx`, CV mayor de 5 MB, contacto, 429, aceptacion, rechazo, S2S, ownership y caida de `public-api`
- AND no se considera completo el cambio si falla cualquiera de esos casos

#### Scenario: Documentacion permite verificar limites de arquitectura

- GIVEN una persona revisora sin contexto adicional del change
- WHEN consulta la documentacion y ADRs
- THEN puede identificar que servicio posee cada almacenamiento, como se autoriza S2S, que redes son publicas y que trade-offs fueron aceptados

## Reglas de error y comportamiento transversal

1. `400 Bad Request` DEBE utilizarse para validacion de DTO, campos invalidos, extension/MIME/tamano de archivo e idempotencia mal formada.
2. `401 Unauthorized` DEBE utilizarse para ausencia o expiracion de autenticacion; `403 Forbidden` para identidad autenticada sin autorizacion.
3. `404 Not Found` DEBE utilizarse para recursos inexistentes sin revelar informacion adicional.
4. `409 Conflict` DEBE utilizarse para transiciones de estado invalidas, duplicados o conflictos de idempotencia cuando no pueda devolverse el resultado previo.
5. `429 Too Many Requests` DEBE incluir `Retry-After` y un mensaje seguro.
6. `5xx` NO DEBE devolver stack traces, credenciales, detalles de infraestructura ni datos de postulantes.
7. Los controllers DEBEN permanecer delgados; reglas de negocio, ownership y transiciones DEBEN quedar en casos de uso/servicios detras de DTOs y puertos de infraestructura.

## Fuera de alcance

- `flutter/`, Kubernetes, Helm, service mesh y despliegue cloud especifico.
- Bridge service o acceso cruzado entre `admin-api` y los almacenes de `public-api`.
- Portal autenticado de candidatos, seguimiento publico, ATS, CRM, integraciones externas o analitica avanzada.
- CMS general, multi-tenant, internacionalizacion y rediseño transversal del Angular existente.
- Broker durable adicional; el correo usa eventos Spring y procesamiento asincrono dentro del alcance definido.

## Resumen

| # | Requisito | Area | Escenarios |
|---|---|---|---:|
| R1 | Infraestructura, redes y entrada HTTP | Infraestructura | 3 |
| R2 | Aislamiento y ownership de datos | Arquitectura | 3 |
| R3 | Publicaciones y cartelera | Publicaciones | 3 |
| R4 | Convocatorias | Talento | 2 |
| R5 | Postulaciones y maquina de estados | Talento | 4 |
| R6 | CV y archivos | Archivos | 5 |
| R7 | Correo asincrono y persistencia primero | Notificaciones | 2 |
| R8 | Formulario de contacto y modulo contable | Contacto | 2 |
| R9 | Destinatarios de notificaciones | RBAC/Notificaciones | 2 |
| R10 | Seguridad de `public-api` | Seguridad | 3 |
| R11 | Rate limiting publico | Seguridad | 2 |
| R12 | JWT S2S e endpoints internos | Seguridad | 3 |
| R13 | Resiliencia y degradacion | Resiliencia | 1 |
| R14 | Observabilidad y correlation IDs | Operabilidad | 2 |
| R15 | Portal Astro publico | Frontend publico | 2 |
| R16 | Modulo Angular de talento | Frontend administrativo | 2 |
| R17 | RBAC para modulos nuevos | Seguridad/UI | 2 |
| R18 | Testing y documentacion | Calidad | 2 |
| **Total** |  |  | **45** |

## Cobertura

- **Happy paths**: cubiertos para infraestructura, publicaciones, convocatorias, postulacion, CV valido, contacto, correo, destinatarios, Astro y Angular.
- **Edge cases**: cubiertos para convocatoria cerrada, estados terminales, MIME real, extension `.xlsx`, tamano mayor a 5 MB, idempotencia, honeypot, rotacion de claves, ownership y degradacion.
- **Error states**: cubiertos para validacion, 401/403, 409, 429 con `Retry-After`, SMTP, dependencias caidas y ausencia de puertos publicos.
- **Decisiones vinculantes aplicadas**: JWT asimetrico sin HMAC; estados exactos sin reapertura; limites confirmados; admin automatico para modulos nuevos; CV con MIME real, extension allowlist y limite de 5 MB.

## Next Step

Ready for **design** (`sdd-design`).
