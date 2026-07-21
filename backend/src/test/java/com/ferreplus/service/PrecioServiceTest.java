package com.ferreplus.service;

import com.ferreplus.dto.ActualizarPrecioVentaDTO;
import com.ferreplus.dto.PrecioProductoDTO;
import com.ferreplus.entity.HistoricoPrecioProducto;
import com.ferreplus.entity.Producto;
import com.ferreplus.entity.Usuario;
import com.ferreplus.exception.BadRequestException;
import com.ferreplus.repository.HistoricoPrecioProductoRepository;
import com.ferreplus.repository.ProductoRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PrecioServiceTest {

    @Mock
    private ProductoRepository productoRepository;

    @Mock
    private HistoricoPrecioProductoRepository historicoRepository;

    @InjectMocks
    private PrecioService precioService;

    @Captor
    private ArgumentCaptor<Producto> productoCaptor;

    @Captor
    private ArgumentCaptor<HistoricoPrecioProducto> historicoCaptor;

    @Test
    void listarPrecios_shouldReturnAllActiveProductsWithCalculatedMargins() {
        // Given
        Producto producto1 = Producto.builder()
                .id(1L)
                .nombre("Producto 1")
                .codigoBarras("001")
                .precioCompra(new BigDecimal("100"))
                .precioVenta(new BigDecimal("150"))
                .activo(true)
                .build();

        Producto producto2 = Producto.builder()
                .id(2L)
                .nombre("Producto 2")
                .codigoBarras("002")
                .precioCompra(BigDecimal.ZERO)
                .precioVenta(new BigDecimal("50"))
                .activo(true)
                .build();

        when(productoRepository.findAll()).thenReturn(List.of(producto1, producto2));

        // When
        List<PrecioProductoDTO> result = precioService.listarPrecios();

        // Then
        assertEquals(2, result.size());

        // Producto 1: precioCompra=100, precioVenta=150 → ganancia=50, margen=50%
        PrecioProductoDTO dto1 = result.get(0);
        assertEquals("Producto 1", dto1.getNombre());
        assertEquals(0, new BigDecimal("100").compareTo(dto1.getPrecioCompra()));
        assertEquals(0, new BigDecimal("150").compareTo(dto1.getPrecioVenta()));
        assertEquals(0, new BigDecimal("50").compareTo(dto1.getGanancia()));
        assertEquals(50.0, dto1.getMargenPorcentaje(), 0.001);

        // Producto 2: precioCompra=0 → ganancia=null, margen=null
        PrecioProductoDTO dto2 = result.get(1);
        assertEquals("Producto 2", dto2.getNombre());
        assertEquals(0, BigDecimal.ZERO.compareTo(dto2.getPrecioCompra()));
        assertEquals(0, new BigDecimal("50").compareTo(dto2.getPrecioVenta()));
        assertNull(dto2.getGanancia());
        assertNull(dto2.getMargenPorcentaje());
    }

    @Test
    void actualizarPrecioVenta_withNewPrice_shouldUpdateAndSaveHistory() {
        // Given
        Producto producto = Producto.builder()
                .id(1L)
                .nombre("Producto Test")
                .precioCompra(new BigDecimal("100"))
                .precioVenta(new BigDecimal("150"))
                .activo(true)
                .build();

        Usuario usuario = Usuario.builder()
                .id(1L)
                .nombre("Admin")
                .build();

        when(productoRepository.findById(1L)).thenReturn(java.util.Optional.of(producto));
        when(productoRepository.save(any(Producto.class))).thenReturn(producto);
        when(historicoRepository.save(any(HistoricoPrecioProducto.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        ActualizarPrecioVentaDTO dto = new ActualizarPrecioVentaDTO(
                new BigDecimal("200"), null, "Ajuste estacional"
        );

        // When
        precioService.actualizarPrecioVenta(1L, dto, usuario);

        // Then
        assertEquals(0, new BigDecimal("200").compareTo(producto.getPrecioVenta()),
                "El precio de venta debe actualizarse a 200");

        verify(historicoRepository).save(historicoCaptor.capture());
        HistoricoPrecioProducto historico = historicoCaptor.getValue();
        assertEquals("ACTUALIZACION_VENTA", historico.getTipoCambio());
        assertEquals(producto, historico.getProducto());
        assertEquals(0, new BigDecimal("100").compareTo(historico.getPrecioCompra()));
        assertEquals(0, new BigDecimal("200").compareTo(historico.getPrecioVenta()));
        assertEquals("Ajuste estacional", historico.getReferencia());
        assertEquals(usuario, historico.getUsuario());
    }

    @Test
    void actualizarPrecioVenta_withMargin_shouldCalculatePriceAndSaveHistory() {
        // Given
        Producto producto = Producto.builder()
                .id(1L)
                .nombre("Producto Test")
                .precioCompra(new BigDecimal("100"))
                .precioVenta(new BigDecimal("100"))
                .activo(true)
                .build();

        Usuario usuario = Usuario.builder()
                .id(1L)
                .nombre("Admin")
                .build();

        when(productoRepository.findById(1L)).thenReturn(java.util.Optional.of(producto));
        when(productoRepository.save(any(Producto.class))).thenReturn(producto);
        when(historicoRepository.save(any(HistoricoPrecioProducto.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        ActualizarPrecioVentaDTO dto = new ActualizarPrecioVentaDTO(null, 50.0, null);

        // When
        precioService.actualizarPrecioVenta(1L, dto, usuario);

        // Then: precioVenta = 100 * (1 + 50/100) = 150
        assertEquals(0, new BigDecimal("150.00").compareTo(producto.getPrecioVenta()),
                "El precio de venta debe ser 150 (100 * 1.5)");

        verify(historicoRepository).save(historicoCaptor.capture());
        HistoricoPrecioProducto historico = historicoCaptor.getValue();
        assertEquals("ACTUALIZACION_VENTA", historico.getTipoCambio());
        assertEquals(0, new BigDecimal("150.00").compareTo(historico.getPrecioVenta()));
    }

    @Test
    void actualizarPrecioVenta_withBothFields_shouldThrowError() {
        // Given
        ActualizarPrecioVentaDTO dto = new ActualizarPrecioVentaDTO(
                new BigDecimal("100"), 50.0, null
        );

        // When / Then
        BadRequestException exception = assertThrows(BadRequestException.class,
                () -> precioService.actualizarPrecioVenta(1L, dto, null));
        assertTrue(exception.getMessage().contains("no ambos"),
                "Mensaje debe indicar que los campos son mutuamente excluyentes");
    }

    @Test
    void actualizarPrecioVenta_withNoFields_shouldThrowError() {
        // Given
        ActualizarPrecioVentaDTO dto = new ActualizarPrecioVentaDTO(null, null, null);

        // When / Then
        BadRequestException exception = assertThrows(BadRequestException.class,
                () -> precioService.actualizarPrecioVenta(1L, dto, null));
        assertTrue(exception.getMessage().contains("Debe proporcionar"),
                "Mensaje debe indicar que se debe proporcionar nuevoPrecio o margenPorcentaje");
    }

    @Test
    void registrarHistorico_shouldSaveRecord() {
        // Given
        Producto producto = Producto.builder().id(1L).build();
        Usuario usuario = Usuario.builder().id(1L).nombre("Admin").build();

        when(historicoRepository.save(any(HistoricoPrecioProducto.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        // When
        precioService.registrarHistorico(
                producto,
                new BigDecimal("100"),
                new BigDecimal("200"),
                "ACTUALIZACION_VENTA",
                "REF-001",
                usuario
        );

        // Then
        verify(historicoRepository).save(historicoCaptor.capture());
        HistoricoPrecioProducto saved = historicoCaptor.getValue();
        assertEquals(producto, saved.getProducto());
        assertEquals(0, new BigDecimal("100").compareTo(saved.getPrecioCompra()));
        assertEquals(0, new BigDecimal("200").compareTo(saved.getPrecioVenta()));
        assertEquals("ACTUALIZACION_VENTA", saved.getTipoCambio());
        assertEquals("REF-001", saved.getReferencia());
        assertEquals(usuario, saved.getUsuario());
    }
}
