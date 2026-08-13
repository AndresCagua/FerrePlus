package com.ferreplus.service.chat;

import com.ferreplus.service.GeminiChatService;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

class ChatServiceTest {

    @Test
    void answer_withContext_returnsAnswerAndSources() {
        RagService rag = mock(RagService.class);
        GeminiChatService gemini = mock(GeminiChatService.class);
        RagService.Source source = new RagService.Source("PRODUCTO", 4L, "Cable");
        when(rag.search("¿Que hay?", 5)).thenReturn(new RagService.RagResult(
                "[PRODUCTO:4] Cable", List.of(source), List.of(new com.ferreplus.entity.DocumentEmbedding())));
        when(gemini.generate(anyString())).thenReturn("Hay un cable. [PRODUCTO:4]");

        ChatService.ChatResult result = new ChatService(rag, gemini).answer("¿Que hay?");

        assertThat(result.answer()).contains("[PRODUCTO:4]");
        assertThat(result.sources()).containsExactly(source);
    }

    @Test
    void answer_emptyQuestion_rejectsValidation() {
        ChatService service = new ChatService(mock(RagService.class), mock(GeminiChatService.class));

        assertThatThrownBy(() -> service.answer("  "))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("pregunta");
    }

    @Test
    void answer_withoutDocuments_returnsFriendlyMessageWithoutCallingGemini() {
        RagService rag = mock(RagService.class);
        GeminiChatService gemini = mock(GeminiChatService.class);
        when(rag.search("sin resultados", 5)).thenReturn(new RagService.RagResult("", List.of(), List.of()));

        ChatService.ChatResult result = new ChatService(rag, gemini).answer("sin resultados");

        assertThat(result.answer()).contains("No dispongo de datos suficientes");
        verifyNoInteractions(gemini);
    }
}
