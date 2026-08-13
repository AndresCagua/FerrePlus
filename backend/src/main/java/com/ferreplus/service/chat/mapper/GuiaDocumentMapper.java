package com.ferreplus.service.chat.mapper;

import com.ferreplus.entity.GuiaSistema;
import com.ferreplus.service.chat.EntityDocumentMapper;
import org.springframework.stereotype.Component;
import java.util.LinkedHashMap;
import java.util.Map;

@Component
public class GuiaDocumentMapper implements EntityDocumentMapper<GuiaSistema> {
    @Override public String entityType() { return "GUIA"; }
    @Override public Long entityId(GuiaSistema entity) { return entity.getId(); }
    @Override public String toContentText(GuiaSistema g) {
        return String.format("Guia del modulo %s. Titulo: %s. Descripcion: %s. Ruta: %s. Pasos: %s. Palabras clave: %s.",
                value(g.getModulo()), value(g.getTitulo()), value(g.getDescripcion()), value(g.getRuta()), value(g.getPasos()), value(g.getKeywords()));
    }
    @Override public Map<String, Object> metadata(GuiaSistema g) {
        Map<String, Object> result = new LinkedHashMap<>(); result.put("title", g.getTitulo()); result.put("ruta", g.getRuta()); result.put("modulo", g.getModulo()); return result;
    }
    private String value(Object value) { return value == null ? "no informado" : value.toString(); }
}
