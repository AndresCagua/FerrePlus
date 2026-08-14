package com.ferreplus.service;

import com.ferreplus.dto.AuthLoginDTO;
import com.ferreplus.dto.MovimientoStockDTO;
import com.ferreplus.entity.Auditoria;
import com.ferreplus.entity.MovimientoStock;
import com.ferreplus.entity.Producto;
import com.ferreplus.entity.Usuario;
import com.ferreplus.entity.Venta;
import com.ferreplus.exception.BadRequestException;
import com.ferreplus.repository.AuditoriaRepository;
import com.ferreplus.repository.ProductoRepository;
import com.ferreplus.repository.UsuarioRepository;
import com.ferreplus.repository.VentaRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * R4/R5/R10 — Instrumentación del resto del sistema y del login exitoso.
 *
 * <p>La instrumentación (productos, movimiento, venta) registra la fila tras el
 * save exitoso con el actor autenticado; una operación rechazada (stock
 * insuficiente → 400) NO deja fila (atomicidad MANDATORY). El login registra
 * {@code AUTH}/{@code LOGIN} de forma explícita (usuario pasado) y el fallo no
 * registra nada.</p>
 */
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("test")
@Transactional
class AuditoriaInstrumentacionTest {

    @Autowired
    private ProductoService productoService;

    @Autowired
    private MovimientoStockService movimientoStockService;

    @Autowired
    private VentaService ventaService;

    @Autowired
    private AuthService authService;

    @Autowired
    private AuditoriaRepository auditoriaRepository;

    @Autowired
    private ProductoRepository productoRepository;

    @Autowired
    private VentaRepository ventaRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    private Usuario admin;

    @BeforeEach
    void autenticarAdmin() {
        admin = usuarioRepository.findByEmail("admin@ferreplus.com").orElseThrow();
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(admin, null, List.of()));
    }

    @AfterEach
    void limpiarContexto() {
        SecurityContextHolder.clearContext();
    }

    private Producto productoConStock(int stock) {
        return productoRepository.save(Producto.builder()
                .nombre("Producto Instrumentado")
                .precioCompra(BigDecimal.TEN)
                .precioVenta(new BigDecimal("15"))
                .stockActual(stock)
                .stockMinimo(0)
                .stockMaximo(0)
                .activo(true)
                .build());
    }

    @Test
    void crearProducto_registraEntidadIdYUsuarioCorrectos() {
        Producto creado = productoService.create(productoConStock(10));

        List<Auditoria> filas = auditoriaRepository
                .findByEntidadAndEntidadIdAndAccion("PRODUCTO", creado.getId(), "CREAR");
        assertEquals(1, filas.size(), "Crear producto debe generar 1 fila PRODUCTO/CREAR");
        assertEquals(creado.getId(), filas.get(0).getEntidadId());
        assertEquals(admin.getId(), filas.get(0).getUsuario().getId(),
                "El usuario_id debe ser el actor autenticado");
    }

    @Test
    void actualizarProducto_registraEntidadIdYusuarioCorrectos() throws Exception {
        Producto existente = productoConStock(10);
        Producto cambios = new Producto();
        cambios.setNombre("Producto Instrumentado Renombrado");
        cambios.setPrecioCompra(new BigDecimal("12"));
        cambios.setPrecioVenta(new BigDecimal("18"));
        cambios.setActivo(true);

        productoService.update(existente.getId(), cambios);

        List<Auditoria> filas = auditoriaRepository
                .findByEntidadAndEntidadIdAndAccion("PRODUCTO", existente.getId(), "ACTUALIZAR");
        assertEquals(1, filas.size(), "Actualizar producto debe generar 1 fila PRODUCTO/ACTUALIZAR");
        assertEquals(admin.getId(), filas.get(0).getUsuario().getId());

        JsonNode detalle = new ObjectMapper().readTree(filas.get(0).getDetalle());
        assertTrue(detalle.isObject(), "El detalle de ACTUALIZAR debe ser un JSON de diff");
        assertTrue(detalle.has("nombre"), "El diff debe incluir el campo cambiado 'nombre'");
        assertEquals("Producto Instrumentado", detalle.get("nombre").get("antes").asText());
        assertEquals("Producto Instrumentado Renombrado", detalle.get("nombre").get("despues").asText());

        assertTrue(detalle.has("precioCompra"), "El diff debe incluir el campo cambiado 'precioCompra'");
        assertEquals(0, new BigDecimal("10").compareTo(detalle.get("precioCompra").get("antes").decimalValue()));
        assertEquals(0, new BigDecimal("12").compareTo(detalle.get("precioCompra").get("despues").decimalValue()));

        assertFalse(detalle.has("activo"), "El diff NO debe incluir campos sin cambios (activo)");
        assertFalse(detalle.has("descripcion"), "El diff NO debe incluir campos nulos sin cambios");
    }

    @Test
    void crearMovimiento_registraFilaMovimiento() {
        Producto producto = productoConStock(0);

        MovimientoStockDTO dto = new MovimientoStockDTO();
        dto.setProductoId(producto.getId());
        dto.setCantidad(50);
        dto.setTipo("ENTRADA");
        dto.setUsuarioId(admin.getId());

        MovimientoStock movimiento = movimientoStockService.create(dto);

        List<Auditoria> filas = auditoriaRepository
                .findByEntidadAndEntidadIdAndAccion("MOVIMIENTO", movimiento.getId(), "CREAR");
        assertEquals(1, filas.size(), "Crear movimiento debe generar 1 fila MOVIMIENTO/CREAR");
        assertEquals(admin.getId(), filas.get(0).getUsuario().getId());
    }

    @Test
    void anularVenta_registraFilaAnular() {
        Venta venta = ventaRepository.save(Venta.builder()
                .numeroFactura("FV-TEST-ANULAR")
                .estado("COMPLETADA")
                .subtotal(BigDecimal.TEN)
                .descuento(BigDecimal.ZERO)
                .iva(BigDecimal.ZERO)
                .total(BigDecimal.TEN)
                .usuario(admin)
                .build());

        ventaService.anular(venta.getId());

        List<Auditoria> filas = auditoriaRepository
                .findByEntidadAndEntidadIdAndAccion("VENTA", venta.getId(), "ANULAR");
        assertEquals(1, filas.size(), "Anular una venta debe generar 1 fila VENTA/ANULAR");
        assertEquals(admin.getId(), filas.get(0).getUsuario().getId());
    }

    @Test
    void operacionRechazadaPorStockInsuficiente_noDejaFila() {
        Producto producto = productoConStock(5);

        MovimientoStockDTO dto = new MovimientoStockDTO();
        dto.setProductoId(producto.getId());
        dto.setCantidad(99);
        dto.setTipo("SALIDA");
        dto.setUsuarioId(admin.getId());

        assertThrows(BadRequestException.class, () -> movimientoStockService.create(dto));

        List<Auditoria> filas = auditoriaRepository
                .findByEntidadAndEntidadIdAndAccion("MOVIMIENTO", producto.getId(), "CREAR");
        assertTrue(filas.isEmpty(), "Una operación rechazada (400) no debe dejar fila (R10)");
    }

    @Test
    void loginExitoso_registraAuthLoginConUsuarioExplicito() {
        AuthLoginDTO dto = new AuthLoginDTO();
        dto.setEmail("admin@ferreplus.com");
        dto.setPassword("admin123");
        authService.login(dto);

        List<Auditoria> filas = auditoriaRepository
                .findByEntidadAndEntidadIdAndAccion("AUTH", admin.getId(), "LOGIN");
        assertEquals(1, filas.size(), "Login exitoso debe generar exactamente 1 fila AUTH/LOGIN");
        assertEquals(admin.getId(), filas.get(0).getEntidadId());
        assertEquals(admin.getId(), filas.get(0).getUsuario().getId(),
                "El usuario_id debe ser el mismo usuario autenticado (actor explícito, R5)");
    }

    @Test
    void loginFallido_noRegistraFilaAuth() {
        AuthLoginDTO dto = new AuthLoginDTO();
        dto.setEmail("admin@ferreplus.com");
        dto.setPassword("incorrecta");

        assertThrows(Exception.class, () -> authService.login(dto));

        List<Auditoria> filas = auditoriaRepository
                .findByEntidadAndEntidadIdAndAccion("AUTH", admin.getId(), "LOGIN");
        assertTrue(filas.isEmpty(), "Un login fallido NO debe registrar fila AUTH (R5)");
    }

    /**
     * Fix data-loss: el form de producto no manda proveedor/categoria. Antes del fix,
     * setProveedor(null) pisaba el valor real. Con el fix (preserve-if-null), el
     * proveedor se conserva y el diff NO incluye proveedorId (no cambió).
     */
    @Test
    void actualizarProducto_sinCambiarProveedor_noRegistraProveedorIdEnDiff() throws Exception {
        // Crear producto con nombre y sin proveedor explícito
        Producto existente = productoConStock(10);

        // Simular el envío del frontend: solo cambia nombre, NO manda proveedor
        Producto cambios = new Producto();
        cambios.setNombre("Nombre Actualizado");
        cambios.setPrecioCompra(new BigDecimal("12"));
        cambios.setPrecioVenta(new BigDecimal("18"));
        cambios.setActivo(true);
        // cambios.getProveedor() es null (el form no lo envía)

        productoService.update(existente.getId(), cambios);

        // Verificar que el diff de auditoría NO contiene proveedorId
        List<Auditoria> filas = auditoriaRepository
                .findByEntidadAndEntidadIdAndAccion("PRODUCTO", existente.getId(), "ACTUALIZAR");
        assertEquals(1, filas.size());

        JsonNode detalle = new ObjectMapper().readTree(filas.get(0).getDetalle());
        assertTrue(detalle.isObject(), "El detalle debe ser un JSON de diff");
        assertTrue(detalle.has("nombre"), "El diff debe incluir el campo cambiado 'nombre'");
        assertFalse(detalle.has("proveedorId"),
                "El diff NO debe incluir proveedorId cuando no se modificó (data-loss guard)");
        assertFalse(detalle.has("categoriaId"),
                "El diff NO debe incluir categoriaId cuando no se modificó (data-loss guard)");
    }
}