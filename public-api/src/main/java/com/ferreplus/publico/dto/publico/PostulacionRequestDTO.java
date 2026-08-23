package com.ferreplus.publico.dto.publico;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record PostulacionRequestDTO(@NotBlank @Size(max = 100) String nombres,
        @NotBlank @Size(max = 100) String apellidos, @NotBlank @Email @Size(max = 254) String email,
        @NotBlank @Size(max = 30) String telefono, @NotBlank @Size(max = 100) String ciudad,
        @Size(max = 100) String honeypot, @Size(max = 4096) String captchaToken) {}
