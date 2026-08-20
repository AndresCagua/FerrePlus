package com.ferreplus.publico.dto.publico;

import java.time.Instant;
import java.util.List;

public record ConvocatoriaPublicaDTO(String id, String titulo, String descripcion,
        List<String> requisitos, String ubicacion, String modalidad,
        Instant fechaApertura, Instant fechaCierre) {}
