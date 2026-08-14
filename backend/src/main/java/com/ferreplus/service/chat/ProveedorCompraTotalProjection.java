package com.ferreplus.service.chat;

import java.math.BigDecimal;

public interface ProveedorCompraTotalProjection {
    Long getProveedorId();

    String getProveedorNombre();

    BigDecimal getTotalAcumulado();
}
