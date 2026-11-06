package com.ferreplus.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ferreplus.config.TypeSafeProperties;
import com.ferreplus.exception.TypeSafeException;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
public class TypeSafeClient {
    private final RestClient restClient;
    private final TypeSafeProperties properties;
    private final ObjectMapper objectMapper;

    public TypeSafeClient(TypeSafeProperties properties, ObjectMapper objectMapper) {
        this.properties = properties;
        this.objectMapper = objectMapper;
        this.restClient = RestClient.builder()
                .baseUrl(properties.getBaseUrl())
                .requestFactory(requestFactory(properties.getTimeoutSeconds()))
                .build();
    }

    public String classify(String question) {
        String body = requestBody(question);
        JsonNode response = post("/v1/systemone", body);
        JsonNode answer = response.path("answers").path("intent");
        String choice = answer.path("choice").asText("");
        if (choice.isBlank()) {
            throw new TypeSafeException("TypeSafe devolvio una clasificacion vacia", 502);
        }
        return choice;
    }

    private JsonNode post(String path, String body) {
        if (properties.getApiKey() == null || properties.getApiKey().isBlank()) {
            throw new TypeSafeException("La integracion con TypeSafe no esta configurada", 503);
        }
        int attempts = Math.max(1, properties.getMaxRetries() + 1);
        for (int attempt = 1; attempt <= attempts; attempt++) {
            try {
                String response = restClient.post()
                        .uri(path)
                        .header("Authorization", "Bearer " + properties.getApiKey())
                        .header("Content-Type", "application/json")
                        .body(body)
                        .retrieve()
                        .onStatus(HttpStatusCode::isError, (request, clientResponse) -> {
                            throw new TypeSafeException("TypeSafe rechazo la solicitud", clientResponse.getStatusCode().value());
                        })
                        .body(String.class);
                return objectMapper.readTree(response);
            } catch (TypeSafeException exception) {
                if (attempt == attempts || !isTransient(exception.getStatusCode())) throw exception;
            } catch (RestClientException exception) {
                if (attempt == attempts) throw new TypeSafeException("TypeSafe no esta disponible", 503, exception);
            } catch (Exception exception) {
                throw new TypeSafeException("Respuesta invalida de TypeSafe", 502, exception);
            }
        }
        throw new TypeSafeException("TypeSafe no esta disponible", 503);
    }

    private String requestBody(String question) {
        try {
            var root = objectMapper.createObjectNode();
            root.put("model", properties.getModel());
            root.put("state", question);
            var questions = root.putObject("questions");
            var intent = questions.putObject("intent");
            intent.put("type", "choice");
            intent.put("instructions", "Selecciona la intencion que corresponde a la pregunta de negocio.");
            var criteria = intent.putObject("criteria");
            criteria.put("mas_vendidos", "Consulta cuales son los productos mas vendidos.");
            criteria.put("ventas_mes", "Consulta las ventas de un mes o periodo.");
            criteria.put("stock_bajo", "Consulta productos con stock bajo.");
            criteria.put("mayor_compra", "Consulta la compra de mayor monto.");
            criteria.put("mayor_gasto", "Consulta el gasto de mayor monto.");
            criteria.put("proveedor_top", "Consulta el proveedor al que mas se le compro.");
            criteria.put("guia_catalogo", "Pregunta como usar el sistema o consulta el catalogo/documentacion.");
            criteria.put("ultimo_cambio", "Pregunta por el ultimo cambio o modificacion de una entidad.");
            criteria.put("desconocido", "No coincide claramente con ninguna intencion o pide modificar datos.");
            return objectMapper.writeValueAsString(root);
        } catch (Exception exception) {
            throw new TypeSafeException("No se pudo preparar la solicitud a TypeSafe", 500, exception);
        }
    }

    private boolean isTransient(int statusCode) {
        return statusCode == 429 || statusCode >= 500;
    }

    private SimpleClientHttpRequestFactory requestFactory(int timeoutSeconds) {
        int timeoutMillis = Math.max(1, timeoutSeconds) * 1_000;
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(timeoutMillis);
        factory.setReadTimeout(timeoutMillis);
        return factory;
    }
}
