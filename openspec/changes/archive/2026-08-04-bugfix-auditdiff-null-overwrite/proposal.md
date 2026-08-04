# Proposal: Fix AuditDiff — Sobrescritura de valores reales con null en actualizaciones parciales

## Intent

Cuando el frontend envía una actualización parcial (ej. solo `{"stockActual": 10}`), Jackson deserializa la entidad completa con los campos no enviados como `null`. El método `update()` sobrescribe los valores reales de la BD con esos `null`, causando que el diff de auditoría muestre falsos cambios (ej. precioCompra pasa de `7.50` a `null`). Esto es un **bug de pérdida de datos** (data loss) que afecta la integridad de las entidades y la confiabilidad del log de auditoría.

Secundariamente, `BigDecimal.equals()` es scale-sensitive: `BigDecimal("7.50")` (scale=2) ≠ `BigDecimal("7.5")` (scale=1), generando falsos positivos en el diff aunque los valores sean matemáticamente iguales.

## Scope

### In Scope

1. **Fix Bug 1 — ProductoService.update()**: Solo sobrescribir campos que el request realmente envió (no null). Extender el patrón ya existente para `categoria`/`proveedor` (líneas 63-68) a todos los campos escalares.
2. **Fix Bug 2 — AuditDiff.diff()**: Hacer que la comparación de BigDecimal use `compareTo() == 0` en lugar de `Objects.equals()`.
3. **Fix Bug 1 en otros servicios**: Aplicar el mismo patrón de guard `!= null` a `ClienteService.update()`, `GastoService.update()`, y cualquier otro servicio que reciba la entidad completa del frontend.
4. **Tests unitarios para AuditDiff**: Crear `AuditDiffTest` que valide:
   - BigDecimal con diferentes scales se compara correctamente.
   - null vs valor real se detecta como cambio.
   - Sin cambios → diff vacío.
5. **Tests de integración**: Verificar que una actualización parcial de Producto no sobrescribe campos no enviados.

### Out of Scope

- **DTOs tipados para updates**: Opción B (usar DTOs con `Optional` fields) es más robusta pero requiere crear un DTO por entidad y cambiar el controller. Se deja como mejora futura.
- **CompraService.update()**: Usa un DTO (`CompraDTO`) en lugar de la entidad directa — su patrón es diferente (ya calcula montos, maneja detalles). Se revisa pero no se modifica en este change.
- **UsuarioService/RolService**: Ya usan DTOs (`UsuarioRequestDTO`, `RolRequestDTO`) — no tienen el bug.
- **Frontend**: No se modifica el frontend. El fix es puramente backend.

## Approach

### Bug 1: Null-guard en services (Option A extendida)

El proyecto ya tiene el patrón para `categoria` y `proveedor` en `ProductoService` (líneas 63-68):

```java
if (productoActualizado.getCategoria() != null) {
    producto.setCategoria(productoActualizado.getCategoria());
}
```

**Decisión**: Extender este mismo patrón a TODOS los campos escalares de `update()`. Es la opción más simple, consistente con el código existente, y no requiere cambios de arquitectura.

**Services a modificar:**
- `ProductoService.update()` — 10 campos escalares (líneas 50-59)
- `ClienteService.update()` — 6 campos escalares (líneas 46-52)
- `GastoService.update()` — 7 campos escalares (líneas 46-53)

**Excepción**: `categoria` y `proveedor` en `ProductoService` ya tienen el guard. `ProveedorService.update()` y `CategoriaService.update()` no tienen campos BigDecimal y sus updates son de bajo riesgo (strings + boolean), pero se les aplica el mismo patrón por consistencia.

**NOTA sobre `activo` (boolean)**: Los campos `boolean`/`boolean isActivo` no pueden ser null (primitivo). No necesitan guard. Se mantienen como `setActivo(productoActualizado.isActivo())`.

### Bug 2: Comparación de BigDecimal en AuditDiff

**Decisión**: Special-case BigDecimal en `AuditDiff.diff()` usando `compareTo() == 0`.

```java
private static boolean sonIguales(Object a, Object b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a instanceof BigDecimal && b instanceof BigDecimal) {
        return ((BigDecimal) a).compareTo((BigDecimal) b) == 0;
    }
    return Objects.equals(a, b);
}
```

**Por qué no Option B (normalizar scale)**: Requiere mutar los valores o crear copias, lo cual es innecesario cuando `compareTo()` ya resuelve el problema de forma limpia.

**Por qué no Option C (custom equals helper externo)**: `compareTo` es el método canónico de `BigDecimal` para comparación de valor. No hay razón para abstraer más.

### Decisiones con trade-offs

| # | Decisión | Opción elegida | Alternativas descartadas |
|---|----------|---------------|-------------------------|
| 1 | Null-guard por campo | Option A: `if (x != null) set(x)` por cada campo | Option B (DTOs Optional): más robusto pero requiere crear DTOs por entidad y cambiar controllers. Deferred. Option C (compare before set): mismo costo que A pero más complejo de leer |
| 2 | BigDecimal comparison | `compareTo() == 0` en AuditDiff | Normalizar scale antes de comparar (innecesario, compareTo ya lo resuelve) |
| 3 | Alcance de fix null-guard | ProductoService + ClienteService + GastoService + ProveedorService + CategoriaService | Solo ProductoService (dejaría el mismo bug en otros services) |

## Affected Areas

| Área | Impacto | Descripción |
|------|---------|-------------|
| `backend/.../util/AuditDiff.java` | Modificado | Nuevo método `sonIguales()` con special-case para BigDecimal; `diff()` lo usa en lugar de `Objects.equals()` |
| `backend/.../service/ProductoService.java` | Modificado | `update()`: null-guard en 10 campos escalares (nombre, descripcion, codigoBarras, ubicacion, stockMinimo, stockMaximo, precioCompra, precioVenta, unidadMedida, imagen) |
| `backend/.../service/ClienteService.java` | Modificado | `update()`: null-guard en 6 campos (nombre, ruc, telefono, email, direccion, saldoPendiente) |
| `backend/.../service/GastoService.java` | Modificado | `update()`: null-guard en 7 campos (descripcion, monto, categoria, metodoPago, numeroComprobante, fechaGasto, observaciones) |
| `backend/.../service/ProveedorService.java` | Modificado | `update()`: null-guard en 6 campos (nombre, ruc, contacto, telefono, email, direccion) |
| `backend/.../service/CategoriaService.java` | Modificado | `update()`: null-guard en 2 campos (nombre, descripcion) |
| `backend/src/test/.../AuditDiffTest.java` | Nuevo | Tests unitarios de AuditDiff: BigDecimal scale, null vs real, sin cambios |
| `backend/src/test/...` | Modificado | Test de integración de actualización parcial de Producto |

## Risks

| Riesgo | Probabilidad | Mitigación |
|--------|--------------|------------|
| Un campo que SÍ debe ser null (ej. limpiar descripcion) no se sobrescribe | Media | Los guards `!= null` previenen sobrescritura con null del request. Si el usuario quiere limpiar un campo, debe enviarlo explícitamente como `""` (string vacío) o el endpoint debe soportar un mecanismo de "clear" (PATCH con campo explícito null). **Decisión**: mantener `!= null` — el frontend ya envía strings vacíos para campos opcionales. Si se necesita limpiar, se agrega un endpoint dedicado o se usa `@JsonSetter` con sentinel. |
| `activo` (boolean primitivo) no puede ser null — ¿necesita guard? | Baja | No. `isActivo()` retorna primitivo `boolean`, no `Boolean`. Jackson siempre lo deserializa a `true`/`false`. Se mantiene sin guard. |
| BigDecimal compareTo puede tener efectos colaterales en el diff JSON | Baja | `compareTo` solo afecta la decisión de incluir/excluir del diff. El valor serializado en `antes`/`despues` sigue siendo el BigDecimal original (con su scale). No hay cambio en la serialización. |
| Services no auditados (MovimientoStockService, VentaService) no usan diff parcial | Baja | MovimientoStockService solo crea (no update). VentaService no recibe entidad completa del frontend (usa DTOs o es write-only). No aplican. |
| Tests existentes (AuditoriaInstrumentacionTest, LogServiceTest) pueden fallar | Baja | El fix NO cambia la API ni la estructura del diff — solo corrige falsos positivos. Los tests de integración existentes no dependen de valores BigDecimal específicos en el diff. |

## Rollback Plan

Cambio de código puro, sin migración de esquema ni datos:

- **Código**: revertir el PR (`git revert`). Los archivos modificados (`AuditDiff.java`, `ProductoService.java`, `ClienteService.java`, `GastoService.java`, `ProveedorService.java`, `CategoriaService.java`) vuelven al estado previo. El archivo nuevo (`AuditDiffTest.java`) se elimina.
- **Datos**: no hay cambios de datos. Las filas de auditoría existentes no se ven afectadas. Los nulls ya escritos en auditoría por este bug quedan como registro histórico del bug (no se corruptan más).
- **Regla de oro**: no mergear sin pasar `mvn test` completo (Docker) y verificar manualmente que una actualización parcial de Producto NO sobrescribe campos no enviados.

## Dependencies

- **Sin dependencias externas**. El fix es autónomo dentro del backend.
- **Prerrequisito**: el bug fue explorado y confirmado en el change `modulo-logs` (contexto de auditoría).

## Success Criteria

- [ ] `AuditDiffTest` pasa: BigDecimal con diferentes scales se compara como igual; null vs valor real se detecta como cambio; sin cambios → diff vacío.
- [ ] Actualización parcial de Producto (ej. `{"stockActual": 10}`) NO sobrescribe precioCompra, precioVenta, nombre, ni ningún otro campo no enviado.
- [ ] El diff de auditoría para una actualización parcial SOLO muestra los campos que realmente cambiaron (no falsos positivos por null).
- [ ] `mvn test` (Docker) pasa en verde — tests existentes no se rompen.
- [ ] Los 5 services modificados aplican el mismo patrón de null-guard de forma consistente.
