package com.ferreplus.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "app.gemini")
public class GeminiProperties {

    private String apiKey;
    private String baseUrl = "https://generativelanguage.googleapis.com";
    private String embeddingModel = "gemini-embedding-001";
    private String chatModel = "gemini-2.0-flash";
    private int timeoutSeconds = 10;
    private int maxRetries = 1;
}
