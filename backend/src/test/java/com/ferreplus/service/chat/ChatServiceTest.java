package com.ferreplus.service.chat;

import com.ferreplus.config.ChatAnalyticsProperties;
import com.ferreplus.service.GeminiChatService;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Optional;

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

        ChatService.ChatResult result = new ChatService(
                rag, gemini, new ChatAnalyticsProperties(false), null, null, null).answer("¿Que hay?");

        assertThat(result.answer()).contains("[PRODUCTO:4]");
        assertThat(result.sources()).containsExactly(source);
    }

    @Test
    void answer_emptyQuestion_rejectsValidation() {
        ChatService service = new ChatService(
                mock(RagService.class), mock(GeminiChatService.class),
                new ChatAnalyticsProperties(false), null, null, null);

        assertThatThrownBy(() -> service.answer("  "))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("pregunta");
    }

    @Test
    void answer_withoutDocuments_returnsFriendlyMessageWithoutCallingGemini() {
        RagService rag = mock(RagService.class);
        GeminiChatService gemini = mock(GeminiChatService.class);
        when(rag.search("sin resultados", 5)).thenReturn(new RagService.RagResult("", List.of(), List.of()));

        ChatService.ChatResult result = new ChatService(
                rag, gemini, new ChatAnalyticsProperties(false), null, null, null).answer("sin resultados");

        assertThat(result.answer()).contains("No dispongo de datos suficientes");
        verifyNoInteractions(gemini);
    }

    @Test
    void answer_routesMostExpensivePurchaseAndComposesEmptyResult() {
        ChatIntent intent = ChatIntent.MAYOR_COMPRA;
        ChatRouter router = mock(ChatRouter.class);
        ChatIntentClassifier classifier = mock(ChatIntentClassifier.class);
        AnalyticalResponseComposer composer = mock(AnalyticalResponseComposer.class);
        when(classifier.classify("compra mas cara")).thenReturn(new ChatIntentResult(intent, null, Optional.empty()));
        when(router.route(eq(new ChatIntentResult(intent, null, Optional.empty())), any(), eq("compra mas cara")))
                .thenReturn(new ChatRouteResult(intent, Optional.empty(), false));
        when(composer.composeMayorCompra(Optional.empty())).thenReturn("No se encontraron compras completadas.");

        ChatService.ChatResult result = new ChatService(mock(RagService.class), mock(GeminiChatService.class),
                new ChatAnalyticsProperties(true), classifier, router, composer).answer("compra mas cara");

        assertThat(result.answer()).isEqualTo("No se encontraron compras completadas.");
        verify(composer).composeMayorCompra(Optional.empty());
    }

    @Test
    void answer_routesLargestExpenseAndTopProvider() {
        ChatRouter router = mock(ChatRouter.class);
        ChatIntentClassifier classifier = mock(ChatIntentClassifier.class);
        AnalyticalResponseComposer composer = mock(AnalyticalResponseComposer.class);
        ChatService service = new ChatService(mock(RagService.class), mock(GeminiChatService.class),
                new ChatAnalyticsProperties(true), classifier, router, composer);

        when(classifier.classify("mayor gasto")).thenReturn(
                new ChatIntentResult(ChatIntent.MAYOR_GASTO, null, Optional.empty()));
        when(router.route(eq(new ChatIntentResult(ChatIntent.MAYOR_GASTO, null, Optional.empty())), any(),
                eq("mayor gasto"))).thenReturn(new ChatRouteResult(ChatIntent.MAYOR_GASTO, Optional.empty(), false));
        when(composer.composeMayorGasto(Optional.empty())).thenReturn("No se encontraron gastos registrados.");
        assertThat(service.answer("mayor gasto").answer()).isEqualTo("No se encontraron gastos registrados.");

        when(classifier.classify("proveedor top")).thenReturn(
                new ChatIntentResult(ChatIntent.PROVEEDOR_TOP, null, Optional.empty()));
        when(router.route(eq(new ChatIntentResult(ChatIntent.PROVEEDOR_TOP, null, Optional.empty())), any(),
                eq("proveedor top"))).thenReturn(new ChatRouteResult(ChatIntent.PROVEEDOR_TOP, Optional.empty(), false));
        when(composer.composeProveedorTop(Optional.empty())).thenReturn("No se encontraron compras registradas.");
        assertThat(service.answer("proveedor top").answer()).isEqualTo("No se encontraron compras registradas.");

        verify(composer).composeMayorGasto(Optional.empty());
        verify(composer).composeProveedorTop(Optional.empty());
    }
}
