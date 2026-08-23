# FerrePlus

Sistema de gestión de inventario para ferreterías y bodegas de repuestos, con portal público y módulo de Talento. El sistema combina un backend administrativo para la operación interna, una API pública para contenido y postulaciones, y dos interfaces web.

## Stack Tecnológico

| Capa     | Tecnología                                  |
| -------- | ------------------------------------------- |
| Backend administrativo | Java 21, Spring Boot 3, Maven       |
| API pública | Java 21, Spring Boot 3, MongoDB, Redis, MinIO |
| Frontend | Angular 22, Bootstrap 5, Angular Material   |
| Portal público | Astro 6, salida estática con contenido consultado en runtime |
| BD       | PostgreSQL (pgvector)                       |
| Auth     | JWT (JSON Web Tokens)                       |
| IA       | Google Gemini (chat + embeddings)           |
| Backend (prod) | Docker (multi-stage)                  |

### Arquitectura actual

- **Admin UI (`frontend/`)**: SPA Angular para inventario, ventas, compras, reportes, usuarios, chat IA y Talento.
- **Admin API (`admin-api/`)**: API REST autenticada con JWT para la operación interna y el proxy autenticado hacia Talento.
- **Portal público (`portal/`)**: sitio Astro para publicaciones, convocatorias, postulaciones y contactos.
- **API pública (`public-api/`)**: API REST para contenido público y formularios; persiste contenido en MongoDB, usa Redis para límites/estado auxiliar y MinIO para medios y CV.
- **Traefik**: entrypoint local y enrutamiento por hostname. Cloudflare Tunnel es opcional.

El portal no depende de datos embebidos en un build para las listas y detalles normales: consulta `public-api` en runtime. Por eso publicar o actualizar una publicación o convocatoria desde Talento no requiere reconstruir el portal.

## Requisitos

- **Docker** (para el backend)
- **Node.js 18+** (para el frontend)
- **PostgreSQL 15+** (base de datos local)

## Configuración Rápida

### 1. Base de datos

```bash
# Crear la base de datos
psql -U postgres -c "CREATE DATABASE ferreplus;"

# Ejecutar script de inicialización
psql -U postgres -d ferreplus -f admin-api/src/main/resources/schema.sql
```

### 2. Entorno local (Docker)

```bash
# Desde la raíz del proyecto
docker compose up -d --build
```

Esto compila las APIs y levanta el entorno local con Traefik como entrypoint. Los puertos de
MongoDB, Redis y MinIO quedan publicados exclusivamente en `127.0.0.1`.

El `.env` local del proyecto usa Traefik HTTP en `8088` y HTTPS en `8443`. Los valores por
defecto de Compose son `80` y `443`; si se cambian, deben ajustarse las URLs siguientes.

#### Rutas locales

| Servicio | URL |
| -------- | --- |
| Portal publico | `http://public.localhost:8088` |
| API publica | `http://api.localhost:8088/api` |
| Admin UI | `http://admin.localhost:8088` |
| API admin | `http://api-admin.localhost:8088/api` |
| MinIO API | `http://127.0.0.1:9000` |
| MinIO console | `http://127.0.0.1:9001` |
| Admin UI directa (contenedor) | `http://127.0.0.1:4200` |

#### Conexiones locales para DataGrip/pruebas

MongoDB usa `127.0.0.1:27017`, Redis `127.0.0.1:6379` y MinIO API
`127.0.0.1:9000`. Las credenciales se toman del `.env` local ignorado; no se
documentan aqui. En DataGrip, MongoDB requiere autenticacion **User & Password**,
base de autenticacion `admin` y la URI con `authSource=admin`, por ejemplo:

```text
mongodb://<usuario>:<password>@127.0.0.1:27017/ferreplus_public?authSource=admin
```

No borres los volumenes de Compose para resolver errores de autenticacion: el volumen
`mongodb_data` conserva el usuario creado durante la inicializacion y sus credenciales.
Revisa el secreto local o realiza una rotacion controlada.

> **Swagger UI:** [`http://api-admin.localhost:8088/swagger-ui/index.html`](http://api-admin.localhost:8088/swagger-ui/index.html) — documentación interactiva de la API REST.
>
> **Scalar UI:** [`http://api-admin.localhost:8088/scalar`](http://api-admin.localhost:8088/scalar) — alternativa moderna a Swagger para probar los endpoints.

### 3. Frontend

```bash
cd frontend
npm install
npm start
```

El frontend corre en `http://localhost:4200`.

### Portal público y Talento

El portal público usa las rutas `http://public.localhost:8088`, `http://api.localhost:8088/api`
y carga publicaciones y convocatorias desde `public-api` en runtime. El contenido visible
puede cambiar sin rebuild del portal; solo hace falta reconstruir si cambia el código o la
configuración de la imagen.

Desde **Talento** el usuario autorizado puede:

- Crear, editar, publicar, despublicar y eliminar publicaciones.
- Gestionar publicaciones con portada, galería de imágenes, video de YouTube y enlaces X.
- Crear, editar, publicar y cerrar convocatorias.
- Filtrar postulaciones por convocatoria, revisar su estado y descargar el CV.
- Cambiar el estado de una postulación.
- Consultar contactos y marcarlos como leídos/no leídos.
- Crear, editar y eliminar destinatarios de notificaciones.

Las operaciones de Talento se realizan desde el Admin UI a través del contrato autenticado
de `admin-api`; la API pública expone únicamente el contenido y formularios públicos.

### CAPTCHA Turnstile

- En perfiles `dev` y `test` se puede usar `CAPTCHA_ENABLED=false` para desarrollo y pruebas.
- En producción el CAPTCHA debe permanecer habilitado y `public-api` exige una clave secreta
  configurada mediante `TURNSTILE_SECRET_KEY`.
- El portal recibe la clave pública mediante `PUBLIC_TURNSTILE_SITE_KEY` y la compilación
  también puede controlar la presentación con `PUBLIC_CAPTCHA_ENABLED`.
- Nunca se deben incluir claves reales en este README, en el repositorio ni en logs.

Para producción se recomienda usar el endpoint oficial de verificación configurado por
`TURNSTILE_VERIFY_URL` y mantener el timeout de verificación en `CAPTCHA_TIMEOUT`.

### Gmail SMTP

`public-api` envía notificaciones mediante SMTP. Para Gmail, configura en el entorno local
o de despliegue únicamente estas variables:

| Variable | Valor para Gmail |
| -------- | ---------------- |
| `SMTP_HOST` | `smtp.gmail.com` |
| `SMTP_PORT` | `587` |
| `SMTP_USERNAME` | Cuenta Gmail remitente |
| `SMTP_PASSWORD` | Contraseña de aplicación |
| `SMTP_AUTH` | `true` |
| `SMTP_STARTTLS_ENABLE` | `true` |
| `SMTP_STARTTLS_REQUIRED` | `true` |
| `SMTP_FROM` | Remitente autorizado |

Gmail normalmente requiere verificación en dos pasos y una **contraseña de aplicación**;
no uses la contraseña normal de la cuenta ni documentes ningún valor real.

### Cloudflare Tunnel

El servicio `cloudflared` usa el perfil opcional `tunnel` y ejecuta un **named tunnel** con
un token montado como secreto desde `./secrets/cloudflared.token` (ruta ignorada por Git):

```bash
docker compose --profile tunnel up -d cloudflared
```

El token debe permanecer únicamente en `secrets/` o en otra ruta local ignorada y nunca se
documenta. Un Quick Tunnel gratuito (`trycloudflare.com`) sirve para pruebas temporales,
pero no ofrece un hostname estable ni las garantías operativas de un named tunnel; no lo
trates como configuración de producción.

## App Móvil Flutter

La aplicación móvil vive en `flutter/` y comparte los contratos REST del sistema
sin modificar el backend ni el frontend web.

### Stack y arquitectura

- **Flutter 3.38** y Dart 3.10.
- **Riverpod** para estado y dependencias; **GoRouter** para navegación.
- **Drift/SQLite** para cola y caché local; sincronización orientada a conectividad.
- **Clean Architecture**: `presentation/` depende de `domain/` y `data/`
  implementa sus contratos.
- Tema de tres capas: tokens primitivos, semánticos y de componentes en
  `flutter/lib/presentation/theme/`.

### Estructura principal

```text
flutter/
├── lib/core/                  # configuración, routing y providers base
├── lib/data/                  # Dio, repositorios, Drift y sincronización offline
├── lib/domain/                # modelos, contratos y casos de uso
├── lib/presentation/          # pantallas, formularios, tema y widgets compartidos
├── test/                      # unit, repository y widget tests
└── integration_test/          # flujos de ciclo de vida y sincronización
```

### Desarrollo y verificación

```bash
cd flutter
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081
flutter analyze
flutter test
# Para un build de despliegue, sustituye URL_REAL_DE_LA_API por la URL real.
flutter build apk --dart-define=API_BASE_URL=URL_REAL_DE_LA_API
```

En un emulador Android, `10.0.2.2` apunta al host del equipo. La suite debe
mantener todos los tests existentes y los nuevos tests de widgets/integración.

### Funcionalidades móviles recientes

- Rediseño responsive de chat y formularios: secciones claras, labels legibles,
  espaciado consistente y acciones alcanzables con el teclado abierto.
- Trabajo offline para ventas, compras, gastos y movimientos mediante cola
  SQLite durable, caché optimista y sincronización FIFO al recuperar la red.
- Reintentos acotados, manejo de sesión expirada y notificaciones locales
  agrupadas sin exponer datos sensibles.

### 4. Acceso inicial

- **Email:** `admin@ferreplus.com`
- **Password:** definida solo en la configuracion local ignorada por Git.

## Chat Inteligente (IA)

FerrePlus incluye un asistente conversacional que responde preguntas sobre el negocio en lenguaje natural. Combina **RAG (Retrieval-Augmented Generation)** sobre los datos del sistema con **consultas analíticas** predefinidas.

- **Frontend:** widget de chat disponible en `http://localhost:4200/chat` (requiere sesión iniciada).
- **Backend:** `POST /api/chat` — autenticado con JWT, responde JSON `{ answer, sources }`.

### Consultas soportadas

| Consulta | Ejemplo |
| -------- | ------- |
| Ventas del mes | "¿Cuánto vendimos este mes?" |
| Productos más vendidos | "¿Cuáles son los 5 productos más vendidos?" |
| Stock bajo | "¿Qué productos tienen stock bajo?" |
| Último cambio de producto | "¿Cuál fue el último cambio a un producto?" |
| Compra de mayor monto | "¿Cuál fue la compra más cara?" |
| Mayor gasto | "¿Cuál es el mayor gasto?" |
| Proveedor principal | "¿A qué proveedor le compramos más?" |
| Guías y catálogo (RAG) | "¿Cómo registro una venta?" |

**Semántica de fechas:** sin mencionar fecha = historial completo; "este mes" = mes actual; "último mes"/"el mes pasado" = mes calendario anterior; fechas explícitas `YYYY-MM-DD` = rango.

### Seguridad

- Gemini **nunca genera SQL**: las preguntas se clasifican contra un conjunto cerrado de intents y el enrutado usa una whitelist explícita.
- Todas las consultas analíticas son **solo lectura** (`readOnly`); el chat jamás puede modificar ni eliminar datos.
- Si la pregunta no corresponde a ningún intent soportado, responde con un fallback seguro.

### Configuración

Las credenciales de Gemini se inyectan por variables de entorno (ver `application.example.yml`):

| Variable | Default | Descripción |
| -------- | ------- | ----------- |
| `GEMINI_API_KEY` | — (requerida) | API key de Google AI Studio |
| `GEMINI_CHAT_MODEL` | `gemini-3.6-flash` | Modelo del chat |
| `GEMINI_EMBEDDING_MODEL` | `gemini-embedding-001` | Modelo de embeddings |
| `GEMINI_BASE_URL` | `https://generativelanguage.googleapis.com` | Endpoint de Gemini |

Las consultas analíticas se pueden desactivar con `chat.analytics.enabled: false` (default `true`).

> Sin `GEMINI_API_KEY` el chat responde con un fallback seguro y las consultas analíticas siguen funcionando.

## Desarrollo

### Cuando modificas el backend

Cada vez que cambies código Java, entities, servicios o controladores:

```bash
# 1. Baja el contenedor
docker compose down

# 2. Reconstruye y levanta (compila todo en el contenedor)
docker compose up -d --build

# 3. Verifica que levantó bien
docker compose logs --tail=20
```

> No necesitas Maven instalado en tu máquina — el multi-stage build lo maneja adentro del contenedor.

### Cuando solo cambias config (application.yml)

Si solo modificas `admin-api/src/main/resources/application.yml` (no código Java):

```bash
docker compose down
docker compose up -d --build
```

> `--build` obliga a Docker a re-compilar la imagen aunque el código no haya cambiado.

### Frontend

```bash
cd frontend
npm start    # hot-reload en :4200
```

## Tests

### Backend (requiere PostgreSQL con pgvector)

La suite de tests del backend corre contra un **PostgreSQL real con la extensión pgvector** (no H2) para validar los tipos `vector(768)`, `JSONB` y el operador de similitud coseno `<=>` de forma fiel a producción.

**1. Levantar el contenedor de tests (una sola vez):**

```bash
docker run -d --name ferreplus-pgtest \
  -e POSTGRES_PASSWORD=test \
  -e POSTGRES_DB=ferreplus_test \
  -p 5433:5432 \
  pgvector/pgvector:pg16
```

> Usa el puerto `5433` para no chocar con tu PostgreSQL local de desarrollo (`5432`). La configuración está en `admin-api/src/test/resources/application-test.properties`.

**2. Correr la suite:**

```bash
# Desde la raíz del proyecto (Maven corre dentro de un contenedor, no necesitás instalarlo)
docker run --rm --network=host \
  -v "$(pwd)/admin-api:/app" -w /app \
  maven:3.9-eclipse-temurin-21 mvn test
```

**3. Detener/limpiar el contenedor cuando no lo necesites:**

```bash
docker stop ferreplus-pgtest
docker rm ferreplus-pgtest   # para eliminarlo definitivamente
```

### Frontend

```bash
cd frontend
CI=true npm test -- --watch=false
```

> Los tests del chat (ChatService, ChatComponent) están incluidos en la suite.

### Estado de verificación

En esta actualización del README no se ejecutaron Maven, la suite completa, builds de
Angular/Astro ni pruebas de integración. Los comandos anteriores son la referencia para
ejecutarlos. La verificación del backend administrativo sigue dependiendo de PostgreSQL
con pgvector; la API pública usa además MongoDB, Redis, MinIO y, para ciertos flujos,
servicios externos como Turnstile y SMTP. No se debe interpretar la existencia de tests o
de un contenedor saludable como una ejecución exitosa de toda la suite.

## Seguridad

- Usa `admin-api/src/main/resources/application.example.yml` y `.env.example` como plantillas;
  los secretos reales deben mantenerse en archivos locales ignorados.
- Las credenciales de despliegue se inyectan vía variables de entorno y secretos de Compose.
- Nunca incluyas contraseñas, tokens, claves Turnstile, contraseñas de aplicación Gmail ni
  material criptográfico en el README.

## Estructura del Proyecto

```
ferreplus/
├── admin-api/                  # Spring Boot REST API administrativa
│   ├── Dockerfile              # Build multi-stage de la API
│   ├── pom.xml
│   └── src/main/java/com/ferreplus/
│       ├── config/             # Configuración (CORS, Security)
│       ├── auth/               # JWT (token provider, filters)
│       ├── entity/             # Entidades JPA
│       ├── dto/                # Data Transfer Objects
│       ├── repository/         # Repositorios JPA
│       ├── service/            # Lógica de negocio
│       ├── service/chat/       # Chat RAG (mappers, indexing, RAG)
│       ├── controller/         # Controladores REST
│       └── exception/          # Manejo de errores
├── frontend/                   # Angular SPA
│   └── src/app/
│       ├── core/               # Servicios core, guards, interceptors
│       ├── shared/             # Sidebar, header, shared module
│       ├── auth/               # Login
│       ├── dashboard/          # Dashboard con métricas
│       ├── productos/          # Gestión de productos
│       ├── categorias/         # Categorías
│       ├── proveedores/        # Proveedores
│       ├── clientes/           # Clientes
│       ├── ventas/             # Punto de venta (POS)
│       ├── compras/            # Compras a proveedores
│       ├── movimientos/        # Movimientos de stock
│       ├── gastos/             # Gastos operativos
│       ├── chat/               # Widget de chat IA
│       ├── usuarios/           # Gestión de usuarios (admin)
│       └── reportes/           # Reportes y gráficos
├── docker-compose.yml          # Solo local, excluido de git
└── README.md
```

## Roles del Sistema

| Rol        | Acceso                                                      |
| ---------- | ----------------------------------------------------------- |
| **ADMIN**  | Acceso completo. Gestión de usuarios, roles y configuración. |
| **VENDEDOR** | Ventas, clientes, consulta de productos.                  |
| **BODEGUERO** | Inventario, productos, compras, movimientos de stock.    |

## API Endpoints Principales

| Método | Endpoint                    | Descripción              |
| ------ | --------------------------- | ------------------------ |
| POST   | `/api/auth/login`           | Inicio de sesión         |
| POST   | `/api/chat`                 | Chat IA (consultas y RAG) |
| GET    | `/api/reportes/dashboard`   | Métricas del dashboard   |
| GET    | `/api/reportes/ventas`      | Ventas por período       |
| GET    | `/api/productos`            | Listar productos         |
| POST   | `/api/productos`            | Crear producto           |
| GET    | `/api/productos/stock-bajo` | Productos con stock bajo |
| POST   | `/api/ventas`               | Registrar venta          |
| POST   | `/api/compras`              | Registrar compra         |
| POST   | `/api/movimientos-stock`    | Movimiento manual        |
| GET    | `/api/usuarios`             | Listar usuarios (admin)  |
| POST   | `/api/usuarios`             | Crear usuario (admin)    |
