package com.ferreplus.publico.service;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;

import com.ferreplus.publico.config.CaptchaProperties;
import com.ferreplus.publico.exception.PublicApiException;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

class CaptchaVerificationServiceTest {
    private static final String URL = "https://captcha.test/verify";

    @Test void tokenValidoEsAceptado() {
        RestClient.Builder builder = RestClient.builder();
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        RestClient client = builder.build();
        server.expect(requestTo(URL)).andRespond(withSuccess("{\"success\":true}", MediaType.APPLICATION_JSON));
        new CaptchaVerificationService(new CaptchaProperties(true, "secret", "site", URL, Duration.ofSeconds(1)),
                new MockEnvironment().withProperty("spring.profiles.active", "test"), client).verify("valid");
        server.verify();
    }

    @Test void deshabilitadoAceptaTokenAusenteSinContactarProveedor() {
        CaptchaVerificationService service = new CaptchaVerificationService(
                new CaptchaProperties(false, "", "", URL, Duration.ofSeconds(1)),
                new MockEnvironment().withProperty("spring.profiles.active", "test"), RestClient.builder().build());
        service.verify(null);
    }

    @Test void tokenInvalidoSeRechazaSinPersistencia() {
        RestClient.Builder builder = RestClient.builder();
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        RestClient client = builder.build();
        server.expect(requestTo(URL)).andRespond(withSuccess("{\"success\":false}", MediaType.APPLICATION_JSON));
        assertThatThrownBy(() -> new CaptchaVerificationService(new CaptchaProperties(true, "secret", "site", URL, Duration.ofSeconds(1)),
                new MockEnvironment().withProperty("spring.profiles.active", "test"), client).verify("expired"))
                .isInstanceOf(PublicApiException.class).hasMessageContaining("invalido");
    }

    @Test void falloDelProveedorEs503() {
        RestClient.Builder builder = RestClient.builder();
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        RestClient client = builder.build();
        server.expect(requestTo(URL)).andRespond(withServerError());
        assertThatThrownBy(() -> new CaptchaVerificationService(new CaptchaProperties(true, "secret", "site", URL, Duration.ofSeconds(1)),
                new MockEnvironment().withProperty("spring.profiles.active", "test"), client).verify("valid"))
                .isInstanceOf(PublicApiException.class).hasMessageContaining("no disponible");
    }

    @Test void prodSinConfiguracionFallaCerrado() {
        assertThatThrownBy(() -> new CaptchaVerificationService(new CaptchaProperties(false, "", "site", URL, Duration.ofSeconds(1)),
                new MockEnvironment().withProperty("spring.profiles.active", "prod"), RestClient.builder().build()))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test void prodSinSiteKeyFallaCerrado() {
        assertThatThrownBy(() -> new CaptchaVerificationService(new CaptchaProperties(true, "secret", "", URL, Duration.ofSeconds(1)),
                new MockEnvironment().withProperty("spring.profiles.active", "prod"), RestClient.builder().build()))
                .isInstanceOf(IllegalStateException.class);
    }
}
