package com.ferreplus.service.chat.mapper;

import com.ferreplus.entity.Gasto;
import com.ferreplus.service.chat.EntityDocumentMapper;
import org.springframework.stereotype.Component;
import java.util.LinkedHashMap;
import java.util.Map;

@Component
public class GastoDocumentMapper implements EntityDocumentMapper<Gasto> {
    @Override public String entityType() { return "GASTO"; }
    @Override public Long entityId(Gasto entity) { return entity.getId(); }
    @Override public String toContentText(Gasto g) {
        return String.format("Gasto: %s. Categoria: %s. Monto: %s. Fecha: %s. Pago: %s. Comprobante: %s. Observaciones: %s.",
                value(g.getDescripcion()), value(g.getCategoria()), value(g.getMonto()), value(g.getFechaGasto()), value(g.getMetodoPago()), value(g.getNumeroComprobante()), value(g.getObservaciones()));
    }
    @Override public Map<String, Object> metadata(Gasto g) { Map<String, Object> result = new LinkedHashMap<>(); result.put("title", g.getDescripcion()); return result; }
    private String value(Object value) { return value == null ? "no informado" : value.toString(); }
}
