package com.ferreplus.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "app.typesafe")
public class TypeSafeProperties {

    private String apiKey;
    private String baseUrl = "https://api.typesafe.ai";
    private String model = "jev-latest";
    private int timeoutSeconds = 10;
    private int maxRetries = 1;
}
