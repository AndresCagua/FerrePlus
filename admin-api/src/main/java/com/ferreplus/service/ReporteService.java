package com.ferreplus.service;

import com.ferreplus.dto.ProductoRankingDTO;
import com.ferreplus.dto.ReporteDTO;
import com.ferreplus.dto.VentaDiariaDTO;
import com.ferreplus.entity.DetalleVenta;
import com.ferreplus.entity.Producto;
import com.ferreplus.entity.Venta;
import com.ferreplus.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@Transactional
@RequiredArgsConstructor
public class ReporteService {

    private final ProductoRepository productoRepository;
    private final VentaRepository ventaRepository;
    private final DetalleVentaRepository detalleVentaRepository;
    private final ClienteRepository clienteRepository;
    private final ProveedorRepository proveedorRepository;
    private final GastoRepository gastoRepository;

    @Transactional(readOnly = true)
    public ReporteDTO getDashboardMetrics() {
        LocalDate today = LocalDate.now();
        LocalDateTime startOfDay = today.atStartOfDay();
        LocalDateTime endOfDay = today.atTime(LocalTime.MAX);

        LocalDate firstOfMonth = today.withDayOfMonth(1);
        LocalDateTime startOfMonth = firstOfMonth.atStartOfDay();
        LocalDateTime endOfMonth = today.atTime(LocalTime.MAX);

        long totalProductos = productoRepository.count();
        long totalStockBajo = productoRepository.findStockBajo().size();

        BigDecimal ventasHoy = ventaRepository.sumTotalByFechaCreacionBetweenAndEstado(startOfDay, endOfDay, "COMPLETADA");
        if (ventasHoy == null) ventasHoy = BigDecimal.ZERO;

        BigDecimal ventasMes = getVentasMes(firstOfMonth, today);

        long totalClientes = clienteRepository.count();
        long totalProveedores = proveedorRepository.count();

        BigDecimal totalGastosMes = gastoRepository.sumMontoByFechaGastoBetween(firstOfMonth, today);
        if (totalGastosMes == null) totalGastosMes = BigDecimal.ZERO;

        List<ProductoRankingDTO> productosMasVendidos = getProductosMasVendidos();

        List<VentaDiariaDTO> ventasPorDia = getVentasPorDia(firstOfMonth, today);
        List<Producto> productosStockBajoList = getProductosStockBajo();

        return ReporteDTO.builder()
                .totalProductos(totalProductos)
                .productosStockBajo(totalStockBajo)
                .ventasHoy(ventasHoy)
                .ventasMes(ventasMes)
                .totalClientes(totalClientes)
                .totalProveedores(totalProveedores)
                .totalGastosMes(totalGastosMes)
                .productosMasVendidos(productosMasVendidos)
                .ventasPorDia(ventasPorDia)
                .productosStockBajoList(productosStockBajoList)
                .build();
    }

    public List<ProductoRankingDTO> getProductosMasVendidos() {
        return getProductosMasVendidos(10);
    }

    @Transactional(readOnly = true)
    public List<ProductoRankingDTO> getProductosMasVendidos(int limit) {
        List<DetalleVenta> detalles = detalleVentaRepository
                .findAllWithVentaAndProductoByVentaEstado("COMPLETADA");
        Map<Long, ProductoRankingDTO> rankingMap = new LinkedHashMap<>();

        for (DetalleVenta detalle : detalles) {
            Long productoId = detalle.getProducto().getId();
            ProductoRankingDTO existing = rankingMap.get(productoId);
            if (existing != null) {
                existing.setTotalVendido(existing.getTotalVendido() + detalle.getCantidad());
            } else {
                rankingMap.put(productoId, ProductoRankingDTO.builder()
                        .productoId(productoId)
                        .nombre(detalle.getProducto().getNombre())
                        .totalVendido(detalle.getCantidad().longValue())
                        .build());
            }
        }

        return rankingMap.values().stream()
                .sorted((a, b) -> Long.compare(b.getTotalVendido(), a.getTotalVendido()))
                .limit(limit)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<Producto> getProductosStockBajo() {
        return productoRepository.findStockBajo();
    }

    @Transactional(readOnly = true)
    public BigDecimal getVentasMes(LocalDate from, LocalDate to) {
        BigDecimal total = ventaRepository.sumTotalByFechaCreacionBetweenAndEstado(
                from.atStartOfDay(), to.atTime(LocalTime.MAX), "COMPLETADA");
        return total == null ? BigDecimal.ZERO : total;
    }

    private List<VentaDiariaDTO> getVentasPorDia(LocalDate firstOfMonth, LocalDate today) {
        Map<LocalDate, BigDecimal> dailyTotals = new LinkedHashMap<>();

        List<Venta> ventasDelMes = ventaRepository.findByFechaCreacionBetweenOrderByFechaCreacionDesc(
                firstOfMonth.atStartOfDay(),
                today.atTime(LocalTime.MAX)
        );

        for (Venta venta : ventasDelMes) {
            if (!"COMPLETADA".equals(venta.getEstado())) {
                continue;
            }
            LocalDate fechaVenta = venta.getFechaCreacion().toLocalDate();
            dailyTotals.merge(fechaVenta, venta.getTotal(), BigDecimal::add);
        }

        return dailyTotals.entrySet().stream()
                .map(entry -> VentaDiariaDTO.builder()
                        .fecha(entry.getKey())
                        .total(entry.getValue())
                        .build())
                .sorted(Comparator.comparing(VentaDiariaDTO::getFecha))
                .collect(Collectors.toList());
    }
}
