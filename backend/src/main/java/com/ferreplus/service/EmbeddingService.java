package com.ferreplus.service;

import com.ferreplus.client.GeminiClient;
import com.ferreplus.exception.GeminiException;
import org.springframework.stereotype.Service;

import java.util.Locale;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

@Service
public class EmbeddingService {

    private final GeminiClient geminiClient;

    public EmbeddingService(GeminiClient geminiClient) {
        this.geminiClient = geminiClient;
    }

    public float[] embed(String content) {
        try {
            float[] embedding = geminiClient.embed(content);
            if (embedding.length != 768) {
                throw new GeminiException("El embedding generado no tiene 768 dimensiones", 502);
            }
            return embedding;
        } catch (GeminiException exception) {
            throw exception;
        } catch (RuntimeException exception) {
            throw new GeminiException("No se pudo generar el embedding del contenido", 503, exception);
        }
    }

    public String toPgVector(float[] embedding) {
        return "[" + IntStream.range(0, embedding.length)
                .mapToObj(index -> String.format(Locale.ROOT, "%.8f", embedding[index]))
                .collect(Collectors.joining(",")) + "]";
    }
}
