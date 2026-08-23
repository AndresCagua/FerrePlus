package com.ferreplus.controller;

import com.ferreplus.dto.SeoSuggestionResponse;
import com.ferreplus.auth.JwtTokenProvider;
import com.ferreplus.auth.JwtAuthenticationFilter;
import com.ferreplus.auth.JwtAuthenticationEntryPoint;
import com.ferreplus.auth.PermisoResolver;
import com.ferreplus.config.SecurityConfig;
import com.ferreplus.repository.UsuarioRepository;
import com.ferreplus.service.seo.SeoSuggestionService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.security.test.context.support.WithMockUser;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(SeoSuggestionController.class)
@AutoConfigureMockMvc
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, JwtAuthenticationEntryPoint.class})
class SeoSuggestionControllerTest {
    @Autowired MockMvc mockMvc;
    @MockBean SeoSuggestionService service;
    @MockBean JwtTokenProvider jwtTokenProvider;
    @MockBean UsuarioRepository usuarioRepository;
    @MockBean PermisoResolver permisoResolver;

    @Test
    void sinJwtDevuelve401YNoInvocaIa() throws Exception {
        mockMvc.perform(post("/api/admin/talento/publicaciones/seo")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titulo\":\"Publicacion\"}"))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(service);
    }

    @Test
    @WithMockUser(authorities = "TALENTO_PUBLICACIONES_VER")
    void sinPermisoDeEdicionDevuelve403YNoInvocaIa() throws Exception {
        mockMvc.perform(post("/api/admin/talento/publicaciones/seo")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titulo\":\"Publicacion\"}"))
                .andExpect(status().isForbidden());

        verifyNoInteractions(service);
    }

    @Test
    @WithMockUser(authorities = "TALENTO_PUBLICACIONES_EDITAR")
    void requestValidoDevuelveSugerencia() throws Exception {
        when(service.suggest(any())).thenReturn(new SeoSuggestionResponse("Titulo", "Descripcion"));

        mockMvc.perform(post("/api/admin/talento/publicaciones/seo")
                        .header("X-Correlation-ID", "seo-test-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titulo\":\"Publicacion\",\"resumen\":\"Resumen\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("Titulo"))
                .andExpect(jsonPath("$.description").value("Descripcion"));
    }

    @Test
    @WithMockUser(authorities = "TALENTO_PUBLICACIONES_EDITAR")
    void requestExcedidoDevuelveProblemDetail400SinInvocarIa() throws Exception {
        mockMvc.perform(post("/api/admin/talento/publicaciones/seo")
                        .header("X-Correlation-ID", "seo-test-2")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titulo\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.correlationId").exists());

        verifyNoInteractions(service);
    }

    @Test
    @WithMockUser(authorities = "TALENTO_PUBLICACIONES_EDITAR")
    void respuestaIncompletaConserva502BadGateway() throws Exception {
        when(service.suggest(any()))
                .thenThrow(new com.ferreplus.exception.SeoSuggestionException("incompleta", 502));

        mockMvc.perform(post("/api/admin/talento/publicaciones/seo")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titulo\":\"Publicacion\"}"))
                .andExpect(status().isBadGateway())
                .andExpect(jsonPath("$.status").value(502));
    }
}
