package com.ferreplus.service.chat;

import com.ferreplus.client.GeminiClient;
import com.ferreplus.exception.GeminiException;
import com.ferreplus.service.GeminiChatService;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

class GeminiChatServiceTest {

    @Test
    void generate_returnsGeminiAnswer() {
        GeminiClient client = mock(GeminiClient.class);
        when(client.generate(anyString())).thenReturn("Respuesta en espanol");

        assertThat(new GeminiChatService(client).generate("Contexto: producto"))
                .isEqualTo("Respuesta en espanol");
        verify(client).generate(argThat(prompt -> prompt.contains("Responde siempre en espanol")));
    }

    @Test
    void generate_translatesRateLimitToFriendlyError() {
        GeminiClient client = mock(GeminiClient.class);
        when(client.generate(anyString())).thenThrow(new GeminiException("internal 429", 429));

        assertThatThrownBy(() -> new GeminiChatService(client).generate("contexto"))
                .isInstanceOf(GeminiException.class)
                .hasMessageContaining("Intenta nuevamente mas tarde")
                .extracting("statusCode").isEqualTo(429);
    }

    @Test
    void generate_hidesProviderDetailsOnFailure() {
        GeminiClient client = mock(GeminiClient.class);
        when(client.generate(anyString())).thenThrow(new RuntimeException("https://internal-provider/secret"));

        assertThatThrownBy(() -> new GeminiChatService(client).generate("contexto"))
                .isInstanceOf(GeminiException.class)
                .hasMessageContaining("no esta disponible")
                .hasMessageNotContaining("internal-provider");
    }
}
