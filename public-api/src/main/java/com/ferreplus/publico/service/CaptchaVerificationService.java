package com.ferreplus.publico.service;

import com.ferreplus.publico.config.CaptchaProperties;
import com.ferreplus.publico.exception.PublicApiException;
import java.time.Duration;
import java.util.Map;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
@EnableConfigurationProperties(CaptchaProperties.class)
public class CaptchaVerificationService {
    private static final Logger LOG = LoggerFactory.getLogger(CaptchaVerificationService.class);
    private final CaptchaProperties properties;
    private final RestClient client;

    @org.springframework.beans.factory.annotation.Autowired
    public CaptchaVerificationService(CaptchaProperties properties, Environment environment) {
        this(properties, environment, buildClient(properties));
    }

    CaptchaVerificationService(CaptchaProperties properties, Environment environment, RestClient client) {
        this.properties = properties;
        this.client = client;
        if (environment.matchesProfiles("prod") && (!properties.enabled()
                || properties.secret() == null || properties.secret().isBlank()
                || properties.siteKey() == null || properties.siteKey().isBlank())) {
            throw new IllegalStateException("CAPTCHA debe estar habilitado y configurado en prod");
        }
    }

    private static RestClient buildClient(CaptchaProperties properties) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        int timeout = (int) Math.max(250, properties.timeout().toMillis());
        factory.setConnectTimeout(timeout); factory.setReadTimeout(timeout);
        return RestClient.builder().requestFactory(factory).build();
    }

    public void verify(String token) {
        if (!properties.enabled()) {
            LOG.info("contact.captcha outcome=disabled correlationId={}", com.ferreplus.publico.config.SafeDiagnosticLog.correlationId("unknown"));
            return;
        }
        if (token == null || token.isBlank()) {
            LOG.info("contact.captcha outcome=failure code=missing_token correlationId={}", com.ferreplus.publico.config.SafeDiagnosticLog.correlationId("unknown"));
            throw new PublicApiException(HttpStatus.BAD_REQUEST, "CAPTCHA requerido");
        }
        if (properties.secret() == null || properties.secret().isBlank()) {
            LOG.warn("contact.captcha outcome=failure code=not_configured correlationId={}", com.ferreplus.publico.config.SafeDiagnosticLog.correlationId("unknown"));
            throw new PublicApiException(HttpStatus.SERVICE_UNAVAILABLE, "CAPTCHA no configurado");
        }
        try {
            VerificationResponse result = client.post().uri(properties.verifyUrl())
                    .header("Content-Type", "application/x-www-form-urlencoded")
                    .body("secret=" + encode(properties.secret()) + "&response=" + encode(token))
                    .retrieve().body(VerificationResponse.class);
            if (result == null || !result.success()) {
                LOG.info("contact.captcha outcome=failure code=provider_rejected correlationId={}", com.ferreplus.publico.config.SafeDiagnosticLog.correlationId("unknown"));
                throw new PublicApiException(HttpStatus.FORBIDDEN, "CAPTCHA invalido o expirado");
            }
            LOG.info("contact.captcha outcome=success correlationId={}", com.ferreplus.publico.config.SafeDiagnosticLog.correlationId("unknown"));
        } catch (PublicApiException exception) {
            throw exception;
        } catch (RestClientException exception) {
            LOG.warn("contact.captcha outcome=failure code=provider_unavailable correlationId={} failure={}",
                    com.ferreplus.publico.config.SafeDiagnosticLog.correlationId("unknown"),
                    com.ferreplus.publico.config.SafeDiagnosticLog.failure(exception));
            throw new PublicApiException(HttpStatus.SERVICE_UNAVAILABLE, "Proveedor CAPTCHA no disponible");
        }
    }

    private String encode(String value) {
        return java.net.URLEncoder.encode(value, java.nio.charset.StandardCharsets.UTF_8);
    }

    private record VerificationResponse(boolean success, Map<String, Object> metadata) { }
}
