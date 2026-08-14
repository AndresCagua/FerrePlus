package com.ferreplus.service.chat;

import java.time.LocalDateTime;

public record UltimoCambioResult(
        String entidad,
        Long entidadId,
        String accion,
        LocalDateTime fecha,
        String usuarioNombre,
        String detalle) {
}
