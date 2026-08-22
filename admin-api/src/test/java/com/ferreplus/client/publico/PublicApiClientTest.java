package com.ferreplus.client.publico;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.*;
import static org.hamcrest.Matchers.startsWith;

import java.security.KeyPairGenerator;
import java.time.Duration;
import java.util.Base64;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;
import org.springframework.http.client.SimpleClientHttpRequestFactory;

class PublicApiClientTest {
    @Test
    void agregaJwtAsimetricoYCorrelationId() throws Exception {
        var generator = KeyPairGenerator.getInstance("RSA"); generator.initialize(2048);
        var key = generator.generateKeyPair();
        String pem = "-----BEGIN PRIVATE KEY-----\n" + Base64.getMimeEncoder(64, "\n".getBytes()).encodeToString(key.getPrivate().getEncoded()) + "\n-----END PRIVATE KEY-----";
        var properties = new S2sJwtProperties("ferreplus-admin-api", "ferreplus-public-api", "admin-api", "test-key", pem, "", Duration.ofSeconds(120), "http://public-api.test");
        var factory = new SimpleClientHttpRequestFactory(); factory.setConnectTimeout(1000); factory.setReadTimeout(3000);
        RestClient.Builder builder = RestClient.builder().requestFactory(factory).baseUrl("http://public-api.test");
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        PublicApiClient client = new PublicApiClient(builder.build(), properties);
        server.expect(requestTo("http://public-api.test/api/internal/ping"))
                .andExpect(header(HttpHeaders.AUTHORIZATION, startsWith("Bearer ")))
                .andExpect(header("X-Correlation-ID", "corr-test"))
                .andRespond(withSuccess("{\"status\":\"ok\"}", MediaType.APPLICATION_JSON));
        assertThat(client.exchange(org.springframework.http.HttpMethod.GET, "/api/internal/ping", null, Object.class, "corr-test")).isNotNull();
        server.verify();
    }

    @Test
    void traduceErroresDeDependenciaYConflicto() throws Exception {
        var generator = KeyPairGenerator.getInstance("RSA"); generator.initialize(2048);
        var key = generator.generateKeyPair();
        String pem = Base64.getEncoder().encodeToString(key.getPrivate().getEncoded());
        var properties = new S2sJwtProperties("iss", "aud", "admin-api", "kid", pem, "", Duration.ofSeconds(120), "http://public-api.test");
        RestClient.Builder builder = RestClient.builder().baseUrl("http://public-api.test"); MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        PublicApiClient client = new PublicApiClient(builder.build(), properties);
        server.expect(requestTo("http://public-api.test/api/internal/down")).andRespond(withServerError());
        assertThatThrownBy(() -> client.exchange(org.springframework.http.HttpMethod.GET, "/api/internal/down", null, Object.class, "c"))
                .isInstanceOf(PublicApiClient.PublicApiUnavailableException.class);
    }

    @Test
    void conserva404ComoErrorHttpDeDominio() throws Exception {
        var generator = KeyPairGenerator.getInstance("RSA"); generator.initialize(2048);
        var key = generator.generateKeyPair();
        var properties = new S2sJwtProperties("iss", "aud", "admin-api", "kid",
                Base64.getEncoder().encodeToString(key.getPrivate().getEncoded()), "", Duration.ofSeconds(120),
                "http://public-api.test");
        RestClient.Builder builder = RestClient.builder().baseUrl("http://public-api.test");
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        PublicApiClient client = new PublicApiClient(builder.build(), properties);
        server.expect(requestTo("http://public-api.test/api/internal/publicaciones/missing"))
                .andRespond(withStatus(org.springframework.http.HttpStatus.NOT_FOUND)
                        .contentType(MediaType.APPLICATION_PROBLEM_JSON)
                        .body("{\"status\":404,\"detail\":\"Publicacion no encontrada\"}"));

        assertThatThrownBy(() -> client.exchange(org.springframework.http.HttpMethod.GET,
                "/api/internal/publicaciones/missing", null, Object.class, "c"))
                .isInstanceOf(PublicApiClient.PublicApiHttpException.class)
                .extracting("status.value")
                .isEqualTo(404);
    }
}
