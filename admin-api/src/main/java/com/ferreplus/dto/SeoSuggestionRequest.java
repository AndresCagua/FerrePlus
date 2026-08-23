package com.ferreplus.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record SeoSuggestionRequest(
        @NotBlank(message = "El titulo es obligatorio")
        @Size(max = 200, message = "El titulo no puede superar 200 caracteres")
        String titulo,
        @Size(max = 500, message = "El resumen no puede superar 500 caracteres")
        String resumen,
        @Size(max = 5_000, message = "La descripcion no puede superar 5000 caracteres")
        String descripcion) {
}
