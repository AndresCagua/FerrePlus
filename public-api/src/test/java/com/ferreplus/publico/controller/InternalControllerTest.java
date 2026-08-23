package com.ferreplus.publico.controller;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.ferreplus.publico.exception.GlobalExceptionHandler;
import com.ferreplus.publico.exception.PublicApiException;
import com.ferreplus.publico.model.Convocatoria;
import com.ferreplus.publico.service.ContactoService;
import com.ferreplus.publico.service.ConvocatoriaService;
import com.ferreplus.publico.service.DestinatarioService;
import com.ferreplus.publico.service.PostulacionService;
import com.ferreplus.publico.service.PublicacionService;
import com.ferreplus.publico.mail.MailEventListener;
import com.ferreplus.publico.security.KeyService;
import com.ferreplus.publico.storage.MinioObjectStorage;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

@ExtendWith(MockitoExtension.class)
class InternalControllerTest {
    @Mock ConvocatoriaService convocatorias;
    @Mock PostulacionService postulaciones;
    @Mock MinioObjectStorage storage;
    @Mock PublicacionService publicaciones;
    @Mock ContactoService contactos;
    @Mock DestinatarioService destinatarios;
    @Mock MailEventListener mail;
    @Mock KeyService keys;
    @InjectMocks InternalController controller;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    void getConvocatoriaReturnsMappedResponse() throws Exception {
        Convocatoria convocatoria = new Convocatoria();
        convocatoria.setId("c-1");
        convocatoria.setTitulo("Convocatoria existente");
        when(convocatorias.find("c-1")).thenReturn(convocatoria);

        mockMvc.perform(get("/api/internal/convocatorias/c-1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value("c-1"))
                .andExpect(jsonPath("$.titulo").value("Convocatoria existente"));
    }

    @Test
    void getMissingConvocatoriaReturnsNotFound() throws Exception {
        when(convocatorias.find("missing"))
                .thenThrow(new PublicApiException(org.springframework.http.HttpStatus.NOT_FOUND,
                        "Convocatoria no encontrada"));

        mockMvc.perform(get("/api/internal/convocatorias/missing"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.detail").value("Convocatoria no encontrada"));
    }
}
