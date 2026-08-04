# Test Report — bugfix-auditdiff-null-overwrite

**Date**: 2026-08-04
**Status**: ✅ PASS

---

## Summary

| Metric | Value |
|--------|-------|
| Total backend tests | 92 |
| New tests (AuditDiffTest) | 5 |
| Failures | 0 |
| Regressions | 0 |

---

## What Was Tested

### AuditDiffTest (5 tests — new)

| Test | Description | Result |
|------|-------------|--------|
| `diff_bigDecimalMismoValorDifferentScale_estaVacio` | `BigDecimal("7.50")` vs `BigDecimal("7.5")` → diff vacío | ✅ |
| `diff_bigDecimalDiferenteValor_detectaCambio` | `BigDecimal("7.50")` vs `BigDecimal("8.00")` → diff presenta | ✅ |
| `diff_nullVsValor_detectaCambio` | `null` vs `BigDecimal("7.50")` → diff presenta | ✅ |
| `diff_sinCambios_estaVacio` | Snapshots idénticos → diff vacío | ✅ |
| `diff_tiposNoBigDecimal_usanObjectsEquals` | String/Integer con `Objects.equals()` — regresión | ✅ |

### Null-guards (5 services — code-level verification)

| Service | Fields guarded | Result |
|---------|---------------|--------|
| ProductoService | 10 (nombre, descripcion, codigoBarras, ubicacion, stockMinimo, stockMaximo, precioCompra, precioVenta, unidadMedida, imagen) | ✅ |
| ClienteService | 6 (nombre, ruc, telefono, email, direccion, saldoPendiente) | ✅ |
| GastoService | 7 (descripcion, monto, categoria, metodoPago, numeroComprobante, fechaGasto, observaciones) | ✅ |
| ProveedorService | 6 (nombre, ruc, contacto, telefono, email, direccion) | ✅ |
| CategoriaService | 2 (nombre, descripcion) | ✅ |

### Existing Tests (87 tests — no regressions)

All existing tests (AuditoriaTest, AuditoriaInstrumentacionTest, LogServiceTest, etc.) pass without modification.

---

## How to Reproduce

```bash
# From project root
docker compose exec backend mvn test -pl backend

# Or run only AuditDiffTest
docker compose exec backend mvn test -pl backend -Dtest=AuditDiffTest
```

---

## Verdict

✅ **ALL 92 TESTS PASSING** — No regressions, no failures.
