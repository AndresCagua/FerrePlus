package com.ferreplus.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CambioPasswordDTO {

    @NotBlank
    private String passwordActual;

    @NotBlank
    private String nuevoPassword;
}
