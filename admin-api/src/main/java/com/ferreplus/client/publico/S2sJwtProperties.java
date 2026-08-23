package com.ferreplus.client.publico;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.s2s")
public record S2sJwtProperties(String issuer, String audience, String subject, String keyId,
                               String privateKey, String privateKeyFile, Duration tokenLifetime, String publicApiUrl) {
    public S2sJwtProperties {
        issuer = issuer == null ? "ferreplus-admin-api" : issuer;
        audience = audience == null ? "ferreplus-public-api" : audience;
        subject = subject == null ? "admin-api" : subject;
        tokenLifetime = tokenLifetime == null ? Duration.ofSeconds(120) : tokenLifetime;
        publicApiUrl = publicApiUrl == null ? "http://public-api:8080" : publicApiUrl;
    }
}
