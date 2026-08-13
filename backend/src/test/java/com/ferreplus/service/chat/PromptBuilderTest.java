package com.ferreplus.service.chat;

import com.ferreplus.service.GeminiChatService;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class PromptBuilderTest {

    @Test
    void answer_buildsPromptInSpanishWithContextQuestionAndAntiInventionRules() {
        RagService ragService = mock(RagService.class);
        GeminiChatService geminiChatService = mock(GeminiChatService.class);
        when(ragService.search("¿Dónde registro un producto?", 5))
                .thenReturn(new RagService.RagResult(
                        "[GUIA:7] Ruta: /productos. Pasos: abrir Productos y seleccionar Nuevo.",
                        List.of(new RagService.Source("GUIA", 7L, "Registrar producto")),
                        List.of(mock(com.ferreplus.entity.DocumentEmbedding.class))));
        when(geminiChatService.generate(anyString())).thenReturn("Debes ir a /productos. [GUIA:7]");

        new ChatService(ragService, geminiChatService).answer("¿Dónde registro un producto?");

        ArgumentCaptor<String> prompt = ArgumentCaptor.forClass(String.class);
        verify(geminiChatService).generate(prompt.capture());
        assertThat(prompt.getValue())
                .contains("Responde en espanol")
                .contains("unicamente el contexto")
                .contains("No inventes cifras, rutas ni pasos")
                .contains("[GUIA:7]")
                .contains("¿Dónde registro un producto?");
    }
}
