package com.ferreplus.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "chat.analytics")
public record ChatAnalyticsProperties(boolean enabled) {
    public ChatAnalyticsProperties() {
        this(true);
    }
}
