package com.ferreplus.service.chat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ferreplus.entity.DocumentEmbedding;
import com.ferreplus.repository.DocumentEmbeddingRepository;
import com.ferreplus.service.EmbeddingService;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
public class RagService {
    private final EmbeddingService embeddingService;
    private final DocumentEmbeddingRepository documentRepository;
    private final ObjectMapper objectMapper;

    public RagService(EmbeddingService embeddingService, DocumentEmbeddingRepository documentRepository, ObjectMapper objectMapper) {
        this.embeddingService = embeddingService; this.documentRepository = documentRepository; this.objectMapper = objectMapper;
    }

    public RagResult search(String question, int limit) {
        List<DocumentEmbedding> documents = documentRepository.findNearest(embeddingService.toPgVector(embeddingService.embed(question)), Math.max(1, limit));
        List<Source> sources = documents.stream().map(this::source).toList();
        String context = documents.stream().map(document -> "[" + document.getEntityType() + ":" + document.getEntityId() + "] " + document.getContentText()).reduce("", (left, right) -> left.isBlank() ? right : left + "\n\n" + right);
        return new RagResult(context, sources, documents);
    }

    public Answer answer(String question) {
        RagResult result = search(question, 5);
        if (result.documents().isEmpty()) return new Answer("No dispongo de datos suficientes para responder esa pregunta.", result.sources());
        return new Answer(result.context(), result.sources());
    }

    private Source source(DocumentEmbedding document) {
        String title = document.getEntityType() + " " + document.getEntityId();
        try { if (document.getMetadata() != null) title = objectMapper.readTree(document.getMetadata()).path("title").asText(title); } catch (Exception ignored) { }
        return new Source(document.getEntityType(), document.getEntityId(), title);
    }
    public record Source(String entityType, Long entityId, String title) {}
    public record RagResult(String context, List<Source> sources, List<DocumentEmbedding> documents) {}
    public record Answer(String answer, List<Source> sources) {}
}
