package com.ferreplus.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ChatRequest(
        @NotBlank(message = "La pregunta es obligatoria")
        @Size(max = 1000, message = "La pregunta no puede superar los 1000 caracteres")
        String question,
        String conversationId
) {
}
