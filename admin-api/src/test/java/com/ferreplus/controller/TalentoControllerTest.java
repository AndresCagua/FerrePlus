package com.ferreplus.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ferreplus.client.publico.PublicApiClient;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;

class TalentoControllerTest {
    @Test
    void conservaYCodificaLosFiltrosDelListado() {
        PublicApiClient client = mock(PublicApiClient.class);
        TalentoController controller = new TalentoController(client);
        HttpServletRequest request = mock(HttpServletRequest.class);
        org.mockito.Mockito.when(request.getParameterMap()).thenReturn(Map.of(
                "convocatoriaId", new String[] {"id/with space"},
                "estado", new String[] {"RECEIVED"}));

        controller.list("postulaciones", request);

        verify(client).exchange(eq(HttpMethod.GET), org.mockito.ArgumentMatchers.argThat(path ->
                        path.startsWith("/api/internal/postulaciones?")
                                && path.contains("convocatoriaId=id/with%20space")
                                && path.contains("estado=RECEIVED")),
                eq(null), eq(JsonNode.class), eq(null));
        assertThat(request.getParameterMap()).containsKey("convocatoriaId");
    }

    @Test
    void reenviaLaTransicionComoPatchAlPublicApi() throws Exception {
        PublicApiClient client = mock(PublicApiClient.class);
        TalentoController controller = new TalentoController(client);
        HttpServletRequest request = mock(HttpServletRequest.class);
        JsonNode body = new ObjectMapper().readTree("{\"estado\":\"PUBLICADA\"}");

        controller.state("publicaciones", "abc", body, request);

        verify(client).exchange(eq(HttpMethod.PATCH), eq("/api/internal/publicaciones/abc"),
                eq(body), eq(JsonNode.class), eq(null));
    }
}
