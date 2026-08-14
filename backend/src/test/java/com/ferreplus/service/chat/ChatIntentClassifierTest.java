package com.ferreplus.service.chat;

import com.ferreplus.service.GeminiChatService;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class ChatIntentClassifierTest {

    @Test
    void parse_acceptsEverySimpleIntent() {
        ChatIntentClassifier classifier = new ChatIntentClassifier(mock(GeminiChatService.class));

        assertThat(classifier.parse("INTENT: mas_vendidos").intent()).isEqualTo(ChatIntent.MAS_VENDIDOS);
        assertThat(classifier.parse("INTENT: ventas_mes").intent()).isEqualTo(ChatIntent.VENTAS_MES);
        assertThat(classifier.parse("INTENT: stock_bajo").intent()).isEqualTo(ChatIntent.STOCK_BAJO);
        assertThat(classifier.parse("INTENT: guia_catalogo").intent()).isEqualTo(ChatIntent.GUIA_CATALOGO);
        assertThat(classifier.parse("INTENT: desconocido").intent()).isEqualTo(ChatIntent.DESCONOCIDO);
    }

    @Test
    void parse_acceptsLastChangeWithEntityAndName() {
        ChatIntentResult result = new ChatIntentClassifier(mock(GeminiChatService.class))
                .parse("INTENT: ultimo_cambio; ENTITY: PRODUCTO; NAME: Martillo");

        assertThat(result).isEqualTo(new ChatIntentResult(
                ChatIntent.ULTIMO_CAMBIO, ChatEntity.PRODUCTO, Optional.of("Martillo")));
    }

    @Test
    void parse_acceptsLastChangeWithoutName() {
        ChatIntentResult result = new ChatIntentClassifier(mock(GeminiChatService.class))
                .parse("INTENT: ultimo_cambio; ENTITY: VENTA; NAME: ");

        assertThat(result).isEqualTo(new ChatIntentResult(
                ChatIntent.ULTIMO_CAMBIO, ChatEntity.VENTA, Optional.empty()));
    }

    @Test
    void parse_trimsOnlyOuterWhitespace() {
        assertThat(new ChatIntentClassifier(mock(GeminiChatService.class))
                .parse("\n INTENT: mas_vendidos \t").intent())
                .isEqualTo(ChatIntent.MAS_VENDIDOS);
    }

    @Test
    void parse_rejectsExtraTextJsonSqlAndComments() {
        ChatIntentClassifier classifier = new ChatIntentClassifier(mock(GeminiChatService.class));

        assertUnknown(classifier.parse("INTENT: mas_vendidos\nextra"));
        assertUnknown(classifier.parse("{\"intent\":\"mas_vendidos\"}"));
        assertUnknown(classifier.parse("DROP TABLE productos;"));
        assertUnknown(classifier.parse("/* DROP TABLE productos */"));
        assertUnknown(classifier.parse("INTENT: ultimo_cambio; ENTITY: PRODUCTO; NAME: /* DROP */"));
    }

    @Test
    void parse_rejectsInvalidEntityAndUnsupportedName() {
        ChatIntentClassifier classifier = new ChatIntentClassifier(mock(GeminiChatService.class));

        assertUnknown(classifier.parse("INTENT: ultimo_cambio; ENTITY: FACTURA; NAME: x"));
        assertUnknown(classifier.parse("INTENT: ultimo_cambio; ENTITY: VENTA; NAME: factura-1"));
        assertUnknown(classifier.parse("INTENT: ultimo_cambio; ENTITY: PRODUCTO; NAME: Martillo; DROP"));
    }

    @Test
    void classify_returnsParsedIntentFromGemini() {
        GeminiChatService gemini = mock(GeminiChatService.class);
        when(gemini.classify("pregunta")).thenReturn("INTENT: stock_bajo");

        ChatIntentResult result = new ChatIntentClassifier(gemini).classify("pregunta");

        assertThat(result.intent()).isEqualTo(ChatIntent.STOCK_BAJO);
        verify(gemini).classify("pregunta");
    }

    @Test
    void classify_mapsExceptionAndTimeoutToUnknownWithoutAnalyticalCalls() {
        GeminiChatService gemini = mock(GeminiChatService.class);
        when(gemini.classify(anyString())).thenThrow(new RuntimeException("timeout"));

        ChatIntentResult result = new ChatIntentClassifier(gemini).classify("pregunta");

        assertUnknown(result);
        verify(gemini).classify("pregunta");
        verifyNoMoreInteractions(gemini);
    }

    private void assertUnknown(ChatIntentResult result) {
        assertThat(result).isEqualTo(ChatIntentResult.unknown());
    }
}
