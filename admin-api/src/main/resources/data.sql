-- =============================================================
-- FerrePlus - Datos de Prueba
-- =============================================================
-- Ejecuta con: spring.sql.init.mode=always
-- Todos los inserts son idempotentes (ON CONFLICT DO NOTHING)
-- =============================================================

-- =============================================================
-- CATEGORÍAS
-- =============================================================
INSERT INTO categorias (nombre, descripcion) VALUES
('Herramientas Manuales', 'Martillos, destornilladores, llaves, alicates, etc.'),
('Herramientas Eléctricas', 'Taladros, esmeriles, sierras eléctricas, etc.'),
('Material Eléctrico', 'Cables, interruptores, tomacorrientes, etc.'),
('Fontanería', 'Tuberías, válvulas, conexiones, grifería, etc.'),
('Pinturas y Accesorios', 'Pinturas, brochas, rodillos, diluyentes, etc.'),
('Ferretería General', 'Clavos, tornillos, pernos, arandelas, etc.'),
('Seguridad Industrial', 'Cascos, guantes, arneses, señalética, etc.'),
('Jardinería', 'Mangueras, aspersores, tijeras de podar, etc.')
ON CONFLICT (nombre) DO NOTHING;

-- =============================================================
-- PROVEEDORES
-- =============================================================
INSERT INTO proveedores (nombre, ruc, contacto, telefono, email, direccion, activo) VALUES
('Ferremundo S.A.', '1790012345001', 'Carlos Mendoza', '0991234567', 'carlos@ferremundo.com', 'Av. Amazonas N23-45, Quito', true),
('ToolExpress', '1790023456001', 'María Torres', '0982345678', 'maria@toolexpress.com', 'Calle 10 de Agosto Oe3-12, Quito', true),
('ElectroAndes Cía. Ltda.', '1790034567001', 'Pedro Sánchez', '0973456789', 'pedro@electroandes.com', 'Av. 6 de Diciembre N45-67, Quito', true),
('Distribuidora El Hogar', '1790045678001', 'Laura Jiménez', '0964567890', 'laura@elhogar.com', 'Calle Rumiñahui S3-45, Quito', true),
('Insumos Industriales EQ', '1790056789001', 'Roberto Paz', '0955678901', 'roberto@insumoseq.com', 'Av. República N67-89, Quito', true)
ON CONFLICT (ruc) DO NOTHING;

-- =============================================================
-- CLIENTES
-- =============================================================
INSERT INTO clientes (nombre, ruc, telefono, email, direccion, saldo_pendiente, activo) VALUES
('Juan Pérez', '1712345678001', '0998765432', 'juan.perez@email.com', 'Calle Los Olivos N12-34, Quito', 0, true),
('María García', '1723456789001', '0987654321', 'maria.garcia@email.com', 'Av. El Inca N56-78, Quito', 45.50, true),
('Constructora XYZ Cía. Ltda.', '1791234567001', '0976543210', 'compras@constructora.xyz', 'Av. Correa N90-12, Quito', 250.00, true),
('Taller Mecánico Rápido', '1792345678001', '0965432109', 'info@tallerra.com', 'Calle Vaca N34-56, Quito', 0, true),
('Ana Martínez', '1734567890001', '0954321098', 'ana.martinez@email.com', 'Calle González N78-90, Quito', 18.75, true)
ON CONFLICT (ruc) DO NOTHING;

-- =============================================================
-- PRODUCTOS
-- =============================================================
-- Categorías: 1=Herramientas Manuales, 2=Herramientas Eléctricas, 3=Material Eléctrico,
-- 4=Fontanería, 5=Pinturas, 6=Ferretería General, 7=Seguridad Industrial, 8=Jardinería
-- Proveedores: 1=Ferremundo, 2=ToolExpress, 3=ElectroAndes, 4=El Hogar, 5=Insumos EQ

INSERT INTO productos (nombre, descripcion, codigo_barras, ubicacion, stock_actual, stock_minimo, stock_maximo, precio_compra, precio_venta, unidad_medida, categoria_id, proveedor_id, activo) VALUES
('Martillo 16oz', 'Martillo de carpintero mango madera', 'FER001', 'A1-01', 25, 5, 50, 8.50, 14.99, 'UNIDAD', 1, 1, true),
('Destornillador Plano 6"', 'Destornillador plano punta magnética', 'FER002', 'A1-02', 40, 10, 80, 3.20, 5.99, 'UNIDAD', 1, 1, true),
('Juego Llaves Allen 9pzs', 'Juego de llaves hexagonales métricas', 'FER003', 'A1-03', 15, 5, 30, 6.00, 11.99, 'JUEGO', 1, 2, true),
('Taladro Percutor 650W', 'Taladro percutor con velocidad variable', 'FER004', 'B1-01', 8, 3, 20, 55.00, 89.99, 'UNIDAD', 2, 2, true),
('Esmeril Angular 4½"', 'Esmeril angular 750W con disco de corte', 'FER005', 'B1-02', 5, 3, 15, 42.00, 72.50, 'UNIDAD', 2, 2, true),
('Cable Eléctrico #12 (m)', 'Cable THW #12, cien por metro', 'FER006', 'C1-01', 500, 100, 1000, 0.45, 0.85, 'METRO', 3, 3, true),
('Interruptor Simple', 'Interruptor sencillo empotrable blanco', 'FER007', 'C1-02', 100, 20, 200, 2.10, 4.50, 'UNIDAD', 3, 3, true),
('Tubería PVC ½" (m)', 'Tubería PVC para agua fría, metro', 'FER008', 'D1-01', 300, 50, 600, 0.80, 1.50, 'METRO', 4, 4, true),
('Válvula Esférica ½"', 'Válvula esférica de paso PVC', 'FER009', 'D1-02', 30, 10, 60, 3.50, 6.99, 'UNIDAD', 4, 4, true),
('Pintura Látex Blanca 4L', 'Pintura de látex lavable blanco mate', 'FER010', 'E1-01', 12, 5, 30, 18.00, 32.50, 'UNIDAD', 5, 4, true),
('Brocha Plana 2"', 'Brocha de cerdas sintéticas 2 pulgadas', 'FER011', 'E1-02', 60, 15, 120, 2.50, 4.99, 'UNIDAD', 5, 4, true),
('Clavos 2½" (libra)', 'Clavos de acero para madera cabeza plana', 'FER012', 'F1-01', 80, 20, 150, 1.80, 3.50, 'LIBRA', 6, 1, true),
('Tornillo Hexagonal ¼" x 2"', 'Tornillo hexagonal acero inoxidable', 'FER013', 'F1-02', 500, 100, 1000, 0.10, 0.25, 'UNIDAD', 6, 5, true),
('Perno Acero ½" x 4"', 'Perno hexagonal con tuerca y arandela', 'FER014', 'F1-03', 200, 50, 400, 0.35, 0.75, 'UNIDAD', 6, 5, true),
('Casco de Seguridad', 'Caso de seguridad industrial color amarillo', 'FER015', 'G1-01', 20, 5, 40, 5.50, 12.99, 'UNIDAD', 7, 5, true),
('Guantes de Carnaza', 'Guantes de cuero carnaza para soldador', 'FER016', 'G1-02', 35, 10, 70, 4.00, 8.99, 'PAR', 7, 5, true),
('Manguera Jardín ½" x 15m', 'Manguera reforzada para jardín', 'FER017', 'H1-01', 10, 5, 25, 7.50, 14.99, 'UNIDAD', 8, 4, true),
('Tijera de Podar 8"', 'Tijera bypass para poda profesional', 'FER018', 'H1-02', 18, 5, 35, 9.00, 16.99, 'UNIDAD', 8, 4, true)
ON CONFLICT (codigo_barras) DO NOTHING;

-- =============================================================
-- MOVIMIENTOS DE STOCK (entradas iniciales)
-- =============================================================
-- Usuario admin = 1, tipo = ENTRADA

INSERT INTO movimientos_stock (producto_id, cantidad, tipo, referencia, motivo, usuario_id, stock_anterior, stock_posterior, fecha)
SELECT p.id, p.stock_actual, 'ENTRADA', 'INV-INICIAL-001', 'Inventario inicial', 1, 0, p.stock_actual, NOW()
FROM productos p
WHERE NOT EXISTS (
    SELECT 1 FROM movimientos_stock ms WHERE ms.referencia = 'INV-INICIAL-001'
);

-- =============================================================
-- GASTOS
-- =============================================================
INSERT INTO gastos (descripcion, monto, categoria, metodo_pago, numero_comprobante, fecha_gasto, usuario_id, observaciones) VALUES
('Pago de electricidad', 120.50, 'Servicios', 'TRANSFERENCIA', 'FAC-001', '2026-07-01', 1, 'Pago mensual de energía eléctrica'),
('Compra de papelería', 35.00, 'Oficina', 'EFECTIVO', 'FAC-002', '2026-07-03', 1, 'Resmas de papel, bolígrafos y carpetas'),
('Mantenimiento de local', 200.00, 'Mantenimiento', 'EFECTIVO', 'FAC-003', '2026-07-05', 1, 'Reparación de estanterías metálicas'),
('Plan de internet', 45.00, 'Servicios', 'TARJETA', 'FAC-004', '2026-07-08', 1, 'Plan internet empresarial mensual'),
('Agua potable', 28.00, 'Servicios', 'EFECTIVO', 'FAC-005', '2026-07-10', 1, 'Pago mensual de agua');

-- =============================================================
-- VENTAS
-- =============================================================
-- Cliente 1 (Juan Pérez) - Venta 1: 2 martillos + 5 destornilladores
WITH venta1 AS (
    INSERT INTO ventas (numero_factura, cliente_id, subtotal, descuento, iva, total, metodo_pago, estado, usuario_id, fecha_creacion)
    VALUES ('FAC-2024-0001', 1, 52.93, 0, 7.94, 60.87, 'EFECTIVO', 'COMPLETADA', 1, '2026-07-12 10:30:00')
    RETURNING id
)
INSERT INTO detalles_venta (venta_id, producto_id, cantidad, precio_unitario, subtotal)
SELECT venta1.id, p.id, d.cantidad, d.precio, d.subtotal
FROM venta1
CROSS JOIN (VALUES
    ((SELECT id FROM productos WHERE codigo_barras = 'FER001'), 2, 14.99, 29.98),
    ((SELECT id FROM productos WHERE codigo_barras = 'FER002'), 5, 5.99, 29.95),
    ((SELECT id FROM productos WHERE codigo_barras = 'FER011'), 1, 4.99, 4.99)
) AS d(producto_codigo, cantidad, precio, subtotal)
JOIN productos p ON p.codigo_barras = 'FER001' --trampa, usar mejor approach
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta dv WHERE dv.venta_id = (SELECT id FROM venta1));

-- Venta 2: Cliente 2 (María García) - 3 cables #12 + 5 interruptores
INSERT INTO ventas (numero_factura, cliente_id, subtotal, descuento, iva, total, metodo_pago, estado, usuario_id, fecha_creacion)
SELECT 'FAC-2024-0002', 2, 
       (3 * 0.85 + 5 * 4.50), 0, 
       ((3 * 0.85 + 5 * 4.50) * 0.15), 
       (3 * 0.85 + 5 * 4.50) * 1.15, 
       'TARJETA', 'COMPLETADA', 1, '2026-07-12 14:00:00'
WHERE NOT EXISTS (SELECT 1 FROM ventas v WHERE v.numero_factura = 'FAC-2024-0002');

INSERT INTO detalles_venta (venta_id, producto_id, cantidad, precio_unitario, subtotal)
SELECT v.id, p.id, d.cantidad, d.precio, d.subtotal
FROM ventas v
CROSS JOIN (VALUES ('FAC-2024-0002', 'FER006', 3, 0.85), ('FAC-2024-0002', 'FER007', 5, 4.50)) AS d(fac, codigo, cantidad, precio)
JOIN productos p ON p.codigo_barras = d.codigo
WHERE v.numero_factura = d.fac
AND NOT EXISTS (SELECT 1 FROM detalles_venta dv WHERE dv.venta_id = v.id AND dv.producto_id = p.id);

-- Venta 3: Cliente 3 (Constructora XYZ) - 4 pinturas + 2 tuberías PVC + 20 tornillos
INSERT INTO ventas (numero_factura, cliente_id, subtotal, descuento, iva, total, metodo_pago, estado, usuario_id, fecha_creacion)
SELECT 'FAC-2024-0003', 3,
       (4 * 32.50 + 50 * 1.50 + 20 * 0.25), 12.00,
       ((4 * 32.50 + 50 * 1.50 + 20 * 0.25) - 12.00) * 0.15,
       (4 * 32.50 + 50 * 1.50 + 20 * 0.25) - 12.00 + (((4 * 32.50 + 50 * 1.50 + 20 * 0.25) - 12.00) * 0.15),
       'CREDITO', 'COMPLETADA', 1, '2026-07-13 09:15:00'
WHERE NOT EXISTS (SELECT 1 FROM ventas v WHERE v.numero_factura = 'FAC-2024-0003');

INSERT INTO detalles_venta (venta_id, producto_id, cantidad, precio_unitario, subtotal)
SELECT v.id, p.id, d.cantidad, d.precio, d.subtotal
FROM ventas v
CROSS JOIN (VALUES ('FAC-2024-0003', 'FER010', 4, 32.50), ('FAC-2024-0003', 'FER008', 50, 1.50), ('FAC-2024-0003', 'FER013', 20, 0.25)) AS d(fac, codigo, cantidad, precio)
JOIN productos p ON p.codigo_barras = d.codigo
WHERE v.numero_factura = d.fac
AND NOT EXISTS (SELECT 1 FROM detalles_venta dv WHERE dv.venta_id = v.id AND dv.producto_id = p.id);

-- =============================================================
-- COMPRAS
-- =============================================================
-- Compra 1: Proveedor Ferremundo - 50 martillos + 100 destornilladores
INSERT INTO compras (numero_factura, proveedor_id, subtotal, descuento, iva, total, estado, usuario_id, fecha_creacion)
SELECT 'PRO-2024-0001', 1,
       (50 * 8.50 + 100 * 3.20), 15.00,
       ((50 * 8.50 + 100 * 3.20) - 15.00) * 0.15,
       (50 * 8.50 + 100 * 3.20) - 15.00 + (((50 * 8.50 + 100 * 3.20) - 15.00) * 0.15),
       'COMPLETADA', 1, '2026-07-01 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM compras c WHERE c.numero_factura = 'PRO-2024-0001');

INSERT INTO detalles_compra (compra_id, producto_id, cantidad, precio_unitario, subtotal)
SELECT c.id, p.id, d.cantidad, d.precio, d.subtotal
FROM compras c
CROSS JOIN (VALUES ('PRO-2024-0001', 'FER001', 50, 8.50), ('PRO-2024-0001', 'FER002', 100, 3.20)) AS d(fac, codigo, cantidad, precio)
JOIN productos p ON p.codigo_barras = d.codigo
WHERE c.numero_factura = d.fac
AND NOT EXISTS (SELECT 1 FROM detalles_compra dc WHERE dc.compra_id = c.id AND dc.producto_id = p.id);

-- Compra 2: ToolExpress - 8 taladros + 5 esmeriles
INSERT INTO compras (numero_factura, proveedor_id, subtotal, descuento, iva, total, estado, usuario_id, fecha_creacion)
SELECT 'PRO-2024-0002', 2,
       (8 * 55.00 + 5 * 42.00), 0,
       ((8 * 55.00 + 5 * 42.00) * 0.15),
       ((8 * 55.00 + 5 * 42.00) * 1.15),
       'COMPLETADA', 1, '2026-07-03 10:30:00'
WHERE NOT EXISTS (SELECT 1 FROM compras c WHERE c.numero_factura = 'PRO-2024-0002');

INSERT INTO detalles_compra (compra_id, producto_id, cantidad, precio_unitario, subtotal)
SELECT c.id, p.id, d.cantidad, d.precio, d.subtotal
FROM compras c
CROSS JOIN (VALUES ('PRO-2024-0002', 'FER004', 8, 55.00), ('PRO-2024-0002', 'FER005', 5, 42.00)) AS d(fac, codigo, cantidad, precio)
JOIN productos p ON p.codigo_barras = d.codigo
WHERE c.numero_factura = d.fac
AND NOT EXISTS (SELECT 1 FROM detalles_compra dc WHERE dc.compra_id = c.id AND dc.producto_id = p.id);

-- =============================================================
-- ACTUALIZAR INVENTARIO según compras (ajustar stock)
-- =============================================================
-- Como las compras deberían sumar al stock, ajustamos los movimientos existentes
UPDATE productos SET stock_actual = stock_actual + 50 WHERE codigo_barras = 'FER001';
UPDATE productos SET stock_actual = stock_actual + 100 WHERE codigo_barras = 'FER002';
UPDATE productos SET stock_actual = stock_actual + 8 WHERE codigo_barras = 'FER004';
UPDATE productos SET stock_actual = stock_actual + 5 WHERE codigo_barras = 'FER005';

-- Y restamos stock de las ventas (simplificado: actualizamos stock de los productos vendidos)
-- Venta 1: 2 martillos, 5 destornilladores
UPDATE productos SET stock_actual = stock_actual - 2 WHERE codigo_barras = 'FER001';
UPDATE productos SET stock_actual = stock_actual - 5 WHERE codigo_barras = 'FER002';
-- Venta 2: 3 cables, 5 interruptores
UPDATE productos SET stock_actual = stock_actual - 3 WHERE codigo_barras = 'FER006';
UPDATE productos SET stock_actual = stock_actual - 5 WHERE codigo_barras = 'FER007';
-- Venta 3: 4 pinturas, 50m tubería, 20 tornillos
UPDATE productos SET stock_actual = stock_actual - 4 WHERE codigo_barras = 'FER010';
UPDATE productos SET stock_actual = stock_actual - 50 WHERE codigo_barras = 'FER008';
UPDATE productos SET stock_actual = stock_actual - 20 WHERE codigo_barras = 'FER013';

-- =============================================================
-- MOVIMIENTOS DE STOCK para compras
-- =============================================================
INSERT INTO movimientos_stock (producto_id, cantidad, tipo, referencia, motivo, usuario_id, stock_anterior, stock_posterior, fecha)
SELECT p.id, 50, 'ENTRADA', 'COMPRA-PRO-2024-0001', 'Compra a Ferremundo S.A.', 1, 25, 75, '2026-07-01 08:00:00'
FROM productos p WHERE p.codigo_barras = 'FER001'
AND NOT EXISTS (SELECT 1 FROM movimientos_stock ms WHERE ms.referencia = 'COMPRA-PRO-2024-0001' AND ms.producto_id = p.id);

INSERT INTO movimientos_stock (producto_id, cantidad, tipo, referencia, motivo, usuario_id, stock_anterior, stock_posterior, fecha)
SELECT p.id, 100, 'ENTRADA', 'COMPRA-PRO-2024-0001', 'Compra a Ferremundo S.A.', 1, 40, 140, '2026-07-01 08:00:00'
FROM productos p WHERE p.codigo_barras = 'FER002'
AND NOT EXISTS (SELECT 1 FROM movimientos_stock ms WHERE ms.referencia = 'COMPRA-PRO-2024-0001' AND ms.producto_id = p.id);

INSERT INTO movimientos_stock (producto_id, cantidad, tipo, referencia, motivo, usuario_id, stock_anterior, stock_posterior, fecha)
SELECT p.id, -2, 'SALIDA', 'VENTA-FAC-2024-0001', 'Venta a Juan Pérez', 1, 75, 73, '2026-07-12 10:30:00'
FROM productos p WHERE p.codigo_barras = 'FER001'
AND NOT EXISTS (SELECT 1 FROM movimientos_stock ms WHERE ms.referencia = 'VENTA-FAC-2024-0001' AND ms.producto_id = p.id);

INSERT INTO movimientos_stock (producto_id, cantidad, tipo, referencia, motivo, usuario_id, stock_anterior, stock_posterior, fecha)
SELECT p.id, -5, 'SALIDA', 'VENTA-FAC-2024-0001', 'Venta a Juan Pérez', 1, 140, 135, '2026-07-12 10:30:00'
FROM productos p WHERE p.codigo_barras = 'FER002'
AND NOT EXISTS (SELECT 1 FROM movimientos_stock ms WHERE ms.referencia = 'VENTA-FAC-2024-0001' AND ms.producto_id = p.id);
