package com.ferreplus.config;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(properties = "chat.analytics.enabled=true")
@ActiveProfiles("test")
class ChatAnalyticsPropertiesEnabledTest {
    @Autowired
    private ChatAnalyticsProperties properties;

    @Test
    void bindsEnabledValueFromConfiguration() {
        assertThat(properties.enabled()).isTrue();
    }
}
