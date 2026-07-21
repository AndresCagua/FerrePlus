package com.ferreplus.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReporteDTO {

    private Long totalProductos;
    private Long productosStockBajo;
    private BigDecimal ventasHoy;
    private BigDecimal totalVentasHoy;
    private BigDecimal ventasMes;
    private BigDecimal totalVentasMes;
    private Long comprasMes;
    private BigDecimal totalComprasMes;
    private Long gastosMes;
    private BigDecimal totalGastosMes;
    private Long totalClientes;
    private Long totalProveedores;
    private Long totalUsuarios;
    private BigDecimal saldoPendienteClientes;
    private List<ProductoRankingDTO> productosMasVendidos;
    private List<VentaDiariaDTO> ventasPorDia;
}
