package com.ferreplus.publico.config;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.captcha")
public record CaptchaProperties(boolean enabled, String secret, String siteKey, String verifyUrl,
                                Duration timeout) {
    public CaptchaProperties {
        verifyUrl = verifyUrl == null || verifyUrl.isBlank()
                ? "https://challenges.cloudflare.com/turnstile/v0/siteverify" : verifyUrl;
        timeout = timeout == null ? Duration.ofSeconds(3) : timeout;
    }
}
