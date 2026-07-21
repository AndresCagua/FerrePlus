package com.ferreplus.service;

import com.ferreplus.dto.CompraDTO;
import com.ferreplus.dto.DetalleCompraDTO;
import com.ferreplus.entity.*;
import com.ferreplus.repository.*;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.ANY)
@ActiveProfiles("test")
class CompraServiceIntegrationTest {

    @Autowired
    private CompraService compraService;

    @Autowired
    private ProductoRepository productoRepository;

    @Autowired
    private ProveedorRepository proveedorRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private RolRepository rolRepository;

    @Autowired
    private CategoriaRepository categoriaRepository;

    @Autowired
    private HistoricoPrecioProductoRepository historicoRepository;

    @Autowired
    private CompraRepository compraRepository;

    @Autowired
    private DetalleCompraRepository detalleCompraRepository;

    @Autowired
    private MovimientoStockRepository movimientoStockRepository;

    private Rol rol;
    private Categoria categoria;
    private Proveedor proveedor;
    private Usuario usuario;

    @BeforeEach
    void setUp() {
        // Clean up in reverse dependency order to respect FK constraints
        detalleCompraRepository.deleteAll();
        compraRepository.deleteAll();
        historicoRepository.deleteAll();
        movimientoStockRepository.deleteAll();
        productoRepository.deleteAll();
        usuarioRepository.deleteAll();
        proveedorRepository.deleteAll();
        categoriaRepository.deleteAll();
        rolRepository.deleteAll();

        // Create reference data
        rol = rolRepository.save(Rol.builder()
                .nombre("ADMIN_TEST")
                .build());

        categoria = categoriaRepository.save(Categoria.builder()
                .nombre("Test Categoria IT")
                .build());

        proveedor = proveedorRepository.save(Proveedor.builder()
                .nombre("Proveedor Test IT")
                .ruc("0999999999001")
                .activo(true)
                .build());

        usuario = usuarioRepository.save(Usuario.builder()
                .nombre("Usuario Test IT")
                .email("test-it@ferreplus.com")
                .password("encoded-password")
                .rol(rol)
                .activo(true)
                .build());
    }

    @AfterEach
    void tearDown() {
        // Clean up in reverse dependency order
        detalleCompraRepository.deleteAll();
        compraRepository.deleteAll();
        historicoRepository.deleteAll();
        movimientoStockRepository.deleteAll();
        productoRepository.deleteAll();
        usuarioRepository.deleteAll();
        proveedorRepository.deleteAll();
        categoriaRepository.deleteAll();
        rolRepository.deleteAll();
    }

    @Test
    void createCompra_shouldUpdatePrecioCompraAndSaveHistory() {
        // Given
        Producto producto = productoRepository.save(Producto.builder()
                .nombre("Producto Test Create")
                .codigoBarras("CT-001")
                .precioCompra(new BigDecimal("10.00"))
                .precioVenta(new BigDecimal("20.00"))
                .stockActual(10)
                .stockMinimo(2)
                .stockMaximo(50)
                .categoria(categoria)
                .activo(true)
                .build());

        DetalleCompraDTO detalle = new DetalleCompraDTO();
        detalle.setProductoId(producto.getId());
        detalle.setCantidad(5);
        detalle.setPrecioUnitario(new BigDecimal("25.50"));

        CompraDTO compraDTO = new CompraDTO();
        compraDTO.setNumeroFactura("FC-TEST-CREATE-001");
        compraDTO.setProveedorId(proveedor.getId());
        compraDTO.setUsuarioId(usuario.getId());
        compraDTO.setDetalles(List.of(detalle));

        // When
        compraService.create(compraDTO);

        // Then — verify producto.precioCompra was updated to 25.50
        Producto updatedProducto = productoRepository.findById(producto.getId()).orElseThrow();
        assertEquals(0, new BigDecimal("25.50").compareTo(updatedProducto.getPrecioCompra()),
                "precioCompra debe actualizarse al precioUnitario del detalle");

        // Then — verify historico record was created
        List<HistoricoPrecioProducto> historicos = historicoRepository
                .findByProductoIdOrderByFechaCambioDesc(producto.getId());
        assertEquals(1, historicos.size(), "Debe haber 1 registro histórico");

        HistoricoPrecioProducto historico = historicos.get(0);
        assertEquals("COMPRA", historico.getTipoCambio());
        assertEquals(0, new BigDecimal("25.50").compareTo(historico.getPrecioCompra()));
        assertEquals(0, new BigDecimal("20.00").compareTo(historico.getPrecioVenta()),
                "El precioVenta en el histórico debe mantener el valor original del producto");
        assertNotNull(historico.getReferencia(), "La referencia debe ser el número de factura");
        assertNull(historico.getUsuario(), "El usuario debe ser null en cambios automáticos por compra");
    }

    @Test
    void updateCompra_shouldUpdatePrecioCompraForNewDetails() {
        // Given — create a product
        Producto producto = productoRepository.save(Producto.builder()
                .nombre("Producto Test Update")
                .codigoBarras("CT-002")
                .precioCompra(new BigDecimal("10.00"))
                .precioVenta(new BigDecimal("20.00"))
                .stockActual(15)
                .stockMinimo(2)
                .stockMaximo(50)
                .categoria(categoria)
                .activo(true)
                .build());

        // Create first compra with precioUnitario=10.00
        DetalleCompraDTO detalle1 = new DetalleCompraDTO();
        detalle1.setProductoId(producto.getId());
        detalle1.setCantidad(2);
        detalle1.setPrecioUnitario(new BigDecimal("10.00"));

        CompraDTO compraDTO = new CompraDTO();
        compraDTO.setNumeroFactura("FC-TEST-UPDATE-001");
        compraDTO.setProveedorId(proveedor.getId());
        compraDTO.setUsuarioId(usuario.getId());
        compraDTO.setDetalles(List.of(detalle1));

        Compra createdCompra = compraService.create(compraDTO);

        // Verify precioCompra is 10.00 after first create
        Producto afterCreate = productoRepository.findById(producto.getId()).orElseThrow();
        assertEquals(0, new BigDecimal("10.00").compareTo(afterCreate.getPrecioCompra()),
                "Después de crear la compra, precioCompra debe ser 10.00");

        // Verify first historico record
        assertEquals(1, historicoRepository.findByProductoIdOrderByFechaCambioDesc(producto.getId()).size(),
                "Debe haber 1 registro histórico después de crear");

        // When — update the compra with a new detalle precioUnitario=15.00
        DetalleCompraDTO detalle2 = new DetalleCompraDTO();
        detalle2.setProductoId(producto.getId());
        detalle2.setCantidad(3);
        detalle2.setPrecioUnitario(new BigDecimal("15.00"));

        CompraDTO updateDTO = new CompraDTO();
        updateDTO.setNumeroFactura("FC-TEST-UPDATE-001");
        updateDTO.setProveedorId(proveedor.getId());
        updateDTO.setUsuarioId(usuario.getId());
        updateDTO.setDetalles(List.of(detalle2));

        compraService.update(createdCompra.getId(), updateDTO);

        // Then — verify producto.precioCompra was updated to 15.00
        Producto afterUpdate = productoRepository.findById(producto.getId()).orElseThrow();
        assertEquals(0, new BigDecimal("15.00").compareTo(afterUpdate.getPrecioCompra()),
                "Después de actualizar la compra, precioCompra debe ser 15.00");

        // Then — verify historico has 2 records (one for create, one for update)
        List<HistoricoPrecioProducto> historicos = historicoRepository
                .findByProductoIdOrderByFechaCambioDesc(producto.getId());
        assertEquals(2, historicos.size(), "Debe haber 2 registros históricos (create + update)");

        // Both should have tipoCambio = "COMPRA"
        assertTrue(historicos.stream().allMatch(h -> "COMPRA".equals(h.getTipoCambio())),
                "Todos los registros históricos deben tener tipoCambio=COMPRA");

        // The most recent (first descending) should have precioCompra=15.00
        assertEquals(0, new BigDecimal("15.00").compareTo(historicos.get(0).getPrecioCompra()),
                "El registro más reciente debe tener precioCompra=15.00");

        // The oldest (last descending) should have precioCompra=10.00
        assertEquals(0, new BigDecimal("10.00").compareTo(historicos.get(1).getPrecioCompra()),
                "El registro más antiguo debe tener precioCompra=10.00");
    }
}
