# FerrePlus

Sistema de gestión de inventario para ferreterías y bodegas de repuestos. Backend REST API con Spring Boot 3 + Angular 22 + PostgreSQL.

## Stack Tecnológico

| Capa     | Tecnología                                  |
| -------- | ------------------------------------------- |
| Backend  | Java 21, Spring Boot 3.4, Maven             |
| Frontend | Angular 22, Bootstrap 5, Angular Material   |
| BD       | PostgreSQL                                  |
| Auth     | JWT (JSON Web Tokens)                       |
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

### 3. Frontend

```bash
cd frontend
npm install
npm start
```

El frontend corre en `http://localhost:4200`.

### 4. Acceso inicial

- **Email:** `admin@ferreplus.com`
- **Password:** `admin123`

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
