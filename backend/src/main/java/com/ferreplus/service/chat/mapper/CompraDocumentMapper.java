package com.ferreplus.service.chat.mapper;

import com.ferreplus.entity.Compra;
import com.ferreplus.entity.DetalleCompra;
import com.ferreplus.service.chat.EntityDocumentMapper;
import org.springframework.stereotype.Component;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Collectors;

@Component
public class CompraDocumentMapper implements EntityDocumentMapper<Compra> {
    @Override public String entityType() { return "COMPRA"; }
    @Override public Long entityId(Compra entity) { return entity.getId(); }
    @Override public String toContentText(Compra c) {
        String detalles = c.getDetalles() == null ? "sin detalles" : c.getDetalles().stream().map(this::detail).collect(Collectors.joining("; "));
        return String.format("Compra factura %s. Proveedor: %s. Fecha: %s. Estado: %s. Total: %s. Detalles: %s.",
                value(c.getNumeroFactura()), c.getProveedor() == null ? "sin proveedor" : value(c.getProveedor().getNombre()), value(c.getFechaFactura()), value(c.getEstado()), value(c.getTotal()), detalles);
    }
    @Override public Map<String, Object> metadata(Compra c) { Map<String, Object> result = new LinkedHashMap<>(); result.put("title", "Factura " + value(c.getNumeroFactura())); return result; }
    private String detail(DetalleCompra d) { return value(d.getProducto() == null ? null : d.getProducto().getNombre()) + " x " + value(d.getCantidad()) + " = " + value(d.getSubtotal()); }
    private String value(Object value) { return value == null ? "no informado" : value.toString(); }
}
