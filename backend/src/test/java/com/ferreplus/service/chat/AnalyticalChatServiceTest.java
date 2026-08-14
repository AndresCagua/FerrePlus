package com.ferreplus.service.chat;

import com.ferreplus.dto.ProductoRankingDTO;
import com.ferreplus.entity.Auditoria;
import com.ferreplus.entity.Producto;
import com.ferreplus.repository.AuditoriaRepository;
import com.ferreplus.repository.ClienteRepository;
import com.ferreplus.repository.ProductoRepository;
import com.ferreplus.repository.ProveedorRepository;
import com.ferreplus.repository.UsuarioRepository;
import com.ferreplus.service.ReporteService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

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
}
