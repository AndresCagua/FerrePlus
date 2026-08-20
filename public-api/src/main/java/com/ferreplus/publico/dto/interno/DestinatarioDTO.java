package com.ferreplus.publico.dto.interno;

import com.ferreplus.publico.model.TipoDestinatario;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record DestinatarioDTO(String id, @NotNull TipoDestinatario tipo,
        @NotBlank @Email String email, boolean activo) {}
