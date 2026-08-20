package com.ferreplus.publico.dto.interno;

import com.ferreplus.publico.model.EstadoPostulacion;
import jakarta.validation.constraints.NotNull;

public record PostulacionAdminDTO(String id, String convocatoriaId, String nombres, String apellidos,
        String email, @NotNull EstadoPostulacion estado) {}
