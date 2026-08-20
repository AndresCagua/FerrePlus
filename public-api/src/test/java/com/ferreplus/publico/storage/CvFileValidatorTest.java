package com.ferreplus.publico.storage;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.assertThat;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

class CvFileValidatorTest {
    private final CvFileValidator validator = new CvFileValidator();

    @Test void validaPdfPorMagicBytes() {
        var result = validator.validate(new MockMultipartFile("cv", "perfil.pdf", "application/pdf", "%PDF-1.7".getBytes(StandardCharsets.US_ASCII)));
        assertThat(result.mimeType()).isEqualTo("application/pdf");
    }
    @Test void rechazaXlsxExplicitamente() {
        assertThatThrownBy(() -> validator.validate(new MockMultipartFile("cv", "perfil.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", new byte[] {'P','K',3,4})))
                .isInstanceOf(CvValidationException.class).hasMessageContaining("Extension de CV no permitida");
    }
    @Test void rechazaArchivoMayorA5Mb() {
        assertThatThrownBy(() -> validator.validate(new MockMultipartFile("cv", "perfil.pdf", "application/pdf", new byte[(int) CvFileValidator.MAX_SIZE + 1])))
                .isInstanceOf(CvValidationException.class).hasMessageContaining("5 MB");
    }
    @Test void rechazaMimeFalso() {
        assertThatThrownBy(() -> validator.validate(new MockMultipartFile("cv", "perfil.pdf", "application/pdf", "not-a-pdf".getBytes(StandardCharsets.US_ASCII))))
                .isInstanceOf(CvValidationException.class).hasMessageContaining("contenido real");
    }
}
