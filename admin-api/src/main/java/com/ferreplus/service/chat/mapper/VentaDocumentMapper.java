package com.ferreplus.service.chat.mapper;

import com.ferreplus.entity.DetalleVenta;
import com.ferreplus.entity.Venta;
import com.ferreplus.service.chat.EntityDocumentMapper;
import org.springframework.stereotype.Component;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Collectors;

@Component
public class VentaDocumentMapper implements EntityDocumentMapper<Venta> {
    @Override public String entityType() { return "VENTA"; }
    @Override public Long entityId(Venta entity) { return entity.getId(); }
    @Override public String toContentText(Venta v) {
        String detalles = v.getDetalles() == null ? "sin detalles" : v.getDetalles().stream().map(this::detail).collect(Collectors.joining("; "));
        return String.format("Venta factura %s. Cliente: %s. Fecha: %s. Estado: %s. Pago: %s. Total: %s. Detalles: %s.",
                value(v.getNumeroFactura()), v.getCliente() == null ? "sin cliente" : value(v.getCliente().getNombre()), value(v.getFechaCreacion()), value(v.getEstado()), value(v.getMetodoPago()), value(v.getTotal()), detalles);
    }
    @Override public Map<String, Object> metadata(Venta v) { Map<String, Object> result = new LinkedHashMap<>(); result.put("title", "Factura " + value(v.getNumeroFactura())); return result; }
    private String detail(DetalleVenta d) { return value(d.getProducto() == null ? null : d.getProducto().getNombre()) + " x " + value(d.getCantidad()) + " = " + value(d.getSubtotal()); }
    private String value(Object value) { return value == null ? "no informado" : value.toString(); }
}
