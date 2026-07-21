# FerrePlus

Sistema de gestión de inventario para ferreterías y bodegas de repuestos. Backend REST API con Spring Boot 3 + Angular 18 + PostgreSQL.

## Stack Tecnológico

| Capa     | Tecnología                              |
| -------- | --------------------------------------- |
| Backend  | Java 21, Spring Boot 3.4, Maven         |
| Frontend | Angular 18, Bootstrap 5, Angular Material |
| BD       | PostgreSQL                              |
| Auth     | JWT (JSON Web Tokens)                   |
| Backend (prod) | Docker                 |

## Requisitos

- **Docker** (para correr el backend en producción)
- **Node.js 18+** (para el frontend)
- **PostgreSQL 15+** (base de datos local)

## Configuración Rápida

### 1. Base de datos

```bash
# Crear la base de datos
psql -U postgres -c "CREATE DATABASE ferreplus;"

# Ejecutar script de inicialización (roles y admin por defecto)
psql -U postgres -d ferreplus -f backend/src/main/resources/schema.sql
```

### 2. Backend (Docker)

```bash
cd backend
docker build -t ferreplus-backend .
docker run -p 8080:8080 \
  -e DB_HOST=host.docker.internal \
  -e DB_PORT=5432 \
  -e DB_NAME=ferreplus \
  -e DB_USERNAME=postgres \
  -e DB_PASSWORD=base_datos_local_andres \
  ferreplus-backend
```

O usando docker-compose desde la raíz:

```bash
docker compose up -d
```

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

## Estructura del Proyecto

```
ferreplus/
├── backend/                    # Spring Boot REST API
│   ├── Dockerfile
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
├── docker-compose.yml
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
| GET    | `/api/productos`            | Listar productos         |
| POST   | `/api/productos`            | Crear producto           |
| GET    | `/api/productos/stock-bajo` | Productos con stock bajo |
| POST   | `/api/ventas`               | Registrar venta          |
| POST   | `/api/compras`              | Registrar compra         |
| POST   | `/api/movimientos-stock`    | Movimiento manual        |
| GET    | `/api/usuarios`             | Listar usuarios (admin)  |
| POST   | `/api/usuarios`             | Crear usuario (admin)    |

Ver `DOCUMENTACION_INTERNA.md` para la documentación completa del modelo de datos y API.
