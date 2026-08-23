package com.ferreplus.service.seo;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ferreplus.client.GeminiClient;
import com.ferreplus.dto.SeoSuggestionRequest;
import com.ferreplus.exception.SeoSuggestionException;
import com.ferreplus.exception.GeminiException;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class SeoSuggestionServiceTest {
    private final GeminiClient client = mock(GeminiClient.class);
    private final SeoSuggestionService service = new SeoSuggestionService(client, new ObjectMapper());

    @Test
    void generaSugerenciaYEnviaSoloLosCamposPermitidos() {
        when(client.generate(argThat(prompt -> prompt.contains("Titulo seguro")
                && prompt.contains("Resumen breve") && prompt.contains("Descripcion limitada")
                && !prompt.contains("apiKey"))))
                .thenReturn("{\"title\":\"Titulo SEO\",\"description\":\"Descripcion SEO\"}");

        var result = service.suggest(new SeoSuggestionRequest("Titulo seguro", "Resumen breve", "Descripcion limitada"));

        assertThat(result.title()).isEqualTo("Titulo SEO");
        assertThat(result.description()).isEqualTo("Descripcion SEO");
        verify(client).generate(argThat(prompt -> prompt.contains("Titulo seguro")));
    }

    @Test
    void rechazaRespuestaIncompleta() {
        when(client.generate(org.mockito.ArgumentMatchers.anyString()))
                .thenReturn("{\"title\":\"Solo titulo\"}");

        assertThatThrownBy(() -> service.suggest(new SeoSuggestionRequest("Titulo", null, null)))
                .isInstanceOf(SeoSuggestionException.class)
                .extracting("statusCode").isEqualTo(502);
    }

    @Test
    void transformaFallaDelProveedorEnError503() {
        when(client.generate(org.mockito.ArgumentMatchers.anyString()))
                .thenThrow(new GeminiException("timeout interno", 503));

        assertThatThrownBy(() -> service.suggest(new SeoSuggestionRequest("Titulo", null, null)))
                .isInstanceOf(SeoSuggestionException.class)
                .extracting("statusCode").isEqualTo(503);
    }
}
