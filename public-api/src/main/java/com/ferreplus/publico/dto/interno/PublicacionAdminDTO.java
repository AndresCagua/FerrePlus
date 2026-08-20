package com.ferreplus.publico.dto.interno;

import com.ferreplus.publico.model.EstadoPublicacion;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record PublicacionAdminDTO(@NotBlank String titulo, @NotBlank String slug,
        @NotNull EstadoPublicacion estado) {}
