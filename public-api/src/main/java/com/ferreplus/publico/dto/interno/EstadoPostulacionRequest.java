package com.ferreplus.publico.dto.interno;

import com.ferreplus.publico.model.EstadoPostulacion;
import jakarta.validation.constraints.NotNull;

public record EstadoPostulacionRequest(@NotNull EstadoPostulacion estado) {}
