package com.ferreplus.publico.dto.interno;

import com.ferreplus.publico.model.EstadoConvocatoria;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

public record ConvocatoriaAdminDTO(@NotBlank String titulo, @NotBlank String descripcion,
        @NotNull Instant fechaApertura, @NotNull Instant fechaCierre, @NotNull EstadoConvocatoria estado) {}
