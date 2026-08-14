package com.ferreplus.service.chat;

import com.ferreplus.config.ChatAnalyticsProperties;
import com.ferreplus.service.GeminiChatService;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class ChatService {
    private final RagService ragService;
    private final GeminiChatService geminiChatService;
    private final ChatAnalyticsProperties analyticsProperties;
    private final ChatIntentClassifier intentClassifier;
    private final ChatRouter chatRouter;
    private final AnalyticalResponseComposer responseComposer;

    public ChatService(RagService ragService, GeminiChatService geminiChatService,
                       ChatAnalyticsProperties analyticsProperties, ChatIntentClassifier intentClassifier,
                       ChatRouter chatRouter, AnalyticalResponseComposer responseComposer) {
        this.ragService = ragService;
        this.geminiChatService = geminiChatService;
        this.analyticsProperties = analyticsProperties;
        this.intentClassifier = intentClassifier;
        this.chatRouter = chatRouter;
        this.responseComposer = responseComposer;
    }

    public ChatResult answer(String question) {
        if (question == null || question.isBlank()) throw new IllegalArgumentException("La pregunta no puede estar vacia");
        if (!analyticsProperties.enabled()) return answerWithRag(question);
        ChatIntentResult intent;
        try {
            intent = intentClassifier.classify(question);
        } catch (RuntimeException exception) {
            return safeFallback();
        }
        if (intent == null || intent.intent() == ChatIntent.DESCONOCIDO) return safeFallback();
        if (intent.intent() == ChatIntent.GUIA_CATALOGO) return answerWithRag(question);

        try {
            return answerAnalytically(intent, question);
        } catch (RuntimeException exception) {
            return safeFallback();
        }
    }

    private ChatResult answerAnalytically(ChatIntentResult intent, String question) {
        var parameters = QueryParameterExtractor.extract(question);
        if (parameters.isEmpty()) return safeFallback();
        ChatRouteResult route = chatRouter.route(intent, parameters.get(), question);
        if (route.fallback()) return safeFallback();
        String answer = switch (route.intent()) {
            case MAS_VENDIDOS -> responseComposer.composeProductosMasVendidos(cast(route.result()));
            case VENTAS_MES -> responseComposer.composeVentasMes((VentasMesResult) route.result());
            case STOCK_BAJO -> responseComposer.composeStockBajo(cast(route.result()));
            case ULTIMO_CAMBIO -> responseComposer.composeUltimoCambio(castOptional(route.result()));
            default -> throw new IllegalStateException("Ruta analitica no soportada");
        };
        return new ChatResult(answer, List.of());
    }

    @SuppressWarnings("unchecked")
    private <T> List<T> cast(Object value) {
        return (List<T>) value;
    }

    @SuppressWarnings("unchecked")
    private Optional<UltimoCambioResult> castOptional(Object value) {
        return (Optional<UltimoCambioResult>) value;
    }

    private ChatResult answerWithRag(String question) {
        RagService.RagResult rag = ragService.search(question, 5);
        if (rag.documents().isEmpty()) return new ChatResult("No dispongo de datos suficientes para responder esa pregunta.", rag.sources());
        String prompt = "Responde en espanol usando unicamente el contexto. No inventes cifras, rutas ni pasos. No incluyas marcadores de citacion como [GUIA:1] ni [TIPO:id] en la respuesta; las fuentes se muestran por separado.\n\nContexto:\n" + rag.context() + "\n\nPregunta: " + question;
        return new ChatResult(geminiChatService.generate(prompt), rag.sources());
    }

    private ChatResult safeFallback() {
        return new ChatResult("No puedo resolver esa consulta de forma segura.", List.of());
    }

    public record ChatResult(String answer, java.util.List<RagService.Source> sources) {}
}
