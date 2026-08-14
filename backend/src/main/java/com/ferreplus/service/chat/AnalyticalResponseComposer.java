package com.ferreplus.service.chat;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Component
public class AnalyticalResponseComposer {
    public String composeProductosMasVendidos(List<ProductoMasVendidoResult> results) {
        if (results == null || results.isEmpty()) return "No se encontraron productos vendidos.";
        String products = results.stream()
                .map(result -> "- " + result.nombre() + " (" + result.totalVendido() + ")")
                .collect(Collectors.joining("\n"));
        return "Productos mas vendidos:\n" + products;
    }

    public String composeVentasMes(VentasMesResult result) {
        if (result == null) return "No se encontraron ventas para el periodo consultado.";
        return "Ventas completadas del " + result.from() + " al " + result.to() + ": " + money(result.totalCompletadas()) + ".";
    }

    public String composeStockBajo(List<StockBajoResult> results) {
        if (results == null || results.isEmpty()) return "No hay productos con stock bajo.";
        return "Productos con stock bajo:\n" + results.stream()
                .map(result -> "- " + result.nombre() + " (" + result.stockActual() + "/" + result.stockMinimo() + ")")
                .collect(Collectors.joining("\n"));
    }

    public String composeUltimoCambio(java.util.Optional<UltimoCambioResult> result) {
        if (result == null || result.isEmpty()) return "No se encontraron cambios registrados";
        UltimoCambioResult change = result.get();
        String user = change.usuarioNombre() == null ? "usuario no identificado" : change.usuarioNombre();
        return "Ultimo cambio: " + change.accion() + " el " + change.fecha() + " por " + user
                + ". Detalle: " + (change.detalle() == null ? "sin detalle" : change.detalle()) + ".";
    }

    public String composeMayorCompra(Optional<MayorCompraResult> result) {
        if (result == null || result.isEmpty()) return "No se encontraron compras completadas.";
        MayorCompraResult purchase = result.get();
        return "La compra mas cara fue la factura " + purchase.numeroFactura() + " de "
                + purchase.proveedorNombre() + " por " + money(purchase.total()) + " el "
                + purchase.fechaFactura() + ".";
    }

    public String composeMayorGasto(Optional<MayorGastoResult> result) {
        if (result == null || result.isEmpty()) return "No se encontraron gastos registrados.";
        MayorGastoResult expense = result.get();
        return "El mayor gasto fue " + expense.descripcion() + " por " + money(expense.monto())
                + " el " + expense.fechaGasto() + ".";
    }

    public String composeProveedorTop(Optional<ProveedorTopResult> result) {
        if (result == null || result.isEmpty()) return "No se encontraron compras registradas.";
        ProveedorTopResult provider = result.get();
        return "El proveedor al que mas se le ha comprado es " + provider.proveedorNombre()
                + " con " + money(provider.totalAcumulado()) + " acumulados.";
    }

    private String money(BigDecimal value) {
        return value == null ? "0" : value.toPlainString();
    }
}
