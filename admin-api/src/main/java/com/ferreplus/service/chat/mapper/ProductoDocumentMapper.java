package com.ferreplus.service.chat.mapper;

import com.ferreplus.entity.Producto;
import com.ferreplus.service.chat.EntityDocumentMapper;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;

@Component
public class ProductoDocumentMapper implements EntityDocumentMapper<Producto> {
    @Override public String entityType() { return "PRODUCTO"; }
    @Override public Long entityId(Producto entity) { return entity.getId(); }
    @Override public String toContentText(Producto p) {
        return String.format("Producto: %s. Descripcion: %s. Codigo: %s. Categoria: %s. Ubicacion: %s. Stock: %s %s. Precio de compra: %s. Precio de venta: %s.",
                value(p.getNombre()), value(p.getDescripcion()), value(p.getCodigoBarras()),
                p.getCategoria() == null ? "sin categoria" : value(p.getCategoria().getNombre()),
                value(p.getUbicacion()), value(p.getStockActual()), value(p.getUnidadMedida()),
                value(p.getPrecioCompra()), value(p.getPrecioVenta()));
    }
    @Override public Map<String, Object> metadata(Producto p) {
        Map<String, Object> metadata = new LinkedHashMap<>();
        metadata.put("title", p.getNombre()); metadata.put("categoria", p.getCategoria() == null ? null : p.getCategoria().getNombre());
        return metadata;
    }
    private String value(Object value) { return value == null ? "no informado" : value.toString(); }
}
