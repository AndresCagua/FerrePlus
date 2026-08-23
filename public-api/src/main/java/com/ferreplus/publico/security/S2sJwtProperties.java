package com.ferreplus.publico.security;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.s2s")
public record S2sJwtProperties(String issuer, String audience, String bootstrapPublicKey,
                               String bootstrapPublicKeyFile, Duration clockSkew) {
    public S2sJwtProperties {
        issuer = issuer == null ? "ferreplus-admin-api" : issuer;
        audience = audience == null ? "ferreplus-public-api" : audience;
        clockSkew = clockSkew == null ? Duration.ofSeconds(30) : clockSkew;
    }
}
