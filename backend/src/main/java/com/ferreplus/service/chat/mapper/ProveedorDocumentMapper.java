package com.ferreplus.service.chat.mapper;

import com.ferreplus.entity.Proveedor;
import com.ferreplus.service.chat.EntityDocumentMapper;
import org.springframework.stereotype.Component;
import java.util.LinkedHashMap;
import java.util.Map;

@Component
public class ProveedorDocumentMapper implements EntityDocumentMapper<Proveedor> {
    @Override public String entityType() { return "PROVEEDOR"; }
    @Override public Long entityId(Proveedor entity) { return entity.getId(); }
    @Override public String toContentText(Proveedor p) {
        return String.format("Proveedor: %s. RUC: %s. Contacto: %s. Telefono: %s. Email: %s. Direccion: %s.",
                value(p.getNombre()), value(p.getRuc()), value(p.getContacto()), value(p.getTelefono()), value(p.getEmail()), value(p.getDireccion()));
    }
    @Override public Map<String, Object> metadata(Proveedor p) { Map<String, Object> result = new LinkedHashMap<>(); result.put("title", p.getNombre()); return result; }
    private String value(Object value) { return value == null ? "no informado" : value.toString(); }
}
