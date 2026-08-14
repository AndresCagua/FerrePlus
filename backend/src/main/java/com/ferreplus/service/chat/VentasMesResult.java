package com.ferreplus.service.chat;

import java.math.BigDecimal;
import java.time.LocalDate;

public record VentasMesResult(LocalDate from, LocalDate to, BigDecimal totalCompletadas) {
}
