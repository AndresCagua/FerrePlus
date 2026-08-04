# Tasks — bugfix-auditdiff-null-overwrite

## STACK 1: Core fix — AuditDiff

### T1: AuditDiff — agregar helper `sonIguales()` y actualizar `diff()`

- **Archivo**: `backend/src/main/java/com/ferreplus/util/AuditDiff.java`
- **Acción**:
  1. Agregar import de `java.math.BigDecimal`
  2. Crear método `private static boolean sonIguales(Object a, Object b)` con la lógica:
     - `a == null && b == null` → `true`
     - `a == null || b == null` → `false`
     - ambos `instanceof BigDecimal` → `((BigDecimal) a).compareTo((BigDecimal) b) == 0`
     - fallback → `Objects.equals(a, b)`
  3. En `diff()` línea 49, reemplazar `!Objects.equals(valorAntes, valorDespues)` por `!sonIguales(valorAntes, valorDespues)`
- **Resultado esperado**: `AuditDiff.diff()` ahora compara BigDecimal con `compareTo()`, eliminando falsos positivos por scale
- **Verificación**: Compila sin errores. Tests existentes no se rompen (el cambio solo afecta la semántica de comparación, no la API)

---

## STACK 2: Null-guards en services

### T2: ProductoService — null-guards en 10 campos escalares

- **Archivo**: `backend/src/main/java/com/ferreplus/service/ProductoService.java`
- **Acción**: En `update()` (líneas 50-59), envolver cada setter en un null-guard `if (productoActualizado.getCampo() != null)`:
  - `nombre` (línea 50)
  - `descripcion` (línea 51)
  - `codigoBarras` (línea 52)
  - `ubicacion` (línea 53)
  - `stockMinimo` (línea 54)
  - `stockMaximo` (línea 55)
  - `precioCompra` (línea 56)
  - `precioVenta` (línea 57)
  - `unidadMedida` (línea 58)
  - `imagen` (línea 59)
  - **NO modificar**: `categoria`/`proveedor` (ya tienen guard, líneas 63-68), `activo` (boolean primitivo, línea 69)
- **Resultado esperado**: Un PUT parcial con `{"stockActual": 100}` no sobrescribe `nombre`, `precioCompra`, etc.
- **Verificación**: Revisar que el patrón sea idéntico al de `categoria`/`proveedor` existente. Compilar sin errores

### T3: ClienteService — null-guards en 6 campos

- **Archivo**: `backend/src/main/java/com/ferreplus/service/ClienteService.java`
- **Acción**: En `update()` (líneas 46-51), envolver cada setter en un null-guard:
  - `nombre` (línea 46)
  - `ruc` (línea 47)
  - `telefono` (línea 48)
  - `email` (línea 49)
  - `direccion` (línea 50)
  - `saldoPendiente` (línea 51)
  - **NO modificar**: `activo` (boolean primitivo, línea 52)
- **Resultado esperado**: Un update parcial solo modifica los campos enviados
- **Verificación**: Compilar sin errores

### T4: GastoService — null-guards en 7 campos

- **Archivo**: `backend/src/main/java/com/ferreplus/service/GastoService.java`
- **Acción**: En `update()` (líneas 46-52), envolver cada setter en un null-guard:
  - `descripcion` (línea 46)
  - `monto` (línea 47)
  - `categoria` (línea 48)
  - `metodoPago` (línea 49)
  - `numeroComprobante` (línea 50)
  - `fechaGasto` (línea 51)
  - `observaciones` (línea 52)
  - **NO modificar**: `usuario` (línea 53 — el frontend siempre lo envía)
- **Resultado esperado**: Un update parcial de gasto preserva campos no enviados
- **Verificación**: Compilar sin errores

### T5: ProveedorService — null-guards en 6 campos

- **Archivo**: `backend/src/main/java/com/ferreplus/service/ProveedorService.java`
- **Acción**: En `update()` (líneas 46-51), envolver cada setter en un null-guard:
  - `nombre` (línea 46)
  - `ruc` (línea 47)
  - `contacto` (línea 48)
  - `telefono` (línea 49)
  - `email` (línea 50)
  - `direccion` (línea 51)
  - **NO modificar**: `activo` (boolean primitivo, línea 52)
- **Resultado esperado**: Un update parcial de proveedor preserva campos no enviados
- **Verificación**: Compilar sin errores

### T6: CategoriaService — null-guards en 2 campos

- **Archivo**: `backend/src/main/java/com/ferreplus/service/CategoriaService.java`
- **Acción**: En `update()` (líneas 46-47), envolver cada setter en un null-guard:
  - `nombre` (línea 46)
  - `descripcion` (línea 47)
- **Resultado esperado**: Un update parcial de categoría preserva campos no enviados
- **Verificación**: Compilar sin errores

---

## STACK 3: Tests

### T7: Crear `AuditDiffTest.java` — tests unitarios

- **Archivo**: `backend/src/test/java/com/ferreplus/util/AuditDiffTest.java` (nuevo)
- **Acción**: Crear clase de test JUnit 5 **pura** (sin contexto Spring — `AuditDiff` es un util estático). Importar `org.junit.jupiter.api.Test` y `static org.junit.jupiter.api.Assertions.*`. Implementar 5 tests:
  1. `diff_bigDecimalMismoValorDifferentScale_estaVacio` — `BigDecimal("7.50")` vs `BigDecimal("7.5")` → diff vacío `{}`
  2. `diff_bigDecimalDiferenteValor_detectaCambio` — `BigDecimal("7.50")` vs `BigDecimal("8.00")` → diff contiene `"precio"` con antes/después
  3. `diff_nullVsValor_detectaCambio` — `null` vs `BigDecimal("7.50")` → diff contiene `"precio"` con `antes: null, después: 7.50`
  4. `diff_sinCambios_estaVacio` — snapshots idénticos con String, Integer, BigDecimal y null → diff `{}`
  5. `diff_tiposNoBigDecimal_usanObjectsEquals` — String distinto → diff presente; Integer distinto → diff presente; valores iguales → diff vacío
- **Estructura del test**:
  ```java
  package com.ferreplus.util;
  // imports...
  class AuditDiffTest {
      // helper privado para crear snapshots Map<String, Object>
      @Test void diff_bigDecimalMismoValorDifferentScale_estaVacio() { ... }
      @Test void diff_bigDecimalDiferenteValor_detectaCambio() { ... }
      @Test void diff_nullVsValor_detectaCambio() { ... }
      @Test void diff_sinCambios_estaVacio() { ... }
      @Test void diff_tiposNoBigDecimal_usanObjectsEquals() { ... }
  }
  ```
- **Resultado esperado**: Todos los tests pasan. La suite existente no se rompe
- **Verificación**: Ejecutar `mvn test -pl backend -Dtest=AuditDiffTest` — todos verdes

---

## STACK 4: Verificación

### T8: Ejecutar suite completa y verificar

- **Archivo**: Ninguno (ejecución de comandos)
- **Acción**:
  1. Ejecutar `mvn test -pl backend` (o vía Docker si aplica)
  2. Verificar que `AuditDiffTest` pasa (5/5 tests)
  3. Verificar que tests existentes (`AuditoriaTest`, `AuditoriaInstrumentacionTest`, `LogServiceTest`, etc.) siguen pasando
  4. Si algún test falla, diagnosticar y corregir — el fix NO debe cambiar la API ni la estructura del diff
- **Resultado esperado**: Suite completa en verde, sin regresiones
- **Verificación**: `mvn test` exitoso con 0 fallos

---

## Resumen de dependencias

```
T1 (AuditDiff sonIguales)
  └─ T7 (AuditDiffTest) puede ejecutarse en paralelo con T2-T6

T2 (ProductoService)
T3 (ClienteService)
T4 (GastoService)
T5 (ProveedorService)
T6 (CategoriaService)
  └─ Todos independientes entre sí, pueden ejecutarse en paralelo

T8 (Suite completa) — depende de T1-T7 completados
```

## Orden recomendado de implementación

1. **T1 primero** — es la base que corrige la comparación de BigDecimal
2. **T2-T6 en paralelo** — son independientes, uno por service
3. **T7 después de T1** — los tests validan el fix de AuditDiff
4. **T8 al final** — verificación de regresión completa
