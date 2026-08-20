package com.ferreplus.service.chat;

import com.ferreplus.entity.Auditoria;
import com.ferreplus.entity.Compra;
import com.ferreplus.entity.DetalleVenta;
import com.ferreplus.entity.Gasto;
import com.ferreplus.entity.Producto;
import com.ferreplus.entity.Proveedor;
import com.ferreplus.entity.Rol;
import com.ferreplus.entity.Usuario;
import com.ferreplus.entity.Venta;
import com.ferreplus.repository.AuditoriaRepository;
import com.ferreplus.repository.CompraRepository;
import com.ferreplus.repository.DetalleVentaRepository;
import com.ferreplus.repository.GastoRepository;
import com.ferreplus.repository.ProductoRepository;
import com.ferreplus.repository.ProveedorRepository;
import com.ferreplus.repository.RolRepository;
import com.ferreplus.repository.UsuarioRepository;
import com.ferreplus.repository.VentaRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class ChatAnalyticalIntegrationTest {
    @Autowired private AnalyticalChatService analyticalChatService;
    @Autowired private ProductoRepository productoRepository;
    @Autowired private VentaRepository ventaRepository;
    @Autowired private DetalleVentaRepository detalleVentaRepository;
    @Autowired private AuditoriaRepository auditoriaRepository;
    @Autowired private CompraRepository compraRepository;
    @Autowired private GastoRepository gastoRepository;
    @Autowired private ProveedorRepository proveedorRepository;
    @Autowired private UsuarioRepository usuarioRepository;
    @Autowired private RolRepository rolRepository;

    private Producto firstProduct;
    private Producto secondProduct;
    private Usuario testUser;
    private Venta completedSale;
    private Venta cancelledSale;
    private Auditoria audit;
    private Proveedor firstSupplier;
    private Proveedor secondSupplier;
    private final List<Compra> purchases = new java.util.ArrayList<>();
    private final List<Gasto> expenses = new java.util.ArrayList<>();

    @BeforeEach
    void setUp() {
        Rol role = rolRepository.findByNombre("ADMIN").orElseGet(
                () -> rolRepository.findAll().stream().findFirst().orElseThrow());
        testUser = usuarioRepository.save(Usuario.builder()
                .nombre("Chat Analytics Test User")
                .email("chat-analytics-test@ferreplus.local")
                .password("encoded")
                .rol(role)
                .activo(true)
                .build());
        firstProduct = productoRepository.save(Producto.builder()
                .nombre("Chat Analytics Product One")
                .stockActual(1).stockMinimo(5).stockMaximo(20)
                .precioCompra(new BigDecimal("5.00")).precioVenta(new BigDecimal("10.00"))
                .activo(true).build());
        secondProduct = productoRepository.save(Producto.builder()
                .nombre("Chat Analytics Product Two")
                .stockActual(10).stockMinimo(2).stockMaximo(20)
                .precioCompra(new BigDecimal("6.00")).precioVenta(new BigDecimal("12.00"))
                .activo(true).build());

        completedSale = saveSale("CHAT-ANALYTICS-COMPLETED", "COMPLETADA", new BigDecimal("100.00"));
        cancelledSale = saveSale("CHAT-ANALYTICS-CANCELLED", "ANULADA", new BigDecimal("900.00"));
        detalleVentaRepository.saveAll(List.of(
                detail(completedSale, firstProduct, 5), detail(completedSale, secondProduct, 2),
                detail(cancelledSale, firstProduct, 100)));

        audit = auditoriaRepository.save(Auditoria.builder()
                .entidad("PRODUCTO").entidadId(firstProduct.getId())
                .accion("ACTUALIZAR").detalle("Cambio de stock de prueba").build());

        firstSupplier = proveedorRepository.save(Proveedor.builder()
                .nombre("Chat Analytics Supplier One").activo(true).build());
        secondSupplier = proveedorRepository.save(Proveedor.builder()
                .nombre("Chat Analytics Supplier Two").activo(true).build());

        purchases.add(savePurchase("CHAT-ANALYTICS-P-900", firstSupplier, "COMPLETADA",
                new BigDecimal("900.00"), LocalDate.of(2024, 3, 10)));
        purchases.add(savePurchase("CHAT-ANALYTICS-P-100", firstSupplier, "COMPLETADA",
                new BigDecimal("100.00"), LocalDate.of(2024, 2, 10)));
        purchases.add(savePurchase("CHAT-ANALYTICS-P-600", secondSupplier, "COMPLETADA",
                new BigDecimal("600.00"), LocalDate.of(2024, 3, 11)));
        purchases.add(savePurchase("CHAT-ANALYTICS-P-400", secondSupplier, "COMPLETADA",
                new BigDecimal("400.00"), LocalDate.of(2024, 3, 12)));
        purchases.add(savePurchase("CHAT-ANALYTICS-P-2000", firstSupplier, "ANULADA",
                new BigDecimal("2000.00"), LocalDate.of(2024, 3, 13)));
        purchases.add(savePurchase("CHAT-ANALYTICS-P-1900", secondSupplier, "PENDIENTE",
                new BigDecimal("1900.00"), LocalDate.of(2024, 3, 14)));
        purchases.add(savePurchase("CHAT-ANALYTICS-P-TIE-1", firstSupplier, "COMPLETADA",
                new BigDecimal("500.00"), LocalDate.of(2024, 4, 1)));
        purchases.add(savePurchase("CHAT-ANALYTICS-P-TIE-2", secondSupplier, "COMPLETADA",
                new BigDecimal("500.00"), LocalDate.of(2024, 4, 2)));

        expenses.add(saveExpense("Gasto histórico", new BigDecimal("1000.00"), LocalDate.of(2024, 2, 5)));
        expenses.add(saveExpense("Gasto de marzo", new BigDecimal("800.00"), LocalDate.of(2024, 3, 5)));
        expenses.add(saveExpense("Gasto empate uno", new BigDecimal("700.00"), LocalDate.of(2024, 4, 1)));
        expenses.add(saveExpense("Gasto empate dos", new BigDecimal("700.00"), LocalDate.of(2024, 4, 2)));
    }

    @AfterEach
    void tearDown() {
        if (audit != null) auditoriaRepository.deleteById(audit.getId());
        expenses.forEach(expense -> gastoRepository.deleteById(expense.getId()));
        purchases.forEach(purchase -> compraRepository.deleteById(purchase.getId()));
        if (firstSupplier != null) proveedorRepository.deleteById(firstSupplier.getId());
        if (secondSupplier != null) proveedorRepository.deleteById(secondSupplier.getId());
        if (completedSale != null) detalleVentaRepository.deleteAll(detalleVentaRepository.findByVentaId(completedSale.getId()));
        if (cancelledSale != null) detalleVentaRepository.deleteAll(detalleVentaRepository.findByVentaId(cancelledSale.getId()));
        if (completedSale != null) ventaRepository.deleteById(completedSale.getId());
        if (cancelledSale != null) ventaRepository.deleteById(cancelledSale.getId());
        if (firstProduct != null) productoRepository.deleteById(firstProduct.getId());
        if (secondProduct != null) productoRepository.deleteById(secondProduct.getId());
        if (testUser != null) usuarioRepository.deleteById(testUser.getId());
        expenses.clear();
        purchases.clear();
    }

    @Test
    void analyticalQueriesUseRealPostgresDataAndTypedResults() {
        DateRange range = new DateRange(LocalDate.now(), LocalDate.now());
        ValidatedChatParameters parameters = new ValidatedChatParameters(Optional.of(range), 2);

        assertThat(analyticalChatService.productosMasVendidos(parameters))
                .extracting(ProductoMasVendidoResult::nombre)
                .containsExactly("Chat Analytics Product One", "Chat Analytics Product Two");
        assertThat(analyticalChatService.ventasMes(parameters).totalCompletadas())
                .isEqualByComparingTo("100.00");
        assertThat(analyticalChatService.stockBajo(parameters))
                .extracting(StockBajoResult::nombre)
                .contains("Chat Analytics Product One");

        assertThat(analyticalChatService.ultimoCambio(
                ChatEntity.PRODUCTO, Optional.of("Chat Analytics Product One")))
                .get().extracting(UltimoCambioResult::entidadId).isEqualTo(firstProduct.getId());
        assertThat(analyticalChatService.ultimoCambio(ChatEntity.PRODUCTO, Optional.empty()))
                .get().extracting(UltimoCambioResult::entidadId).isEqualTo(firstProduct.getId());
        assertThat(analyticalChatService.ultimoCambio(ChatEntity.VENTA, Optional.of("x"))).isEmpty();
    }

    @Test
    void resolvesPurchaseExpenseAndSupplierAnalyticsWithRealPostgres() {
        ValidatedChatParameters noRange = new ValidatedChatParameters(Optional.empty(), 10);
        ValidatedChatParameters march = new ValidatedChatParameters(Optional.of(
                new DateRange(LocalDate.of(2024, 3, 1), LocalDate.of(2024, 3, 31))), 10);
        ValidatedChatParameters april = new ValidatedChatParameters(Optional.of(
                new DateRange(LocalDate.of(2024, 4, 1), LocalDate.of(2024, 4, 30))), 10);
        ValidatedChatParameters noData = new ValidatedChatParameters(Optional.of(
                new DateRange(LocalDate.of(2030, 1, 1), LocalDate.of(2030, 1, 31))), 10);

        assertThat(analyticalChatService.compraMasCara(noRange)).get()
                .extracting(MayorCompraResult::numeroFactura).isEqualTo("CHAT-ANALYTICS-P-900");
        assertThat(analyticalChatService.compraMasCara(march)).get()
                .extracting(MayorCompraResult::numeroFactura).isEqualTo("CHAT-ANALYTICS-P-900");
        assertThat(analyticalChatService.compraMasCara(april)).get()
                .extracting(MayorCompraResult::numeroFactura).isEqualTo("CHAT-ANALYTICS-P-TIE-1");
        assertThat(analyticalChatService.compraMasCara(noData)).isEmpty();

        assertThat(analyticalChatService.mayorGasto(noRange)).get()
                .extracting(MayorGastoResult::descripcion).isEqualTo("Gasto histórico");
        assertThat(analyticalChatService.mayorGasto(march)).get()
                .extracting(MayorGastoResult::descripcion).isEqualTo("Gasto de marzo");
        assertThat(analyticalChatService.mayorGasto(april)).get()
                .extracting(MayorGastoResult::descripcion).isEqualTo("Gasto empate uno");
        assertThat(analyticalChatService.mayorGasto(noData)).isEmpty();

        assertThat(analyticalChatService.proveedorTop(noRange)).get()
                .extracting(ProveedorTopResult::proveedorId).isEqualTo(firstSupplier.getId());
        assertThat(analyticalChatService.proveedorTop(march)).get()
                .extracting(ProveedorTopResult::proveedorId).isEqualTo(secondSupplier.getId());
        assertThat(analyticalChatService.proveedorTop(april)).get()
                .extracting(ProveedorTopResult::proveedorId).isEqualTo(firstSupplier.getId());
        assertThat(analyticalChatService.proveedorTop(noData)).isEmpty();
    }

    private Venta saveSale(String invoice, String state, BigDecimal total) {
        return ventaRepository.saveAndFlush(Venta.builder()
                .numeroFactura(invoice).usuario(testUser).estado(state)
                .subtotal(total).iva(BigDecimal.ZERO).descuento(BigDecimal.ZERO).total(total)
                .metodoPago("EFECTIVO").build());
    }

    private DetalleVenta detail(Venta sale, Producto product, int quantity) {
        return DetalleVenta.builder().venta(sale).producto(product).cantidad(quantity)
                .precioUnitario(product.getPrecioVenta())
                .subtotal(product.getPrecioVenta().multiply(BigDecimal.valueOf(quantity))).build();
    }

    private Compra savePurchase(String invoice, Proveedor supplier, String state,
                                BigDecimal total, LocalDate invoiceDate) {
        return compraRepository.saveAndFlush(Compra.builder()
                .numeroFactura(invoice).proveedor(supplier).usuario(testUser).estado(state)
                .subtotal(total).iva(BigDecimal.ZERO).descuento(BigDecimal.ZERO).total(total)
                .fechaFactura(invoiceDate).build());
    }

    private Gasto saveExpense(String description, BigDecimal amount, LocalDate expenseDate) {
        return gastoRepository.saveAndFlush(Gasto.builder()
                .descripcion(description).monto(amount).fechaGasto(expenseDate).usuario(testUser).build());
    }
}
