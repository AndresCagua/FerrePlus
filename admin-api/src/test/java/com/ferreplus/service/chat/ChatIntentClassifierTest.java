package com.ferreplus.service.chat;

import com.ferreplus.client.TypeSafeClient;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class ChatIntentClassifierTest {

    @Test
    void parse_acceptsEverySimpleIntent() {
        ChatIntentClassifier classifier = new ChatIntentClassifier(mock(TypeSafeClient.class));

        assertThat(classifier.parse("INTENT: mas_vendidos").intent()).isEqualTo(ChatIntent.MAS_VENDIDOS);
        assertThat(classifier.parse("INTENT: ventas_mes").intent()).isEqualTo(ChatIntent.VENTAS_MES);
        assertThat(classifier.parse("INTENT: stock_bajo").intent()).isEqualTo(ChatIntent.STOCK_BAJO);
        assertThat(classifier.parse("INTENT: mayor_compra").intent()).isEqualTo(ChatIntent.MAYOR_COMPRA);
        assertThat(classifier.parse("INTENT: mayor_gasto").intent()).isEqualTo(ChatIntent.MAYOR_GASTO);
        assertThat(classifier.parse("INTENT: proveedor_top").intent()).isEqualTo(ChatIntent.PROVEEDOR_TOP);
        assertThat(classifier.parse("INTENT: guia_catalogo").intent()).isEqualTo(ChatIntent.GUIA_CATALOGO);
        assertThat(classifier.parse("INTENT: desconocido").intent()).isEqualTo(ChatIntent.DESCONOCIDO);
    }

    @Test
    void parse_preservesLegacyValidationForProviderLikeResponses() {
        ChatIntentClassifier classifier = new ChatIntentClassifier(mock(TypeSafeClient.class));
        assertThat(classifier.parse("INTENT: ultimo_cambio; ENTITY: PRODUCTO; NAME: Martillo"))
                .isEqualTo(new ChatIntentResult(ChatIntent.ULTIMO_CAMBIO, ChatEntity.PRODUCTO, Optional.of("Martillo")));
        assertThat(classifier.parse("INTENT: ultimo_cambio; ENTITY: PRODUCTO; NAME: Select; DROP"))
                .isEqualTo(ChatIntentResult.unknown());
    }

    @Test
    void classify_returnsJevChoice() {
        TypeSafeClient typeSafe = mock(TypeSafeClient.class);
        when(typeSafe.classify("pregunta")).thenReturn("stock_bajo");

        ChatIntentResult result = new ChatIntentClassifier(typeSafe).classify("pregunta");

        assertThat(result.intent()).isEqualTo(ChatIntent.STOCK_BAJO);
        verify(typeSafe).classify("pregunta");
    }

    @Test
    void classify_extractsEntityForLastChangeFromQuestion() {
        TypeSafeClient typeSafe = mock(TypeSafeClient.class);
        when(typeSafe.classify(anyString())).thenReturn("ultimo_cambio");

        ChatIntentResult result = new ChatIntentClassifier(typeSafe)
                .classify("¿Cuál fue el último cambio del producto?");

        assertThat(result).isEqualTo(new ChatIntentResult(
                ChatIntent.ULTIMO_CAMBIO, ChatEntity.PRODUCTO, Optional.empty()));
    }

    @Test
    void classify_mapsProviderFailureToUnknownWithoutAnalyticalCalls() {
        TypeSafeClient typeSafe = mock(TypeSafeClient.class);
        when(typeSafe.classify(anyString())).thenThrow(new RuntimeException("timeout"));

        ChatIntentResult result = new ChatIntentClassifier(typeSafe).classify("pregunta");

        assertThat(result).isEqualTo(ChatIntentResult.unknown());
        verify(typeSafe).classify("pregunta");
        verifyNoMoreInteractions(typeSafe);
    }
}
