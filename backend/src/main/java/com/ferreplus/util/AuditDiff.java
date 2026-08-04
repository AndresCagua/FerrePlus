package com.ferreplus.util;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

/**
 * Helper reutilizable para el detalle de auditoría de operaciones {@code ACTUALIZAR}.
 *
 * <p>Genera un diff ANTES/DESPUÉS con <strong>solo</strong> los campos que realmente
 * cambiaron, cada uno con la forma {@code {"campo": {"antes": X, "despues": Y}}}
 * (ej. {@code {"nombre": {"antes": "Tornillo Hex", "despues": "Tornillo Hex 3"}}}),
 * en lugar del snapshot completo del estado nuevo. Es null-safe (compara con
 * {@link Objects#equals}) y determinista (orden de inserción del mapa snapshot).</p>
 *
 * <p>El cálculo se hace sobre mapas ya aplanados (snapshots por entidad con
 * selección explícita de campos escalares y {@code fkId}), NO por reflexión sobre
 * la entidad JPA — evita serializar colecciones/relaciones LAZY y mantiene el
 * detalle estable y legible.</p>
 *
 * <p>Decisión documentada: todas las entidades instrumentadas tienen campos
 * escalares difieren; si una actualización no cambia ningún campo, el diff queda
 * {@code {}} (evidencia honesta de "sin cambios detectados") en lugar de un
 * snapshot minimal fabricado.</p>
 */
public final class AuditDiff {

    private AuditDiff() {
    }

    /**
     * Calcula los campos con valores distintos entre dos snapshots.
     *
     * @param antes   snapshot del estado previo (antes de mutar la entidad)
     * @param despues snapshot del estado posterior (después de mutar/salvar)
     * @return mapa con solo los campos diferentes, mapeados a
     *         {@code {"antes": ..., "despues": ...}}; vacío si no hubo cambios.
     */
    public static Map<String, Object> diff(Map<String, Object> antes, Map<String, Object> despues) {
        Map<String, Object> cambios = new LinkedHashMap<>();
        for (String campo : unionDeClaves(antes, despues)) {
            Object valorAntes = antes.get(campo);
            Object valorDespues = despues.get(campo);
            if (!sonIguales(valorAntes, valorDespues)) {
                Map<String, Object> cambio = new LinkedHashMap<>();
                cambio.put("antes", valorAntes);
                cambio.put("despues", valorDespues);
                cambios.put(campo, cambio);
            }
        }
        return cambios;
    }

    private static boolean sonIguales(Object a, Object b) {
        if (a == null && b == null) return true;
        if (a == null || b == null) return false;
        if (a instanceof BigDecimal && b instanceof BigDecimal) {
            return ((BigDecimal) a).compareTo((BigDecimal) b) == 0;
        }
        return Objects.equals(a, b);
    }

    /**
     * Serializa el diff resultante a JSON crudo (fallback {@code {}}).
     */
    public static String toJson(ObjectMapper objectMapper, Map<String, Object> diff) {
        try {
            return objectMapper.writeValueAsString(diff);
        } catch (JsonProcessingException e) {
            return "{}";
        }
    }

    private static Set<String> unionDeClaves(Map<String, Object> antes, Map<String, Object> despues) {
        Set<String> claves = new LinkedHashSet<>(antes.keySet());
        claves.addAll(despues.keySet());
        return claves;
    }
}