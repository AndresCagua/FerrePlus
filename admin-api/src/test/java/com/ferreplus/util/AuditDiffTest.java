package com.ferreplus.util;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests unitarios de {@link AuditDiff} — valida comparación de BigDecimal
 * con diferentes scales, null vs valor, y tipos no-BigDecimal.
 */
class AuditDiffTest {

    private static Map<String, Object> snapshot(Object... keyValues) {
        Map<String, Object> map = new LinkedHashMap<>();
        for (int i = 0; i < keyValues.length; i += 2) {
            map.put((String) keyValues[i], keyValues[i + 1]);
        }
        return map;
    }

    @Test
    void diff_bigDecimalMismoValorDifferentScale_estaVacio() {
        Map<String, Object> antes = snapshot("precio", new BigDecimal("7.50"));
        Map<String, Object> despues = snapshot("precio", new BigDecimal("7.5"));

        Map<String, Object> diff = AuditDiff.diff(antes, despues);

        assertTrue(diff.isEmpty(),
                "BigDecimal(7.50) y BigDecimal(7.5) son el mismo valor matemático, diff debe ser vacío");
    }

    @Test
    void diff_bigDecimalDiferenteValor_detectaCambio() {
        Map<String, Object> antes = snapshot("precio", new BigDecimal("7.50"));
        Map<String, Object> despues = snapshot("precio", new BigDecimal("8.00"));

        Map<String, Object> diff = AuditDiff.diff(antes, despues);

        assertNotNull(diff.get("precio"), "Diff debe contener 'precio' para valores distintos");
        @SuppressWarnings("unchecked")
        Map<String, Object> cambio = (Map<String, Object>) diff.get("precio");
        assertEquals(new BigDecimal("7.50"), cambio.get("antes"));
        assertEquals(new BigDecimal("8.00"), cambio.get("despues"));
    }

    @Test
    void diff_nullVsValor_detectaCambio() {
        Map<String, Object> antes = snapshot("precio", null);
        Map<String, Object> despues = snapshot("precio", new BigDecimal("7.50"));

        Map<String, Object> diff = AuditDiff.diff(antes, despues);

        assertNotNull(diff.get("precio"), "Diff debe contener 'precio' cuando antes es null y después tiene valor");
        @SuppressWarnings("unchecked")
        Map<String, Object> cambio = (Map<String, Object>) diff.get("precio");
        assertNull(cambio.get("antes"), "antes debe ser null");
        assertEquals(new BigDecimal("7.50"), cambio.get("despues"));
    }

    @Test
    void diff_sinCambios_estaVacio() {
        Map<String, Object> antes = snapshot(
                "nombre", "Tornillo",
                "cantidad", 10,
                "precio", new BigDecimal("7.50"),
                "descripcion", null
        );
        Map<String, Object> despues = snapshot(
                "nombre", "Tornillo",
                "cantidad", 10,
                "precio", new BigDecimal("7.50"),
                "descripcion", null
        );

        Map<String, Object> diff = AuditDiff.diff(antes, despues);

        assertTrue(diff.isEmpty(), "Snapshots idénticos deben generar diff vacío");
    }

    @Test
    void diff_tiposNoBigDecimal_usanObjectsEquals() {
        // String distinto → diff presente
        Map<String, Object> antes1 = snapshot("campo", "abc");
        Map<String, Object> despues1 = snapshot("campo", "xyz");
        assertFalse(AuditDiff.diff(antes1, despues1).isEmpty(),
                "Strings distintos deben generar diff");

        // Integer distinto → diff presente
        Map<String, Object> antes2 = snapshot("campo", 1);
        Map<String, Object> despues2 = snapshot("campo", 2);
        assertFalse(AuditDiff.diff(antes2, despues2).isEmpty(),
                "Integers distintos deben generar diff");

        // Strings iguales → diff vacío
        Map<String, Object> antes3 = snapshot("campo", "abc");
        Map<String, Object> despues3 = snapshot("campo", "abc");
        assertTrue(AuditDiff.diff(antes3, despues3).isEmpty(),
                "Strings iguales no deben generar diff");
    }
}
