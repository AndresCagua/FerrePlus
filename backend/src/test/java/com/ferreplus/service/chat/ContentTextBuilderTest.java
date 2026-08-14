package com.ferreplus.service.chat;

import com.ferreplus.entity.Categoria;
import com.ferreplus.entity.DetalleVenta;
import com.ferreplus.entity.GuiaSistema;
import com.ferreplus.entity.Producto;
import com.ferreplus.entity.Venta;
import com.ferreplus.service.chat.mapper.GuiaDocumentMapper;
import com.ferreplus.service.chat.mapper.ProductoDocumentMapper;
import com.ferreplus.service.chat.mapper.VentaDocumentMapper;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class ContentTextBuilderTest {

    @Test
    void productoContent_includesSearchableBusinessFields() {
        Producto producto = Producto.builder()
                .id(11L).nombre("Cable THHN").descripcion("Cable electrico")
                .codigoBarras("789").ubicacion("A-1").stockActual(20)
                .unidadMedida("metro").precioVenta(new BigDecimal("2.50"))
                .categoria(Categoria.builder().nombre("Electricidad").build()).build();

        String content = new ProductoDocumentMapper().toContentText(producto);

        assertThat(content).contains("Cable THHN", "Cable electrico", "Electricidad", "Stock: 20", "2.50");
        assertThat(content).doesNotContain("password", "token", "secreto");
    }

    @Test
    void ventaContent_includesInvoiceCustomerTotalAndDetails() {
        Producto producto = Producto.builder().nombre("Tornillo").build();
        DetalleVenta detalle = DetalleVenta.builder().producto(producto).cantidad(3)
                .subtotal(new BigDecimal("6.00")).build();
        Venta venta = Venta.builder().id(4L).numeroFactura("F-004").estado("COMPLETADA")
                .total(new BigDecimal("6.00")).detalles(List.of(detalle)).build();

        String content = new VentaDocumentMapper().toContentText(venta);

        assertThat(content).contains("F-004", "COMPLETADA", "6.00", "Tornillo", "x 3");
        assertThat(content).doesNotContain("password", "token", "secreto");
    }

    @Test
    void guiaContent_composesRouteStepsKeywordsAndDescription() {
        GuiaSistema guia = GuiaSistema.builder().id(7L).modulo("PRODUCTO")
                .titulo("Registrar producto").descripcion("Permite crear productos")
                .ruta("/productos").pasos("[\"Abrir Productos\",\"Seleccionar Nuevo\"]")
                .keywords("producto, inventario").build();

        String content = new GuiaDocumentMapper().toContentText(guia);

        assertThat(content).contains("PRODUCTO", "Registrar producto", "/productos",
                "Abrir Productos", "Seleccionar Nuevo", "inventario");
    }
}
