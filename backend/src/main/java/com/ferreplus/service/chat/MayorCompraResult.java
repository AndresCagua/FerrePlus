package com.ferreplus.service.chat;

import java.math.BigDecimal;
import java.time.LocalDate;

public record MayorCompraResult(
        Long id,
        String numeroFactura,
        BigDecimal total,
        String proveedorNombre,
        LocalDate fechaFactura) {
}
