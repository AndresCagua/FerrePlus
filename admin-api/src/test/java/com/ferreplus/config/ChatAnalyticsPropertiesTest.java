package com.ferreplus.config;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(properties = "chat.analytics.enabled=false")
@ActiveProfiles("test")
class ChatAnalyticsPropertiesTest {
    @Autowired
    private ChatAnalyticsProperties properties;

    @Test
    void bindsDisabledValueFromConfiguration() {
        assertThat(properties.enabled()).isFalse();
    }

    @Test
    void explicitTrueValueBindsFromConfiguration() {
        assertThat(new ChatAnalyticsProperties(true).enabled()).isTrue();
    }
}
