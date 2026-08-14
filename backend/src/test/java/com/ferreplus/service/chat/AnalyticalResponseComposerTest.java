package com.ferreplus.service.chat;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

class AnalyticalResponseComposerTest {
    private final AnalyticalResponseComposer composer = new AnalyticalResponseComposer();

    @Test
    void composesMostExpensivePurchaseAndEmptyResult() {
        MayorCompraResult result = new MayorCompraResult(1L, "F-1", new BigDecimal("125.50"),
                "Acme", LocalDate.of(2026, 8, 14));

        assertThat(composer.composeMayorCompra(Optional.of(result)))
                .isEqualTo("La compra mas cara fue la factura F-1 de Acme por 125.50 el 2026-08-14.");
        assertThat(composer.composeMayorCompra(Optional.empty()))
                .isEqualTo("No se encontraron compras completadas.");
    }

    @Test
    void composesLargestExpenseAndEmptyResult() {
        MayorGastoResult result = new MayorGastoResult(1L, "Arriendo", new BigDecimal("500.00"),
                LocalDate.of(2026, 8, 14));

        assertThat(composer.composeMayorGasto(Optional.of(result)))
                .isEqualTo("El mayor gasto fue Arriendo por 500.00 el 2026-08-14.");
        assertThat(composer.composeMayorGasto(Optional.empty()))
                .isEqualTo("No se encontraron gastos registrados.");
    }

    @Test
    void composesTopProviderAndEmptyResult() {
        ProveedorTopResult result = new ProveedorTopResult(1L, "Acme", new BigDecimal("1200.00"));

        assertThat(composer.composeProveedorTop(Optional.of(result)))
                .isEqualTo("El proveedor al que mas se le ha comprado es Acme con 1200.00 acumulados.");
        assertThat(composer.composeProveedorTop(Optional.empty()))
                .isEqualTo("No se encontraron compras registradas.");
    }
}
