package com.ferreplus.publico.dto.interno;

import static org.assertj.core.api.Assertions.assertThat;

import com.ferreplus.publico.model.EstadoConvocatoria;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;

class ConvocatoriaAdminDTOTest {
    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void validatesRequiredJobFields() {
        ConvocatoriaAdminDTO dto = new ConvocatoriaAdminDTO("", "", List.of(" "), "", "", null, null,
                EstadoConvocatoria.DRAFT);

        assertThat(validator.validate(dto)).extracting(error -> error.getPropertyPath().toString())
                .contains("titulo", "descripcion", "requisitos", "ubicacion", "modalidad", "fechaApertura", "fechaCierre");
    }

    @Test
    void acceptsCompletePayload() {
        ConvocatoriaAdminDTO dto = new ConvocatoriaAdminDTO("Titulo", "Descripcion", List.of("Experiencia"),
                "Bogota", "Hibrida", Instant.parse("2026-08-20T10:00:00Z"),
                Instant.parse("2026-08-20T11:00:00Z"), EstadoConvocatoria.DRAFT);

        assertThat(validator.validate(dto)).isEmpty();
    }
}
