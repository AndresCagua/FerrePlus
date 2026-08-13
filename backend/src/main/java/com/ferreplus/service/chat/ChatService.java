package com.ferreplus.service.chat;

import com.ferreplus.service.GeminiChatService;
import org.springframework.stereotype.Service;

@Service
public class ChatService {
    private final RagService ragService;
    private final GeminiChatService geminiChatService;

    public ChatService(RagService ragService, GeminiChatService geminiChatService) { this.ragService = ragService; this.geminiChatService = geminiChatService; }

    public ChatResult answer(String question) {
        if (question == null || question.isBlank()) throw new IllegalArgumentException("La pregunta no puede estar vacia");
        RagService.RagResult rag = ragService.search(question, 5);
        if (rag.documents().isEmpty()) return new ChatResult("No dispongo de datos suficientes para responder esa pregunta.", rag.sources());
        String prompt = "Responde en espanol usando unicamente el contexto. No inventes cifras, rutas ni pasos. Cita cada fuente con [TIPO:id].\n\nContexto:\n" + rag.context() + "\n\nPregunta: " + question;
        return new ChatResult(geminiChatService.generate(prompt), rag.sources());
    }

    public record ChatResult(String answer, java.util.List<RagService.Source> sources) {}
}
