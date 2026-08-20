package com.ferreplus.service.chat;

import com.ferreplus.dto.ProductoRankingDTO;
import com.ferreplus.entity.Auditoria;
import com.ferreplus.entity.Compra;
import com.ferreplus.entity.Producto;
import com.ferreplus.entity.Proveedor;
import com.ferreplus.entity.Gasto;
import com.ferreplus.repository.AuditoriaRepository;
import com.ferreplus.repository.ClienteRepository;
import com.ferreplus.repository.CompraRepository;
import com.ferreplus.repository.GastoRepository;
import com.ferreplus.repository.ProductoRepository;
import com.ferreplus.repository.ProveedorRepository;
import com.ferreplus.repository.UsuarioRepository;
import com.ferreplus.service.ReporteService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageRequest;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AnalyticalChatServiceTest {
    @Mock private ReporteService reporteService;
    @Mock private AuditoriaRepository auditoriaRepository;
    @Mock private CompraRepository compraRepository;
    @Mock private GastoRepository gastoRepository;
    @Mock private ProductoRepository productoRepository;
    @Mock private ClienteRepository clienteRepository;
    @Mock private ProveedorRepository proveedorRepository;
    @Mock private UsuarioRepository usuarioRepository;
    @InjectMocks private AnalyticalChatService service;

    private final ValidatedChatParameters parameters = new ValidatedChatParameters(
            Optional.of(new DateRange(LocalDate.of(2026, 8, 1), LocalDate.of(2026, 8, 14))), 1);

    @Test
    void mapsRankingAndAppliesValidatedLimit() {
        ProductoRankingDTO first = ProductoRankingDTO.builder().productoId(1L).nombre("Martillo").totalVendido(8L).build();
        ProductoRankingDTO second = ProductoRankingDTO.builder().productoId(2L).nombre("Taladro").totalVendido(4L).build();
        when(reporteService.getProductosMasVendidos(1)).thenReturn(List.of(first));

        assertThat(service.productosMasVendidos(parameters))
                .containsExactly(new ProductoMasVendidoResult(1L, "Martillo", 8L));
    }

    @Test
    void sumsCompletedSalesThroughReporteService() {
        when(reporteService.getVentasMes(parameters.dateRange().orElseThrow().from(), parameters.dateRange().orElseThrow().to()))
                .thenReturn(new BigDecimal("125.50"));

        assertThat(service.ventasMes(parameters).totalCompletadas()).isEqualByComparingTo("125.50");
        verify(reporteService).getVentasMes(parameters.dateRange().orElseThrow().from(), parameters.dateRange().orElseThrow().to());
    }

    @Test
    void mapsLowStockProductsWithoutExposingEntities() {
        Producto product = Producto.builder().id(7L).nombre("Cinta").stockActual(2).stockMinimo(5).build();
        when(reporteService.getProductosStockBajo()).thenReturn(List.of(product));

        assertThat(service.stockBajo(parameters)).containsExactly(new StockBajoResult(7L, "Cinta", 2, 5));
    }

    @Test
    void resolvesNameBeforeQueryingAudit() {
        Producto product = Producto.builder().id(42L).nombre("Martillo").build();
        Auditoria audit = Auditoria.builder().entidad("PRODUCTO").entidadId(42L)
                .accion("ACTUALIZAR").fecha(LocalDateTime.now()).detalle("Cambio").build();
        when(productoRepository.findFirstByNombreIgnoreCaseOrderByIdAsc("Martillo")).thenReturn(Optional.of(product));
        when(auditoriaRepository.findFirstByEntidadAndEntidadIdOrderByFechaDescIdDesc("PRODUCTO", 42L))
                .thenReturn(Optional.of(audit));

        assertThat(service.ultimoCambio(ChatEntity.PRODUCTO, Optional.of("Martillo"))).isPresent();
        verify(auditoriaRepository).findFirstByEntidadAndEntidadIdOrderByFechaDescIdDesc("PRODUCTO", 42L);
    }

    @Test
    void missingNameDoesNotQueryAudit() {
        when(productoRepository.findFirstByNombreIgnoreCaseOrderByIdAsc("Inexistente")).thenReturn(Optional.empty());

        assertThat(service.ultimoCambio(ChatEntity.PRODUCTO, Optional.of("Inexistente"))).isEmpty();
        verifyNoInteractions(auditoriaRepository);
    }

    @Test
    void unsupportedNamedEntityDoesNotQueryAnyRepository() {
        assertThat(service.ultimoCambio(ChatEntity.VENTA, Optional.of("factura-1"))).isEmpty();
        verifyNoInteractions(auditoriaRepository, productoRepository, clienteRepository, proveedorRepository, usuarioRepository);
    }

    @Test
    void findsMostExpensiveCompletedPurchaseFromHistory() {
        Compra purchase = Compra.builder().id(4L).numeroFactura("F-4").total(new BigDecimal("900.00"))
                .fechaFactura(LocalDate.of(2026, 8, 10))
                .proveedor(Proveedor.builder().id(8L).nombre("Proveedor Uno").build()).build();
        when(compraRepository.findFirstByEstadoOrderByTotalDescIdAsc("COMPLETADA"))
                .thenReturn(Optional.of(purchase));

        assertThat(service.compraMasCara(new ValidatedChatParameters(Optional.empty(), 10)))
                .contains(new MayorCompraResult(4L, "F-4", new BigDecimal("900.00"), "Proveedor Uno",
                        LocalDate.of(2026, 8, 10)));
        verify(compraRepository).findFirstByEstadoOrderByTotalDescIdAsc("COMPLETADA");
        verify(compraRepository, never()).findFirstByEstadoAndFechaFacturaBetweenOrderByTotalDescIdAsc(
                anyString(), any(), any());
    }

    @Test
    void findsMostExpensiveCompletedPurchaseWithinRange() {
        DateRange range = new DateRange(LocalDate.of(2026, 8, 1), LocalDate.of(2026, 8, 14));
        when(compraRepository.findFirstByEstadoAndFechaFacturaBetweenOrderByTotalDescIdAsc(
                "COMPLETADA", range.from(), range.to())).thenReturn(Optional.empty());

        assertThat(service.compraMasCara(new ValidatedChatParameters(Optional.of(range), 10))).isEmpty();
        verify(compraRepository).findFirstByEstadoAndFechaFacturaBetweenOrderByTotalDescIdAsc(
                "COMPLETADA", range.from(), range.to());
        verify(compraRepository, never()).findFirstByEstadoOrderByTotalDescIdAsc(anyString());
    }

    @Test
    void findsLargestExpenseWithAndWithoutRange() {
        Gasto expense = Gasto.builder().id(3L).descripcion("Arriendo").monto(new BigDecimal("500.00"))
                .fechaGasto(LocalDate.of(2026, 8, 5)).build();
        when(gastoRepository.findFirstByOrderByMontoDescIdAsc()).thenReturn(Optional.of(expense));
        assertThat(service.mayorGasto(new ValidatedChatParameters(Optional.empty(), 10))).contains(
                new MayorGastoResult(3L, "Arriendo", new BigDecimal("500.00"), LocalDate.of(2026, 8, 5)));
        verify(gastoRepository).findFirstByOrderByMontoDescIdAsc();

        DateRange range = new DateRange(LocalDate.of(2026, 8, 1), LocalDate.of(2026, 8, 14));
        when(gastoRepository.findFirstByFechaGastoBetweenOrderByMontoDescIdAsc(range.from(), range.to()))
                .thenReturn(Optional.empty());
        assertThat(service.mayorGasto(new ValidatedChatParameters(Optional.of(range), 10))).isEmpty();
        verify(gastoRepository).findFirstByFechaGastoBetweenOrderByMontoDescIdAsc(range.from(), range.to());
    }

    @Test
    void findsTopProviderUsingHistoryOrRangeProjection() {
        PageRequest page = PageRequest.of(0, 1);
        ProveedorCompraTotalProjection projection = mock(ProveedorCompraTotalProjection.class);
        when(projection.getProveedorId()).thenReturn(8L);
        when(projection.getProveedorNombre()).thenReturn("Proveedor Uno");
        when(projection.getTotalAcumulado()).thenReturn(new BigDecimal("1200.00"));
        when(compraRepository.findProveedorTotalsByEstado("COMPLETADA", page))
                .thenReturn(List.of(projection));

        assertThat(service.proveedorTop(new ValidatedChatParameters(Optional.empty(), 10))).contains(
                new ProveedorTopResult(8L, "Proveedor Uno", new BigDecimal("1200.00")));
        verify(compraRepository).findProveedorTotalsByEstado("COMPLETADA", page);

        DateRange range = new DateRange(LocalDate.of(2026, 8, 1), LocalDate.of(2026, 8, 14));
        when(compraRepository.findProveedorTotalsByEstadoAndFechaFacturaBetween(
                "COMPLETADA", range.from(), range.to(), page)).thenReturn(List.of());
        assertThat(service.proveedorTop(new ValidatedChatParameters(Optional.of(range), 10))).isEmpty();
        verify(compraRepository).findProveedorTotalsByEstadoAndFechaFacturaBetween(
                "COMPLETADA", range.from(), range.to(), page);
    }
}
