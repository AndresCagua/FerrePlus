package com.ferreplus.publico.dto.publico;

import com.ferreplus.publico.model.EstadoPostulacion;
import java.time.Instant;

public record PostulacionPublicaDTO(String id, String convocatoriaId, EstadoPostulacion estado, Instant createdAt) {}
