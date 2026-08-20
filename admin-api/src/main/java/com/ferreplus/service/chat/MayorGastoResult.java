package com.ferreplus.service.chat;

import java.math.BigDecimal;
import java.time.LocalDate;

public record MayorGastoResult(
        Long id,
        String descripcion,
        BigDecimal monto,
        LocalDate fechaGasto) {
}
