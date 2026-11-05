# Capítulo 1 — Qué es FerrePlus y cómo se conectan sus partes

**Estado:** Borrador pendiente de aprobación humana  
**Idioma:** Español neutro internacional  
**Duración objetivo:** 6–8 minutos  
**Formato:** 1920×1080, 16:9  
**Regla:** No iniciar grabaciones hasta aprobar este guion.

## Objetivo

Presentar FerrePlus de forma general: qué problema resuelve, cuáles son sus módulos principales y cómo una petición recorre las interfaces, el entrypoint, las APIs y los servicios de datos.

## Audiencia

Personas técnicas o integrantes del equipo que necesitan entender el sistema antes de trabajar en una funcionalidad concreta.

## Texto de narración

### Escena 1 — Introducción | 0:00–0:35

Bienvenidos a FerrePlus.

FerrePlus es un sistema de gestión para ferreterías y bodegas de repuestos. Su objetivo es centralizar la operación interna, el contenido público y algunos flujos relacionados con talento y comunicación.

En este capítulo veremos la arquitectura general del sistema y la forma en que sus principales componentes se conectan. No entraremos todavía en una funcionalidad específica; primero construiremos el mapa que nos permitirá entender los capítulos siguientes.

### Escena 2 — Vista general | 0:35–1:20

FerrePlus está organizado en varias piezas con responsabilidades diferentes.

El panel administrativo permite gestionar la operación interna. El portal público presenta información para visitantes y usuarios externos. Las APIs separan las reglas del servidor de las interfaces visuales, y los servicios de datos almacenan la información según su naturaleza.

La entrada HTTP local pasa por Traefik, que funciona como punto de enrutamiento. Desde allí, cada hostname dirige la solicitud hacia el servicio que corresponde.

### Escena 3 — Las interfaces | 1:20–2:10

En el lado administrativo se encuentra la interfaz principal de operación. Desde allí se pueden gestionar módulos internos como inventario, ventas, compras, reportes, usuarios y otras áreas configuradas en la aplicación.

El portal público tiene una responsabilidad distinta. Presenta publicaciones, convocatorias, contactos y postulaciones para visitantes. Este portal consulta la API pública en tiempo de ejecución, por lo que la actualización de ciertos contenidos no depende de reconstruir toda la interfaz.

La separación entre ambos frentes ayuda a que cada experiencia tenga sus propias rutas, permisos y necesidades de presentación.

### Escena 4 — Las APIs | 2:10–3:10

El backend administrativo, identificado en el proyecto como `admin-api`, atiende la operación interna y los controles asociados a usuarios autenticados.

La `public-api` atiende el contenido y los formularios públicos. También coordina el acceso a los servicios que pertenecen al dominio público.

Esta separación es importante porque evita que todas las partes del sistema tengan acceso directo a todos los datos. Cada API actúa como una frontera con sus propias validaciones, contratos y responsabilidades.

Cuando una interfaz necesita datos, no debería conectarse directamente a una base de datos. La solicitud pasa por la API correspondiente, que valida la entrada, aplica las reglas necesarias y devuelve una respuesta que la interfaz puede presentar.

### Escena 5 — Traefik y Docker | 3:10–4:05

En el entorno local, los servicios se ejecutan mediante Docker Compose.

Traefik funciona como entrypoint HTTP. En lugar de acceder a cada contenedor por separado, usamos hostnames locales como `public.localhost`, `admin.localhost`, `api.localhost` y `api-admin.localhost`.

Esta decisión permite que el entorno local se parezca al flujo de entrada de un despliegue real, manteniendo los servicios internos separados y evitando publicar innecesariamente las bases de datos en Internet.

El archivo de Compose también define redes, dependencias, healthchecks, límites de recursos, perfiles opcionales y secretos montados desde archivos locales ignorados por Git.

### Escena 6 — Servicios de datos | 4:05–5:05

FerrePlus utiliza distintos servicios de datos, cada uno con una función específica.

PostgreSQL respalda la operación administrativa. MongoDB almacena contenido asociado al portal público. Redis se utiliza para límites y estados auxiliares. MinIO proporciona almacenamiento para medios y archivos.

La decisión importante no es solamente qué tecnología se utiliza, sino qué servicio es responsable de cada dato y qué componentes pueden acceder a él.

Por eso las redes internas y las fronteras entre APIs son parte de la arquitectura. Un servicio no debería obtener acceso directo a un almacenamiento que pertenece a otro dominio si no existe una razón explícita para hacerlo.

### Escena 7 — Recorrido de una petición | 5:05–6:15

Veamos el recorrido general de una petición pública.

El navegador solicita una ruta del portal. Traefik recibe la solicitud y la dirige al frontend público. Cuando el portal necesita contenido dinámico, consulta la `public-api` a través de la ruta correspondiente.

La API valida la solicitud, aplica sus reglas de negocio y consulta el almacenamiento que le pertenece. Después devuelve una respuesta al portal, que actualiza la pantalla para el usuario.

En el caso administrativo, el recorrido cambia de frontera: la interfaz administrativa consulta el `admin-api`, que valida la identidad, los permisos y las reglas de la operación antes de acceder a PostgreSQL o comunicarse con otros servicios autorizados.

### Escena 8 — Desarrollo local y Cloudflare Tunnel | 6:15–7:05

El entorno local funciona sin Cloudflare. Para pruebas temporales o acceso externo controlado, el proyecto puede utilizar Cloudflare Tunnel mediante el perfil opcional de `cloudflared`.

El token del named tunnel se monta como secreto local y no forma parte del repositorio. También existe un flujo de Quick Tunnel para pruebas temporales, pero sus URLs cambian y no deben tratarse como configuración de producción.

Esta distinción permite mantener el desarrollo local reproducible sin convertir una herramienta de prueba en una dependencia obligatoria del sistema.

### Escena 9 — Cierre | 7:05–7:40

En resumen, FerrePlus combina dos experiencias principales, varias APIs, un entrypoint común y servicios de datos separados por responsabilidad.

La idea central es que cada parte tenga un límite claro: las interfaces presentan y solicitan información, las APIs aplican reglas y validaciones, Traefik enruta las solicitudes y cada almacenamiento conserva los datos que le corresponden.

En el siguiente capítulo veremos cómo levantar este entorno local y cómo comprobar que sus servicios están saludables.

## Texto en pantalla

- `FerrePlus`
- `Panel administrativo`
- `Portal público`
- `admin-api`
- `public-api`
- `Traefik`
- `PostgreSQL`
- `MongoDB`
- `Redis`
- `MinIO`
- `Cloudflare Tunnel opcional`

## Tomas requeridas

| ID | Toma | Fuente | Acción |
| --- | --- | --- | --- |
| T1 | Portada | Gráfico generado | Mostrar título y objetivo |
| T2 | Portal público | `http://public.localhost:8088` | Mostrar la página inicial sin datos sensibles |
| T3 | Panel administrativo | `http://admin.localhost:8088` | Mostrar únicamente la interfaz; ocultar cuentas y datos reales |
| T4 | Arquitectura | Diagrama Mermaid | Mostrar interfaces, Traefik, APIs y datos |
| T5 | Docker Compose | Terminal | Mostrar solo comandos seguros y salida resumida |
| T6 | Hostnames locales | Navegador/diagrama | Mostrar `public.localhost`, `admin.localhost`, `api.localhost` y `api-admin.localhost` |
| T7 | Servicios | Diagrama | Mostrar PostgreSQL, MongoDB, Redis y MinIO con sus responsabilidades |
| T8 | Flujo público | Diagrama animado o estático | Mostrar navegador → Traefik → portal → `public-api` → almacenamiento |
| T9 | Cloudflare opcional | Diagrama | Mostrar `cloudflared` sin mostrar token |
| T10 | Cierre | Gráfico generado | Mostrar resumen y siguiente capítulo |

## Reglas de grabación

- No mostrar `.env`, `secrets/`, tokens, claves, contraseñas ni datos personales.
- No mostrar videos o audio externos durante la captura.
- Silenciar `Desktop Audio` y `Mic/Aux` en OBS.
- Usar viewport y canvas de `1920×1080`.
- No modificar la aplicación para producir el video.
- Usar datos ficticios o pantallas públicas para las demostraciones.
- Aprobar este archivo antes de generar las tomas.

## Criterios de aprobación

El guion se considera aprobado cuando se confirme:

- [ ] El orden de las escenas es correcto.
- [ ] La narración representa correctamente el sistema.
- [ ] La duración objetivo es adecuada.
- [ ] Las tomas requeridas son aceptables.
- [ ] No hay afirmaciones que deban eliminarse o reformularse.
- [ ] Se autoriza comenzar la grabación automática.
