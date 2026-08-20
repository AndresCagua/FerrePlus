package com.ferreplus.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.ConstructorBinding;
import org.springframework.boot.context.properties.bind.DefaultValue;

@ConfigurationProperties(prefix = "chat.analytics")
public record ChatAnalyticsProperties(boolean enabled) {
    @ConstructorBinding
    public ChatAnalyticsProperties(@DefaultValue("true") boolean enabled) {
        this.enabled = enabled;
    }
}
