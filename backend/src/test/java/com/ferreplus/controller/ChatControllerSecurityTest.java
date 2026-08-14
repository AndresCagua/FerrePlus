package com.ferreplus.controller;

import com.ferreplus.dto.AuthLoginDTO;
import com.ferreplus.dto.AuthResponseDTO;
import com.ferreplus.service.AuthService;
import com.ferreplus.service.chat.ChatService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ChatControllerSecurityTest {
    @Autowired private MockMvc mockMvc;
    @Autowired private AuthService authService;
    @MockitoBean private ChatService chatService;

    @Test
    void anonymousChatRequestIsRejectedBeforeServiceExecution() throws Exception {
        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"question\":\"¿Que hay?\"}"))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(chatService);
    }

    @Test
    void authenticatedChatRequestReturnsExistingResponseContract() throws Exception {
        AuthLoginDTO login = new AuthLoginDTO();
        login.setEmail("admin@ferreplus.com");
        login.setPassword("admin123");
        AuthResponseDTO auth = authService.login(login);
        when(chatService.answer("consulta segura")).thenReturn(
                new ChatService.ChatResult("Respuesta segura", List.of()));

        mockMvc.perform(post("/api/chat")
                        .header("Authorization", "Bearer " + auth.getToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"question\":\"consulta segura\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.answer").value("Respuesta segura"))
                .andExpect(jsonPath("$.sources").isArray())
                .andExpect(jsonPath("$.sources").isEmpty());
    }
}
