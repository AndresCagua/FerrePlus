-- =============================================================
-- FerrePlus - Inicialización de Base de Datos (REFERENCIA)
-- =============================================================
-- ⚠️ NO SE EJECUTA EN RUNTIME: spring.sql.init.mode=never.
-- La fuente única de verdad del seed es DataSeeder (CommandLineRunner),
-- que siembra el catálogo de módulos/permisos (13 módulos, 42 permisos),
-- la matriz de los 3 roles base (ADMIN 42 / VENDEDOR 9 / BODEGUERO 18 → 69
-- pares rol_permisos) y el usuario admin. Ver DOCUMENTACION_INTERNA.md §4.
--
-- Este archivo queda como REFERENCIA del estado inicial mínimo (roles base
-- y password BCrypt del admin) para setup manual de BD.
-- Ejecutar SOLO una vez al inicio del proyecto.
-- =============================================================

-- Crear base de datos (ejecutar como superusuario)
-- CREATE DATABASE ferreplus;

-- =============================================================
-- Roles iniciales del sistema
-- =============================================================
INSERT INTO roles (nombre, descripcion) VALUES
('ADMIN', 'Acceso total al sistema. Gestión de usuarios, configuraciones y todos los módulos.'),
('VENDEDOR', 'Gestión de ventas, clientes y consulta de productos.'),
('BODEGUERO', 'Gestión de inventario, productos, compras y movimientos de stock.')
ON CONFLICT (nombre) DO NOTHING;

-- =============================================================
-- Usuario administrador por defecto
-- =============================================================
-- Password: admin123 (BCrypt encoded)
INSERT INTO usuarios (nombre, email, password, telefono, activo, rol_id, fecha_creacion, fecha_actualizacion)
VALUES ('Administrador', 'admin@ferreplus.com',
        '$2a$10$T/6qIUAIjuo9PbSHwUApd.OdBQuvmXdVIgkcsiY1qxfwD3lE.Psta',
        '0999999999', true, 1, NOW(), NOW())
ON CONFLICT (email) DO NOTHING;
