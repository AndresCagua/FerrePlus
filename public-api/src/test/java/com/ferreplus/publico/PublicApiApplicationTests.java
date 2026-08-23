package com.ferreplus.publico;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mail.javamail.JavaMailSenderImpl;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PublicApiApplicationTests {
    @Autowired MockMvc mockMvc;
    @Autowired JavaMailSenderImpl mailSender;

    @Test
    void contextLoadsWithoutPostgresConfiguration() {
        assertThat(PublicApiApplication.class).isNotNull();
    }

    @Test
    void mailSenderRequiresAuthenticatedStartTlsByDefault() {
        assertThat(mailSender.getJavaMailProperties())
                .containsEntry("mail.smtp.auth", "true")
                .containsEntry("mail.smtp.starttls.enable", "true")
                .containsEntry("mail.smtp.starttls.required", "true")
                .containsEntry("mail.smtp.connectiontimeout", "5000")
                .containsEntry("mail.smtp.timeout", "5000")
                .containsEntry("mail.smtp.writetimeout", "5000");
    }

    @Test
    void publicPingReturnsCorrelationId() throws Exception {
        mockMvc.perform(get("/api/public/ping"))
                .andExpect(status().isOk())
                .andExpect(header().exists("X-Correlation-ID"));
    }

    @Test
    void internalPingRequiresS2sAuthentication() throws Exception {
        mockMvc.perform(get("/api/internal/ping"))
                .andExpect(status().isForbidden());
    }
}
