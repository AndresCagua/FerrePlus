# Technical Design — bugfix-auditdiff-null-overwrite

## Decisiones de Diseño

### D1: Helper `sonIguales()` vive dentro de `AuditDiff`

- **Elección**: Agregar un método `private static boolean sonIguales(Object a, Object b)` en `AuditDiff.java` y usarlo desde `diff()` en lugar de `Objects.equals()`.
- **Racional**: La comparación es un detalle interno del cálculo de diff. Mantenerla privada en `AuditDiff` mantiene la cohesión y no expande la API pública del helper. No justifica crear una clase de utilidad separada.
- **Implementación**:
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

### D2: Patrón de null-guard `if (actualizado.getCampo() != null)` en todos los services

- **Elección**: Extender el patrón ya existente en `ProductoService` (líneas 63-68 para `categoria`/`proveedor`) a todos los campos escalares de los 5 services.
- **Racional**: Es consistente con el código actual, mínimo en cambios y no requiere tocar controllers ni crear DTOs. La alternativa (DTOs con `Optional`) es más robusta pero queda fuera de alcance según la propuesta.
- **Consecuencia**: Un campo solo se sobrescribe si el request lo envió explícitamente. Si el usuario quiere "limpiar" un campo opcional, debe enviar `""` (string vacío), no `null`.

### D3: No modificar campos `boolean` primitivos

- **Elección**: `activo` se mantiene como `setActivo(actualizado.isActivo())` sin guard.
- **Racional**: `isActivo()` retorna `boolean` primitivo; Jackson siempre lo deserializa a `true` o `false`, nunca `null`. Agregar un guard sería imposible y confuso.

### D4: Comparación de BigDecimal con `compareTo()`

- **Elección**: Special-case `BigDecimal` usando `compareTo() == 0`.
- **Racional**: `BigDecimal.equals()` incluye la escala en la comparación, lo que genera falsos positivos cuando la BD devuelve `7.50` (scale 2) y el JSON deserializado es `7.5` (scale 1). `compareTo()` compara el valor matemático sin mutar los objetos.

## Archivos Afectados

| Archivo | Cambio |
|---------|--------|
| `backend/src/main/java/com/ferreplus/util/AuditDiff.java` | Agregar `sonIguales()` y usarlo en `diff()`. |
| `backend/src/main/java/com/ferreplus/service/ProductoService.java` | Null-guard en 10 campos escalares; `activo` sin guard. |
| `backend/src/main/java/com/ferreplus/service/ClienteService.java` | Null-guard en 6 campos escalares; `activo` sin guard. |
| `backend/src/main/java/com/ferreplus/service/GastoService.java` | Null-guard en 7 campos escalares; `usuario` sin cambios. |
| `backend/src/main/java/com/ferreplus/service/ProveedorService.java` | Null-guard en 6 campos escalares; `activo` sin guard. |
| `backend/src/main/java/com/ferreplus/service/CategoriaService.java` | Null-guard en 2 campos escalares. |
| `backend/src/test/java/com/ferreplus/util/AuditDiffTest.java` | Nuevo: tests unitarios de `AuditDiff`. |

## Patrón de Null-Guards

### ProductoService

Campos con guard (`String`, `BigDecimal`, `Integer`):
- `nombre`, `descripcion`, `codigoBarras`, `ubicacion`
- `stockMinimo`, `stockMaximo`
- `precioCompra`, `precioVenta`
- `unidadMedida`, `imagen`

Campos sin guard:
- `categoria`, `proveedor` — ya tienen guard (líneas 63-68).
- `activo` — `boolean` primitivo; se mantiene `setActivo(productoActualizado.isActivo())`.

### ClienteService

Campos con guard:
- `nombre`, `ruc`, `telefono`, `email`, `direccion`, `saldoPendiente`

Campos sin guard:
- `activo` — `boolean` primitivo.

### GastoService

Campos con guard:
- `descripcion`, `monto`, `categoria`, `metodoPago`, `numeroComprobante`, `fechaGasto`, `observaciones`

Campos sin guard:
- `usuario` — el frontend siempre lo envía; no requiere guard en este change.

### ProveedorService

Campos con guard:
- `nombre`, `ruc`, `contacto`, `telefono`, `email`, `direccion`

Campos sin guard:
- `activo` — `boolean` primitivo.

### CategoriaService

Campos con guard:
- `nombre`, `descripcion`

Nota: para limpiar `descripcion`, el frontend debe enviar `""` en lugar de omitir el campo (que Jackson interpretaría como `null`).

## Estrategia de Tests

### Unitarios — `AuditDiffTest.java`

Ubicación: `backend/src/test/java/com/ferreplus/util/AuditDiffTest.java`

Framework: JUnit 5 (mismo stack que `AuditoriaTest` y `LogServiceTest`). No requiere contexto de Spring; es un test puro de utilidad.

Casos a cubrir:

1. **BigDecimal con mismo valor, diferente scale → diff vacío**
   - `antes = {"precio": BigDecimal("7.50")}`
   - `despues = {"precio": BigDecimal("7.5")}`
   - Assert: `diff` es `{}`.

2. **BigDecimal con diferente valor → diff presente**
   - `antes = {"precio": BigDecimal("7.50")}`
   - `despues = {"precio": BigDecimal("8.00")}`
   - Assert: `diff` contiene `"precio"` con `{"antes": 7.50, "despues": 8.00}`.

3. **null vs valor real → diff presente**
   - `antes = {"precio": null}`
   - `despues = {"precio": BigDecimal("7.50")}`
   - Assert: `diff` contiene `"precio"` con `{"antes": null, "despues": 7.50}`.

4. **Sin cambios → diff vacío**
   - Snapshots idénticos con `String`, `Integer`, `BigDecimal` y `null`.
   - Assert: `diff` es `{}`.

5. **Regresión: tipos no BigDecimal usan `Objects.equals()`**
   - String distinto → diff presente.
   - Integer distinto → diff presente.
   - Valores iguales → diff vacío.

### Integración (opcional, fuera del core de este design)

- Verificar que `PUT /api/productos/{id}` con `{"stockActual": 100}` no sobrescriba `nombre` ni `precioCompra`.
- Esta cobertura ya existe como criterio de aceptación en la propuesta; se puede implementar si el equipo lo prioriza, pero el foco del change es el fix en el backend y los unitarios de `AuditDiff`.
