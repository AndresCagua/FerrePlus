package com.ferreplus.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ferreplus.config.GeminiProperties;
import com.ferreplus.exception.GeminiException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.util.ArrayList;
import java.util.List;

@Component
@Slf4j
public class GeminiClient {

    private final RestClient restClient;
    private final GeminiProperties properties;
    private final ObjectMapper objectMapper;

    public GeminiClient(GeminiProperties properties, ObjectMapper objectMapper) {
        this.properties = properties;
        this.objectMapper = objectMapper;
        this.restClient = RestClient.builder()
                .baseUrl(properties.getBaseUrl())
                .requestFactory(requestFactory(properties.getTimeoutSeconds()))
                .build();
    }

    public float[] embed(String text) {
        JsonNode response = post("/v1beta/models/" + properties.getEmbeddingModel() + ":embedContent",
                "{\"content\":{\"parts\":[{\"text\":" + quote(text) + "}]},"
                        + "\"outputDimensionality\":768}");
        JsonNode values = response.path("embedding").path("values");
        if (!values.isArray() || values.size() != 768) {
            throw new GeminiException("Gemini devolvio un embedding con dimensiones invalidas", 502);
        }
        float[] embedding = new float[values.size()];
        for (int index = 0; index < values.size(); index++) {
            embedding[index] = values.get(index).floatValue();
        }
        return embedding;
    }

    public String generate(String prompt) {
        JsonNode response = post("/v1beta/models/" + properties.getChatModel() + ":generateContent",
                "{\"contents\":[{\"parts\":[{\"text\":" + quote(prompt) + "}]}]}");
        JsonNode text = response.path("candidates").path(0).path("content").path("parts").path(0).path("text");
        if (!text.isTextual() || text.asText().isBlank()) {
            throw new GeminiException("Gemini devolvio una respuesta vacia", 502);
        }
        return text.asText();
    }

    private JsonNode post(String path, String body) {
        if (properties.getApiKey() == null || properties.getApiKey().isBlank()) {
            throw new GeminiException("La integracion con Gemini no esta configurada", 503);
        }
        int attempts = Math.max(1, properties.getMaxRetries() + 1);
        for (int attempt = 1; attempt <= attempts; attempt++) {
            try {
                String response = restClient.post()
                        .uri(uriBuilder -> uriBuilder.path(path).queryParam("key", properties.getApiKey()).build())
                        .body(body)
                        .retrieve()
                        .onStatus(HttpStatusCode::isError, (request, clientResponse) -> {
                            throw new GeminiException("Gemini rechazo la solicitud", clientResponse.getStatusCode().value());
                        })
                        .body(String.class);
                return objectMapper.readTree(response);
            } catch (GeminiException exception) {
                if (attempt == attempts || !isTransient(exception.getStatusCode())) {
                    throw exception;
                }
            } catch (RestClientException exception) {
                if (attempt == attempts) {
                    throw new GeminiException("Gemini no esta disponible", 503, exception);
                }
            } catch (Exception exception) {
                throw new GeminiException("Respuesta invalida de Gemini", 502, exception);
            }
        }
        throw new GeminiException("Gemini no esta disponible", 503);
    }

    private boolean isTransient(int statusCode) {
        return statusCode == 429 || statusCode >= 500;
    }

    private String quote(String value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception exception) {
            throw new GeminiException("No se pudo preparar la solicitud a Gemini", 500, exception);
        }
    }

    private SimpleClientHttpRequestFactory requestFactory(int timeoutSeconds) {
        int timeoutMillis = Math.max(1, timeoutSeconds) * 1_000;
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(timeoutMillis);
        factory.setReadTimeout(timeoutMillis);
        return factory;
    }
}
