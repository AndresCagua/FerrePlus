package com.ferreplus.service.chat;

import java.math.BigDecimal;

public record ProveedorTopResult(
        Long proveedorId,
        String proveedorNombre,
        BigDecimal totalAcumulado) {
}
