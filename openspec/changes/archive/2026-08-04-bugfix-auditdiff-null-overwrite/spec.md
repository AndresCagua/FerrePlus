# Delta Spec — bugfix-auditdiff-null-overwrite

## Propósito

Corregir dos bugs que causan falsos positivos en el diff de auditoría y pérdida de datos en actualizaciones parciales:

1. **Sobrescritura con null**: Cuando el frontend envía un update parcial (ej. solo `{"stockActual": 10}`), Jackson deserializa la entidad completa con campos no enviados como `null`. Los métodos `update()` sobrescriben los valores reales de la BD con esos `null`. Esto provoca data loss Y genera entradas falsas en el diff de auditoría (ej. `precioCompra: 7.50 -> null`).

2. **BigDecimal scale-sensitive**: `Objects.equals()` en `AuditDiff.diff()` delega a `BigDecimal.equals()` que compara valor Y scale. La BD retorna scale=2, JSON deserialization retorna scale=1, así que `equals()` retorna false aunque los valores sean matemáticamente iguales (ej. `precioCompra: 7.50 -> 7.5` aparece como cambiado).

Este es un **bugfix**, no un módulo nuevo. La spec es mínima y enfocada.

## Alcance

### MODIFICADO (modificado)

- `AuditDiff.java`: método `diff()` reemplaza `Objects.equals()` por un helper `sonIguales()` que special-case `BigDecimal` usando `compareTo() == 0`.
- `ProductoService.java`: `update()` agrega null-guards en 10 campos escalares (nombre, descripcion, codigoBarras, ubicacion, stockMinimo, stockMaximo, precioCompra, precioVenta, unidadMedida, imagen). `categoria` y `proveedor` ya tienen el guard (líneas 63-68). `isActivo()` (boolean primitivo) no necesita guard.
- `ClienteService.java`: `update()` agrega null-guards en 6 campos (nombre, ruc, telefono, email, direccion, saldoPendiente). `isActivo()` no necesita guard.
- `GastoService.java`: `update()` agrega null-guards en 7 campos (descripcion, monto, categoria, metodoPago, numeroComprobante, fechaGasto, observaciones). `usuario` (relación) no necesita guard porque el frontend siempre lo envía.
- `ProveedorService.java`: `update()` agrega null-guards en 6 campos (nombre, ruc, contacto, telefono, email, direccion). `isActivo()` no necesita guard.
- `CategoriaService.java`: `update()` agrega null-guards en 2 campos (nombre, descripcion).

### AGREGADO (agregado)

- `AuditDiffTest.java`: tests unitarios de AuditDiff que validan BigDecimal scale, null vs real, sin cambios.

### FUERA DE ALCANCE

- **DTOs tipados para updates** (Option B): más robusto pero requiere crear DTOs por entidad y cambiar controllers. Deferred.
- **CompraService.update()**: usa un DTO (`CompraDTO`), no recibe la entidad directamente — no tiene el bug.
- **UsuarioService/RolService**: ya usan DTOs — no tienen el bug.
- **Frontend**: no se modifica. El fix es puramente backend.

---

## Requisitos

### R1: Null-guards en servicios — sobrescribir solo campos enviados

**Domain**: Backend / Data Integrity

Cada método `update()` de los servicios afectados DEBE sobrescribir un campo solo si el valor recibido no es `null`. Para cada campo escalar (String, BigDecimal, Integer, LocalDate), el patrón DEBE ser:

```java
if (actualizado.getCampo() != null) {
    existente.setCampo(actualizado.getCampo());
}
```

**Excepción**: campos `boolean` primitivos (`isActivo()`) no pueden ser null (primitivo) y NO necesitan guard — se mantienen como `setActivo(actualizado.isActivo())`.

**Excepción**: `ProductoService` ya tiene guards para `categoria` y `proveedor` (líneas 63-68) — se mantienen sin cambio.

#### Scenario: Actualización parcial de Producto no sobrescribe campos no enviados

- GIVEN un producto existente con `nombre="Tornillo"`, `precioCompra=7.50`, `precioVenta=10.00`, `stockActual=50`
- WHEN se envía `PUT /api/productos/{id}` con solo `{"stockActual": 100}` (nombre, precioCompra, precioVenta no vienen en el request → Jackson los deserializa como null)
- THEN después de la actualización, `nombre` DEBE seguir siendo `"Tornillo"`, `precioCompra` DEBE seguir siendo `7.50`, `precioVenta` DEBE seguir siendo `10.00`
- AND `stockActual` DEBE ser `100`
- AND el diff de auditoría NO DEBE contener entradas para nombre, precioCompra ni precioVenta

#### Scenario: Actualización parcial de Cliente no sobrescribe campos no enviados

- GIVEN un cliente existente con `nombre="Juan"`, `email="juan@mail.com"`, `saldoPendiente=500.00`
- WHEN se envía un update con solo `{"telefono": "555-1234"}`
- THEN después de la actualización, `nombre`, `email` y `saldoPendiente` DEBEN conservar sus valores originales
- AND el diff de auditoría solo DEBE contener `telefono` (si es que cambió)

#### Scenario: Actualización parcial de Gasto no sobrescribe campos no enviados

- GIVEN un gasto existente con `descripcion="Transporte"`, `monto=150.00`, `metodoPago="EFECTIVO"`
- WHEN se envía un update con solo `{"observaciones": "Revisado"}`
- THEN `descripcion`, `monto` y `metodoPago` DEBEN conservar sus valores originales
- AND el diff de auditoría solo DEBE contener `observaciones` (si es que cambió)

#### Scenario: Actualización que envía todos los campos sobrescribe normalmente

- GIVEN un producto existente con `nombre="Tornillo"` y `precioCompra=7.50`
- WHEN se envía un update con `{"nombre": "Tornillo 500g", "precioCompra": 8.00, ...}` (todos los campos presentes)
- THEN `nombre` DEBE cambiar a `"Tornillo 500g"` y `precioCompra` DEBE cambiar a `8.00`
- AND el diff DEBE registrar ambos cambios

#### Scenario: Campo String vacío sobrescribe (no es null)

- GIVEN un producto existente con `descripcion="Descripción larga"`
- WHEN se envía un update con `{"descripcion": ""}`
- THEN `descripcion` DEBE cambiar a `""` (string vacío no es null, se sobrescribe)

---

### R2: BigDecimal scale-insensitive en AuditDiff

**Domain**: Backend / Auditoría

El método `AuditDiff.diff()` DEBE comparar `BigDecimal` usando `compareTo() == 0` en lugar de `Objects.equals()`. Esto significa que `BigDecimal("7.50")` (scale=2) y `BigDecimal("7.5")` (scale=1) se consideran iguales y NO generan entrada en el diff.

El helper `sonIguales(Object a, Object b)` DEBE:
1. Retornar `true` si ambos son `null`
2. Retornar `false` si solo uno es `null`
3. Special-case: si ambos son `BigDecimal`, usar `((BigDecimal) a).compareTo((BigDecimal) b) == 0`
4. Para todo lo demás, usar `Objects.equals(a, b)`

#### Scenario: BigDecimal con diferentes scales se compara como igual

- GIVEN un snapshot `antes` con `precioCompra = BigDecimal("7.50")` (scale=2)
- AND un snapshot `despues` con `precioCompra = BigDecimal("7.5")` (scale=1)
- WHEN se calcula `AuditDiff.diff(antes, despues)`
- THEN el diff DEBE ser un mapa vacío `{}` (no hay cambios detectados)

#### Scenario: BigDecimal con valores diferentes se detecta como cambio

- GIVEN un snapshot `antes` con `precioCompra = BigDecimal("7.50")`
- AND un snapshot `despues` con `precioCompra = BigDecimal("8.00")`
- WHEN se calcula `AuditDiff.diff(antes, despues)`
- THEN el diff DEBE contener la entrada `precioCompra: {antes: 7.50, despues: 8.00}`

#### Scenario: null vs valor real se detecta como cambio

- GIVEN un snapshot `antes` con `precioCompra = null`
- AND un snapshot `despues` con `precioCompra = BigDecimal("7.50")`
- WHEN se calcula `AuditDiff.diff(antes, despues)`
- THEN el diff DEBE contener la entrada `precioCompra: {antes: null, despues: 7.50}`

#### Scenario: Sin cambios produce diff vacío

- GIVEN dos snapshots idénticos con los mismos valores escalares
- WHEN se calcula `AuditDiff.diff(antes, despues)`
- THEN el diff DEBE ser `{}` (mapa vacío)

---

### R3: Tests unitarios de AuditDiff

**Domain**: Testing / Backend

El sistema DEBE incluir `AuditDiffTest.java` que valide al menos:

1. BigDecimal con diferentes scales se compara como igual (R2 Scenario 1)
2. BigDecimal con valores diferentes se detecta como cambio (R2 Scenario 2)
3. null vs valor real se detecta como cambio (R2 Scenario 3)
4. Sin cambios → diff vacío (R2 Scenario 4)
5. Campos String, Integer y otros tipos se comparan correctamente con `Objects.equals()` (regresión)

#### Scenario: AuditDiffTest cubre los casos de BigDecimal y null

- GIVEN la clase `AuditDiffTest` en `backend/src/test/`
- WHEN se ejecuta `mvn test` (o equivalente Docker)
- THEN todos los tests de `AuditDiffTest` DEBEN pasar
- AND los tests existentes NO DEBEN romperse (el fix no cambia la API, solo corrige falsos positivos)

---

## Requisitos no funcionales

#### Consistencia

1. Los 5 services modificados DEBEN aplicar el mismo patrón de null-guard de forma consistente.
2. El fix NO cambia la API, la estructura del diff ni la serialización JSON — solo corrige falsos positivos y previene data loss.

#### Regresión

3. `mvn test` (Docker) DEBE pasar en verde — los tests existentes no deben romperse.
4. El fix de BigDecimal NO afecta la serialización del diff: el valor en `antes`/`despues` sigue siendo el BigDecimal original (con su scale).

#### Seguridad

5. `activo` (boolean primitivo) no necesita guard — `isActivo()` retorna `boolean`, no `Boolean`. Jackson siempre lo deserializa a `true`/`false`.

---

## Fuera de alcance

- **DTOs tipados para updates**: Option B (DTOs con `Optional` fields) es más robusta pero deferred — requiere crear un DTO por entidad y cambiar controllers.
- **CompraService.update()**: usa DTO, no recibe la entidad directamente — no tiene el bug.
- **UsuarioService/RolService**: ya usan DTOs — no tienen el bug.
- **Frontend**: no se modifica. Fix puramente backend.
- **Borrar campos explícitamente**: si un usuario quiere limpiar un campo (hacerlo null), debe enviar `""` (string vacío) o el endpoint debe soportar un mecanismo de "clear" dedicado. Este fix usa `!= null` que es consistente con el comportamiento actual del frontend.
