package com.ferreplus.publico;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PublicApiApplicationTests {
    @Autowired MockMvc mockMvc;

    @Test
    void contextLoadsWithoutPostgresConfiguration() {
        assertThat(PublicApiApplication.class).isNotNull();
    }

    @Test
    void publicPingReturnsCorrelationId() throws Exception {
        mockMvc.perform(get("/api/public/ping"))
                .andExpect(status().isOk())
                .andExpect(header().exists("X-Correlation-ID"));
    }

    @Test
    void internalPingIsAvailableForContainerReadiness() throws Exception {
        mockMvc.perform(get("/api/internal/ping"))
                .andExpect(status().isOk());
    }
}
