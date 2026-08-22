package com.ferreplus.publico.dto.publico;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ContactoRequestDTO(@NotBlank @Size(max = 150) String nombre,
        @NotBlank @Email @Size(max = 254) String email, @Size(max = 30) String telefono,
        @NotBlank @Size(max = 150) String asunto, @NotBlank @Size(max = 5000) String mensaje,
        @Size(max = 100) String honeypot, @Size(max = 4096) String captchaToken) {}
