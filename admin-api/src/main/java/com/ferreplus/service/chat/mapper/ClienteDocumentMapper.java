package com.ferreplus.service.chat.mapper;

import com.ferreplus.entity.Cliente;
import com.ferreplus.service.chat.EntityDocumentMapper;
import org.springframework.stereotype.Component;
import java.util.LinkedHashMap;
import java.util.Map;

@Component
public class ClienteDocumentMapper implements EntityDocumentMapper<Cliente> {
    @Override public String entityType() { return "CLIENTE"; }
    @Override public Long entityId(Cliente entity) { return entity.getId(); }
    @Override public String toContentText(Cliente c) {
        return String.format("Cliente: %s. RUC: %s. Telefono: %s. Email: %s. Direccion: %s. Saldo pendiente: %s.",
                value(c.getNombre()), value(c.getRuc()), value(c.getTelefono()), value(c.getEmail()), value(c.getDireccion()), value(c.getSaldoPendiente()));
    }
    @Override public Map<String, Object> metadata(Cliente c) { return title(c.getNombre()); }
    private Map<String, Object> title(String title) { Map<String, Object> result = new LinkedHashMap<>(); result.put("title", title); return result; }
    private String value(Object value) { return value == null ? "no informado" : value.toString(); }
}
