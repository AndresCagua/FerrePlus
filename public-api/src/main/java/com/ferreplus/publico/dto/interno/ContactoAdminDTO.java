package com.ferreplus.publico.dto.interno;

import com.ferreplus.publico.model.Contacto.EstadoContacto;
import jakarta.validation.constraints.NotNull;

public record ContactoAdminDTO(String id, String nombre, String email, String asunto, String mensaje,
        @NotNull EstadoContacto estado) {}
