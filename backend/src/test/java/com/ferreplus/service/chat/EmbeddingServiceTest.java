package com.ferreplus.service.chat;

import com.ferreplus.client.GeminiClient;
import com.ferreplus.exception.GeminiException;
import com.ferreplus.service.EmbeddingService;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

class EmbeddingServiceTest {

    @Test
    void embed_returns768DimensionsFromGemini() {
        GeminiClient client = mock(GeminiClient.class);
        float[] embedding = new float[768];
        embedding[0] = 0.5f;
        when(client.embed("pregunta")).thenReturn(embedding);

        float[] result = new EmbeddingService(client).embed("pregunta");

        assertThat(result).hasSize(768).containsExactly(embedding);
    }

    @Test
    void embed_propagatesRateLimitAsGeminiException() {
        GeminiClient client = mock(GeminiClient.class);
        when(client.embed("pregunta")).thenThrow(new GeminiException("rate limit", 429));

        assertThatThrownBy(() -> new EmbeddingService(client).embed("pregunta"))
                .isInstanceOf(GeminiException.class)
                .extracting("statusCode").isEqualTo(429);
    }

    @Test
    void embed_rejectsUnexpectedDimensions() {
        GeminiClient client = mock(GeminiClient.class);
        when(client.embed("pregunta")).thenReturn(new float[3]);

        assertThatThrownBy(() -> new EmbeddingService(client).embed("pregunta"))
                .isInstanceOf(GeminiException.class)
                .hasMessageContaining("768");
    }
}
