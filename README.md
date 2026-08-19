# FerrePlus

Sistema de gestión de inventario para ferreterías y bodegas de repuestos. Backend REST API con Spring Boot 3 + Angular 22 + PostgreSQL.

## Stack Tecnológico

| Capa     | Tecnología                                  |
| -------- | ------------------------------------------- |
| Backend  | Java 21, Spring Boot 3.4, Maven             |
| Frontend | Angular 22, Bootstrap 5, Angular Material   |
| BD       | PostgreSQL (pgvector)                       |
| Auth     | JWT (JSON Web Tokens)                       |
| IA       | Google Gemini (chat + embeddings)           |
| Backend (prod) | Docker (multi-stage)                  |

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
psql -U postgres -d ferreplus -f backend/src/main/resources/schema.sql
```

### 2. Backend (Docker)

```bash
# Desde la raíz del proyecto
docker compose up -d --build
```

Esto compila el backend (multi-stage: Maven → JRE) y levanta el contenedor en `http://localhost:8081`.

> **Swagger UI:** [`http://localhost:8081/swagger-ui/index.html`](http://localhost:8081/swagger-ui/index.html) — documentación interactiva de la API REST.
>
> **Scalar UI:** [`http://localhost:8081/scalar`](http://localhost:8081/scalar) — alternativa moderna a Swagger para probar los endpoints.

### 3. Frontend

```bash
cd frontend
npm install
npm start
```

El frontend corre en `http://localhost:4200`.

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
flutter build apk --dart-define=API_BASE_URL=https://api.example.com
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
- **Password:** `admin123`

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

Si solo modificas `backend/src/main/resources/application.yml` (no código Java):

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

> Usa el puerto `5433` para no chocar con tu PostgreSQL local de desarrollo (`5432`). La configuración está en `backend/src/test/resources/application-test.properties`.

**2. Correr la suite:**

```bash
# Desde la raíz del proyecto (Maven corre dentro de un contenedor, no necesitás instalarlo)
docker run --rm --network=host \
  -v "$(pwd)/backend:/app" -w /app \
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

## Seguridad

- `backend/src/main/resources/application.yml` contiene credenciales locales y **está excluido de git** (`.gitignore`).
- Usá `application.example.yml` como plantilla para tu configuración local.
- Las credenciales de producción se inyectan vía variables de entorno en `docker-compose.yml`.
- `docker-compose.yml` y `backend/Dockerfile` también están excluidos de git.

## Estructura del Proyecto

```
ferreplus/
├── backend/                    # Spring Boot REST API
│   ├── Dockerfile              # Multi-stage (solo local, excluido de git)
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
