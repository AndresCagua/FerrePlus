package com.ferreplus.exception;

import static org.assertj.core.api.Assertions.assertThat;

import com.ferreplus.client.publico.PublicApiClient;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class GlobalExceptionHandlerTest {
    @Test
    void convierteValidacionDeEnlaceXEnRespuestaAmigableSinDetalleInterno() {
        String message = "El enlace de X no es valido. Usa una URL de x.com o twitter.com.";
        var exception = new PublicApiClient.PublicApiValidationException(
                "detalle interno ignorado", new IllegalStateException("secret-host stacktrace"),
                Map.of("enlacesX", message));

        var response = new GlobalExceptionHandler().handlePublicApiValidation(exception);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).containsEntry("detail", message)
                .containsEntry("errors", Map.of("enlacesX", message));
        assertThat(response.getBody().toString()).doesNotContain("secret-host");
    }
}
