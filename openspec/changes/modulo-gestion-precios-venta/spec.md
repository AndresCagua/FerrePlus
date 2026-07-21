# Módulo Gestión de Precios de Venta — Especificación

## Purpose

Este módulo introduce la gestión centralizada de precios de venta sobre los productos existentes. Permite consultar precios actuales con márgenes calculados, actualizar precios de venta (directo o por margen), mantener un historial auditable de cambios de precio, y registrar automáticamente el precio de compra cuando se crean o modifican compras.

No existe una tabla independiente de productos para precios; todo se construye sobre la entidad `Producto` existente y la nueva entidad `HistoricoPrecioProducto`.

---

## Requirements

### Requirement: Entidad HistoricoPrecioProducto

**Domain**: Pricing / Base de datos

El sistema DEBE crear una nueva entidad JPA `HistoricoPrecioProducto` mapeada a la tabla `historico_precios_producto` que registre cada cambio de precio de un producto.

La entidad DEBE contener:
- `id` (Long, auto-generado)
- `producto` (ManyToOne a `Producto`, obligatorio)
- `usuario` (ManyToOne a `Usuario`, OPCIONAL — puede ser nulo cuando el cambio es automático por compra)
- `precioCompra` (BigDecimal, precision 12 scale 2, el precio de compra EN EL MOMENTO del cambio)
- `precioVenta` (BigDecimal, precision 12 scale 2, el precio de venta EN EL MOMENTO del cambio)
- `tipoCambio` (String, uno de: `COMPRA`, `ACTUALIZACION_VENTA`, `AJUSTE`)
- `referencia` (String, opcional — ej: número de factura, o motivo de la actualización)
- `fechaCambio` (LocalDateTime, no nulo, se setea al persistir)

El repositorio DEBE exponer:
- `findByProductoIdOrderByFechaCambioDesc(Long productoId)` — historial descendente (para tabla)
- `findByProductoIdOrderByFechaCambioAsc(Long productoId)` — historial ascendente (para chart cronológico)

#### Scenario: Creación de entidad con valores mínimos

- GIVEN un producto existente con `precioCompra = 5.00` y `precioVenta = 8.50`
- WHEN se crea un `HistoricoPrecioProducto` con `tipoCambio = "COMPRA"` y referencia "FC-001"
- THEN el registro se persiste en `historico_precios_producto`
- AND `precioCompra = 5.00`, `precioVenta = 8.50`, `fechaCambio` es la fecha/hora actual

#### Scenario: Usuario opcional en histórico

- GIVEN un registro histórico generado automáticamente por una compra (sin asociación directa a usuario)
- WHEN se consulta el registro
- THEN el campo `usuario` DEBE ser `null`
- AND NO DEBE lanzar excepción por violación de integridad referencial

---

### Requirement: PrecioCompra se actualiza SOLO al crear/actualizar compras

**Domain**: Pricing / Compras

El `precioCompra` de un producto NO DEBE tener edición directa. La ÚNICA forma de modificarlo es a través de la creación o actualización de compras.

Esta es una regla de negocio crítica: el `precioCompra` siempre refleja el **último precio de compra registrado**.

#### Scenario: Creación de compra actualiza precioCompra y guarda histórico

- GIVEN un producto con `precioCompra = 10.00`
- WHEN se crea una compra con un detalle que incluye ese producto con `precioUnitario = 12.50`
- THEN `producto.precioCompra` DEBE actualizarse a `12.50`
- AND se DEBE guardar un `HistoricoPrecioProducto` con `tipoCambio = "COMPRA"`, `precioCompra = 12.50`, `precioVenta` igual al valor actual del producto, y `referencia` = número de factura de la compra

#### Scenario: Creación de compra con múltiples productos

- GIVEN tres productos A (precioCompra=5), B (precioCompra=8), C (precioCompra=3)
- WHEN se crea una compra con detalles para A (precioUnitario=6), B (precioUnitario=9), C (precioUnitario=4)
- THEN `A.precioCompra = 6`, `B.precioCompra = 9`, `C.precioCompra = 4`
- AND SE DEBEN guardar TRES registros en `historico_precios_producto`, uno por cada producto

#### Scenario: Actualización de compra actualiza precioCompra de nuevos detalles (NO revierte precioCompra de viejos)

- GIVEN una compra existente con un detalle para producto X (precioUnitario=10, precioCompra de X=10)
- WHEN se actualiza la compra cambiando el detalle a producto Y (precioUnitario=20)
- THEN el stock del producto X se revierte (SALIDA)
- AND el stock del producto Y se aplica (ENTRADA)
- AND `X.precioCompra` NO DEBE revertirse a un valor anterior (sigue siendo 10)
- AND `Y.precioCompra` DEBE actualizarse a 20
- AND se DEBE guardar un histórico para Y con `tipoCambio = "COMPRA"`

#### Scenario: Producto inactivo en compra

- GIVEN un producto con `activo = false`
- WHEN se intenta crear una compra con un detalle que referencia ese producto
- THEN `CompraService.create()` DEBE lanzar una excepción (el `ProductoService.getById()` ya valida existencia pero no actividad — se DEBE validar que el producto esté activo o permitirlo según la lógica existente)

---

### Requirement: Listado de precios GET /api/precios

**Domain**: Pricing / API

El sistema DEBE exponer un endpoint `GET /api/precios` que retorne la lista de todos los productos activos con información de precios.

Cada elemento DEBE incluir:
- `id`, `nombre`, `codigoBarras`
- `precioCompra`, `precioVenta`
- `ganancia` = `precioVenta - precioCompra`
- `margenPorcentaje` = ((`precioVenta - precioCompra`) / `precioCompra`) × 100, PERO:
  - Si `precioCompra = 0`, `margenPorcentaje` DEBE ser `null` (NO división por cero)
  - Si `precioCompra = 0`, `ganancia` DEBE ser `null` (no se puede calcular sin base)
- `fechaActualizacion` del producto

#### Scenario: Listado de todos los productos activos

- GIVEN 5 productos activos y 2 productos inactivos
- WHEN se llama a `GET /api/precios`
- THEN la respuesta DEBE contener exactamente 5 elementos
- AND cada elemento DEBE incluir los campos especificados

#### Scenario: Cálculo correcto de ganancia y margen

- GIVEN un producto con `precioCompra = 100.00` y `precioVenta = 150.00`
- WHEN se llama a `GET /api/precios`
- THEN `ganancia` DEBE ser `50.00`
- AND `margenPorcentaje` DEBE ser `50.00` (el 50% de ganancia sobre el precio de compra)

#### Scenario: División por cero evitada

- GIVEN un producto con `precioCompra = 0` y `precioVenta = 25.00`
- WHEN se llama a `GET /api/precios`
- THEN `ganancia` DEBE ser `null`
- AND `margenPorcentaje` DEBE ser `null`
- AND NO DEBE lanzar `ArithmeticException`

#### Scenario: PrecioCompra cero y PrecioVenta cero

- GIVEN un producto con `precioCompra = 0` y `precioVenta = 0`
- WHEN se llama a `GET /api/precios`
- THEN `ganancia` DEBE ser `null`
- AND `margenPorcentaje` DEBE ser `null`

---

### Requirement: Precio de producto individual GET /api/precios/{id}

**Domain**: Pricing / API

El sistema DEBE exponer un endpoint `GET /api/precios/{id}` que retorne la información de precio de un producto específico.

#### Scenario: Producto existente retorna datos

- GIVEN un producto con id=5 y precioCompra=80, precioVenta=120
- WHEN se llama a `GET /api/precios/5`
- THEN la respuesta DEBE tener `ganancia = 40.00` y `margenPorcentaje = 50.00`

#### Scenario: Producto inexistente retorna 404

- GIVEN un id de producto que no existe (ej: 9999)
- WHEN se llama a `GET /api/precios/9999`
- THEN la respuesta DEBE ser HTTP 404 con un mensaje de error descriptivo

#### Scenario: Producto inactivo retorna 404

- GIVEN un producto con `activo = false`
- WHEN se llama a `GET /api/precios/{id}`
- THEN la respuesta DEBE ser HTTP 404 (producto inactivo no debería consultarse en precios)

---

### Requirement: Historial de precios GET /api/precios/{id}/historial

**Domain**: Pricing / API

El sistema DEBE exponer un endpoint `GET /api/precios/{id}/historial` que retorne el historial de cambios de precio de un producto, ordenado por fecha descendente (más reciente primero).

Cada elemento DEBE incluir:
- `id`, `productoId`
- `precioCompra`, `precioVenta`
- `tipoCambio`, `referencia`
- `fechaCambio`
- `usuarioNombre` (String — nombre del usuario si existe, `null` si no tiene usuario asociado)

#### Scenario: Producto con historial retorna registros ordenados

- GIVEN un producto con 3 registros históricos (fechas: 2026-07-20, 2026-07-18, 2026-07-15)
- WHEN se llama a `GET /api/precios/{id}/historial`
- THEN la respuesta DEBE tener 3 elementos
- AND el primer elemento DEBE ser el de fecha 2026-07-20

#### Scenario: Producto sin historial retorna lista vacía

- GIVEN un producto que nunca ha tenido cambios de precio registrados
- WHEN se llama a `GET /api/precios/{id}/historial`
- THEN la respuesta DEBE ser una lista vacía (HTTP 200, no 404)

#### Scenario: Historial incluye nombre de usuario cuando existe

- GIVEN un registro histórico con usuario asociado (nombre="Carlos")
- WHEN se llama al endpoint de historial
- THEN `usuarioNombre` DEBE ser "Carlos"

#### Scenario: Historial con usuario nulo

- GIVEN un registro histórico generado automáticamente por compra (usuario=null)
- WHEN se llama al endpoint de historial
- THEN `usuarioNombre` DEBE ser `null`

---

### Requirement: Actualizar precio de venta PUT /api/precios/{id}/venta

**Domain**: Pricing / API

El sistema DEBE exponer un endpoint `PUT /api/precios/{id}/venta` que permita actualizar el precio de venta de un producto.

El cuerpo de la petición (`ActualizarPrecioVentaDTO`) DEBE aceptar dos campos mutuamente excluyentes:
- `nuevoPrecio` (BigDecimal) — establece directamente el precio de venta
- `margenPorcentaje` (BigDecimal) — calcula `precioVenta = precioCompra × (1 + margenPorcentaje / 100)`

El DTO DEBE incluir además:
- `referencia` (String, opcional) — motivo o nota sobre el cambio

Validaciones:
- Se DEBE enviar EXACTAMENTE UNO de los dos campos (`nuevoPrecio` o `margenPorcentaje`)
- Si se envían ambos, el sistema DEBE rechazar con HTTP 400
- Si no se envía ninguno, el sistema DEBE rechazar con HTTP 400
- `nuevoPrecio` DEBE ser positivo (> 0)
- `margenPorcentaje` DEBE ser positivo (> 0)

Al actualizar:
- Se actualiza `producto.precioVenta`
- Se guarda un `HistoricoPrecioProducto` con `tipoCambio = "ACTUALIZACION_VENTA"`
- El `producto.precioCompra` NO DEBE modificarse

#### Scenario: Actualización por precio directo

- GIVEN un producto con `precioCompra = 100.00` y `precioVenta = 150.00`
- WHEN se envía `PUT /api/precios/1/venta` con `{"nuevoPrecio": 180.00, "referencia": "Ajuste estacional"}`
- THEN `producto.precioVenta` DEBE ser `180.00`
- AND se DEBE guardar un histórico con `tipoCambio = "ACTUALIZACION_VENTA"`, `precioCompra = 100.00`, `precioVenta = 180.00`, `referencia = "Ajuste estacional"`
- AND `producto.precioCompra` DEBE seguir siendo `100.00`

#### Scenario: Actualización por margen porcentual

- GIVEN un producto con `precioCompra = 80.00` y `precioVenta = 100.00`
- WHEN se envía `PUT /api/precios/1/venta` con `{"margenPorcentaje": 50.00}`
- THEN `producto.precioVenta` DEBE ser `120.00` (80 × 1.5)
- AND se DEBE guardar un histórico con `tipoCambio = "ACTUALIZACION_VENTA"`, `precioVenta = 120.00`

#### Scenario: Rechazo cuando se envían ambos campos

- GIVEN cualquier producto
- WHEN se envía `PUT /api/precios/1/venta` con `{"nuevoPrecio": 200.00, "margenPorcentaje": 30.00}`
- THEN la respuesta DEBE ser HTTP 400
- AND el mensaje de error DEBE indicar que los campos son mutuamente excluyentes

#### Scenario: Rechazo cuando no se envía ningún campo

- GIVEN cualquier producto
- WHEN se envía `PUT /api/precios/1/venta` con `{"referencia": "sin precio"}`
- THEN la respuesta DEBE ser HTTP 400
- AND el mensaje de error DEBE indicar que se debe proporcionar `nuevoPrecio` o `margenPorcentaje`

#### Scenario: Cálculo por margen con precioCompra cero

- GIVEN un producto con `precioCompra = 0`
- WHEN se envía `PUT /api/precios/1/venta` con `{"margenPorcentaje": 30.00}`
- THEN la respuesta DEBE ser HTTP 400
- AND el mensaje DEBE indicar que no se puede calcular margen porque el precio de compra es cero

#### Scenario: Producto inexistente retorna 404

- GIVEN un id de producto inexistente
- WHEN se envía `PUT /api/precios/9999/venta` con `{"nuevoPrecio": 100.00}`
- THEN la respuesta DEBE ser HTTP 404

---

### Requirement: Interfaz de listado de precios

**Domain**: Pricing / UI

El frontend DEBE tener un componente `PreciosListComponent` (dentro de `GestionPreciosModule`) que muestre una tabla Material con todos los productos y sus precios.

Columnas de la tabla:
| Columna | Fuente |
|---------|--------|
| Producto | producto.nombre |
| Código | producto.codigoBarras |
| Precio Compra | producto.precioCompra |
| Precio Venta | producto.precioVenta |
| Ganancia ($) | ganancia (null → "—") |
| Margen (%) | margenPorcentaje (null → "Sin datos") |
| Última Actualización | producto.fechaActualización |

La tabla DEBE incluir:
- Filtro/búsqueda por nombre o código de barras
- Ordenamiento por columnas (MatSort)
- Al hacer clic en una fila, navegar a `/gestion-precios/{id}`

#### Scenario: Listado muestra todos los productos activos

- GIVEN 3 productos activos con precios variados
- WHEN el usuario navega a `/gestion-precios`
- THEN la tabla DEBE mostrar 3 filas con sus datos de precio

#### Scenario: Margen muestra "Sin datos" cuando precioCompra es cero

- GIVEN un producto con `precioCompra = 0` y `precioVenta = 25.00`
- WHEN el listado se renderiza
- THEN la columna "Margen (%)" DEBE mostrar "Sin datos"
- AND la columna "Ganancia ($)" DEBE mostrar "—"

#### Scenario: Búsqueda filtra por nombre

- GIVEN productos "Clavo 2 pulgadas", "Tornillo 1/4", "Martillo"
- WHEN el usuario escribe "Clavo" en el filtro
- THEN solo DEBE mostrarse la fila de "Clavo 2 pulgadas"

#### Scenario: Clic en fila navega al detalle

- GIVEN un listado con un producto de id=3
- WHEN el usuario hace clic en la fila del producto
- THEN el router DEBE navegar a `/gestion-precios/3`

---

### Requirement: Detalle de precio con histórico y gráfico

**Domain**: Pricing / UI

El frontend DEBE tener un componente `PrecioDetailComponent` que muestre:

1. **Tarjeta de info actual**: precioCompra, precioVenta, ganancia, margen
2. **Gráfico de línea** (ng2-charts): evolución de precioCompra y precioVenta a través del tiempo (dos series)
3. **Tabla de historial**: Material Table con todos los registros históricos del producto
4. **Botón** "Actualizar Precio de Venta" que abre un diálogo Material

#### Scenario: Detalle carga datos del producto e historial

- GIVEN un producto con id=5 que tiene 4 registros históricos
- WHEN el usuario navega a `/gestion-precios/5`
- THEN la tarjeta DEBE mostrar los datos actuales del producto
- AND la tabla de historial DEBE mostrar 4 filas ordenadas por fecha descendente
- AND el gráfico DEBE renderizar con 2 series de datos

#### Scenario: Producto sin historial muestra gráfico vacío

- GIVEN un producto sin registros históricos
- WHEN se carga el detalle
- THEN la tabla de historial DEBE mostrar "No hay registros"
- AND el gráfico DEBE mostrar un estado vacío o sin datos (NO error)

---

### Requirement: Diálogo de actualización de precio de venta

**Domain**: Pricing / UI

El frontend DEBE tener un componente `ActualizarPrecioDialog` (Material Dialog) que permita:

- Ingresar un nuevo precio de venta (input numérico)
- O ingresar un margen porcentual (input numérico)
- Validación mutuamente excluyente en frontend: si se llena un campo, el otro se deshabilita
- Campo opcional para referencia/motivo
- Botón "Guardar" que llama a `PUT /api/precios/{id}/venta`
- Botón "Cancelar" que cierra el diálogo sin cambios

#### Scenario: Diálogo permite precio directo

- GIVEN un producto con precioCompra=100, precioVenta=150
- WHEN el usuario ingresa nuevoPrecio=200 y presiona Guardar
- THEN se llama al endpoint PUT con `{"nuevoPrecio": 200}`
- AND al cerrar el diálogo, el detalle se refresca con los nuevos datos

#### Scenario: Diálogo permite margen porcentual cuando precioCompra > 0

- GIVEN un producto con precioCompra=100
- WHEN el usuario ingresa margenPorcentaje=30 y presiona Guardar
- THEN se llama al endpoint PUT con `{"margenPorcentaje": 30}`

#### Scenario: Diálogo deshabilita margen cuando precioCompra es cero

- GIVEN un producto con precioCompra=0
- WHEN se abre el diálogo de actualización
- THEN el campo de margenPorcentaje DEBE estar deshabilitado
- AND DEBE mostrar un tooltip o mensaje "No hay precio de compra registrado"

#### Scenario: Validación frontend de exclusión mutua

- GIVEN el diálogo abierto
- WHEN el usuario escribe en "Nuevo Precio"
- THEN el campo "Margen %" DEBE deshabilitarse automáticamente
- WHEN el usuario borra "Nuevo Precio" y escribe en "Margen %"
- THEN el campo "Nuevo Precio" DEBE deshabilitarse automáticamente

---

### Requirement: Navegación y sidebar

**Domain**: Pricing / UI

El sistema DEBE:
- Agregar la ruta lazy-loaded `gestion-precios` en `AppRoutingModule` con `AuthGuard`
- Agregar un item "Precios" con icono `attach_money` en el `SidebarComponent` en la sección de gestión (cerca de Compras/Movimientos)
- No requiere roles específicos (visible para todos los roles autenticados)

#### Scenario: Ruta lazy-loaded funciona con autenticación

- GIVEN un usuario autenticado
- WHEN navega a `/gestion-precios`
- THEN el módulo `GestionPreciosModule` se carga lazy-loaded
- AND el componente `PreciosListComponent` se renderiza

#### Scenario: Ruta redirige si no autenticado

- GIVEN un usuario NO autenticado
- WHEN intenta navegar a `/gestion-precios`
- THEN el `AuthGuard` redirige a `/auth`

#### Scenario: Sidebar muestra item Precios

- GIVEN el sidebar renderizado
- THEN DEBE existir un item con label "Precios", icono "attach_money" y ruta "/gestion-precios"
- AND DEBE aparecer después del item "Compras" y antes de "Movimientos"

---

### Requirement: Modelos frontend

**Domain**: Pricing / UI / Modelos

El sistema DEBE agregar tres nuevas interfaces en `core/models.ts`:

```typescript
export interface PrecioProducto {
  id: number;
  nombre: string;
  codigoBarras: string;
  precioCompra: number;
  precioVenta: number;
  ganancia: number | null;
  margenPorcentaje: number | null;
  fechaActualizacion: string;
}

export interface HistoricoPrecioProducto {
  id: number;
  productoId: number;
  precioCompra: number;
  precioVenta: number;
  tipoCambio: string;
  referencia: string | null;
  fechaCambio: string;
  usuarioNombre: string | null;
}

export interface ActualizarPrecioVentaRequest {
  nuevoPrecio?: number;
  margenPorcentaje?: number;
  referencia?: string;
}
```

---

### Requirement: Servicio Angular PrecioService

**Domain**: Pricing / UI / Servicios

El sistema DEBE crear un `PrecioService` (provisto en `providedIn: 'root'`) dentro del módulo `gestion-precios` con los siguientes métodos:

| Método | Endpoint | Retorno |
|--------|----------|---------|
| `list()` | GET /api/precios | `Observable<PrecioProducto[]>` |
| `getById(id)` | GET /api/precios/{id} | `Observable<PrecioProducto>` |
| `getHistorial(id)` | GET /api/precios/{id}/historial | `Observable<HistoricoPrecioProducto[]>` |
| `actualizarPrecioVenta(id, dto)` | PUT /api/precios/{id}/venta | `Observable<PrecioProducto>` |

---

### Requirement: Tests de backend

**Domain**: Pricing / Testing

El sistema DEBE incluir 5 tests de backend como mínimo, distribuidos así:

#### Test unitario: PrecioService.listarPrecios

- GIVEN un mock de `ProductoRepository` que retorna 3 productos activos con precios conocidos
- WHEN se llama a `listarPrecios()`
- THEN el resultado DEBE tener 3 elementos
- AND `ganancia` y `margenPorcentaje` DEBEN estar correctamente calculados

#### Test unitario: PrecioService.actualizarPrecioVenta con precio directo

- GIVEN un mock de `ProductoRepository` y `HistoricoPrecioProductoRepository`
- WHEN se llama a `actualizarPrecioVenta(id, dto)` con `nuevoPrecio = 200`
- THEN `precioVenta` del producto DEBE ser `200`
- AND se DEBE guardar un histórico con `tipoCambio = "ACTUALIZACION_VENTA"`

#### Test unitario: PrecioService.actualizarPrecioVenta con margen

- GIVEN un producto con `precioCompra = 100`
- WHEN se llama a `actualizarPrecioVenta(id, dto)` con `margenPorcentaje = 50`
- THEN `precioVenta` DEBE ser `150`
- AND se DEBE guardar un histórico

#### Test unitario: PrecioService.actualizarPrecioVenta con ambos campos — error

- GIVEN cualquier producto
- WHEN se llama a `actualizarPrecioVenta(id, dto)` con `nuevoPrecio=100` y `margenPorcentaje=50`
- THEN DEBE lanzar `BadRequestException` o `IllegalArgumentException`

#### Test unitario: PrecioService.registrarHistorico

- GIVEN un producto y usuario mock
- WHEN se llama a `registrarHistorico(producto, precioCompra, precioVenta, tipoCambio, referencia, usuario)`
- THEN se DEBE guardar un registro en `HistoricoPrecioProductoRepository`

#### Test unitario: PrecioService.listarPrecios con precioCompra cero

- GIVEN un producto con `precioCompra = 0` y `precioVenta = 25`
- WHEN se llama a `listarPrecios()`
- THEN `ganancia` DEBE ser `null` y `margenPorcentaje` DEBE ser `null`

#### Test de integración: CompraService.create actualiza precioCompra y guarda histórico

- GIVEN un contexto Spring con base de datos en memoria (H2)
- WHEN se crea una compra con un detalle de producto (precioUnitario=15)
- THEN `producto.precioCompra` DEBE ser `15`
- AND `historico_precios_producto` DEBE tener 1 registro con `tipoCambio = "COMPRA"`

#### Test de integración: CompraService.update NO revierte precioCompra de viejos detalles

- GIVEN una compra con detalle de producto X (precioUnitario=10)
- WHEN se actualiza la compra cambiando el detalle a producto Y (precioUnitario=20)
- THEN `X.precioCompra` DEBE seguir siendo `10` (NO cambia)
- AND `Y.precioCompra` DEBE ser `20`
- AND el historial DEBE reflejar los cambios

---

### Non-Functional Requirements

#### Validación de errores

1. **400 Bad Request** — Cuando se envían ambos campos o ninguno en `PUT /api/precios/{id}/venta`. Mensaje: "Debe proporcionar nuevoPrecio o margenPorcentaje, no ambos ni ninguno."
2. **400 Bad Request** — Cuando se intenta calcular margen con precioCompra = 0. Mensaje: "No se puede calcular el margen porque el producto no tiene precio de compra registrado."
3. **404 Not Found** — Cuando el producto no existe o está inactivo en cualquiera de los endpoints de precios. Mensaje: "Producto no encontrado con id: {id}"
4. **400 Bad Request (frontend)** — Cuando se envía un margenPorcentaje que excede un límite razonable (ej: > 1000).

#### Reglas de negocio

5. `precioCompra` NUNCA se modifica por fuera de `CompraService.create()` o `CompraService.update()`.
6. Al actualizar una compra, los detalles viejos que se eliminan NO revierten `precioCompra` al valor anterior. El `precioCompra` representa el ÚLTIMO precio de compra registrado.
7. El `tipoCambio = "AJUSTE"` queda definido en la entidad para uso futuro, pero no se implementa en este cambio.

#### Edge cases

8. Si `precioCompra` es 0 y `precioVenta` es 0, tanto ganancia como margen deben ser `null`.
9. Si `precioCompra` es 0 en el diálogo de actualización, el campo de margen porcentual DEBE deshabilitarse con un mensaje informativo.
10. Si `precioCompra` es negativo (debería ser imposible por validación de DTO, pero por seguridad), tratarlo como 0 para el cálculo de margen.
11. El historial para un producto sin cambios retorna lista vacía (HTTP 200, no 404).
12. Al anular una compra, NO se revierte el `precioCompra` ni se agrega historial (ver proposal: out of scope).

---

## Summary

### Requirements Summary

| # | Requirement | Type | Scenarios |
|---|-------------|------|-----------|
| R1 | Entidad HistoricoPrecioProducto | New | 2 |
| R2 | PrecioCompra solo por compras | New | 4 |
| R3 | GET /api/precios — listado | New | 4 |
| R4 | GET /api/precios/{id} — individual | New | 3 |
| R5 | GET /api/precios/{id}/historial | New | 4 |
| R6 | PUT /api/precios/{id}/venta — actualizar | New | 5 |
| R7 | PreciosListComponent — listado UI | New | 4 |
| R8 | PrecioDetailComponent — detalle UI | New | 2 |
| R9 | ActualizarPrecioDialog — diálogo UI | New | 4 |
| R10 | Navegación y sidebar | New | 3 |
| R11 | Modelos frontend | New | — |
| R12 | Servicio Angular PrecioService | New | — |
| R13 | Tests de backend | New | 8 |

### Coverage

- **Happy paths**: ✅ Cubiertos (creación de compra, actualización de venta por precio y margen, listados, consultas)
- **Edge cases**: ✅ Cubiertos (precioCompra=0, exclusión mutua, producto inactivo, sin historial, sin usuario en histórico)
- **Error states**: ✅ Cubiertos (404, 400, validación de campos, división por cero, precios negativos)
- **Total scenarios**: 43 (backend API: 22, frontend UI: 13, tests: 8)

### Next Step

Ready for **design** (sdd-design).
